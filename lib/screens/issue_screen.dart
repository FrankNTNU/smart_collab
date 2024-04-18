import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/widgets/comment_field.dart';
import 'package:smart_collab/widgets/comments.dart';

import '../services/auth_controller.dart';
import '../services/profile_controller.dart';
import '../widgets/add_or_edit_issue_sheet.dart';
import '../widgets/add_or_edit_team_sheet.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/user_avatar.dart';

class IssueScreen extends ConsumerStatefulWidget {
  const IssueScreen({super.key, required this.issue});
  final Issue issue;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _IssueScreenState();
}

class _IssueScreenState extends ConsumerState<IssueScreen> {
  @override
  Widget build(BuildContext context) {
    final issueData = ref.watch(issueProvider(widget.issue.teamId).select(
        (value) =>
            value.issues.where((issue) => issue.id == widget.issue.id).first));
    final areYouTheOnwerOrAdmin = issueData
                .roles[ref.read(authControllerProvider).user!.uid] ==
            'owner' ||
        issueData.roles[ref.read(authControllerProvider).user!.uid] == 'admin';
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
                      // edit button
                      IconButton(
                          onPressed: () {
                            // open bottom sheet
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
                                  teamId: widget.issue.teamId,
                                  addOrEdit: AddorEdit.update,
                                  issue: issueData,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit)),
                      const CloseButton(),
                    ],
                  ),
                  
                  
                  // creator information
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Consumer(
                          builder: (context, ref, child) {
                            final ownerId = widget.issue.roles.entries
                                .firstWhere(
                                    (element) => element.value == 'owner')
                                .key;
                            final asyncProfilePicProvider =
                                ref.watch(profileDataProvider(ownerId));
                            return asyncProfilePicProvider.when(
                              data: (profileData) {
                                return Row(
                                  children: [
                                    UserAvatar(
                                      uid: ownerId,
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(profileData.displayName ?? ''),
                                        // build time
                                        Text(
                                          'Created at ${issueData.createdAt}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                              loading: () => const CircularProgressIndicator(),
                              error: (error, _) => Text('Error: $error'),
                            );
                          },
                        )
                      ],
                    ),
                  ),
                 
                  Text(
                    issueData.description,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                   Wrap(
                    spacing: 8,
                    children: [
                      ...issueData.tags.map((tag) => Chip(
                        padding: const EdgeInsets.all(0),
                            label: Text(tag),
                          ))
                    ],
                  ),
                  const Divider(),
                  const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Comments(issueId: issueData.id),
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
                  // height 32
                  const SizedBox(height: 64),
                ],
              ),
            ),
          ),
          // a text field stick to bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: CommentField(
              issueId: issueData.id,
            ),
          ),
        ],
      ),
    );
  }
}
