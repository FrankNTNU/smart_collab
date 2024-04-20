import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
//import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_collab/services/auth_controller.dart';
import 'package:smart_collab/utils/translation_keys.dart';
import 'package:smart_collab/widgets/confirm_dialog.dart';
import 'package:smart_collab/widgets/teams.dart';
import 'package:smart_collab/widgets/user_avatar.dart';

import '../widgets/add_or_edit_team_sheet.dart';
import '../widgets/title_text.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Function(bool) toggleTheme;
  final bool isDarkMode;
  const HomeScreen(
      {super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isDarkModel = false;
  @override
  void initState() {
    super.initState();
    _isDarkModel = widget.isDarkMode;
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
          },
          confirmText: TranslationKeys.logout.tr(),
        );
      },
    );
    // pop
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final username = ref.watch(authControllerProvider).user?.displayName;
    return Scaffold(
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: const IconThemeData(size: 22.0),
        children: [
          SpeedDialChild(
            child: const Icon(Icons.group_add),
            label: TranslationKeys.joinTeam.tr(),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return const SizedBox();
                },
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.add),
            label: TranslationKeys.createTeam.tr(),
            onTap: () {
              showModalBottomSheet(
                isScrollControlled: true,
                // show handle
                enableDrag: true,
                showDragHandle: true,
                context: context,
                builder: (context) => const AddTeamSheet(
                  addOrEdit: AddorEdit.add,
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(
            height: 32,
          ),
          // welcome text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TitleText(
                      TranslationKeys.greeting.tr(args: [username ?? 'User'])),
                ),
              ),
              UserAvatar(uid: ref.watch(authControllerProvider).user!.uid!),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: StatefulBuilder(
                      builder: (context, setState) => ListTile(
                        leading: const Icon(Icons.brightness_2),
                        title: Text(_isDarkModel
                            ? TranslationKeys.lightMode.tr()
                            : TranslationKeys.darkMode.tr()),
                        onTap: () {
                          setState(() {
                            widget.toggleTheme(!_isDarkModel);
                            _isDarkModel = !_isDarkModel;
                          });
                        },
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(Icons.logout),
                      title: Text(TranslationKeys.logout.tr()),
                      onTap: _logout,
                    ),
                  ),
                  // change language
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(context.locale == const Locale('en', 'US')
                          ? '繁體中文'
                          : 'English'),
                      onTap: () {
                        // supported language
                        print(
                            'current locale: ${context.locale}, supported languages: ${context.supportedLocales}');
                        context.setLocale(
                            context.locale == const Locale('en', 'US')
                                ? const Locale('zh', 'TW')
                                : const Locale('en', 'US'));
                        // pop
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          //const Profile(),
          const Teams(),
        ],
      ),
    );
  }
}
