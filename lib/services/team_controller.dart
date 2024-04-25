import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/auth_controller.dart';

import 'profile_controller.dart';

enum PerformedAction {
  fetch,
  add,
  update,
  delete,
  bulkFetch,
  bulkAdd,
}

class Team {
  final String? id;
  final String? name;
  final String? description;
  final String? imageUrl;
  final Map<String, String> roles;
  final bool isArchieved;
  final DateTime? archievedDate;
  // ctor
  Team({
    this.id,
    this.name,
    this.description,
    this.imageUrl,
    this.roles = const {},
    this.isArchieved = false,
    this.archievedDate,
  });
  // copyWith
  Team copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    Map<String, String>? roles,
    bool? isArchieved,
    DateTime? archievedDate,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      roles: roles ?? this.roles,
      isArchieved: isArchieved ?? this.isArchieved,
      archievedDate: archievedDate ?? this.archievedDate,
    );
  }

  // fromJson
  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      roles: Map<String, String>.from(json['roles']),
      isArchieved: json['isArchieved'] ?? false,
      archievedDate: json['archievedDate'] != null
          ? (json['archievedDate'] as Timestamp).toDate()
          : null,
    );
  }
  // initial
  static Team initial() {
    return Team(
      id: null,
      name: null,
      description: null,
      imageUrl: null,
      roles: {},
      isArchieved: false,
    );
  }
}

class TeamsState {
  final String userId;
  final ApiStatus apiStatus;
  final List<Team> teams;
  final String? errorMessage;
  final PerformedAction performedAction;
  // ctor
  TeamsState({
    required this.userId,
    required this.apiStatus,
    required this.teams,
    this.errorMessage,
    this.performedAction = PerformedAction.fetch,
  });
  // copyWith
  TeamsState copyWith({
    String? userId,
    ApiStatus? apiStatus,
    List<Team>? teams,
    String? errorMessage,
    PerformedAction? performedAction,
  }) {
    return TeamsState(
      userId: userId ?? this.userId,
      apiStatus: apiStatus ?? this.apiStatus,
      teams: teams ?? this.teams,
      errorMessage: errorMessage,
      performedAction: performedAction ?? this.performedAction,
    );
  }

  // initial
  static TeamsState initial() {
    return TeamsState(
        userId: '',
        apiStatus: ApiStatus.idle,
        teams: [],
        errorMessage: '',
        performedAction: PerformedAction.fetch);
  }
}

class TeamsController extends Notifier<TeamsState> {
  @override
  TeamsState build() {
    final userId =
        ref.watch(authControllerProvider.select((value) => value.user?.uid));
    return TeamsState.initial().copyWith(userId: userId);
  }

  void clearErrorMessage() {
    state = state.copyWith(errorMessage: null);
  }

  // get all members of a team
  Future<List<SmartCollabUser>> fetchTeamMembers(String teamId) async {
    try {
      // state = state.copyWith(
      //     apiStatus: ApiStatus.loading, performedAction: PerformedAction.fetch);
      final snapshot = await FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .get();
      final team = Team.fromJson(snapshot.data()!);
      List<SmartCollabUser> members = [];
      for (String uid in team.roles.keys) {
        final profileData = await ref.read(profileDataProvider(uid).future);
        members.add(profileData);
      }
      //state = state.copyWith(apiStatus: ApiStatus.success);
      return members;
    } catch (e) {
      print('Error occured in the fetchTeamMembers method: $e');
      state = state.copyWith(apiStatus: ApiStatus.error, errorMessage: '$e');
      return [];
    }
  }

  Future<void> removeFromTeam(
      {required String uid, required String teamId}) async {
    // set loading
    state = state.copyWith(
      apiStatus: ApiStatus.loading,
      performedAction: PerformedAction.update,
    );
    try {
      // update the roles in the team
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .update({'roles.$uid': FieldValue.delete()});
      // update the roles in the state
      final updatedTeams = state.teams.map((team) {
        if (team.id == teamId) {
          final updatedRoles = team.roles;
          updatedRoles.remove(uid);
          return team.copyWith(roles: updatedRoles);
        }
        return team;
      }).toList();
      state = state.copyWith(teams: updatedTeams, apiStatus: ApiStatus.success);
    } catch (e) {
      print('Error occured in the removeFromTeam method: $e');
      state = state.copyWith(apiStatus: ApiStatus.error, errorMessage: '$e');
    }
  }

