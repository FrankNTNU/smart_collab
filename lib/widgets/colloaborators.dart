import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/screens/team_user_search_screen.dart';
import 'package:smart_collab/services/auth_controller.dart';
import 'package:smart_collab/services/issue_controller.dart';

import '../services/activity_controller.dart';
import '../services/profile_controller.dart';
import '../utils/translation_keys.dart';
import 'confirm_dialog.dart';
import 'user_avatar.dart';

class Collaborators extends ConsumerStatefulWidget {
  final String issueId;
  final String teamId;
  const Collaborators({super.key, required this.issueId, required this.teamId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CollaboratorsState();
}

class _CollaboratorsState extends ConsumerState<Collaborators> {
  void _onSelected(String uid) async {
    await ref
        .read(issueProvider(widget.teamId).notifier)
        .addCollaborator(issueId: widget.issueId, uid: uid);
    final profile = await ref.read(profileDataProvider(uid).future);
    final issueData = ref.watch(issueProvider(widget.teamId)
        .select((value) => value.issueMap[widget.issueId]));
    // add to activity
    await ref.read(activityProvider(widget.teamId).notifier).addActivity(
          recipientUid: profile.uid!,
          message:
              '${profile.displayName} have been added as collaborator in an issue ${issueData?.title ?? ''}',
          activityType: ActivityType.setAsCollaborator,
          teamId: widget.teamId,
          issueId: widget.issueId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final issue = ref.watch(issueProvider(widget.teamId).select(
        (value) => value.issueMap[widget.issueId])); // all collaborators
    var collaborators = issue?.roles.entries
        .where((role) => role.value == 'collaborator')
        .toList();

    // get owner uid
    final ownerUid =
        issue?.roles.entries.firstWhere((role) => role.value == 'owner').key;
    // isOwnerOrAdmin
    final isLoggedInUserTheOwner =
        ref.watch(authControllerProvider).user!.uid == ownerUid;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // owner info
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              children: [
                UserAvatar(uid: ownerUid!),
                 Text(TranslationKeys.author.tr()),
              ],
            ),
          ),
          // collab info
          if (collaborators != null && collaborators.isNotEmpty)
            ...collaborators.map((role) {
              return InkWell(
                onLongPress: () {
                  if (isLoggedInUserTheOwner) {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // set ad admin
                            ListTile(
                              leading: const Icon(Icons.admin_panel_settings),
                              title: const Text('Remove collaborator'),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return ConfirmDialog(
                                      title: 'Remove collaborator',
                                      content:
                                          'Are you sure you want to remove this collaborator?',
                                      onConfirm: () {
                                        ref
                                            .read(issueProvider(widget.teamId)
                                                .notifier)
                                            .removeCollaborator(
                                                issueId: widget.issueId,
                                                uid: role.key);
                                      },
                                      confirmText: 'Remove',
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only( right: 8),
                  child: Column(
                    children: [
                      UserAvatar(uid: role.key),
                      Text(role.value.tr()),
                    ],
                  ),
                ),
              );
            }),
          if (isLoggedInUserTheOwner)
            Column(
              children: [
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      isScrollControlled: true,
                      enableDrag: true,
                      showDragHandle: true,
                      context: context,
                      builder: (context) => Padding(
                        padding: MediaQuery.of(context).viewInsets,
                        child: TeamUserSearchScreen(
                          teamId: widget.teamId,
                          onSelected: _onSelected,
                          excludedMembers: [
                            // exclude the owner of the issue
                            ownerUid
                          ],
                        ),
                      ),
                    );
                  },
                  child:
                      const SizedBox(height: 50, width: 50, child: CircleAvatar(child: Icon(Icons.add))),
                ),
                 Text(TranslationKeys.add.tr()),
              ],
            )
        ],
      ),
    );
  }
}
