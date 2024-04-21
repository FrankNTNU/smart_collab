/*
  { userId: “…”, activityType: “add_to_team”, activityDetails: { teamId: “...”, … }, timestamp: :”…” }
*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_collab/services/auth_controller.dart';

import 'team_controller.dart';

class Activity {
  final String id;
  final String message;
  final String userId;
  final String activityType;
  final Map<String, dynamic> activityDetails;
  final String timestamp;
  // local state
  final bool read;
  Activity({
    required this.id,
    required this.message,
    required this.userId,
    required this.activityType,
    required this.activityDetails,
    required this.timestamp,
    this.read = false,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] ?? '',
      message: json['message'] ?? '',
      userId: json['userId'],
      activityType: json['activityType'] ?? '',
      activityDetails: Map<String, dynamic>.from(json['activityDetails']),
      timestamp: json['timestamp'],
    );
  }
  // copyWith
  Activity copyWith({
    String? id,
    String? message,
    String? userId,
    String? activityType,
    Map<String, dynamic>? activityDetails,
    String? timestamp,
    bool? read,
  }) {
    return Activity(
      id: id ?? this.id,
      message: message ?? this.message,
      userId: userId ?? this.userId,
      activityType: activityType ?? this.activityType,
      activityDetails: activityDetails ?? this.activityDetails,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
    );
  }
}

class ActivitiesState {
  final ApiStatus apiStatus;
  final PerformedAction performedAction;
  final List<Activity> activities;
  final String? error;
  final String userId;
  // filter state
  final String teamId;
  // unread count
  final int unreadCount;
  // ctor
  ActivitiesState(
      {required this.apiStatus,
      required this.performedAction,
      required this.activities,
      this.error,
      required this.userId,
      required this.teamId,
      this.unreadCount = 0});
  // copyWith
  ActivitiesState copyWith({
    ApiStatus? apiStatus,
    PerformedAction? performedAction,
    List<Activity>? activities,
    String? error,
    String? userId,
    String? teamId,
    int? unreadCount,
  }) {
    return ActivitiesState(
      apiStatus: apiStatus ?? this.apiStatus,
      performedAction: performedAction ?? this.performedAction,
      activities: activities ?? this.activities,
      error: error ?? this.error,
      userId: userId ?? this.userId,
      teamId: teamId ?? this.teamId,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

enum ActivityType {
  // when a member is invited to a team
  addToTeam,
  // when a member is set as an admin
  setAsAdmin,
  // when a comment is added to an issue
  addComment,
  // when an issue is created
  createIssue,
  // when an issue is updated
  updateIssue,
  // when a member is set as an collaborator on an issue
  setAsCollaborator,
  // team updated
  updateTeam,
  // add team
  addTeam,
  // close issue
  closeIssue,
  // open issue
  openIssue,
}

// activityMap
final activityMap = {
  ActivityType.addToTeam: 'add_to_team',
  ActivityType.setAsAdmin: 'set_as_admin',
  ActivityType.addComment: 'add_comment',
  ActivityType.createIssue: 'create_issue',
  ActivityType.updateIssue: 'update_issue',
  ActivityType.setAsCollaborator: 'set_as_collaborator',
  ActivityType.updateTeam: 'update_team',
  ActivityType.addTeam: 'add_team',
  ActivityType.closeIssue: 'close_issue',
  ActivityType.openIssue: 'open_issue',
};

final activityMapReverse = {
  'add_to_team': ActivityType.addToTeam,
  'set_as_admin': ActivityType.setAsAdmin,
  'add_comment': ActivityType.addComment,
  'create_issue': ActivityType.createIssue,
  'update_issue': ActivityType.updateIssue,
  'set_as_collaborator': ActivityType.setAsCollaborator,
  'update_team': ActivityType.updateTeam,
  'add_team': ActivityType.addTeam,
  'close_issue': ActivityType.closeIssue,
  'open_issue': ActivityType.openIssue,
};

class ActivityController
    extends AutoDisposeFamilyNotifier<ActivitiesState, String> {
  @override
  ActivitiesState build(String arg) {
    return ActivitiesState(
      apiStatus: ApiStatus.idle,
      performedAction: PerformedAction.fetch,
      activities: [],
      userId: ref.watch(authControllerProvider).user?.uid ?? '',
      teamId: arg,
    );
  }

  // write to activities
  Future<void> addActivity(
      {required String recipientUid,
      required ActivityType activityType,
      required String message,
      String? teamId,
      String? issueId,
      String? commentId}) async {
    // set loading
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.add);
    try {
      // write to Firestore activities collection
      final snapshotRef = await FirebaseFirestore.instance
          .collection('teams')
          .doc(state.teamId)
          .collection('activities')
          .add({
        'userId': state.userId,
        'message': message,
        'activityType': activityMap[activityType],
        'activityDetails': {
          'teamId': teamId,
          'issueId': issueId,
          'commentId': commentId,
        },
        'timestamp': DateTime.now().toIso8601String(),
      });
      // update the state
      state = state.copyWith(
        activities: [
          ...state.activities,
          Activity(
            id: snapshotRef.id,
            message: message,
            userId: state.userId,
            activityType: activityMap[activityType]!,
            activityDetails: {
              'teamId': teamId,
              'issueId': issueId,
              'commentId': commentId,
            },
            timestamp: DateTime.now().toIso8601String(),
          ),
        ]..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
        apiStatus: ApiStatus.success,
      );
    } catch (e, stackTrace) {
      print('Error adding activity: $e, $stackTrace');
      state = state.copyWith(error: e.toString(), apiStatus: ApiStatus.error);
    }
  }

  // fetch activities
  Future<void> fetchActivities() async {
    // set loading
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.fetch);
    try {
      // fetch activities from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('teams')
          .doc(state.teamId)
          .collection('activities')
          .orderBy('timestamp', descending: true)
          .get();
      // get read activities from shared_preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final readActivities = prefs.getStringList('readActivities') ?? [];
      // update the state
      state = state.copyWith(
        activities: snapshot.docs
            .map((doc) => Activity.fromJson(doc.data())
                .copyWith(id: doc.id, read: readActivities.contains(doc.id)))
            .toList(),
        apiStatus: ApiStatus.success,
      );
    } catch (e, stackTrace) {
      print('Error fetching activities: $e, $stackTrace');
      state = state.copyWith(error: e.toString(), apiStatus: ApiStatus.error);
    }
  }

  // delete activity by id
  Future<void> deleteActivity(String activityId) async {
    // set loading
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.delete);
    try {
      // delete activity from Firestore
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(state.teamId)
          .collection('activities')
          .doc(activityId)
          .delete();
      // update the state
      final activities =
          state.activities.where((activity) => activity.id != activityId);
      state = state.copyWith(
        activities: activities.toList(),
        apiStatus: ApiStatus.success,
      );
    } catch (e) {
      print('Error deleting activity: $e');
      state = state.copyWith(error: e.toString(), apiStatus: ApiStatus.error);
    }
  }

  // set has read count
  Future<void> refreshUnreadCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final readActivities = prefs.getStringList('readActivities') ?? [];
    final unreadCount = state.activities
        .where((activity) => !readActivities.contains(activity.id))
        .length;
    // update the state
    // for each activity in the state, update the read status
    for (var activity in state.activities) {
      activity.copyWith(read: readActivities.contains(activity.id));
    }
    state = state.copyWith(unreadCount: unreadCount);
  }

  // set as read (store such activity id to shared_preferences)
  Future<void> setAsRead(String activityId) async {
    // set loading
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.update);
    try {
      // set as read
      // update the state
      final activities = state.activities
          .map((activity) => activity.id == activityId
              ? activity.copyWith(read: true)
              : activity)
          .toList();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          'readActivities',
          activities
              .where((activity) => activity.read)
              .map((activity) => activity.id)
              .toList());
      state = state.copyWith(
        activities: activities,
        apiStatus: ApiStatus.success,
      );
    } catch (e) {
      print('Error setting as read: $e');
      state = state.copyWith(error: e.toString(), apiStatus: ApiStatus.error);
    }
  }

  // set activities
  void setActivities(List<Activity> activities) async {
    refreshUnreadCount();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final readActivitiesFromSharedPrefs =
        prefs.getStringList('readActivities') ?? [];
    // update has read for each activity
    activities = activities
        .map((activity) => activity.copyWith(
              read: readActivitiesFromSharedPrefs.contains(activity.id),
            ))
        .toList();
    state = state.copyWith(activities: activities);
  }
}

final activityProvider = NotifierProvider.autoDispose
    .family<ActivityController, ActivitiesState, String>(
  () => ActivityController(),
);

// activity stream provider
final activityStreamProvider =
    StreamProvider.autoDispose.family<List<Activity>, String>((ref, teamId) {
  // fetch activities from Firestore
  final snapshot = FirebaseFirestore.instance
      .collection('teams')
      .doc(teamId)
      .collection('activities')
      .orderBy('timestamp', descending: true)
      .snapshots();
  final activites = snapshot.map((snapshot) => snapshot.docs
      .map((doc) => Activity.fromJson(doc.data()).copyWith(
            id: doc.id,
          ))
      .toList());
  // set activities
  activites.first.then((activities) {
    ref.read(activityProvider(teamId).notifier).setActivities(activities);
  });
  return activites;
});
