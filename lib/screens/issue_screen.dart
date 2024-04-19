import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/widgets/colloaborators.dart';
import 'package:smart_collab/widgets/comment_field.dart';
import 'package:smart_collab/widgets/comments.dart';
import 'package:smart_collab/widgets/last_updated.dart';

import '../services/auth_controller.dart';
import '../widgets/add_or_edit_issue_sheet.dart';
import '../widgets/add_or_edit_team_sheet.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/issue_tags.dart';
import 'tag_selector_screen.dart';

class IssueScreen extends ConsumerStatefulWidget {
  const IssueScreen({super.key, required this.issue});
  final Issue issue;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _IssueScreenState();
}

class _IssueScreenState extends ConsumerState<IssueScreen> {
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
                      Text(
                        issueData.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // spacer and close button
                      const Spacer(),
                      if (isAuthorOrColloborator)
                        // edit button
                        IconButton(
                            onPressed: () {
                              // open bottom sheet
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
                            icon: const Icon(Icons.edit)),
                      const CloseButton(),
                    ],
                  ),
                  // last updated at information
                  LastUpdatedAtInfo(issueData: issueData),
                  Text(
                    issueData.description,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  // show tags
                  InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return TagSelectorScreen(
                                teamId: issueData.teamId,
                                issueId: widget.issue.id,
                                initialTags: widget.issue.tags,
                              );
                            },
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: IssueTags(
                          tags: issueData.tags,
                          teamId: widget.issue.teamId,
                          isEditable: true,
                        ),
                      )),
                  const Divider(),
                  const Text(
                    'Collaborators',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  // grey description
                  const Text(
                    'People who can edit this issue',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Collaborators(
                      issueId: issueData.id, teamId: widget.issue.teamId),

                  // show a list of admins horizontally

                  const Divider(),
                  const Text('Comments',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Comments(issueId: issueData.id, teamId: widget.issue.teamId),
                  const Divider(),
                  if (areYouTheOnwerOrAdmin)
                    // delete button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: ElevatedButton(
                        onPressed: () {
                          // use ConfirmDialog
                          showDialog(
                            context: context,
                            builder: (context) {
                              return ConfirmDialog(
                                title: 'Delete',
                                content:
                                    'Are you sure you want to delete this issue?',
                                onConfirm: () {
                                  ref
                                      .read(issueProvider(widget.issue.teamId)
                                          .notifier)
                                      .removeIssue(widget.issue.id);
                                  Navigator.pop(context);
                                },
                                confirmText: 'Delete',
                              );
                            },
                          );
                        },
                        child: const Text('Delete Issue'),
                      ),
                    ),
                  // created at information
                  Text(
                    'Created at ${issueData.createdAt}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
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
