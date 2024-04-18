import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/auth_controller.dart';
import 'package:smart_collab/widgets/add_or_edit_issue_sheet.dart';
import 'package:smart_collab/widgets/add_or_edit_team_sheet.dart';
import 'package:smart_collab/widgets/cover_image.dart';
import 'package:smart_collab/widgets/invite_to_team.dart';
import 'package:smart_collab/widgets/team_members.dart';

import '../services/issue_controller.dart';
import '../services/team_controller.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/issues.dart';

class TeamScreen extends ConsumerStatefulWidget {
  final Team team;
  const TeamScreen({super.key, required this.team});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  // scroll controller
  final _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    // listen to scroll event
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        print('User reached end of list');
        ref
            .read(issueProvider(widget.team.id!).notifier)
            .fetchIssues(widget.team.id!);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamData = ref.watch(teamsProvider.select((value) =>
        value.teams.where((team) => team.id == widget.team.id).first));
    print('All roles: ${teamData.roles}');
    final isOwnerOrAdmin = teamData
                .roles[ref.watch(authControllerProvider).user!.uid] ==
            'owner' ||
        teamData.roles[ref.watch(authControllerProvider).user!.uid] == 'admin';

    final isFetching = ref.watch(issueProvider(widget.team.id!).select(
        (value) =>
            value.apiStatus == ApiStatus.loading &&
            value.performedAction == PerformedAction.fetch));
    return Scaffold(
      appBar: AppBar(
        title: Text(teamData.name ?? ''),
        actions: [
          if (isOwnerOrAdmin)
            IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.edit),
                              title: const Text('Edit'),
                              onTap: () {
                                // show bottom sheet
                                showModalBottomSheet(
                                  isScrollControlled: true,
                                  // show handle
                                  enableDrag: true,
                                  showDragHandle: true,
                                  context: context,
                                  builder: (context) {
                                    return Padding(
                                      padding: MediaQuery.of(context)
                                          .viewInsets
                                          .copyWith(left: 16, right: 16),
                                      child: AddTeamSheet(
                                          addOrEdit: AddorEdit.update,
                                          team: teamData),
                                    );
                                  },
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete),
                              title: const Text('Delete'),
                              onTap: () {
                                //ref.read(teamsProvider.notifier).deleteTeam(teams[index]);
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return ConfirmDialog(
                                      title: 'Delete Team',
                                      content:
                                          'Are you sure you want to delete this team?',
                                      onConfirm: () {
                                        ref
                                            .read(teamsProvider.notifier)
                                            .deleteTeam(teamData.id!);
                                        Navigator.pop(context);
                                      },
                                      confirmText: 'Delete',
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.more_horiz))
        ],
      ),
      floatingActionButton: // add button
          FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            isScrollControlled: true,
            enableDrag: true,
            showDragHandle: true,
            context: context,
            builder: (context) => Padding(
              padding: MediaQuery.of(context)
                  .viewInsets
                  .copyWith(left: 16, right: 16),
              child: AddOrEditIssueSheet(
                teamId: teamData.id!,
                addOrEdit: AddorEdit.add,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ListView(
        controller: _scrollController,
        children: [
          // show cover image
          if (teamData.imageUrl != null)
            // network image
            CoverImage(
              imageUrl: teamData.imageUrl!,
              isRoundedBorder: false,
              height: MediaQuery.of(context).size.height * 0.2,
            ),
          // description about team
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(teamData.description ?? ''),
          ),
          if (isOwnerOrAdmin)
            // add admin button
            ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  isScrollControlled: true,
                  enableDrag: true,
                  showDragHandle: true,
                  context: context,
                  builder: (context) => Padding(
                    padding: MediaQuery.of(context)
                        .viewInsets
                        .copyWith(left: 16, right: 16),
                    child: InviteToTeam(teamId: widget.team.id!),
                  ),
                );
              },
              child: const Text('Invite user to team'),
            ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Members',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          // show a list of admins horizontally
          TeamMembers(
            teamId: teamData.id!,
          ),
          const Divider(),

          Issues(teamId: teamData.id!),
          if (isFetching) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
