import 'package:easy_localization/easy_localization.dart';
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
  const IssueTile(
      {super.key,
      required this.issueData,
      this.tabIndex = IssueTabEnum.open,
      this.onSelected,
      this.trailing, this.isDensed = false});

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
            contentPadding: isDensed
                ? const EdgeInsets.all(0)
                : null,
            leading: isDensed ? null : UserAvatar(
                uid: issueData.lastUpdatedBy ??
                    issueData.roles.entries
                        .where((entry) => entry.value == 'owner')
                        .firstOrNull
                        ?.key ??
                    ''),
            onTap: onSelected != null
                ? () {
                    onSelected!(issueData);
                  }
                : () {
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
                        ),
                      ),
                    );
                  },
            title: Text(issueData.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IssueTags(
                  tags: issueData.tags,
                  teamId: issueData.teamId,
                ),
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
                if (tabIndex == IssueTabEnum.closed)
                  const IsOpenChip(
                    isOpen: false,
                  )
              ],
            ),
            trailing: trailing,
          ),
        ),
      ],
    );
  }
}