  Future<String?> setAsMemeber(
      {required String email, required String teamId}) async {
    // set loading
    state = state.copyWith(
      apiStatus: ApiStatus.loading,
      performedAction: PerformedAction.update,
    );
    try {
      // get the user id from the email
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      // get the user id, note that the user might not exist in the users collection
      final userId = snapshot.docs.isNotEmpty ? snapshot.docs.first.id : '';
      if (userId.isEmpty) {
        print('User not found');
        state = state.copyWith(
          apiStatus: ApiStatus.error,
          errorMessage: 'User not found',
        );
        return null;
      }
      // update the roles in the team
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .update({'roles.$userId': 'member'});
      // update the roles in the state
      final updatedTeams = state.teams.map((team) {
        if (team.id == teamId) {
          return team.copyWith(roles: {...team.roles, userId: 'member'});
        }
        return team;
      }).toList();
      state = state.copyWith(teams: updatedTeams, apiStatus: ApiStatus.success);
      return userId;
    } catch (e) {
      print('Error occured in the setAsMemeber method: $e');
      state = state.copyWith(apiStatus: ApiStatus.error, errorMessage: '$e');
      return null;
    }
  }

  Future<void> setAsAdmin(
      {required String email, required String teamId}) async {
    // set loading
    state = state.copyWith(
      apiStatus: ApiStatus.loading,
      performedAction: PerformedAction.update,
    );
    try {
      // get the user id from the email
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      // get the user id, note that the user might not exist in the users collection
      final userId = snapshot.docs.isNotEmpty ? snapshot.docs.first.id : '';
      if (userId.isEmpty) {
        state = state.copyWith(
          apiStatus: ApiStatus.error,
          errorMessage: 'User not found',
        );
        return;
      }
      // update the roles in the team
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .update({'roles.$userId': 'admin'});
      // update the roles in the state
      final updatedTeams = state.teams.map((team) {
        if (team.id == teamId) {
          return team.copyWith(roles: {...team.roles, userId: 'admin'});
        }
        return team;
      }).toList();
      state = state.copyWith(teams: updatedTeams, apiStatus: ApiStatus.success);
    } catch (e) {
      print('Error occured in the setAsAdmin method: $e');
      state = state.copyWith(apiStatus: ApiStatus.error, errorMessage: '$e');
    }
  }

  Future<List<Team>> fetchTeams() async {
    try {
      state = state.copyWith(
          apiStatus: ApiStatus.loading, performedAction: PerformedAction.fetch);
      // get teams from firestore collection but only where the user is a member or owner
      /*
        { name: “...”, description: “....”, roles: { user1: “owner”, user2: “admin”, user3: “member”}, … }
      */
      final snapshot = await FirebaseFirestore.instance
          .collection('teams')
          .where('roles.${state.userId}',
              whereIn: ['owner', 'admin', 'member']).get();
      final teams = snapshot.docs
          .map((doc) => Team.fromJson(doc.data()).copyWith(
                id: doc.id,
              ))
          .toList();
      state = state.copyWith(apiStatus: ApiStatus.success, teams: teams);
      return teams;
    } catch (e) {
      print('Error occured in the fetchTeams method: $e');
      state = state.copyWith(apiStatus: ApiStatus.error, errorMessage: '$e');
      return [];
    }
  }

