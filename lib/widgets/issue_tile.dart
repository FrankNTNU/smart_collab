import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smart_collab/screens/issue_screen.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/widgets/deadline_info.dart';
import 'package:smart_collab/widgets/issue_tags.dart';
import 'package:smart_collab/widgets/issues.dart';
import 'package:smart_collab/widgets/last_updated.dart';
import 'package:smart_collab/widgets/user_avatar.dart';

class IssueTile extends StatelessWidget {
  final Issue issueData;
  final int tabIndex;
  final Function(Issue)? onSelected;
  final Widget? trailing;
  final bool isDensed;
  final bool isFullScreenWhenTapped;
  final Function()? onLongPressed;
  const IssueTile({
    super.key,
    required this.issueData,
    this.tabIndex = IssueTabEnum.open,
    this.onSelected,
    this.trailing,
    this.isDensed = false,
    this.isFullScreenWhenTapped = true,
    this.onLongPressed,
  });
  /// set to false since currently there is a bug that textfield can't be focused when the screen is full screen and pushed
  final isFullScreenEnabled = true;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          // add a grey light bottom border
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey,
                width: 0.5,
              ),
            ),
          ),
          child: ListTile(
            onLongPress: onLongPressed,
            contentPadding: isDensed ? const EdgeInsets.all(0) : null,
            leading: isDensed
                ? null
                : UserAvatar(
                    radius: 32,
                    uid: issueData.roles.entries
                            .where((entry) => entry.value == 'owner')
                            .firstOrNull
                            ?.key ??
                        ''),
            onTap: onSelected != null
                ? () {
                    onSelected!(issueData);
                  }
                : () {
                    if (kIsWeb) return;
                    if (isFullScreenWhenTapped && isFullScreenEnabled) {
                      // navigate to issue screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            
                            appBar: AppBar(
                              title: Tooltip(message: issueData.title, child: Text(issueData.title)),
                            ),
                            body: IssueScreen(
                              issue: issueData,
                              isFullScreen: true,
                            ),
                          ),
                        ),
                      );
                    } else {
                      // open bottom sheet
                      showModalBottomSheet(
                        isScrollControlled: true,
                        enableDrag: true,
                        showDragHandle: true,
                        context: context,
                        builder: (context) => Padding(
                          padding: MediaQuery.of(context).viewInsets,
                          child: IssueScreen(
                            issue: issueData,
                            // isFullScreen: false,
                            isFullScreen: isFullScreenEnabled,
                          ),
                        ),
                      );
                    }
                  },
            title: Text(issueData.title, // if closed tab then strike
                style: TextStyle(
                  decoration: tabIndex == IssueTabEnum.closed
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                )),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: IssueTags(
                    tags: issueData.tags,
                    teamId: issueData.teamId,
                  ),
                ),
                if (tabIndex == IssueTabEnum.open ||
                    tabIndex == IssueTabEnum.closed)
                  LastUpdatedAtInfo(
                    issueData: issueData,
                    isConcise: true,
                  ),
                if (tabIndex == IssueTabEnum.overdue ||
                    tabIndex == IssueTabEnum.upcoming)
                  DeadlineInfo(
                    issueData: issueData,
                    isConcise: true,
                  ),
              ],
            ),
            trailing: trailing ??
                (issueData.commentCount > 0
                    ? Column(
                        children: [
                          const Icon(Icons.chat_bubble_outline),
                          Text('${issueData.commentCount}'),
                        ],
                      )
                    : null),
          ),
        ),
      ],
    );
  }
}
