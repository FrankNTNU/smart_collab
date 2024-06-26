import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/screens/home_screen.dart';
import 'package:smart_collab/screens/login_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'firebase_options.dart';
import 'services/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // only portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // for timeago i18n, set zh_TW
  timeago.setLocaleMessages('zh_TW', timeago.ZhMessages());
  // add en_US
  timeago.setLocaleMessages('en_US', timeago.EnMessages());
  runApp(ProviderScope(
    child: EasyLocalization(
      path: 'assets/translations',
      supportedLocales: const [
        // en-US and zh-TW
        Locale('en', 'US'),
        Locale('zh', 'TW'),
      ],
      child: const MainApp(),
    ),
  ));
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenicated = ref.watch(authControllerProvider.select(
      (value) => value.isAuthenicated,
    ));
    final isDarkMode = ref.watch(isDarkModeProvider).asData?.value ?? false;
    return MaterialApp(
      // for i18n
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      // theme
      theme: isDarkMode
          ? ThemeData.dark()
          : ThemeData.light().copyWith(
              iconTheme: IconThemeData(color: Colors.grey.shade600),
              listTileTheme: ListTileThemeData(iconColor: Colors.grey.shade600),
            ),
      // remove debug label
      debugShowCheckedModeBanner: false,
      home: !isAuthenicated ? const LoginScreen() : const HomeScreen(),
    );
  }
}
