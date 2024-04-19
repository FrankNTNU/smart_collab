import 'package:flutter/material.dart';

import 'issue_tag_chip.dart';

class IssueTags extends StatelessWidget {
  // list of tags
  final List<String> tags;
  final String teamId;
  final bool isLoose;
  final bool isEditable;
  const IssueTags(
      {super.key,
      required this.tags,
      required this.teamId,
      this.isLoose = false,
      this.isEditable = false});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...tags.toSet().map(
              (tag) => IssueTagChip(
                tagName: tag,
                teamId: teamId,
                isLoose: isLoose,
              ),
            ),
        if (isEditable && tags.isEmpty)
          // add tag chip
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.add),
                Text('Add tag'),
              ],  
            ),
          ),
        if (isEditable && tags.isNotEmpty)
          // add icon
          const Icon(Icons.add),
      ],
    );
  }
}
