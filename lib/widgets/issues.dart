import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/widgets/add_or_edit_team_sheet.dart';
import 'package:smart_collab/widgets/issue_tile.dart';
import 'package:smart_collab/widgets/tab_view_bar.dart';

import '../screens/filter_tags_selection_menu.dart';
import '../utils/translation_keys.dart';
import 'add_or_edit_issue_sheet.dart';
import 'issue_tags.dart';

// tab enum
class IssueTabEnum {
  static const open = 0;
  // overdue
  static const overdue = 1;
  static const upcoming = 2;
  static const closed = 3;
}

// tab view enum
class IssueTabViewEnum {
  static const listView = 0;
  static const calendarView = 1;
}

class Issues extends ConsumerStatefulWidget {
  final String teamId;
  const Issues({super.key, required this.teamId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _IssuesState();
}

class _IssuesState extends ConsumerState<Issues> {
  // searchTerm
  String _searchTerm = '';
  // include tags
  final List<String> _includedFilterTags = [];
  // search text edit controller
  final TextEditingController _searchController = TextEditingController();
  // current tab index
  int _currentTabIndex = IssueTabEnum.open;
  // view tab index
  final int _currentTabViewIndex = IssueTabViewEnum.listView;
  // search tags on selected
  void _searchTagsOnSelected(String tag) {
    setState(() {
      if (_includedFilterTags.contains(tag)) {
        _includedFilterTags.remove(tag);
      } else {
        _includedFilterTags.add(tag);
      }
    });
  }

  void _openFilterTagsSelectionMenu() async {
    await showModalBottomSheet(
        isScrollControlled: true,
        enableDrag: true,
        showDragHandle: true,
        context: context,
        builder: (context) {
          return FilterTagsSelectionMenu(
            purpose: TagSelectionPurpose.filterSearch,
            initialTags: _includedFilterTags,
            onSelected: _searchTagsOnSelected,
            teamId: widget.teamId,
          );
        });
    print('Filter tags selected: $_includedFilterTags');
    ref
        .read(issueProvider(widget.teamId).notifier)
        .fetchIssues(widget.teamId, includedTags: _includedFilterTags);
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration.zero,
      () {
        // empty the error message
        ref
            .read(issueProvider(widget.teamId).notifier)
            .fetchIssues(widget.teamId);
      },
    );
    // listen to search controller changes
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final sourceIssues = ref
        .watch(issueProvider(widget.teamId).select((value) => value.issueMap))
        .values
        .toList();
    print('Source issue length: ${sourceIssues.length}');
    var filteredIssues = sourceIssues.where((issue) {
      return (issue.title.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          issue.description
              .toLowerCase()
              .contains(_searchTerm.toLowerCase()) || // tags include names
          issue.tags.any(
            (tag) => tag.toLowerCase().contains(
                  _searchTerm.toLowerCase(),
                ),
          ));
    }).toList();
    filteredIssues = _includedFilterTags.isEmpty
        ? filteredIssues
        : filteredIssues.where((issue) {
            return issue.tags.any(
              (tag) => _includedFilterTags.contains(tag),
            );
          }).toList();
    // if upcoming tab is selected, then filter issues
    filteredIssues = _currentTabIndex == IssueTabEnum.upcoming
        ? filteredIssues
            .where((issue) =>
                issue.deadline != null &&
                issue.deadline!.isAfter(DateTime.now()))
            .toList()
        : filteredIssues;
    // if overdue tab is selected, then filter issues
    filteredIssues = _currentTabIndex == IssueTabEnum.overdue
        ? filteredIssues
            .where((issue) =>
                issue.deadline != null &&
                issue.deadline!.isBefore(DateTime.now()))
            .toList()
        : filteredIssues;
    // if first tab (open) is selected, then filter issues, if third tab (closed) is selected, then filter issues
    filteredIssues = filteredIssues
        .where((issue) => _currentTabIndex == IssueTabEnum.closed
            ? issue.isClosed
            : !issue.isClosed)
        .toList();
    if (_currentTabIndex == IssueTabEnum.upcoming) {
      // sort by deadline with upcoming first
      filteredIssues.sort((a, b) => a.deadline!.compareTo(b.deadline!));
    } else {
      // sort by updated at
      filteredIssues.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  onTapOutside: (event) {
                    // unfocus
                    FocusScope.of(context).unfocus();
                  },
                  onChanged: (value) {
                    setState(() {
                      _searchTerm = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: TranslationKeys.searchSomething
                        .tr(args: [TranslationKeys.issues.tr()]),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? TextButton.icon(
                            label: Text(TranslationKeys.clear.tr()),
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchTerm = '';
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),
            // add issue button
            TextButton.icon(
              label: Text(TranslationKeys.newIssue.tr()),
              icon: const Icon(Icons.add),
              onPressed: () {
                showModalBottomSheet(
                  isScrollControlled: true,
                  enableDrag: true,
                  showDragHandle: true,
                  context: context,
                  builder: (context) => AddOrEditIssueSheet(
                    teamId: widget.teamId,
                    addOrEdit: AddorEdit.add,
                  ),
                );
              },
            ),
          ],
        ),
        // include tags for search
        InkWell(
          onTap: _openFilterTagsSelectionMenu,
          child: SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                const SizedBox(
                  width: 8,
                ),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${TranslationKeys.includedTags.tr()}:')),
                const SizedBox(
                  width: 4,
                ),
                IssueTags(tags: _includedFilterTags, teamId: widget.teamId),
                const SizedBox(
                  width: 8,
                )
              ],
            ),
          ),
        ),
        const Divider(),
        const SizedBox(
          height: 8,
        ),
        // a tab for issues
        Tabs(
          initialTabIndex: _currentTabIndex,
          onTabChange: (index) {
            setState(() {
              _currentTabIndex = index;
            });
          },
          tabs: [
            TranslationKeys.openIssues.tr(),
            TranslationKeys.upcoming.tr(),
            TranslationKeys.overdue.tr(),
            TranslationKeys.closedIssues.tr(),
          ],
          icons: const [
            Icons.content_paste,
            Icons.hourglass_top_rounded,
            Icons.event_busy,
            Icons.do_not_disturb_on
          ],
        ),
        if (filteredIssues.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(TranslationKeys.somethingNotFound
                  .tr(args: [TranslationKeys.issues.tr()])),
            ),
          )
        else
          ListView.builder(
            // never scroll
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: filteredIssues.length,
            itemBuilder: (context, index) {
              return IssueTile(
                issueData: filteredIssues[index],
                tabIndex: _currentTabIndex,
              );
            },
          ),
        const SizedBox(
          height: 64,
        )
      ],
    );
  }
}
