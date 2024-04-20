import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/issue_controller.dart';

import 'auth_controller.dart';
import 'team_controller.dart';

class IssueTag {
  final String id;
  final String name;
  final String description;
  final String color;

  IssueTag(
      {required this.id,
      required this.name,
      required this.description,
      required this.color});

  factory IssueTag.fromJson(Map<String, dynamic> json) {
    return IssueTag(
      id: json['id'] ?? '',
      name: json['name'],
      description: json['description'] ?? '',
      color: json['color'],
    );
  }
  // copyWith
  IssueTag copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
  }) {
    return IssueTag(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
    );
  }
}

class TagsState {
  final List<IssueTag> tags;
  final ApiStatus apiStatus;
  final PerformedAction performedAction;
  final String? errorMessage;
  // filter state
  final String teamId;

  TagsState({
    required this.tags,
    required this.apiStatus,
    required this.performedAction,
    this.errorMessage,
    required this.teamId,
  });

  TagsState copyWith({
    List<IssueTag>? tags,
    ApiStatus? apiStatus,
    PerformedAction? performedAction,
    String? errorMessage,
    String? teamId,
  }) {
    return TagsState(
      tags: tags ?? this.tags,
      apiStatus: apiStatus ?? this.apiStatus,
      performedAction: performedAction ?? this.performedAction,
      errorMessage: errorMessage ?? this.errorMessage,
      teamId: teamId ?? this.teamId,
    );
  }
}

class TagsController extends FamilyNotifier<TagsState, String> {
  @override
  TagsState build(String arg) {
    return TagsState(
      tags: [],
      apiStatus: ApiStatus.idle,
      performedAction: PerformedAction.fetch,
      teamId: arg,
    );
  }

  // fetch tags under the team
  Future<void> fetchTags() async {
    // set loading
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.fetch);
    try {
      // fetch tags from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('teams')
          .doc(state.teamId)
          .collection('tags')
          .get();
      final tags = snapshot.docs
          .map((doc) => IssueTag.fromJson(doc.data()).copyWith(id: doc.id))
          .toList();
      // update the state
      state = state.copyWith(
        tags: tags,
        apiStatus: ApiStatus.success,
      );
    } catch (e, stackTrace) {
      print('Error fetching tags: $e, $stackTrace');
      // set error message
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // update tag
  Future<void> updateTag(
      {required String tagId,
      required String oldTagName,
      String? newTagName,
      String? newColor}) async {
    // set loading
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.update);
    try {
      // update tag on Firestore
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(state.teamId)
          .collection('tags')
          .doc(tagId)
          .update({}
            ..addAll(newTagName != null ? {'name': newTagName} : {})
            ..addAll(newColor != null ? {'color': newColor} : {}));
      // update the state
      final tags = state.tags.map((tag) {
        if (tag.id == tagId) {
          return tag.copyWith(name: newTagName, color: newColor);
        }
        return tag;
      }).toList();
      state = state.copyWith(
        tags: tags,
        apiStatus: ApiStatus.success,
      );
      var updatedIssuesWithNewTags = <(String, List<String>)>[];
      if (newTagName != null && newTagName != oldTagName) {
        // update all tag names in issues/{issueId} the tags array property
        final issuesWithReferencedTag = await FirebaseFirestore.instance
            .collection('teams')
            .doc(state.teamId)
            .collection('issues')
            .where('tags', arrayContains: oldTagName)
            .get();

        for (var doc in issuesWithReferencedTag.docs) {
          final issue = doc.data();
          //final tags = issue['tags'] as List<String>;
          final tags = List<String>.from(issue['tags']);
          final updatedTags = tags.map((tag) {
            if (tag == oldTagName) {
              return newTagName;
            }
            return tag;
          }).toList();
          updatedIssuesWithNewTags.add((doc.id, updatedTags));
          await doc.reference.update({'tags': updatedTags});
        }
        // update the issue states in issue provider
        ref
            .read(issueProvider(state.teamId).notifier)
            .updatedIssuesState(updatedIssuesWithNewTags);
      }
    } catch (e) {
      print('Error updating tag: $e');
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // is tag name exists on Firestore teams/{teamId}/tags
  Future<bool> isTagNameExists(String tagName) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('teams')
        .doc(state.teamId)
        .collection('tags')
        .where('name', isEqualTo: tagName)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // add tag
  Future<void> addTag({
    required String name,
    String? description,

    /// color in hex
    String? color,
  }) async {
    // set loading
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.add);
    try {
      // add tag to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('teams')
          .doc(state.teamId)
          .collection('tags')
          .add({
        'name': name,
        'description': description,
        'color': color,
      });
      // get the newly added tag
      final snapShot = await docRef.get();
      final data = snapShot.data()!;
      final newTag = IssueTag.fromJson(data).copyWith(id: snapShot.id);
      state = state.copyWith(
        tags: [...state.tags, newTag],
        apiStatus: ApiStatus.success,
      );
    } catch (e, stackTrace) {
      print('Error adding tag: $e, $stackTrace');
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // remove tag by name
  Future<void> removeTagByName(String tagName) async {
    // set loading
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.delete);
    try {
      // delete tag from Firestore
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(state.teamId)
          .collection('tags')
          .where('name', isEqualTo: tagName)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
      // update the state
      final tags = state.tags.where((tag) => tag.name != tagName);
      state = state.copyWith(
        tags: tags.toList(),
        apiStatus: ApiStatus.success,
      );
    } catch (e) {
      print('Error deleting tag: $e');
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // remove tag by id
  Future<void> removeTag(String tagId) async {
    // set loading
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.delete);
    try {
      // delete tag from Firestore
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(state.teamId)
          .collection('tags')
          .doc(tagId)
          .delete();
      // update the state
      final tags = state.tags.where((tag) => tag.id != tagId);
      state = state.copyWith(
        tags: tags.toList(),
        apiStatus: ApiStatus.success,
      );
    } catch (e) {
      print('Error deleting tag: $e');
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final tagProvider = NotifierProvider.family<TagsController, TagsState, String>(
  () => TagsController(),
);
