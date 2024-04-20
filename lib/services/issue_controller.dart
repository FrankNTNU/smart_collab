import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/team_controller.dart';

import 'auth_controller.dart';

class Issue {
  final String title;
  final String description;
  final String status;
  // createdAt
  final DateTime createdAt;
  // updatedAt
  final DateTime updatedAt;
  // id
  final String id;
  // roles
  final Map<String, String> roles;
  // deadline
  final DateTime? deadline;
  // tags
  final List<String> tags;
  // teamId
  final String teamId;
  // last updated by
  final String? lastUpdatedBy;
  // isClosed
  final bool isClosed;
  // linked issue id
  String? linkedIssueId;
  // ctor
  Issue({
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.id,
    required this.roles,
    this.deadline,
    required this.tags,
    required this.teamId,
    this.lastUpdatedBy,
    this.isClosed = false,
  });
  // copyWith
  Issue copyWith({
    String? title,
    String? description,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? id,
    Map<String, String>? roles,
    DateTime? deadline,
    List<String>? tags,
    String? teamId,
    String? lastUpdatedBy,
    bool? isClosed,
  }) {
    return Issue(
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      id: id ?? this.id,
      roles: roles ?? this.roles,
      deadline: deadline ?? this.deadline,
      tags: tags ?? this.tags,
      teamId: teamId ?? this.teamId,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      isClosed: isClosed ?? this.isClosed,
    );
  }

  // fromJson
  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'] ?? '',
      title: json['title'],
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      roles: Map<String, String>.from(json['roles']),
      deadline:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      tags: List<String>.from(json['tags'] ?? []),
      teamId: json['teamId'],
      lastUpdatedBy: json['lastUpdatedBy'],
      isClosed: json['isClosed'] ?? false,
    );
  }
}

class IssuesState {
  final ApiStatus apiStatus;
  final String? errorMessage;
  final PerformedAction performedAction;
  final String userId;
  // for pagination
  // last document Ref
  final DocumentSnapshot? lastDoc;
  final String teamId;
  // issue map
  final Map<String, Issue> issueMap;
  // ctor
  IssuesState({
    required this.apiStatus,
    this.errorMessage,
    this.performedAction = PerformedAction.fetch,
    this.userId = '',
    this.lastDoc,
    required this.teamId,
    this.issueMap = const {},
  });
  // copyWith
  IssuesState copyWith({
    List<Issue>? issues,
    ApiStatus? apiStatus,
    String? errorMessage,
    PerformedAction? performedAction,
    String? userId,
    DocumentSnapshot? lastDoc,
    String? teamId,
    Map<String, Issue>? issueMap,
  }) {
    return IssuesState(
      apiStatus: apiStatus ?? this.apiStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      performedAction: performedAction ?? this.performedAction,
      userId: userId ?? this.userId,
      lastDoc: lastDoc ?? this.lastDoc,
      teamId: teamId ?? this.teamId,
      issueMap: issueMap ?? this.issueMap,
    );
  }

  // initial
  static IssuesState initial() {
    return IssuesState(
        apiStatus: ApiStatus.idle,
        errorMessage: '',
        performedAction: PerformedAction.fetch,
        teamId: '');
  }
}

class IssueController extends AutoDisposeFamilyNotifier<IssuesState, String> {
  @override
  IssuesState build(String arg) {
    final userId =
        ref.watch(authControllerProvider.select((value) => value.user?.uid));
    return IssuesState.initial().copyWith(userId: userId, teamId: arg);
  }

