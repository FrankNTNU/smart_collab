import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/utils/time_utils.dart';
import 'package:smart_collab/utils/translation_keys.dart';
import 'package:smart_collab/widgets/issues.dart';
import 'package:smart_collab/widgets/title_text.dart';
import 'package:table_calendar/table_calendar.dart';

import '../widgets/issue_tile.dart';

class CalendarViewScreen extends ConsumerStatefulWidget {
  final String teamId;
  const CalendarViewScreen({super.key, required this.teamId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CalendarViewScreenState();
}

class _CalendarViewScreenState extends ConsumerState<CalendarViewScreen> {
  // currently selected month and year
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  // focused day
  DateTime _focusedDay = DateTime.now();
  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration.zero,
      () {
        ref.read(issueProvider(widget.teamId).notifier).fetchIssuesByMonth(
              year: _selectedYear,
              month: _selectedMonth,
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final issues = ref.watch(issueProvider(widget.teamId)
        .select((value) => value.issueMap.values.toList()));
    // two years from now
    final twoYearsFromNow = DateTime.now().add(const Duration(days: 365 * 2));
    final twoYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 2));
    return TableCalendar(
      daysOfWeekHeight: 32,
      locale: TimeUtils.getLocale(context),
      onPageChanged: (focusedDay) {
        setState(() {
          _selectedMonth = focusedDay.month;
          _selectedYear = focusedDay.year;
          _focusedDay = focusedDay;
        });
        ref.read(issueProvider(widget.teamId).notifier).fetchIssuesByMonth(
              year: _selectedYear,
              month: _selectedMonth,
            );
      },
      firstDay: twoYearsAgo,
      lastDay: twoYearsFromNow,
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
      // dont allow change format
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
      },
      availableGestures: AvailableGestures.horizontalSwipe,
      rowHeight: MediaQuery.of(context).size.height / 8,
      calendarStyle: const CalendarStyle(outsideDaysVisible: false),
      calendarBuilders: CalendarBuilders(
        headerTitleBuilder: (context, day) {
          // issue count this month
          final openIssueCount = issues
              .where((issue) {
                return issue.deadline != null &&
                    issue.deadline!.month == day.month &&
                    issue.deadline!.year == day.year &&
                    !issue.isClosed;
              })
              .toList()
              .length;
          // closed issue count
          final closedIssueCount = issues
              .where((issue) {
                return issue.deadline != null &&
                    issue.deadline!.month == day.month &&
                    issue.deadline!.year == day.year &&
                    issue.isClosed;
              })
              .toList()
              .length;
          return Wrap(
            children: [
              TitleText(
                '${day.year}/${day.month}',
              ),
              const SizedBox(
                width: 8,
              ),
              // show the number of issues this month
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: openIssueCount == 0
                      ? Colors.grey.shade300
                      : Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$openIssueCount ${TranslationKeys.open.tr()}',
                  style: const TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              // show the number of closed issues this month
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: closedIssueCount == 0
                      ? Colors.grey.shade300
                      : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$closedIssueCount ${TranslationKeys.closed.tr()}',
                  style: const TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          );
        },
        defaultBuilder: (context, day, focusedDay) {
          final dayIssues = issues.where((issue) {
            return issue.deadline != null &&
                issue.deadline!.day == day.day &&
                issue.deadline!.month == day.month &&
                issue.deadline!.year == day.year;
          }).toList();
          return IssueCalendarCell(dayIssues: dayIssues, dateTime: day);
        },
        todayBuilder: (context, day, focusedDay) {
          final todayIssues = issues.where((issue) {
            return issue.deadline != null &&
                issue.deadline!.day == day.day &&
                issue.deadline!.month == day.month &&
                issue.deadline!.year == day.year;
          }).toList();
          return IssueCalendarCell(dayIssues: todayIssues, dateTime: day);
        },
      ),
    );
  }
}

class IssueCalendarCell extends StatelessWidget {
  const IssueCalendarCell(
      {super.key, required this.dayIssues, required this.dateTime});

  final List<Issue> dayIssues;
  final DateTime dateTime;

  @override
  Widget build(BuildContext context) {
    final isToday = dateTime.year == DateTime.now().year &&
        dateTime.month == DateTime.now().month &&
        dateTime.day == DateTime.now().day;
    return InkWell(
      onTap: dayIssues.isEmpty
          ? null
          : () {
              // open bottom sheet
              showModalBottomSheet(
                isScrollControlled: true,
                enableDrag: true,
                showDragHandle: true,
                context: context,
                builder: (context) => SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 16),
                            TitleText(TranslationKeys.xIssuesOnY.tr(args: [
                              dayIssues.length.toString(),
                              dateTime.toString().substring(0, 10)
                            ])),
                            const Spacer(),
                            const CloseButton(),
                          ],
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: dayIssues.length,
                            itemBuilder: (context, index) {
                              return IssueTile(
                                issueData: dayIssues[index],
                                tabIndex: IssueTabEnum.open,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            dateTime.day.toString(), // if it is today then red
            style: TextStyle(
              color: isToday ? Colors.red : null,
              // today then bold
              fontWeight: isToday ? FontWeight.bold : null,
              
            ),
          ),
          // show a badge
          if (dayIssues.isNotEmpty)
            Row(
              children: [
                CircleBadge(
                  count: dayIssues.where((issue) => !issue.isClosed).length,
                  color: Colors.amber.shade300,
                ),
                CircleBadge(
                  count: dayIssues.where((issue) => issue.isClosed).length,
                  color: Colors.green.shade200,
                ),
              ],
            ),
          if (dayIssues.isNotEmpty)
            Expanded(
              child: Text(
                dayIssues.first.title,
                //oneline
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
        ],
      ),
    );
  }
}

class CircleBadge extends StatelessWidget {
  const CircleBadge({
    super.key,
    required this.count,
    required this.color,
  });

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const SizedBox();
    }
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
