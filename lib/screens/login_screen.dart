import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/utils/translation_keys.dart';

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
      body: Column(
        children: [
          // image from file
          Image.asset(
            'assets/images/office.jpg',
            width: double.infinity,
          ),
          // welcome text
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              TranslationKeys.welcomeToSmartcollab.tr(),
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.headlineMedium!.fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(
            child: isAuthenticating
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _googleSignIn,
                    child: SizedBox(
                      height: 64,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Image.network(
                              'http://pngimg.com/uploads/google/google_PNG19635.png',
                              fit: BoxFit.cover),
                          const SizedBox(
                            width: 5.0,
                          ),
                          Text(TranslationKeys.signInWithGoogle.tr())
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
