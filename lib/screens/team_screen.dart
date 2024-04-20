import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/auth_controller.dart';
import 'package:smart_collab/widgets/add_or_edit_team_sheet.dart';
import 'package:smart_collab/widgets/cover_image.dart';
import 'package:smart_collab/widgets/delete_confirm_dialog.dart';
import 'package:smart_collab/widgets/invite_to_team.dart';
import 'package:smart_collab/widgets/notification_bell.dart';
import 'package:smart_collab/widgets/team_members.dart';

import '../services/issue_controller.dart';
import '../services/team_controller.dart';
import '../widgets/issues.dart';
import '../widgets/title_text.dart';

class TeamScreen extends ConsumerStatefulWidget {
  final Team team;
  const TeamScreen({super.key, required this.team});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  // scroll controller
  final _scrollController = ScrollController();
  // cover image height
  final double _coverImageHeight = 128;
  // isCloseToBottom
  bool _isNotAtTop = false;
  @override
  void initState() {
    super.initState();
    // listen to scroll event
    _scrollController.addListener(() {
      bool isNotAtTop = _scrollController.position.pixels > 0;
      if (_isNotAtTop != isNotAtTop) {
        setState(() {
          _isNotAtTop = isNotAtTop;
        });
      }
      final isCloseToBottom = _scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent;
      if (isCloseToBottom) {
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
        value.teams.where((team) => team.id == widget.team.id).firstOrNull));
    if (teamData == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    print('All roles: ${teamData.roles}');
    final uid =
        ref.watch(authControllerProvider.select((value) => value.user!.uid));
    final isOwnerOrAdmin =
        teamData.roles[uid] == 'owner' || teamData.roles[uid] == 'admin';

    final isFetching = ref.watch(issueProvider(widget.team.id!).select(
        (value) =>
            value.apiStatus == ApiStatus.loading &&
            value.performedAction == PerformedAction.fetch));
    return Scaffold(
      appBar: AppBar(
        title: Tooltip(
          message: 'teamId: ${teamData.id}',
          child: Text(teamData.name ?? ''),
        ),
        actions: [
          // notification icon button
          NotificationBell(
            teamId: teamData.id!,
          ),
        ],
      ),
      // scroll tp top button
      floatingActionButton: _isNotAtTop && // when the keybaord is not open
              MediaQuery.of(context).viewInsets.bottom == 0
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              child: const Icon(Icons.arrow_upward),
            )
          : null,
      // floatingActionButton: // add button
      //     FloatingActionButton(
      //   onPressed: () {
      //     showModalBottomSheet(
      //       isScrollControlled: true,
      //       enableDrag: true,
      //       showDragHandle: true,
      //       context: context,
      //       builder: (context) => AddOrEditIssueSheet(
      //         teamId: teamData.id!,
      //         addOrEdit: AddorEdit.add,
      //       ),
      //     );
      //   },
      //   child: const Icon(Icons.add),
      // ),

      body: ListView(
        controller: _scrollController,
        children: [
          // show cover image
          if (teamData.imageUrl != null)
            // network image
            CoverImage(
              imageUrl: teamData.imageUrl!,
              isRoundedBorder: false,
              height: _coverImageHeight,
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TitleText('${teamData.name}'),
              ),
              if (isOwnerOrAdmin)
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Edit Team'),
                        onTap: () {
                          showModalBottomSheet(
                            isScrollControlled: true,
                            enableDrag: true,
                            showDragHandle: true,
                            context: context,
                            builder: (context) {
                              return Padding(
                                padding: const EdgeInsets.all(8),
                                child: AddTeamSheet(
                                  addOrEdit: AddorEdit.update,
                                  team: teamData,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    PopupMenuItem(
                      child: ListTile(
                        leading: const Icon(Icons.delete),
                        title: const Text('Delete'),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return DeleteConfirmDialog(
                                deleteValidationText: teamData.name ?? 'I want to delete this team',
                                title: 'Delete Team',
                                content: 'Are you sure you want to delete this team?',
                                onConfirm: () {
                                  // have the user enter the team name before deletion
                                  
                                  ref
                                      .read(teamsProvider.notifier)
                                      .deleteTeam(teamData.id!);
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                                confirmText: 'Delete',
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_horiz),
                )],
          ),
          // description about team
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            child: Text(teamData.description ?? ''),
          ),
          const Divider(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: TitleText('Members',),
              ),
              if (isOwnerOrAdmin)
                TextButton.icon(
                  label: const Text('Invite'),
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
