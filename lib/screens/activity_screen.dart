import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/activity_controller.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/utils/time_utils.dart';
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
  @override
  void initState() {
    super.initState();
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
        _openIssueScreen(activity);
        break;
      default:
        break;
    }
  }

  void _openIssueScreen(Activity activity) {
    final teamId = activity.activityDetails['teamId'];
    final issueId = activity.activityDetails['issueId'];
    print('teamId: $teamId, issueId: $issueId');
    final issue = ref.watch(
        issueProvider(teamId).select((value) => value.issueMap[issueId]));
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
    var activities = ref.watch(
        activityProvider(widget.teamId).select((value) => value.activities));
    return SizedBox(
      height: widget.isModal ? MediaQuery.of(context).size.height * 0.8 : null,
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (widget.isModal)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TitleText(TranslationKeys.activities.tr()),
                    const CloseButton(),
                  ],
                ),
              )
            else
              const SizedBox(
                height: 8,
              ),
            if (activities.isEmpty)
              SizedBox(
                height: 200,
                child: Center(
                  child: Text(TranslationKeys.somethingNotFound
                      .tr(args: [TranslationKeys.activities.tr()])),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return ListTile(
                    // if teamId is not provided then show team name
                    leading: UserAvatar(uid: activity.userId),
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
                        DateTime.parse(activity.timestamp),context: context)),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
