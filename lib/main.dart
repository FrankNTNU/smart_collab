import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // only portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: MainApp()));
}

// isDarkModeProvider
final isDarkModeProvider = StateProvider((_) => true);

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  @override
  Widget build(BuildContext context) {
    final isAuthenicated = ref.watch(authControllerProvider.select(
      (value) => value.isAuthenicated,
    ));
    return MaterialApp(
        // theme
        theme: ref.watch(isDarkModeProvider)
            ? ThemeData.dark()
            : ThemeData.light(),
        // remove debug label
        debugShowCheckedModeBanner: false,
        home: !isAuthenicated ? const LoginScreen() : const HomeScreen());
  }
}
