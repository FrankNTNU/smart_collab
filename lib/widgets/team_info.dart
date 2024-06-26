import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/team_controller.dart';

import '../services/auth_controller.dart';
import '../utils/translation_keys.dart';
import 'add_or_edit_team_sheet.dart';
import 'delete_confirm_dialog.dart';
import 'grey_description.dart';
import 'invite_to_team.dart';
import 'stats.dart';
import 'team_members.dart';
import 'title_text.dart';

class TeamInfo extends ConsumerStatefulWidget {
  const TeamInfo({super.key, required this.team});
  final Team team;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TeamInfoState();
}

class _TeamInfoState extends ConsumerState<TeamInfo> {
  @override
  Widget build(BuildContext context) {
    final teamData = widget.team;
    final uid =
        ref.watch(authControllerProvider.select((value) => value.user?.uid));
    final isOwnerOrAdmin =
        teamData.roles[uid] == 'owner' || teamData.roles[uid] == 'admin';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TitleText('${teamData.name}'),
              ),
            ),
            if (isOwnerOrAdmin)
              PopupMenuButton(
                onSelected: (value) {
                  if (value == 'edit') {
                    showModalBottomSheet(
                      isScrollControlled: true,
                      enableDrag: true,
                      showDragHandle: true,
                      context: context,
                      builder: (context) {
                        return AddTeamSheet(
                          addOrEdit: AddorEdit.edit,
                          team: teamData,
                        );
                      },
                    );
                  } else if (value == 'delete') {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return DeleteConfirmDialog(
                          deleteValidationText:
                              teamData.name ?? 'I want to delete this team',
                          title: 'Delete Team',
                          description:
                              'The deleted team will be archived, but you can restore it later.',
                          content: TranslationKeys.confirmDeleteTeam.tr(),
                          onConfirm: () {
                            // have the user enter the team name before deletion
                            ref
                                .read(teamsProvider.notifier)
                                .archieveTeam(teamData.id!);
                            // pop
                            Navigator.of(context).pop();
                          },
                          confirmText: TranslationKeys.delete.tr(),
                        );
                      },
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit),
                        const SizedBox(
                          width: 8,
                        ),
                        Text(
                            '${TranslationKeys.edit.tr()} ${TranslationKeys.team.tr()}')
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete),
                        const SizedBox(
                          width: 8,
                        ),
                        Text(
                            '${TranslationKeys.delete.tr()} ${TranslationKeys.team.tr()}')
                      ],
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_horiz),
              )
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          child: Text(teamData.description ?? ''),
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TitleText(
                TranslationKeys.members.tr(),
              ),
            ),
            if (isOwnerOrAdmin)
              TextButton.icon(
                label: Text(TranslationKeys.invite.tr()),
                icon: const Icon(Icons.person_add),
                onPressed: () {
                  showModalBottomSheet(
                    isScrollControlled: true,
                    enableDrag: true,
                    showDragHandle: true,
                    context: context,
                    builder: (context) => InviteToTeam(teamId: teamData.id!),
                  );
                },
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GreyDescription(
              '${teamData.roles.entries.length} ${TranslationKeys.members.tr()}'),
        ),
        TeamMembers(
          teamId: teamData.id!,
        ),
        const Divider(),
        StatsInfo(
          teamId: teamData.id!,
        ),
        const Divider(),
      ],
    );
  }
}
