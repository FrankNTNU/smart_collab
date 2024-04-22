import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/activity_controller.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/widgets/colloaborators.dart';
import 'package:smart_collab/widgets/comment_field.dart';
import 'package:smart_collab/widgets/comments.dart';
import 'package:smart_collab/widgets/deadline_info.dart';
import 'package:smart_collab/widgets/issue_tile.dart';
import 'package:smart_collab/widgets/issues.dart';
import 'package:smart_collab/widgets/last_updated.dart';

import '../services/auth_controller.dart';
import '../utils/translation_keys.dart';
import '../widgets/add_or_edit_issue_sheet.dart';
import '../widgets/add_or_edit_team_sheet.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/grey_description.dart';
import '../widgets/issue_tags.dart';
import '../widgets/title_text.dart';
import 'tags_selection_menu.dart';

class IssueScreen extends ConsumerStatefulWidget {
  const IssueScreen({super.key, required this.issue});
  final Issue issue;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _IssueScreenState();
}

class _IssueScreenState extends ConsumerState<IssueScreen> {
  // scroll controller
  final _scrollController = ScrollController();
  // isCloseToBottom
  bool _isNotAtTop = false;
  // selected linked issues
  final List<Issue> _selectedLinkedIssues = [];
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
    });
    // fetch all linked issued
    Future.delayed(
      Duration.zero,
      () async {
        for (final linkedIssueId in widget.issue.linkedIssueIds) {
          final linkedIssue = await ref
              .read(issueProvider(widget.issue.teamId).notifier)
              .fetchSingleIssueById(linkedIssueId);
          if (linkedIssue != null) {
            setState(() {
              _selectedLinkedIssues.add(linkedIssue);
            });
          }
        }
      },
    );
  }

  void _onTagToggle(String tag) {
    print('Tag toggled: $tag');
    final tags = ref
            .watch(issueProvider(widget.issue.teamId)
                .select((value) => value.issueMap[widget.issue.id]))
            ?.tags ??
        [];
    print('Tags in state in onTagToggle: $tags');
    if (tags.contains(tag)) {
      print('Removing tag from issue, tag: $tag');
      ref
          .read(issueProvider(widget.issue.teamId).notifier)
          .removeTagFromIssue(issueId: widget.issue.id, tag: tag);
    } else {
      print('Adding tag to issue, tag: $tag');
      ref
          .read(issueProvider(widget.issue.teamId).notifier)
          .addTagToIssue(issueId: widget.issue.id, tag: tag);
    }
  }

  void _updateLinkedIssue() {
    ref.read(issueProvider(widget.issue.teamId).notifier).updateLinkedIssueIds(
        issueId: widget.issue.id,
        linkedIssueIds: _selectedLinkedIssues.map((e) => e.id).toList());
  }

  void _showDeletionDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return ConfirmDialog(
          title: TranslationKeys.delete.tr(),
          content: TranslationKeys.confirmSomething.tr(
            args: [TranslationKeys.delete.tr()],
          ),
          onConfirm: () {
            ref
                .read(issueProvider(widget.issue.teamId).notifier)
                .removeIssue(widget.issue.id);
            Navigator.pop(context);
          },
          confirmText: TranslationKeys.delete.tr(),
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
    final username = ref.watch(authControllerProvider).user!.displayName!;
    // add to activity
    final message = !isClosed
        ? TranslationKeys.xHasOpenedIssueY.tr(args: [username, issueData.title])
        : TranslationKeys.xHasClosedIssueY
            .tr(args: [username, issueData.title]);
    await ref.read(activityProvider(widget.issue.teamId).notifier).addActivity(
          issueId: widget.issue.id,
          teamId: widget.issue.teamId,
          message: message,
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
    final issueData = ref.watch(issueProvider(widget.issue.teamId)
        .select((value) => value.issueMap[widget.issue.id]));
    print('Tags in issue screen: ${issueData?.tags}');
    if (issueData == null) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Center(
          child: Text(TranslationKeys.somethingNotFound.tr(
            args: [TranslationKeys.issues.tr()],
          )),
        ),
      );
    }
    final areYouTheOnwerOrAdmin = issueData
                .roles[ref.watch(authControllerProvider).user!.uid] ==
            'owner' ||
        issueData.roles[ref.watch(authControllerProvider).user!.uid] == 'admin';
    final isAuthor =
        issueData.roles[ref.watch(authControllerProvider).user!.uid] == 'owner';
    final isAuthorOrColloborator = isAuthor ||
        issueData.roles[ref.watch(authControllerProvider).user!.uid] ==
            'collaborator';
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.8,
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // is open
                      IsOpenChip(
                        isOpen: !issueData.isClosed,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: TitleText(
                          issueData.title,
                        ),
                      ),

                      const CloseButton(),
                    ],
                  ),
                  // last updated at information
                  Row(
                    children: [
                      Expanded(child: LastUpdatedAtInfo(issueData: issueData)),
                      if (isAuthorOrColloborator)
                        IconButton(
                            onPressed: () {
                              showModalBottomSheet(
                                isScrollControlled: true,
                                enableDrag: true,
                                showDragHandle: true,
                                context: context,
                                builder: (context) => AddOrEditIssueSheet(
                                  teamId: widget.issue.teamId,
                                  addOrEdit: AddorEdit.edit,
                                  issue: issueData,
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit)),
                      if (isAuthorOrColloborator)
                        // edit button
                        PopupMenuButton(
                          itemBuilder: (BuildContext context) => [
                            // to duplicate issue
                            PopupMenuItem(
                              child: ListTile(
                                leading: const Icon(Icons.copy),
                                title: Text(
                                    '${TranslationKeys.duplicate.tr()} ${TranslationKeys.issue.tr()}'),
                                onTap: () {
                                  showModalBottomSheet(
                                    isScrollControlled: true,
                                    enableDrag: true,
                                    showDragHandle: true,
                                    context: context,
                                    builder: (context) => AddOrEditIssueSheet(
                                      teamId: widget.issue.teamId,
                                      addOrEdit: AddorEdit.duplicate,
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
                                  title: Text(
                                      '${TranslationKeys.close.tr()} ${TranslationKeys.issue.tr()}'),
                                  onTap: () {
                                    _toggleIsClosed(
                                        isClosed: true, issueData: issueData);
                                  },
                                ),
                              ),
                            if (isAuthor)
                              PopupMenuItem(
                                child: ListTile(
                                  leading: const Icon(Icons.delete),
                                  title: Text(
                                      '${TranslationKeys.delete.tr()} ${TranslationKeys.issue.tr()}'),
                                  onTap: () {
                                    _showDeletionDialog();
                                  },
                                ),
                              ),
                          ],
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.more_horiz),
                          ),
                        ),
                    ],
                  ),
                  // deadline
                  if (issueData.deadline != null)
                    DeadlineInfo(issueData: issueData),
                  SelectableText(
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
                                    return TagsSelectionMenu(
                                      purpose: TagSelectionPurpose.editIssue,
                                      initialTags: issueData.tags,
                                      onSelected: _onTagToggle,
                                      teamId: widget.issue.teamId,
                                      title:
                                          '${TranslationKeys.edit.tr()} ${TranslationKeys.tags.tr()}',
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
                  //const Divider(),
                  //const TitleText('Files'),
                  const Divider(),
                  TitleText(
                    TranslationKeys.comments.tr(),
                  ),
                  Comments(issueId: issueData.id, teamId: widget.issue.teamId),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TitleText(TranslationKeys.linkedIssues.tr()),
                      TextButton.icon(
                        icon: const Icon(Icons.link),
                        onPressed: () {
                          // show linked issues
                          showModalBottomSheet(
                            isScrollControlled: true,
                            enableDrag: true,
                            showDragHandle: true,
                            context: context,
                            builder: (context) => SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: SingleChildScrollView(
                                child: Issues(
                                  hiddenIssueIds: [issueData.id],
                                  teamId: widget.issue.teamId,
                                  onSelected: (issue) {
                                    if (!_selectedLinkedIssues
                                        .contains(issue)) {
                                      setState(() {
                                        _selectedLinkedIssues.add(issue);
                                      });
                                    }
                                    _updateLinkedIssue();
                                    // pop
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        label: Text(
                          '${TranslationKeys.add.tr()} ${TranslationKeys.linkedIssues.tr()}',
                        ),
                      )
                    ],
                  ),
                  // show linked issues
                  if (_selectedLinkedIssues.isEmpty)
                    Column(
                      children: [
                        Center(
                          child: Text(
                            TranslationKeys.somethingNotFound.tr(
                              args: [TranslationKeys.linkedIssues.tr()],
                            ),
                          ),
                        ),
                        const Divider(),
                      ],
                    )
                  else
                    Wrap(
                      children: _selectedLinkedIssues
                          .map(
                            (issue) => IssueTile(
                                isDensed: true,
                                issueData: issue,
                                trailing: IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _selectedLinkedIssues.remove(issue);
                                    });
                                    _updateLinkedIssue();
                                  },
                                )),
                          )
                          .toList(),
                    ),

                  TitleText(
                    TranslationKeys.collaborators.tr(),
                  ),
                  // grey description
                  GreyDescription(
                    TranslationKeys.collaboratorDescription.tr(),
                  ),
                  Collaborators(
                      issueId: issueData.id, teamId: widget.issue.teamId),
                  const Divider(),

                  // created at information
                  GreyDescription(TranslationKeys.createdAtWhen.tr(
                    args: [
                      issueData.createdAt.toString().substring(0, 10),
                    ],
                  )),
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
          if (_isNotAtTop)
            // scroll to top floating button
            Positioned(
              bottom: 80,
              right: 16,
              child: FloatingActionButton(
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Icon(Icons.arrow_upward),
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
        isOpen ? TranslationKeys.open.tr() : TranslationKeys.closed.tr(),
        style: TextStyle(
          color: isOpen ? Colors.green : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
