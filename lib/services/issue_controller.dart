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
  final DateTime deadline;
  // tags
  final List<String> tags;
  // teamId
  final String teamId;
  // ctor
  Issue({
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.id,
    required this.roles,
    required this.deadline,
    required this.tags,
    required this.teamId,
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
          DateTime.parse(json['deadline'] ?? DateTime.now().toIso8601String()),
      tags: List<String>.from(json['tags'] ?? []),
      teamId: json['teamId'],
    );
  }
}

class IssuesState {
  final List<Issue> issues;
  final ApiStatus apiStatus;
  final String? errorMessage;
  final PerformedAction performedAction;
  final String userId;
  // ctor
  IssuesState({
    required this.issues,
    required this.apiStatus,
    this.errorMessage,
    this.performedAction = PerformedAction.fetch,
    this.userId = '',
  });
  // copyWith
  IssuesState copyWith({
    List<Issue>? issues,
    ApiStatus? apiStatus,
    String? errorMessage,
    PerformedAction? performedAction,
    String? userId,
  }) {
    return IssuesState(
      issues: issues ?? this.issues,
      apiStatus: apiStatus ?? this.apiStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      performedAction: performedAction ?? this.performedAction,
      userId: userId ?? this.userId,
    );
  }

  // initial
  static IssuesState initial() {
    return IssuesState(
      issues: [],
      apiStatus: ApiStatus.idle,
    );
  }
}

class IssueController extends AutoDisposeFamilyNotifier<IssuesState, String> {
  @override
  IssuesState build(String arg) {
    final userId =
        ref.watch(authControllerProvider.select((value) => value.user?.uid));
    return IssuesState.initial().copyWith(userId: userId);
  }

  // fetchIssues
  Future<void> fetchIssues(String teamId) async {
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.fetch);
    try {
      // fetch issues from firestore the issues collection (only fetch issues where teamId is the current teamId, which is arg)
      final snapShot = await FirebaseFirestore.instance
          .collection('issues')
          .where('teamId', isEqualTo: teamId)
          .get();
      final issues = snapShot.docs
          .map((doc) => Issue.fromJson(doc.data()).copyWith(id: doc.id))
          .toList();
      state = state.copyWith(issues: issues, apiStatus: ApiStatus.success);
    } catch (e, stackTrace) {
      print('Error occured in the fetchIssues method: $e, $stackTrace');
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
    required List<String> tags,
    required String issueId,
  }) async {
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.update);
    try {
      // update issue in firestore
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .update({
        'title': title,
        'description': description,
        'updatedAt': DateTime.now().toIso8601String(),
        'tags': tags,
      });
      final updatedIssue =
          state.issues.firstWhere((issue) => issue.id == issueId);
      final updatedIssues = state.issues.map((issue) {
        if (issue.id == issueId) {
          return updatedIssue.copyWith(
            title: title,
            description: description,
            tags: tags,
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
  Future<void> addIssue({
    required String title,
    required String description,
    required List<String> tags,
  }) async {
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.add);
    try {
      // add issue to firestore
      final issueRef =
          await FirebaseFirestore.instance.collection('issues').add({
        'title': title,
        'description': description,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'teamId': arg,
        'roles': {state.userId: 'owner'},
        'tags': tags,
      });
      final issue = Issue(
        title: title,
        description: description,
        status: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        id: issueRef.id,
        roles: {state.userId: 'owner'},
        deadline: DateTime.now(),
        tags: tags,
        teamId: arg,
      );
      state = state.copyWith(apiStatus: ApiStatus.success, issues: [
        ...state.issues,
        issue,
      ]);
    } catch (e) {
      print('Error occured in the addIssue method: $e');
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final issueProvider = NotifierProvider.autoDispose
    .family<IssueController, IssuesState, String>(() {
  return IssueController();
});
