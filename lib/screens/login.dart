import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  void _googleSignIn() async {
    try {
      ref.read(authControllerProvider.notifier).loginWithGoogle();
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticating = ref.watch(authControllerProvider.select(
          (value) => value.apiStatus,
        )) ==
        ApiStatus.loading;
    return Scaffold(
      body: Center(
        child: isAuthenticating
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _googleSignIn,
                child: const Text('Sign in with Google'),
              ),
      ),
    );
  }
}
