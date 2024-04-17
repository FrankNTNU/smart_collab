import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/auth_controller.dart';

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
  // ctor
  TeamsState({
    required this.userId,
    required this.apiStatus,
    required this.teams,
    this.errorMessage,
  });
  // copyWith
  TeamsState copyWith({
    String? userId,
    ApiStatus? apiStatus,
    List<Team>? teams,
    String? errorMessage,
  }) {
    return TeamsState(
      userId: userId ?? this.userId,
      apiStatus: apiStatus ?? this.apiStatus,
      teams: teams ?? this.teams,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // initial
  static TeamsState initial() {
    return TeamsState(
      userId: '',
      apiStatus: ApiStatus.idle,
      teams: [],
      errorMessage: null,
    );
  }
}

class TeamsController extends Notifier<TeamsState> {
  @override
  TeamsState build() {
    final userId =
        ref.watch(authControllerProvider.select((value) => value.user?.uid));
    return TeamsState.initial().copyWith(userId: userId);
  }

  Future<List<Team>> fetchTeams() async {
    try {
      state = state.copyWith(apiStatus: ApiStatus.loading);
      // get teams from firestore collection but only where the user is a member or owner
      /*
        { name: “...”, description: “....”, roles: { user1: “owner”, user2: “admin”, user3: “member”}, … }
      */
      final snapshot = await FirebaseFirestore.instance
          .collection('teams')
          .where('roles.${state.userId}',
              whereIn: ['owner', 'admin', 'member']).get();
      final teams =
          snapshot.docs.map((doc) => Team.fromJson(doc.data())).toList();
      state = state.copyWith(apiStatus: ApiStatus.success, teams: teams);
      return teams;
    } catch (e) {
      state = state.copyWith(apiStatus: ApiStatus.error, errorMessage: '$e');
      return [];
    }
  }
  Future<void> addTeam(Team team, File? image) async {
    try {
      state = state.copyWith(apiStatus: ApiStatus.loading);
      // save the team cover image to firebase storage and get the image url and save the image url to firestore
      if (image != null) {
        final ref = FirebaseStorage.instance
            .ref('teams/${team.name}-${DateTime.now().millisecondsSinceEpoch}');
        await ref.putFile(image);
        team = team.copyWith(imageUrl: await ref.getDownloadURL());
      }
      // save the team to firestore
      final docRef = await FirebaseFirestore.instance.collection('teams').add({
        'name': team.name,
        'description': team.description,
        'imageUrl': team.imageUrl,
        'roles': {state.userId: 'owner'},
      });
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
      state = state.copyWith(apiStatus: ApiStatus.loading);
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
