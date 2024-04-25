import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/issue_controller.dart';

import '../utils/translation_keys.dart';

class DeadlineInfo extends ConsumerStatefulWidget {
  final Issue issueData;
  final bool isConcise;
  const DeadlineInfo(
      {super.key, required this.issueData, this.isConcise = false});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DeadlineInfoState();
}

class _DeadlineInfoState extends ConsumerState<DeadlineInfo> {
  @override
  Widget build(BuildContext context) {
    final issueData = widget.issueData;

    final daysLeft = issueData.deadline!.difference(DateTime.now()).inDays;
    final isToday = issueData.deadline!.year == DateTime.now().year &&
        issueData.deadline!.month == DateTime.now().month &&
        issueData.deadline!.day == DateTime.now().day;
    final isOverdue = issueData.deadline!.isBefore(DateTime.now()) && !isToday;

    final isTomorrow = daysLeft < 1;

    return InkWell(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Wrap(
          children: [
            if (!widget.isConcise)
              Wrap(
                children: [
                  // calendar icon
                  const Icon(
                    Icons.event,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${TranslationKeys.deadline.tr()} ${issueData.deadline.toString().substring(0, 10)}',
                    style: const TextStyle(),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                ],
              ),
            if (isToday)
              FuzzyDeadlineChip(
                color: Colors.red,
                text: TranslationKeys.today.tr(),
              )
            else if (isOverdue)
              FuzzyDeadlineChip(
                color: Colors.red,
                text:
                    '${TranslationKeys.overdue.tr()} ${daysLeft.abs()} ${TranslationKeys.days.tr()}',
              )
            else if (isTomorrow)
              FuzzyDeadlineChip(
                color: Colors.orangeAccent,
                text: TranslationKeys.tomorrow.tr(),
              )
            else if (daysLeft >= 7)
              FuzzyDeadlineChip(
                color: Colors.green,
                text: TranslationKeys.inXDays.tr(args: [
                  issueData.deadline!
                      .difference(DateTime.now())
                      .inDays
                      .toString()
                ]), // r
              )
            else
              FuzzyDeadlineChip(
                color: Colors.orangeAccent,
                text: TranslationKeys.inXDays.tr(args: [
                  issueData.deadline!
                      .difference(DateTime.now())
                      .inDays
                      .toString()
                ]), //
              ),
          ],
        ),
      ),
    );
  }
}

class FuzzyDeadlineChip extends StatelessWidget {
  const FuzzyDeadlineChip({super.key, required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
