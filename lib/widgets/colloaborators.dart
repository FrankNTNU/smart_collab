import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/screens/team_user_search_screen.dart';
import 'package:smart_collab/services/auth_controller.dart';
import 'package:smart_collab/services/issue_controller.dart';

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
    // all collaborators
    final collaborators = ref.watch(issueProvider(widget.teamId).select(
        (value) => value.issues
            .where((issue) => issue.id == widget.issueId)
            .first
            .roles
            .entries));
    if (collaborators.isEmpty) {
      return const Center(
        child: Text('No collaborators found'),
      );
    }
    // get owner uid
    final ownerUid =
        collaborators.where((role) => role.value == 'owner').firstOrNull?.key;
    // isOwnerOrAdmin
    final isOwner = ref.read(authControllerProvider).user!.uid == ownerUid;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...collaborators.map((role) {
            return Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: Column(
                children: [
                  UserAvatar(uid: role.key),
                  Text(role.value),
                ],
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
                                    ownerUid!
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
