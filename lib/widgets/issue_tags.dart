import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../utils/translation_keys.dart';
import 'issue_tag_chip.dart';

class IssueTags extends StatelessWidget {
  // list of tags
  final List<String> tags;
  final String teamId;
  final bool isLoose;
  final bool isEditable;
  final bool isShowUsedCount;
  const IssueTags(
      {super.key,
      required this.tags,
      required this.teamId,
      this.isLoose = false,
      this.isEditable = false,
      this.isShowUsedCount = false});

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
                isShowUsedCount: isShowUsedCount,
              ),
            ),
        if (isEditable && tags.isEmpty)
          // add tag chip
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.add),
                Text(TranslationKeys.addTag.tr()),
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