  // set is closed
  Future<void> setIsClosed(
      {required String issueId, required bool isClosed}) async {
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.update);
    try {
      // update issue in firestore
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(state.teamId)
          .collection('issues')
          .doc(issueId)
          .update({
        'isClosed': isClosed,
      });
      // update the issueMap
      final updatedIssueMap = {
        ...state.issueMap,
        issueId: state.issueMap[issueId]!.copyWith(isClosed: isClosed),
      };
      state = state.copyWith(
          apiStatus: ApiStatus.success, issueMap: updatedIssueMap);
    } catch (e) {
      print('Error occured in the setIsClosed method: $e');
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // add tag to an issue
  Future<void> addTagToIssue(
      {required String issueId, required String tag}) async {
    if (tag.isEmpty) return;
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.update);
    try {
      // update issue in firestore
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(state.teamId)
          .collection('issues')
          .doc(issueId)
          .update({
        'tags': FieldValue.arrayUnion([tag]),
      });
      final updatedIssueMap = {
        ...state.issueMap,
        issueId: state.issueMap[issueId]!.copyWith(
          tags: [...state.issueMap[issueId]!.tags, tag],
        ),
      };
      state = state.copyWith(
          apiStatus: ApiStatus.success, issueMap: updatedIssueMap);
    } catch (e) {
      print('Error occured in the addTagToIssue method: $e');
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // update local issues state due to updated tag name
  void updatedIssuesState(
      List<(String, List<String>)> updatedIssuesWithNewTags) {
    final updatedIssueMap = updatedIssuesWithNewTags
        .fold<Map<String, Issue>>({...state.issueMap}, (map, tuple) {
      final issueId = tuple.$1;
      final newTags = tuple.$2;
      return {
        ...map,
        issueId: map[issueId]!.copyWith(tags: newTags),
      };
    });
    state = state.copyWith(issueMap: updatedIssueMap);
  }

  // remove a tag from an issue
  Future<void> removeTagFromIssue(
      {required String issueId, required String tag}) async {
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.update);
    try {
      // update issue in firestore
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(state.teamId)
          .collection('issues')
          .doc(issueId)
          .update({
        'tags': FieldValue.arrayRemove([tag]),
      });
      final updatedIssueMap = {
        ...state.issueMap,
        issueId: state.issueMap[issueId]!.copyWith(
          tags: state.issueMap[issueId]!.tags..remove(tag),
        ),
      };
      state = state.copyWith(
          apiStatus: ApiStatus.success, issueMap: updatedIssueMap);
    } catch (e) {
      print('Error occured in the removeTagFromIssue method: $e');
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // remove a collaborator
  Future<void> removeCollaborator(
      {required String issueId, required String uid}) async {
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.update);
    try {
      // update issue in firestore
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(state.teamId)
          .collection('issues')
          .doc(issueId)
          .update({
        'roles.$uid': FieldValue.delete(),
      });
      final updatedIssueMap = {
        ...state.issueMap,
        issueId: state.issueMap[issueId]!.copyWith(
          roles: state.issueMap[issueId]!.roles..remove(uid),
        ),
      };
      state = state.copyWith(
          apiStatus: ApiStatus.success, issueMap: updatedIssueMap);
    } catch (e) {
      print('Error occured in the removeCollaborators method: $e');
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // add collaborator
  Future<void> addCollaborator(
      {required String issueId, required String uid}) async {
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.update);
    try {
      // update issue in firestore
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(state.teamId)
          .collection('issues')
          .doc(issueId)
          .update({
        'roles.$uid': 'collaborator',
      });
      final updatedIssueMap = {
        ...state.issueMap,
        issueId: state.issueMap[issueId]!.copyWith(
          roles: {...state.issueMap[issueId]!.roles, uid: 'collaborator'},
        ),
      };
      state = state.copyWith(
          apiStatus: ApiStatus.success, issueMap: updatedIssueMap);
    } catch (e) {
      print('Error occured in the addCollaborators method: $e');
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // fetch issues based on deadline's month and update the local state issues
  Future<void> fetchIssuesByMonth(
      {required int year, required int month}) async {
    print('Fetching issues by month...');
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.fetch);
    try {
      final start = DateTime(year, month);
      final end = DateTime(year, month + 1);
      final snapShot = await FirebaseFirestore.instance
          .collection('teams')
          .doc(state.teamId)
          .collection('issues')
          .where('teamId', isEqualTo: state.teamId)
          .where('deadline', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('deadline', isLessThan: end.toIso8601String())
          .get();
      final fetchIssues = snapShot.docs.map((doc) {
        return Issue.fromJson(doc.data()).copyWith(id: doc.id);
      }).toList();
      state = state.copyWith(apiStatus: ApiStatus.success);
      mergeIssues(fetchIssues);
    } catch (e, stackTrace) {
      print('Error occurred in the fetchIssuesByMonth method: $e, $stackTrace');
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // merge fetched issues with state issues based on their id and update the local state issues
  Future<void> mergeIssues(List<Issue> fetchedIssues) async {
    print('Merging issues...');
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.fetch);
    try {
      // turn the issue list to issue
      final fetchedIssueMap =
          fetchedIssues.fold<Map<String, Issue>>({}, (map, issue) {
        return {...map, issue.id: issue};
      });
      // merged the state.issueMap with the fetched issueMap
      final mergedIssueMap = {...state.issueMap, ...fetchedIssueMap};
      state = state.copyWith(
        apiStatus: ApiStatus.success,
        issueMap: mergedIssueMap,
      );
    } catch (e, stackTrace) {
      print('Error occurred in the mergeIssues method: $e, $stackTrace');
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // fetchIssues
  Future<void> fetchIssues(String teamId, {List<String>? includedTags}) async {
    const limit = 5;
    print('Fetching issues...');
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.fetch);
    try {
      Query query = FirebaseFirestore.instance
          .collection('teams')
          .doc(state.teamId)
          .collection('issues')
          .where('teamId', isEqualTo: teamId)
          .orderBy('updatedAt', descending: true);
      print('Included tags: $includedTags');
      if (includedTags != null && includedTags.isNotEmpty) {
        query = query.where('tags', arrayContainsAny: includedTags);
      }
      if (state.lastDoc != null &&
          state.lastDoc!.exists &&
          state.issueMap.isNotEmpty) {
        print('Setting starting after document');
        query = query.startAfterDocument(state.lastDoc!);
      }

      final snapShot = await query.limit(limit).get();

      final lastDoc = snapShot.docs.isNotEmpty ? snapShot.docs.last : null;
      state = state.copyWith(lastDoc: lastDoc);

      final fetchIssues = snapShot.docs.map((doc) {
        return Issue.fromJson(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id);
      }).toList();
      state = state.copyWith(apiStatus: ApiStatus.success);
      mergeIssues(fetchIssues);
    } catch (e, stackTrace) {
      print('Error occurred in the fetchIssues method: $e, $stackTrace');
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // remove an issue
  Future<void> removeIssue(String issueId) async {
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.delete);
    try {
      // remove issue from firestore
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(state.teamId)
          .collection('issues')
          .doc(issueId)
          .delete();
      state = state.copyWith(
        apiStatus: ApiStatus.success,
        issueMap: state.issueMap..remove(issueId),
      );
    } catch (e) {
      print('Error occured in the removeIssue method: $e');
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // update issue
  Future<void> updateIssue({
    required String title,
    required String description,
    List<String>? tags,
    DateTime? deadline,
    required String issueId,
  }) async {
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.update);
    try {
      // update issue in firestore
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(state.teamId)
          .collection('issues')
          .doc(issueId)
          .update({
            'title': title,
            'description': description,
            'updatedAt': DateTime.now().toIso8601String(),
            'lastUpdatedBy': state.userId,
          }
            ..addAll(tags != null ? {'tags': tags} : {})
            ..addAll(deadline != null
                ? {'deadline': deadline.toIso8601String()}
                : {}));
      state = state.copyWith(apiStatus: ApiStatus.success, issueMap: {
        ...state.issueMap,
        issueId: state.issueMap[issueId]!.copyWith(
          title: title,
          description: description,
          updatedAt: DateTime.now(),
          tags: tags ?? state.issueMap[issueId]!.tags,
          deadline: deadline ?? state.issueMap[issueId]!.deadline,
        ),
      });
    } catch (e) {
      print('Error occured in the updateIssue method: $e');
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // add issue
  Future<String> addIssue({
    required String title,
    required String description,
    List<String>? tags,
    DateTime? deadline,
  }) async {
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.add);
    try {
      // add issue to firestore
      final issueRef = await FirebaseFirestore.instance
          .collection('teams')
          .doc(state.teamId)
          .collection('issues')
          .add({
            'title': title,
            'description': description,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
            'deadline':
                deadline?.toIso8601String() ?? DateTime.now().toIso8601String(),
            'teamId': state.teamId,
            'roles': {state.userId: 'owner'},
          }..addAll(tags != null ? {'tags': tags} : {}));
      final issue = Issue(
        title: title,
        description: description,
        status: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deadline: deadline ?? DateTime.now(),
        id: issueRef.id,
        roles: {state.userId: 'owner'},
        tags: [],
        teamId: state.teamId,
      );
      state = state.copyWith(apiStatus: ApiStatus.success, issueMap: {
        ...state.issueMap,
        issueRef.id: issue,
      });
      return issueRef.id;
    } catch (e) {
      print('Error occured in the addIssue method: $e');
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
      return '';
    }
  }
}

final issueProvider = NotifierProvider.autoDispose
    .family<IssueController, IssuesState, String>(() {
  return IssueController();
});
