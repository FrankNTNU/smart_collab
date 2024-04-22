import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/utils/translation_keys.dart';

import '../services/activity_controller.dart';
import '../services/auth_controller.dart';
import '../services/team_controller.dart';
import '../widgets/add_or_edit_team_sheet.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/title_text.dart';

class TeamsDrawer extends ConsumerStatefulWidget {
  final Function(Team team)? onTeamSelected;
  final Function(bool) toggleTheme;
  final bool isDarkMode;
  const TeamsDrawer(
      {super.key,
      this.onTeamSelected,
      required this.toggleTheme,
      required this.isDarkMode});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TeamsDrawerState();
}

class _TeamsDrawerState extends ConsumerState<TeamsDrawer> {
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
    final teams = ref.watch(teamsProvider.select(
      (value) => value.teams,
    ));
    return Drawer(
      width: 128,
      child: ListView(
        children: [
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TitleText(TranslationKeys.myTeams.tr()),
            ),
          ),
          ...teams.map((team) {
            final unreadActivities = ref.watch(
              activityProvider(team.id!).select((value) =>
                  value.activities.where((activity) => !activity.read)),
            ).length;
            return InkWell(
              onTap: () {
                if (widget.onTeamSelected != null) {
                  widget.onTeamSelected!(team);
                  // pop
                  Navigator.of(context).pop();
                  return;
                }
              },
              child: Column(
                children: [
                  if (team.imageUrl == null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        height: 64,
                        width: double.infinity,
                        // border radius
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          // circle
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            team.name![0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CachedNetworkImage(
                        imageUrl: team.imageUrl!,
                        imageBuilder: (context, imageProvider) => Container(
                          width: 64.0,
                          height: 64.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                                image: imageProvider, fit: BoxFit.cover),
                          ),
                        ),
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(team.name!),
                ],
              ),
            );
          }),
          InkWell(
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
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                  height: 64,
                  width: double.infinity,
                  // border radius
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.5),
                    // circle
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add)),
            ),
          ),
          const SizedBox(
            height: 32,
          ),
          StatefulBuilder(
            builder: (context, setState) => DrawButton(
              onTapped: () {
                setState(() {
                  widget.toggleTheme(!_isDarkModel);
                  _isDarkModel = !_isDarkModel;
                });
              },
              leading: const Icon(Icons.brightness_2),
              text: _isDarkModel
                  ? TranslationKeys.lightMode.tr()
                  : TranslationKeys.darkMode.tr(),
            ),
          ),
          DrawButton(
              onTapped: _logout,
              leading: const Icon(Icons.logout),
              text: TranslationKeys.logout.tr()),
          DrawButton(
              onTapped: () {
                // supported language
                print(
                    'current locale: ${context.locale}, supported languages: ${context.supportedLocales}');
                context.setLocale(context.locale == const Locale('en', 'US')
                    ? const Locale('zh', 'TW')
                    : const Locale('en', 'US'));
                // pop
                Navigator.of(context).pop();
              },
              leading: const Icon(Icons.language),
              text: context.locale == const Locale('en', 'US')
                  ? '繁體中文'
                  : 'English'),
        ],
      ),
    );
  }
}

class DrawButton extends StatelessWidget {
  final Function() onTapped;
  final Widget leading;
  final String text;
  const DrawButton(
      {super.key,
      required this.onTapped,
      required this.leading,
      required this.text});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTapped,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            leading,
            const SizedBox(
              width: 8,
            ),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
