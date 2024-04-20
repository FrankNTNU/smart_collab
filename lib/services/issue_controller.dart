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
    );
  }
}

class IssuesState {
  final List<Issue> issues;
  final ApiStatus apiStatus;
  final String? errorMessage;
  final PerformedAction performedAction;
  final String userId;
  // for pagination
  // last document Ref
  final DocumentSnapshot? lastDoc;
  final String teamId;
  // ctor
  IssuesState({
    required this.issues,
    required this.apiStatus,
    this.errorMessage,
    this.performedAction = PerformedAction.fetch,
    this.userId = '',
    this.lastDoc,
    required this.teamId,
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
  }) {
    return IssuesState(
      issues: issues ?? this.issues,
      apiStatus: apiStatus ?? this.apiStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      performedAction: performedAction ?? this.performedAction,
      userId: userId ?? this.userId,
      lastDoc: lastDoc ?? this.lastDoc,
      teamId: teamId ?? this.teamId,
    );
  }

  // initial
  static IssuesState initial() {
    return IssuesState(
        issues: [],
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

  // add tag to an issue
  Future<void> addTagToIssue(
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
        'tags': FieldValue.arrayUnion([tag]),
      });
      final updatedIssue =
          state.issues.firstWhere((issue) => issue.id == issueId);
      final updatedIssues = state.issues.map((issue) {
        if (issue.id == issueId) {
          return updatedIssue.copyWith(
            tags: [...updatedIssue.tags, tag],
          );
        }
        return issue;
      }).toList();
      state = state
          .copyWith(apiStatus: ApiStatus.success, issues: [...updatedIssues]);
    } catch (e) {
      print('Error occured in the addTagToIssue method: $e');
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
    }
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
      final updatedIssue =
          state.issues.firstWhere((issue) => issue.id == issueId);
      final updatedIssues = state.issues.map((issue) {
        if (issue.id == issueId) {
          return updatedIssue.copyWith(
            tags: updatedIssue.tags.where((t) => t != tag).toList(),
          );
        }
        return issue;
      }).toList();
      state = state
          .copyWith(apiStatus: ApiStatus.success, issues: [...updatedIssues]);
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
      final updatedIssue =
          state.issues.firstWhere((issue) => issue.id == issueId);
      final updatedIssues = state.issues.map((issue) {
        if (issue.id == issueId) {
          // remove the collaborator from the roles map
          final updatedRoles = updatedIssue.roles;
          updatedRoles.remove(uid);
          return updatedIssue.copyWith(
            roles: updatedRoles,
          );
        }
        return issue;
      }).toList();
      state =
          state.copyWith(apiStatus: ApiStatus.success, issues: updatedIssues);
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
      final updatedIssue =
          state.issues.firstWhere((issue) => issue.id == issueId);
      final updatedIssues = state.issues.map((issue) {
        if (issue.id == issueId) {
          return updatedIssue.copyWith(
            roles: {
              ...updatedIssue.roles,
              uid: 'collaborator',
            },
          );
        }
        return issue;
      }).toList();
      state =
          state.copyWith(apiStatus: ApiStatus.success, issues: updatedIssues);
    } catch (e) {
      print('Error occured in the addCollaborators method: $e');
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
      print('Last doc: ${state.lastDoc}, exisits? ${state.lastDoc?.exists}');
      if (state.lastDoc != null && state.lastDoc!.exists && state.issues.isNotEmpty) {
        query = query.startAfterDocument(state.lastDoc!);
      }

      final snapShot = await query.limit(limit).get();

      final lastDoc = snapShot.docs.isNotEmpty ? snapShot.docs.last : null;
      state = state.copyWith(lastDoc: lastDoc);

      final fetchIssues = snapShot.docs.map((doc) {
        return Issue.fromJson(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id);
      }).toList();
      print('Have fetched ${fetchIssues.length} issues');
      state = state
          .copyWith(issues: [...state.issues, ...fetchIssues], apiStatus: ApiStatus.success);
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
        issues: state.issues.where((issue) => issue.id != issueId).toList(),
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
      final updatedIssue =
          state.issues.firstWhere((issue) => issue.id == issueId);
      final updatedIssues = state.issues.map((issue) {
        if (issue.id == issueId) {
          return updatedIssue.copyWith(
            title: title,
            description: description,
            tags: tags,
            updatedAt: DateTime.now(),
            lastUpdatedBy: state.userId,
            deadline: deadline ?? DateTime.now(),
          );
        }
        return issue;
      }).toList();
      state =
          state.copyWith(apiStatus: ApiStatus.success, issues: updatedIssues);
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
      state = state.copyWith(apiStatus: ApiStatus.success, issues: [
        ...state.issues,
        issue,
      ]);
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