  Future<void> editTeam(Team team, File? image) async {
    try {
      state = state.copyWith(
          apiStatus: ApiStatus.loading,
          performedAction: PerformedAction.update);
      if (image != null) {
        // make the image size smaller
        // delete the original image
        if (team.imageUrl != null) {
          // check if such image exists on Firebase Storage given the imageUrl
          final isExist = await FirebaseStorage.instance
              .refFromURL(team.imageUrl!)
              .listAll()
              .then((value) => true)
              .catchError((e) => false);
          if (!isExist) {
            // delete the image from Firebase Storage if such image exists
            await FirebaseStorage.instance.refFromURL(team.imageUrl!).delete();
          }
        }

        // store the new image in Firebase Storage
        final ref = FirebaseStorage.instance.ref('teams/${team.id}/cover');
        await ref.putFile(image);
        team = team.copyWith(imageUrl: await ref.getDownloadURL());
      }
      // update the team in firestore
      await FirebaseFirestore.instance.collection('teams').doc(team.id).update({
            'name': team.name,
            'description': team.description,
          }..addAll(team.imageUrl != null ? {'imageUrl': team.imageUrl} : {}));
      state = state.copyWith(
        apiStatus: ApiStatus.success,
        teams: state.teams.map((t) {
          if (t.id == team.id) {
            // only update properties that could have been updated, otherwise other properties will be null, including roles
            return t.copyWith(
              name: team.name,
              description: team.description,
              imageUrl: team.imageUrl,
            );
          }
          return t;
        }).toList(),
      );
    } catch (e) {
      print('Error occured in the editTeam method: $e');
      state = state.copyWith(apiStatus: ApiStatus.error, errorMessage: '$e');
    }
  }

  Future<String> addTeam(Team team, File? image) async {
    try {
      state = state.copyWith(
          apiStatus: ApiStatus.loading, performedAction: PerformedAction.add);
      // save the team to firestore
      final docRef = await FirebaseFirestore.instance.collection('teams').add({
        'name': team.name,
        'description': team.description,
        'roles': {state.userId: 'owner'},
      });
      // store the image in Firebase Storage and use the document id as the image name
      if (image != null) {
        final ref = FirebaseStorage.instance.ref('teams/${docRef.id}/cover');
        await ref.putFile(image);
        team = team.copyWith(imageUrl: await ref.getDownloadURL());
      }
      // save the team with the imageUrl
      await docRef.update({'imageUrl': team.imageUrl});
      final newTeam =
          team.copyWith(id: docRef.id, roles: {state.userId: 'owner'});
      state = state.copyWith(
        apiStatus: ApiStatus.success,
        teams: [...state.teams, newTeam],
      );
      return docRef.id;
    } catch (e) {
      print('Error occured in the addTeam method: $e');
      state = state.copyWith(apiStatus: ApiStatus.error, errorMessage: '$e');
      return '';
    }
  }

  // restore team
  Future<void> restoreTeam(String teamId) async {
    try {
      state = state.copyWith(
          apiStatus: ApiStatus.loading,
          performedAction: PerformedAction.update);
      // set isArchieved to false
      await FirebaseFirestore.instance.collection('teams').doc(teamId).update({
        'isArchieved': false,
        'archievedDate': null,
      });
      state = state.copyWith(
        apiStatus: ApiStatus.success,
        teams: state.teams.map((team) {
          if (team.id == teamId) {
            return team.copyWith(isArchieved: false, archievedDate: null);
          }
          return team;
        }).toList(),
      );
    } catch (e) {
      print('Error occured in the restoreTeam method: $e');
      state = state.copyWith(apiStatus: ApiStatus.error, errorMessage: '$e');
    }
  }

  Future<void> archieveTeam(String teamId) async {
    try {
      state = state.copyWith(
          apiStatus: ApiStatus.loading,
          performedAction: PerformedAction.delete);
      // set isArchieved to true and archievedDate to the current date
      await FirebaseFirestore.instance.collection('teams').doc(teamId).update({
        'isArchieved': true,
        'archievedDate': FieldValue.serverTimestamp(),
      });
      final updatedTeams = state.teams
          .map((team) => team.id == teamId
              ? team.copyWith(
                  isArchieved: true,
                  archievedDate: DateTime.now(),
                )
              : team)
          .toList();
      state = state
          .copyWith(apiStatus: ApiStatus.success, teams: [...updatedTeams]);
      // delete all subcollections of the team
    } catch (e) {
      print('Error occured in the deleteTeam method: $e');
      state = state.copyWith(apiStatus: ApiStatus.error, errorMessage: '$e');
    }
  }
}

final teamsProvider = NotifierProvider<TeamsController, TeamsState>(
  () => TeamsController(),
);
