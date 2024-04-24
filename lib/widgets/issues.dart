import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/widgets/issue_tile.dart';
import 'package:smart_collab/widgets/tab_view_bar.dart';
import 'package:smart_collab/widgets/title_text.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../screens/tags_selection_menu.dart';
import '../services/auth_controller.dart';
import '../services/team_controller.dart';
import '../utils/translation_keys.dart';
import 'issue_tags.dart';

// tab enum
class IssueTabEnum {
  static const open = 0;
  static const upcoming = 1;
  // overdue
  static const overdue = 2;

  static const closed = 3;
}

// tab view enum
class IssueTabViewEnum {
  static const listView = 0;
  static const calendarView = 1;
}

class Issues extends ConsumerStatefulWidget {
  final String teamId;
  // a on selected callback for linked issues selection
  final Function(Issue)? onSelected;
  // hidden issue ids
  final List<String> hiddenIssueIds;
  // is tabs visible on changed
  final Function(bool)? isTabsVisibleOnChanged;
  final int currentTabIndex;
  // modal header
  final String? modalHeader;
  const Issues(
      {super.key,
      required this.teamId,
      this.onSelected,
      this.hiddenIssueIds = const [],
      this.isTabsVisibleOnChanged,
      this.currentTabIndex = 0,
      this.modalHeader});

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
  // is tabs visiblr
  bool _isTabsVisible = false;
  @override
  // did update widget
  void didUpdateWidget(covariant Issues oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTabIndex != widget.currentTabIndex) {
      print('Current tab index changed: ${widget.currentTabIndex}');
      setState(() {
        _currentTabIndex = widget.currentTabIndex;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // set current index
    _currentTabIndex = widget.currentTabIndex;
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
          return TagsSelectionMenu(
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
  Widget build(BuildContext context) {
    final isFetching = ref.watch(issueProvider(widget.teamId).select((value) =>
        value.apiStatus == ApiStatus.loading &&
        value.performedAction == PerformedAction.fetch));
    final sourceIssues = ref
        .watch(issueProvider(widget.teamId).select((value) => value.issueMap))
        .values
        .toList();
    print('Source issue length: ${sourceIssues.length}');
    print('Current filter tab index: $_currentTabIndex');
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
    if (widget.hiddenIssueIds.isNotEmpty) {
      filteredIssues = filteredIssues
          .where((issue) => !widget.hiddenIssueIds.contains(issue.id))
          .toList();
    }
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
        if (widget.modalHeader != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(child: TitleText(widget.modalHeader!)),
                const CloseButton(),
              ],
            ),
          ),
        // Row(
        //   children: [
        //     Expanded(
        //       child: Padding(
        //         padding: const EdgeInsets.all(8.0),
        //         child: TextField(
        //           controller: _searchController,
        //           onTapOutside: (event) {
        //             // unfocus
        //             FocusScope.of(context).unfocus();
        //           },
        //           onChanged: (value) {
        //             setState(() {
        //               _searchTerm = value;
        //             });
        //           },
        //           decoration: InputDecoration(
        //             hintText: TranslationKeys.searchSomething
        //                 .tr(args: [TranslationKeys.issues.tr()]),
        //             prefixIcon: const Icon(Icons.search),
        //             suffixIcon: _searchController.text.isNotEmpty
        //                 ? TextButton.icon(
        //                     label: Text(TranslationKeys.clear.tr()),
        //                     icon: const Icon(Icons.clear),
        //                     onPressed: () {
        //                       setState(() {
        //                         _searchController.clear();
        //                         _searchTerm = '';
        //                       });
        //                     },
        //                   )
        //                 : null,
        //           ),
        //         ),
        //       ),
        //     ),
        //     // add issue button
        //     TextButton.icon(
        //       label: Text(TranslationKeys.newIssue.tr()),
        //       icon: const Icon(Icons.add),
        //       onPressed: () {
        //         showModalBottomSheet(
        //           isScrollControlled: true,
        //           enableDrag: true,
        //           showDragHandle: true,
        //           context: context,
        //           builder: (context) => AddOrEditIssueSheet(
        //             teamId: widget.teamId,
        //             addOrEdit: AddorEdit.add,
        //           ),
        //         );
        //       },
        //     ),
        //   ],
        // ),
        // add issue button
        // a tab for issues
        VisibilityDetector(
          key: const Key('my-widget-key'),
          onVisibilityChanged: (visibilityInfo) {
            var visiblePercentage = visibilityInfo.visibleFraction * 100;
            debugPrint(
                'Widget ${visibilityInfo.key} is $visiblePercentage% visible');
            final isVisible = visiblePercentage > 0;
            if (_isTabsVisible != isVisible) {
              _isTabsVisible = isVisible;
              if (widget.isTabsVisibleOnChanged != null) {
                widget.isTabsVisibleOnChanged!(_isTabsVisible);
              }
            }
          },
          child: Tabs(
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
              Icons.check
            ],
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        // include tags for search
        InkWell(
          onTap: _openFilterTagsSelectionMenu,
          child: SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // search icon
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.search),
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
                onSelected: widget.onSelected,
              );
            },
          ),
        if (isFetching) const Center(child: CircularProgressIndicator()),
        const SizedBox(
          height: 64,
        )
      ],
    );
  }
}
