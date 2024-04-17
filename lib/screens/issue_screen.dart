import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/issue_controller.dart';

import '../services/profile_controller.dart';
import '../widgets/add_or_edit_issue_sheet.dart';
import '../widgets/add_or_edit_team_sheet.dart';
import '../widgets/confirm_dialog.dart';

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
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.8,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  issueData.title,
                  style: const TextStyle(
                    fontSize: 20,
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
                            issue: widget.issue,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit)),
                const CloseButton(),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                ...issueData.tags.map((tag) => Chip(
                      label: Text(tag),
                    ))
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
                          .firstWhere((element) => element.value == 'owner')
                          .key;
                      final asyncProfilePicProvider =
                          ref.watch(profileDataProvider(ownerId));
                      return asyncProfilePicProvider.when(
                        data: (profileData) {
                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage:
                                    profileData.photoURL?.isNotEmpty == true
                                        ? NetworkImage(profileData.photoURL!)
                                        : null,
                                child: profileData.photoURL == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                },
                child: const Text('Delete Issue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
