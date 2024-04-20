import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/widgets/add_or_edit_team_sheet.dart';
import 'package:smart_collab/widgets/issue_tabs.dart';
import 'package:smart_collab/widgets/issue_tile.dart';

import '../screens/filter_tags_selection_menu.dart';
import 'add_or_edit_issue_sheet.dart';
import 'issue_tags.dart';
import 'title_text.dart';

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
  int _currentTabIndex = 0;
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
    var filteredIssues = ref
        .watch(issueProvider(widget.teamId).select((value) => value.issues))
        .where((issue) {
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
    filteredIssues = _currentTabIndex == 1
        ? filteredIssues
            .where((issue) =>
                issue.deadline != null &&
                issue.deadline!.isAfter(DateTime.now()))
            .toList()
        : filteredIssues;

    // if first tab (open) is selected, then filter issues, if third tab (closed) is selected, then filter issues
    filteredIssues = filteredIssues
        .where(
            (issue) => _currentTabIndex == 2 ? issue.isClosed : !issue.isClosed)
        .toList();
    if (_currentTabIndex == 1) {
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
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: TitleText('Issues'),
            ),
            const Spacer(),
            // add issue button
            TextButton.icon(
              label: const Text('New issue'),
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
        // search bar
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
                    hintText: 'Search issues',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? TextButton.icon(
                            label: const Text('Clear'),
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
            IconButton(
                onPressed: () {
                  _openFilterTagsSelectionMenu();
                },
                icon: const Icon(Icons.filter_list)),
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
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Included tags:')),
                const SizedBox(
                  width: 4,
                ),
                IssueTags(tags: _includedFilterTags, teamId: widget.teamId),
                const SizedBox(
                  width: 4,
                ),
                const Icon(Icons.add),
                const SizedBox(
                  width: 8,
                )
              ],
            ),
          ),
        ),

        const Divider(),
        // a tab for issues
        IssueTabs(onTabChange: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        }),
        if (filteredIssues.isEmpty)
          const Center(
            child: Text('No issues found'),
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
          height: 32,
        )
      ],
    );
  }
}
