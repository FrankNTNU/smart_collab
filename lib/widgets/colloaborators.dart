import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/screens/team_user_search_screen.dart';
import 'package:smart_collab/services/auth_controller.dart';
import 'package:smart_collab/services/issue_controller.dart';

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
  void _onSelected(String uid) {
    ref
        .read(issueProvider(widget.teamId).notifier)
        .addCollaborator(issueId: widget.issueId, uid: uid);
  }

  @override
  Widget build(BuildContext context) {
    final issue = ref
        .watch(issueProvider(widget.teamId).select((value) =>
            value.issues.where((issue) => issue.id == widget.issueId)))
        .firstOrNull;
    // all collaborators
    var collaborators = issue?.roles.entries
        .where((role) => role.value == 'collaborator')
        .toList();

    // get owner uid
    final ownerUid =
        issue?.roles.entries.firstWhere((role) => role.value == 'owner').key;
    // isOwnerOrAdmin
    final isOwner = ref.watch(authControllerProvider).user!.uid == ownerUid;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // owner info
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: Column(
              children: [
                UserAvatar(uid: ownerUid!),
                const Text('author'),
              ],
            ),
          ),
          // collab info
          if (collaborators != null && collaborators.isNotEmpty)
            ...collaborators.map((role) {
              return InkWell(
                onLongPress: () {
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
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: Column(
                    children: [
                      UserAvatar(uid: role.key),
                      Text(role.value),
                    ],
                  ),
                ),
              );
            }),
          if (isOwner)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                children: [
                  CircleAvatar(
                      child: IconButton(
                          onPressed: () {
                            // show bottom sheet
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
                          icon: const Icon(Icons.add))),
                  const Text('Add'),
                ],
              ),
            )
        ],
      ),
    );
  }
}
