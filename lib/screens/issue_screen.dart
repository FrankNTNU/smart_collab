import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/activity_controller.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/widgets/colloaborators.dart';
import 'package:smart_collab/widgets/comment_field.dart';
import 'package:smart_collab/widgets/comments.dart';
import 'package:smart_collab/widgets/deadline_info.dart';
import 'package:smart_collab/widgets/last_updated.dart';

import '../services/auth_controller.dart';
import '../widgets/add_or_edit_issue_sheet.dart';
import '../widgets/add_or_edit_team_sheet.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/grey_description.dart';
import '../widgets/issue_tags.dart';
import '../widgets/title_text.dart';
import 'filter_tags_selection_menu.dart';

class IssueScreen extends ConsumerStatefulWidget {
  const IssueScreen({super.key, required this.issue});
  final Issue issue;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _IssueScreenState();
}

class _IssueScreenState extends ConsumerState<IssueScreen> {
  void _onTagToggle(String tag) {
    print('Tag toggled: $tag');
    final tags = ref
            .watch(issueProvider(widget.issue.teamId).select((value) => value
                .issues
                .where((issue) => issue.id == widget.issue.id)
                .firstOrNull))
            ?.tags ??
        [];
    if (tags.contains(tag)) {
      ref
          .read(issueProvider(widget.issue.teamId).notifier)
          .removeTagFromIssue(issueId: widget.issue.id, tag: tag);
    } else {
      ref
          .read(issueProvider(widget.issue.teamId).notifier)
          .addTagToIssue(issueId: widget.issue.id, tag: tag);
    }
  }

  void _showDeletionDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return ConfirmDialog(
          title: 'Delete',
          content: 'Are you sure you want to delete this issue?',
          onConfirm: () {
            ref
                .read(issueProvider(widget.issue.teamId).notifier)
                .removeIssue(widget.issue.id);
            Navigator.pop(context);
          },
          confirmText: 'Delete',
        );
      },
    );
    // pop
    Navigator.pop(context);
  }

  void _toggleIsClosed(
      {required Issue issueData, required bool isClosed}) async {
    print('Toggling isClosed, isClosed: $isClosed');
    await ref
        .read(issueProvider(widget.issue.teamId).notifier)
        .setIsClosed(issueId: widget.issue.id, isClosed: isClosed);
    final uid = ref.watch(authControllerProvider).user!.uid;
    final username = ref.watch(authControllerProvider).user!.displayName;
    // add to activity
    await ref.read(activityProvider(widget.issue.teamId).notifier).addActivity(
          issueId: widget.issue.id,
          teamId: widget.issue.teamId,
          message:
              '$username has ${isClosed ? 'closed' : 'opened'} the issue ${issueData.title}',
          activityType:
              isClosed ? ActivityType.closeIssue : ActivityType.openIssue,
          recipientUid: uid!,
        );
    // pop
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    print('Rebuilding IssueScreen');
    final issueData = ref.watch(issueProvider(widget.issue.teamId).select(
        (value) => value.issues
            .where((issue) => issue.id == widget.issue.id)
            .firstOrNull));
    if (issueData == null) {
      return const Center(
        child: Text('Issue not found'),
      );
    }
    final areYouTheOnwerOrAdmin = issueData
                .roles[ref.watch(authControllerProvider).user!.uid] ==
            'owner' ||
        issueData.roles[ref.watch(authControllerProvider).user!.uid] == 'admin';
    final isAuthorOrColloborator =
        issueData.roles[ref.watch(authControllerProvider).user!.uid] ==
                'owner' ||
            issueData.roles[ref.watch(authControllerProvider).user!.uid] ==
                'collaborator';
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.85,
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // is open
                      IsOpenChip(
                        isOpen: !issueData.isClosed,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      TitleText(
                        issueData.title,
                      ),
                      // spacer and close button
                      const Spacer(),
                      if (isAuthorOrColloborator)
                        // edit button
                        PopupMenuButton(
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem(
                              child: ListTile(
                                leading: const Icon(Icons.edit),
                                title: const Text('Edit Issue'),
                                onTap: () {
                                  showModalBottomSheet(
                                    isScrollControlled: true,
                                    enableDrag: true,
                                    showDragHandle: true,
                                    context: context,
                                    builder: (context) => AddOrEditIssueSheet(
                                      teamId: widget.issue.teamId,
                                      addOrEdit: AddorEdit.update,
                                      issue: issueData,
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (isAuthorOrColloborator && !issueData.isClosed)
                              // close issue
                              PopupMenuItem(
                                child: ListTile(
                                  leading: const Icon(Icons.close),
                                  title: const Text('Close Issue'),
                                  onTap: () {
                                    _toggleIsClosed(
                                        isClosed: true, issueData: issueData);
                                  },
                                ),
                              ),
                            if (areYouTheOnwerOrAdmin && issueData.isClosed)
                              // open issue
                              PopupMenuItem(
                                child: ListTile(
                                  leading: const Icon(Icons.refresh),
                                  title: const Text('Open Issue'),
                                  onTap: () {
                                    _toggleIsClosed(
                                        isClosed: false, issueData: issueData);
                                  },
                                ),
                              ),
                            if (isAuthorOrColloborator)
                              PopupMenuItem(
                                child: ListTile(
                                  leading: const Icon(Icons.delete),
                                  title: const Text('Delete Issue'),
                                  onTap: () {
                                    _showDeletionDialog();
                                  },
                                ),
                              ),
                          ],
                          child: const Icon(Icons.more_horiz),
                        ),
                      const CloseButton(),
                    ],
                  ),
                  // last updated at information
                  LastUpdatedAtInfo(issueData: issueData),
                  // deadline
                  if (issueData.deadline != null)
                    DeadlineInfo(issueData: issueData),
                  Text(
                    issueData.description,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  // show tags
                  InkWell(
                      onTap: !isAuthorOrColloborator
                          ? null
                          : () {
                              showModalBottomSheet(
                                  isScrollControlled: true,
                                  enableDrag: true,
                                  showDragHandle: true,
                                  context: context,
                                  builder: (context) {
                                    return FilterTagsSelectionMenu(
                                      initialTags: issueData.tags,
                                      onSelected: _onTagToggle,
                                      teamId: widget.issue.teamId,
                                      title: 'Edit Tags',
                                    );
                                  });
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: IssueTags(
                          tags: issueData.tags,
                          teamId: widget.issue.teamId,
                          isEditable: isAuthorOrColloborator,
                        ),
                      )),

                  const Divider(),
                  const TitleText(
                    'Collaborators',
                  ),
                  // grey description
                  const GreyDescription(
                    'People who can edit this issue',
                  ),
                  Collaborators(
                      issueId: issueData.id, teamId: widget.issue.teamId),

                  // show a list of admins horizontally

                  const Divider(),
                  const TitleText('Comments'),
                  Comments(issueId: issueData.id, teamId: widget.issue.teamId),
                  const Divider(),
                  // created at information
                  GreyDescription(
                    'Created at ${issueData.createdAt}',
                  ),
                  // height 32
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          // a text field stick to bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: CommentField(
              issueId: issueData.id,
              teamId: widget.issue.teamId,
            ),
          ),
        ],
      ),
    );
  }
}

class IsOpenChip extends StatelessWidget {
  const IsOpenChip({
    super.key,
    required this.isOpen,
  });

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen
            ? Colors.green.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(
          color: isOpen ? Colors.green : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
