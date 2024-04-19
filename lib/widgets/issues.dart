import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/screens/issue_screen.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/widgets/add_or_edit_team_sheet.dart';
import 'package:smart_collab/widgets/last_updated.dart';
import 'package:smart_collab/widgets/user_avatar.dart';

import 'add_or_edit_issue_sheet.dart';
import 'issue_tags.dart';

class Issues extends ConsumerStatefulWidget {
  final String teamId;
  const Issues({super.key, required this.teamId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _IssuesState();
}

class _IssuesState extends ConsumerState<Issues> {
  // searchTerm
  String _searchTerm = '';
  // search text edit controller
  final TextEditingController _searchController = TextEditingController();
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
    final issues = ref
        .watch(issueProvider(widget.teamId).select((value) => value.issues))
        .where((issue) {
      return issue.title.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          issue.description
              .toLowerCase()
              .contains(_searchTerm.toLowerCase()) || // tags include names
          issue.tags.any(
              (tag) => tag.toLowerCase().contains(_searchTerm.toLowerCase()));
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Issues',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            
            ),
            const Spacer(),
            // add issue button
            TextButton.icon(
              label: const Text('Add issue'),
              icon: const Icon(Icons.add),
              onPressed: () {
                showModalBottomSheet(
                  isScrollControlled: true,
                  enableDrag: true,
                  showDragHandle: true,
                  context: context,
                  builder: (context) => Padding(
                    padding: MediaQuery.of(context).viewInsets,
                    child: AddOrEditIssueSheet(
                      teamId: widget.teamId,
                      addOrEdit: AddorEdit.add,

                    ),
                  ),
                );
              },
            ),
          ],
        ),

        // search bar
        Padding(
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
            decoration:  InputDecoration(
              hintText: 'Search issues',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? TextButton.icon(
                    label: const Text('Clear search'),
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
        if (issues.isEmpty)
          const Center(
            child: Text('No issues found'),
          )
        else
          ListView.builder(
            // never scroll
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(), itemCount: issues.length,
            itemBuilder: (context, index) {
              return Column(
                children: [
                  ListTile(
                    leading: UserAvatar(
                        uid: issues[index].lastUpdatedBy ??
                            issues[index]
                                .roles
                                .entries
                                .where((entry) => entry.value == 'owner')
                                .firstOrNull
                                ?.key ??
                            ''),
                    onTap: () {
                      // open bottom sheet
                      showModalBottomSheet(
                        isScrollControlled: true,
                        enableDrag: true,
                        showDragHandle: true,
                        context: context,
                        builder: (context) => Padding(
                          padding: MediaQuery.of(context).viewInsets,
                          child: IssueScreen(
                            issue: issues[index],
                          ),
                        ),
                      );
                    },
                    title: Text(issues[index].title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IssueTags(
                          tags: issues[index].tags,
                          teamId: widget.teamId,
                        ),
                        LastUpdatedAtInfo(
                          issueData: issues[index],
                          isConcise: true,
                        )
                      ],
                    ),
                  ),
                  //const Divider(),
                ],
              );
            },
          ),
      ],
    );
  }
}
