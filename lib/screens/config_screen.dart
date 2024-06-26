import 'package:cloud_functions/cloud_functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/screens/home_screen.dart';

import '../services/auth_controller.dart';
import '../utils/translation_keys.dart';
import '../widgets/confirm_dialog.dart';
enum OnCallFuncNames {
  manuallyCorrectIssueIsClosed,
  manuallyCloseExpiredIssues,
}
class ConfigurationScreen extends ConsumerStatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ConfigurationScreenState();
}

class _ConfigurationScreenState extends ConsumerState<ConfigurationScreen> {
  bool _isLoading = false;
  Future<void> _triggerOnCallFunction(OnCallFuncNames funcName) async {
    setState(() {
      _isLoading = true;
    });
    HttpsCallable callable = FirebaseFunctions.instance.httpsCallableFromUri(
        Uri.parse(
            'https://us-central1-smart-collab-fd262.cloudfunctions.net/${funcName.name}'));
    try {
      var res = await callable.call();
      print('Triggered $funcName: ${res.data}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Triggered ${funcName.name} successfully'),
      ));
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error triggering $funcName: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to trigger ${funcName.name}'),
      ));
      setState(() {
        _isLoading = false;
      });
    }
    
  }
  
  void _logout() async {
    // confirm logout
    await showDialog(
      context: context,
      builder: (context) {
        return ConfirmDialog(
          title: TranslationKeys.logout.tr(),
          content: TranslationKeys.confirmSomething.tr(
            args: [TranslationKeys.logout.tr()],
          ),
          onConfirm: () {
            ref.read(authControllerProvider.notifier).signOut();
            // pop
            Navigator.of(context).pop();
          },
          confirmText: TranslationKeys.logout.tr(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
      ),
      body: Column(
        children: <Widget>[
          isDarkMode.when(
            data: (isDarkMode) => ListTile(
              trailing: Switch(
                value: isDarkMode,
                onChanged: (value) {
                  ref.read(isDarkModeProvider.notifier).toggleTheme(
                        !isDarkMode,
                      );
                },
              ),
              leading: isDarkMode
                  ? const Icon(Icons.dark_mode)
                  : const Icon(Icons.light_mode),
              title: Text(TranslationKeys.darkMode.tr()),
              onTap: () {
                ref.read(isDarkModeProvider.notifier).toggleTheme(
                      !isDarkMode,
                    );
              },
            ),
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Text('Error: $error'),
          ),
          ListTile(
            trailing: const Icon(Icons.arrow_forward_ios),
            leading: const Icon(Icons.logout),
            title: Text(TranslationKeys.logout.tr()),
            onTap: _logout,
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(context.locale == const Locale('en', 'US')
                ? '繁體中文'
                : 'English'),
            onTap: () {
              // supported language
              print(
                  'current locale: ${context.locale}, supported languages: ${context.supportedLocales}');
              context.setLocale(context.locale == const Locale('en', 'US')
                  ? const Locale('zh', 'TW')
                  : const Locale('en', 'US'));
            },
          ),
          const ListTile(
            // version
            leading: Icon(Icons.info_outline),
            title: Text('Version: 1.0.0'),
          ),
          ListTile(
            title: const Text('Trigger auto close issues'),
            leading: const Icon(Icons.timer),
            onTap: _isLoading
                ? null
                : () async {
                    await _triggerOnCallFunction(
                      OnCallFuncNames.manuallyCloseExpiredIssues
                    );
                  },
          ),
          ListTile(
            title: const Text('Correct issues state'),
            leading: const Icon(Icons.refresh),
            onTap: _isLoading
                ? null
                : () async {
                    await _triggerOnCallFunction(OnCallFuncNames.manuallyCorrectIssueIsClosed);
                  },
          ),
          if (_isLoading) 
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
