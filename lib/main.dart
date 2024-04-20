import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  bool isDarkMode = false;
  @override
  void initState() {
    super.initState();
    _getIsDarkMode();
  }

  void _setIsDarkMode(bool value) async {
    setState(() {
      isDarkMode = value;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', value);
  }

  void _getIsDarkMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenicated = ref.watch(authControllerProvider.select(
      (value) => value.isAuthenicated,
    ));

    return MaterialApp(
      // theme
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light()
        .copyWith(
          iconTheme:  IconThemeData(color: Colors.grey.shade600),
          listTileTheme: ListTileThemeData(iconColor: Colors.grey.shade600),
        ),
      // remove debug label
      debugShowCheckedModeBanner: false,
      home: !isAuthenicated
          ? const LoginScreen()
          : HomeScreen(
              toggleTheme: _setIsDarkMode,
              isDarkMode: isDarkMode,
            ),
    );
  }
}
