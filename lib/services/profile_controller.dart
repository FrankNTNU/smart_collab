// a future provider
// A "functional" provider
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/auth_controller.dart';

final profileDataProvider =
    FutureProvider.autoDispose.family<SmartCollabUser, String>((ref, uid) async {
  // fetch the profile image url from Firestore the users collecions
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  DocumentSnapshot<Map<String, dynamic>> snapshot =
      await firestore.collection('users').doc(uid).get();
  final data = snapshot.data();
  return SmartCollabUser(
    uid: data!['uid'],
    email: data['email'],
    displayName: data['displayName'],
    photoURL: data['photoURL'],
  );

});

// get profile from email
final profileFromEmailProvider =
    FutureProvider.autoDispose.family<SmartCollabUser, String>((ref, email) async {
  // fetch the profile image url from Firestore the users collecions
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  QuerySnapshot<Map<String, dynamic>> snapshot =
      await firestore.collection('users').where('email', isEqualTo: email).get();
  print('Email in profileFromEmailProvider: $email');
  final data = snapshot.docs.first.data();
  return SmartCollabUser(
    uid: data['uid'],
    email: data['email'],
    displayName: data['displayName'],
    photoURL: data['photoURL'],
  );

});
