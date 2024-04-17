import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/screens/issue_screen.dart';
import 'package:smart_collab/services/issue_controller.dart';

class Issues extends ConsumerStatefulWidget {
  final String teamId;
  const Issues({super.key, required this.teamId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _IssuesState();
}

class _IssuesState extends ConsumerState<Issues> {
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
    final issues =
        ref.watch(issueProvider(widget.teamId).select((value) => value.issues));
    if (issues.isEmpty) {
      return const Center(
        child: Text('No issues found'),
      );
    }
    return ListView.builder(
      itemCount: issues.length,
      itemBuilder: (context, index) {
        return ListTile(
          onTap: () {
            // open bottom sheet
            showModalBottomSheet(
              isScrollControlled: true,
              enableDrag: true,
              showDragHandle: true,
              context: context,
              builder: (context) => Padding(
                padding: MediaQuery.of(context)
                    .viewInsets
                    .copyWith(left: 16, right: 16),
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
              Wrap(
                spacing: 8,
                children: [
                  ...issues[index].tags.map((tag) => Chip(
                        label: Text(tag),
                      ))
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
