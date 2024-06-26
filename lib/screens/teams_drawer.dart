import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/screens/config_screen.dart';
import 'package:smart_collab/utils/translation_keys.dart';

import '../services/auth_controller.dart';
import '../services/team_controller.dart';
import '../widgets/add_or_edit_team_sheet.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/title_text.dart';

class TeamsDrawer extends ConsumerStatefulWidget {
  final Function(Team team)? onTeamSelected;
  const TeamsDrawer({
    super.key,
    this.onTeamSelected,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TeamsDrawerState();
}

class _TeamsDrawerState extends ConsumerState<TeamsDrawer> {
  @override
  void initState() {
    super.initState();
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
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
                  if (team.imageUrl == null || team.isArchieved)
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
                        child: team.isArchieved ? 
                        const Icon(Icons.archive, color: Colors.white,)
                        : Expanded(
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(team.name!,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
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
          IconButton(
              onPressed: () {
                // push to
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const ConfigurationScreen()),
                );
              },
              icon: const Icon(Icons.settings)),
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
