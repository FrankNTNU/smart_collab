import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/services/tag_controller.dart';
import 'package:smart_collab/widgets/issue_tags.dart';
import 'package:smart_collab/widgets/title_text.dart';

import '../utils/translation_keys.dart';

class StatsInfo extends ConsumerStatefulWidget {
  final String teamId;
  const StatsInfo({super.key, required this.teamId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _StatsInfoState();
}

class _StatsInfoState extends ConsumerState<StatsInfo> {
  int _count = 0;
  int displayCount = 10;
  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration.zero,
      () {
        ref
            .read(issueProvider(widget.teamId).notifier)
            .fetchIssueStats()
            .then((value) {
          setState(() {
            _count = value;
          });
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var tags = ref
        .watch(tagProvider(widget.teamId).select((value) => value.tags))
      ..sort((a, b) => b.usedCount.compareTo(a.usedCount));

    if (tags.length > displayCount) {
      tags = tags.sublist(0, displayCount);
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TitleText(TranslationKeys.stats.tr()),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(TranslationKeys.totalIssuesCreated.tr()),
              const SizedBox(width: 8),
              Text(_count.toString(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, // blue
                      color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 4),
          Text(TranslationKeys.topXMosedUsedTags
              .tr(args: [displayCount.toString()])),
          const SizedBox(height: 8),
          IssueTags(
            tags: tags.map((tag) => tag.name).toList(),
            teamId: widget.teamId,
            isShowUsedCount: true,
            isLoose: true,
          ),
          const SizedBox(
            height: 32,
          )
        ],
      ),
    );
  }
}
