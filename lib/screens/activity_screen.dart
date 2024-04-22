import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/activity_controller.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/utils/time_utils.dart';
import 'package:smart_collab/widgets/grey_description.dart';
import 'package:smart_collab/widgets/user_avatar.dart';

import '../utils/translation_keys.dart';
import '../widgets/title_text.dart';
import 'issue_screen.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  final String teamId;
  final bool isModal;
  const ActivityScreen({super.key, required this.teamId, this.isModal = true});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  // isAtTop
  bool _isAtTop = false;
  // scroll controller
  final _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    // add listener
    _scrollController.addListener(() {
      final isAtTop = _scrollController.position.pixels == 0;
      if (isAtTop != _isAtTop) {
        setState(() {
          _isAtTop = isAtTop;
        });
      }
    });
  }

  void _activityOnTapped(Activity activity) async {
    // set as read
    await ref
        .read(activityProvider(widget.teamId).notifier)
        .setAsRead(activity.id);
    print('Activity type: ${activity.activityType}');

    switch (activityMapReverse[activity.activityType]) {
      case ActivityType.addComment:
      case ActivityType.openIssue:
      case ActivityType.closeIssue:
      case ActivityType.createIssue:
      case ActivityType.updateIssue:
      case ActivityType.setAsCollaborator:
        _openIssueScreen(activity);
        break;
      default:
        break;
    }
  }

  void _openIssueScreen(Activity activity) async {
    final teamId = activity.activityDetails['teamId'];
    final issueId = activity.activityDetails['issueId'];
    print('teamId: $teamId, issueId: $issueId');
    final issue = await ref
        .read(issueProvider(teamId).notifier)
        .fetchSingleIssueById(issueId);
    if (issue == null) {
      print('Issue not found');
      return;
    }
    // open bottom sheet
    showModalBottomSheet(
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: true,
      context: context,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: IssueScreen(
          issue: issue,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.isModal ? MediaQuery.of(context).size.height * 0.8 : null,
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                if (widget.isModal)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                            child: TitleText(TranslationKeys.activities.tr())),
                        // pop up menu button showing mark all as read and delete
                        PopupMenuButton(
                          itemBuilder: (context) {
                            return [
                              const PopupMenuItem(
                                value: 'markAllAsRead',
                                child: Text('Mark all as read'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ];
                          },
                          onSelected: (value) {
                            print('Selected: $value');
                            if (value == 'markAllAsRead') {
                              ref
                                  .read(activityProvider(widget.teamId).notifier)
                                  .markAllAsRead();
                            }
                          },
                        ),

                        const CloseButton(),
                      ],
                    ),
                  )
                else
                  const SizedBox(
                    height: 8,
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: GreyDescription(
                          'Only the last 100 activities are shown')),
                ),
                ref.watch(activityStreamProvider(widget.teamId)).when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, stackTrace) => Center(
                        child: Text('Error: $error'),
                      ),
                      data: (_) {
                        final activities = ref.watch(
                            activityProvider(widget.teamId)
                                .select((value) => value.activities));
                        if (activities.isEmpty) {
                          return SizedBox(
                            height: 200,
                            child: Center(
                              child: Text(TranslationKeys.somethingNotFound
                                  .tr(args: [TranslationKeys.activities.tr()])),
                            ),
                          );
                        } else {
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: activities.length,
                            itemBuilder: (context, index) {
                              final activity = activities[index];
                              return ListTile(
                                // if teamId is not provided then show team name
                                leading: UserAvatar(
                                  uid: activity.userId,
                                  radius: 32,
                                ),
                                trailing: // show a small red dot if it is unread,
                                    activity.read
                                        ? null
                                        : const CircleAvatar(
                                            radius: 5,
                                            backgroundColor: Colors.red,
                                          ),
                                onTap: () {
                                  _activityOnTapped(activity);
                                },
                                title: Text(activity.message),
                                subtitle: Text(TimeUtils.getFuzzyTime(
                                    DateTime.parse(activity.timestamp),
                                    context: context)),
                              );
                            },
                          );
                        }
                      },
                    ),
              ],
            ),
          ),
          // floating button scroll to top
          if (!_isAtTop)
            Positioned(
              bottom: 16,
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
