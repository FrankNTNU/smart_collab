import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/utils/time_utils.dart';
import 'package:smart_collab/utils/translation_keys.dart';
import 'package:smart_collab/widgets/issues.dart';
import 'package:smart_collab/widgets/title_text.dart';
import 'package:table_calendar/table_calendar.dart';

import '../widgets/add_or_edit_issue_sheet.dart';
import '../widgets/add_or_edit_team_sheet.dart';
import '../widgets/issue_tile.dart';
import 'issue_screen.dart';

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
    return Column(
      children: [
        TableCalendar(
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
          rowHeight: MediaQuery.of(context).size.height / 7.5,
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: true,
            tableBorder: TableBorder(
              bottom: BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
          calendarBuilders: CalendarBuilders(
            outsideBuilder: (context, day, focusedDay) => IssueCalendarCell(
              dayIssues: const [],
              dateTime: day,
              teamId: widget.teamId,
            ),
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
                    width: 4,
                  ),
                  // show the number of issues this month
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
              return IssueCalendarCell(
                  dayIssues: dayIssues, dateTime: day, teamId: widget.teamId);
            },
            todayBuilder: (context, day, focusedDay) {
              final todayIssues = issues.where((issue) {
                return issue.deadline != null &&
                    issue.deadline!.day == day.day &&
                    issue.deadline!.month == day.month &&
                    issue.deadline!.year == day.year;
              }).toList();
              return IssueCalendarCell(
                  dayIssues: todayIssues, dateTime: day, teamId: widget.teamId);
            },
          ),
        ),
        const SizedBox(
          height: 64,
        ),
      ],
    );
  }
}

class IssueCalendarCell extends StatelessWidget {
  const IssueCalendarCell(
      {super.key,
      required this.dayIssues,
      required this.dateTime,
      required this.teamId});

  final List<Issue> dayIssues;
  final DateTime dateTime;
  final String teamId;

  /// set to false until the textfield focus has been fixed (cant't be focused after a new page being pushed)
  final isFullScreenEnabled = false;
  void _openAddIssueSheetOnDay(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: true,
      context: context,
      builder: (context) => AddOrEditIssueSheet(
        teamId: teamId,
        defaultDeadline: dateTime,
        addOrEdit: AddorEdit.add,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isToday = dateTime.year == DateTime.now().year &&
        dateTime.month == DateTime.now().month &&
        dateTime.day == DateTime.now().day;
    return InkWell(
      onTap: dayIssues.isEmpty
          ? () {
              // show bottom sheet
              showModalBottomSheet(
                context: context,
                builder: (context) => ListTile(
                    leading: const Icon(Icons.add),
                    title: Text(
                        'Create an issue on ${dateTime.toString().substring(0, 10)}'),
                    onTap: () {
                      _openAddIssueSheetOnDay(context);
                    }),
              );
            }
          : () {
              // if there is only one issue then open it directly
              if (dayIssues.length == 1 && isFullScreenEnabled) {
                final issue = dayIssues.first;
                // open bottom sheet
                // navigate to issue screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        title: Text(issue.title),
                      ),
                      body: IssueScreen(
                        issue: issue,
                        isFullScreen: true,
                      ),
                    ),
                  ),
                );
                return;
              }
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
                                isFullScreenWhenTapped: true,
                                issueData: dayIssues[index],
                                tabIndex: IssueTabEnum.open,
                              );
                            },
                          ),
                        ),
                        ListTile(
                            leading: const Icon(Icons.add),
                            title: Text(
                                'Create an issue on ${dateTime.toString().substring(0, 10)}'),
                            onTap: () {
                              _openAddIssueSheetOnDay(context);
                            }),
                      ],
                    ),
                  ),
                ),
              );
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        //color: Colors.blue.shade100,
        // border
        decoration: const BoxDecoration(
          border: // left grey border
              Border(
            left: BorderSide(
              color: Colors.grey,
              width: 0.25,
            ),
            right: BorderSide(
              color: Colors.grey,
              width: 0.25,
            ),
            // top grey border
            top: BorderSide(
              color: Colors.grey,
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // date
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dateTime.day.toString(), // if it is today then red
                  style: TextStyle(
                    color: isToday ? Colors.red : null,
                    // today then bold
                    fontWeight: isToday ? FontWeight.bold : null,
                  ),
                ),
              ],
            ),
            // show a badge for open and closed issues
            if (dayIssues.isNotEmpty)
              LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleBadge(
                        count:
                            dayIssues.where((issue) => !issue.isClosed).length,
                        color: Colors.amber.shade300,
                        maxWidth: constraints.maxWidth / 2,
                      ),
                      CircleBadge(
                        count:
                            dayIssues.where((issue) => issue.isClosed).length,
                        color: Colors.green.shade200,
                        maxWidth: constraints.maxWidth / 2,
                      ),
                    ],
                  );
                },
              ),
            // show the first issue title
            if (dayIssues.isNotEmpty)
              Expanded(
                child: Text(
                  dayIssues.first.title,
                  //oneline
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  // small
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CircleBadge extends StatelessWidget {
  const CircleBadge({
    super.key,
    required this.count,
    required this.color,
    required this.maxWidth,
  });

  final int count;
  final Color color;
  final double maxWidth;
  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox();
    return Container(
      width: maxWidth - 4,
      //width: constraints.minWidth / 2,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        // rounded border
        borderRadius: BorderRadius.circular(4),
        //shape: BoxShape.circle,
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
    );
  }
}
