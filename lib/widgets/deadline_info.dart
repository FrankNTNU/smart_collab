import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/issue_controller.dart';

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
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                    'Deadline: ${issueData.deadline.toString().substring(0, 10)}',
                    style: const TextStyle(),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                ],
              ),
            if (isToday || isTomorrow || isOverdue || daysLeft < 7)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isToday
                      ? 'Today'
                      : isTomorrow
                          ? 'Tomorrow'
                          : isOverdue
                              ? 'Overdue'
                              : 'In $daysLeft days',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (daysLeft >= 7)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                    'In ${issueData.deadline!.difference(DateTime.now()).inDays} days', // red
                    style: const TextStyle(
                      color: Colors.green,
                      // bold
                      fontWeight: FontWeight.bold,
                    )),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                    'In ${issueData.deadline!.difference(DateTime.now()).inDays} days', // red
                    style: const TextStyle(
                      color: Colors.grey,
                      // bold
                      fontWeight: FontWeight.bold,
                    )),
              ),
          ],
        ),
      ),
    );
  }
}
