import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum ApiStatus {
  idle,
  loading,
  success,
  error,
}

class AuthState {
  final bool isAuthenicated;
  final SmartCollabUser? user;
  final ApiStatus apiStatus;
  final String? errorMessage;
  // ctor
  AuthState({
    required this.isAuthenicated,
    this.user,
    required this.apiStatus,
    this.errorMessage,
  });
  // copyWith
  AuthState copyWith({
    bool? isAuthenicated,
    SmartCollabUser? user,
    ApiStatus? apiStatus,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenicated: isAuthenicated ?? this.isAuthenicated,
      user: user ?? this.user,
      apiStatus: apiStatus ?? this.apiStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // initial
  static AuthState initial() {
    return AuthState(
      isAuthenicated: false,
      user: null,
      apiStatus: ApiStatus.idle,
      errorMessage: null,
    );
  }
}

class SmartCollabUser {
  final String? uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  SmartCollabUser({
    this.uid,
    this.email,
    this.displayName,
    this.photoURL,
  });
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState.initial().copyWith(
      isAuthenicated: FirebaseAuth.instance.currentUser != null,
      user: SmartCollabUser(
        uid: FirebaseAuth.instance.currentUser?.uid,
        email: FirebaseAuth.instance.currentUser?.email,
        displayName: FirebaseAuth.instance.currentUser?.displayName,
        photoURL: FirebaseAuth.instance.currentUser?.photoURL,
      ),
    );
  }

  void loginWithGoogle() async {
    // loading
    state = state.copyWith(apiStatus: ApiStatus.loading);
    try {
      final userCred = await _signInWithGoogle();
      if (userCred.user != null) {
        state = state.copyWith(
          isAuthenicated: true,
          user: SmartCollabUser(
            uid: userCred.user?.uid,
            email: userCred.user?.email,
            displayName: userCred.user?.displayName,
            photoURL: userCred.user?.photoURL,
          ),
          apiStatus: ApiStatus.success,
        );
        print('User: ${userCred.user}');
        // save this user to firestore users collection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCred.user?.uid)
            .set({
          'uid': userCred.user?.uid,
          'email': userCred.user?.email,
          'displayName': userCred.user?.displayName,
          'photoURL': userCred.user?.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        state = state.copyWith(
          apiStatus: ApiStatus.error,
          errorMessage: 'Failed to login',
        );
      }
    } catch (e) {
      print('Error occured in loginWithGoogle: $e');
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<UserCredential> _signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn(
      // clientId: '914148944165-ss3iva3ib6uma6obbjsiolc2fmkf89ac.apps.googleusercontent.com',
    ).signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final userCred = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(userCred);
  }

  // sign out
  void signOut() async {
    await FirebaseAuth.instance.signOut();
    state = AuthState.initial();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(() => AuthController());
