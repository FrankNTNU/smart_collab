import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/screens/home_screen.dart';
import 'package:smart_collab/screens/login_screen.dart';

import 'firebase_options.dart';
import 'services/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenicated = ref.watch(authControllerProvider.select(
          (value) => value.isAuthenicated,
        ));
    return  MaterialApp(
      // remove debug label
      debugShowCheckedModeBanner: false,
      home: !isAuthenicated ? const LoginScreen() : const HomeScreen()
    );
  }
}
