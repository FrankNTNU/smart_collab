import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/screens/issue_screen.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/widgets/last_updated.dart';
import 'package:smart_collab/widgets/user_avatar.dart';

class Issues extends ConsumerStatefulWidget {
  final String teamId;
  const Issues({super.key, required this.teamId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _IssuesState();
}

class _IssuesState extends ConsumerState<Issues> {
  // searchTerm
  String _searchTerm = '';
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
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Issues',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

        // search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onTapOutside: (event) {
                // unfocus
                FocusScope.of(context).unfocus();
              },
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search issues',
                prefixIcon: Icon(Icons.search),
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
                        Text(
                          issues[index].description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        LastUpdatedAtInfo(
                          issueData: issues[index],
                          isConcise: true,
                        )
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}
