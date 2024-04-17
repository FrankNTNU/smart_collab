import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/auth_controller.dart';

enum PerformedAction {
  fetch,
  add,
  update,
  delete,
}

class Team {
  final String? id;
  final String? name;
  final String? description;
  final String? imageUrl;
  final Map<String, String> roles;
  // ctor
  Team({
    this.id,
    this.name,
    this.description,
    this.imageUrl,
    this.roles = const {},
  });
  // copyWith
  Team copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    Map<String, String>? roles,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      roles: roles ?? this.roles,
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
  Future<void> removeFromTeam({required String uid, required String teamId}) async {
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
      state = state.copyWith(apiStatus: ApiStatus.error, errorMessage: '$e');
    }
  }
  Future<void> setAsMemeber({required String email, required String teamId}) async {
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
          .update({'roles.$userId': 'member'});
      // update the roles in the state
      final updatedTeams = state.teams.map((team) {
        if (team.id == teamId) {
          return team.copyWith(roles: {...team.roles, userId: 'member'});
        }
        return team;
      }).toList();
      state = state.copyWith(teams: updatedTeams, apiStatus: ApiStatus.success);
    } catch (e) {
      state = state.copyWith(apiStatus: ApiStatus.error, errorMessage: '$e');
    }
  }
  
  Future<void> setAsAdmin({required String email, required String teamId}) async {
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
        // store the new image in Firebase Storage
        final ref = FirebaseStorage.instance.ref('teams/${team.id}');
        await ref.putFile(image);
        team = team.copyWith(imageUrl: await ref.getDownloadURL());
      }
      // update the team in firestore
      await FirebaseFirestore.instance.collection('teams').doc(team.id).update({
        'name': team.name,
        'description': team.description,
        'imageUrl': team.imageUrl,
      });
      state = state.copyWith(
        apiStatus: ApiStatus.success,
        teams: state.teams.map((t) => t.id == team.id ? team : t).toList(),
      );
    } catch (e) {
      state = state.copyWith(apiStatus: ApiStatus.error, errorMessage: '$e');
    }
  }

  Future<void> addTeam(Team team, File? image) async {
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
        final ref = FirebaseStorage.instance.ref('teams/${docRef.id}');
        await ref.putFile(image);
        team = team.copyWith(imageUrl: await ref.getDownloadURL());
      }
      // save the team with the imageUrl
      await docRef.update({'imageUrl': team.imageUrl});
      final newTeam = team.copyWith(id: docRef.id);
      state = state.copyWith(
        apiStatus: ApiStatus.success,
        teams: [...state.teams, newTeam],
      );
    } catch (e) {
      state = state.copyWith(apiStatus: ApiStatus.error, errorMessage: '$e');
    }
  }

  Future<void> deleteTeam(String teamId) async {
    try {
      state = state.copyWith(
          apiStatus: ApiStatus.loading,
          performedAction: PerformedAction.delete);
      // delete the image from Firebase Storage
      final team = state.teams.firstWhere((team) => team.id == teamId);
      if (team.imageUrl != null) {
        await FirebaseStorage.instance.refFromURL(team.imageUrl!).delete();
      }
      // delete the team from firestore
      await FirebaseFirestore.instance.collection('teams').doc(teamId).delete();
      state = state.copyWith(
        apiStatus: ApiStatus.success,
        teams: state.teams.where((team) => team.id != teamId).toList(),
      );
    } catch (e) {
      state = state.copyWith(apiStatus: ApiStatus.error, errorMessage: '$e');
    }
  }
}

final teamsProvider = NotifierProvider<TeamsController, TeamsState>(
  () => TeamsController(),
);
