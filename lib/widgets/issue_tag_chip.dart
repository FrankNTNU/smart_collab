import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/tag_controller.dart';

class IssueTagChip extends ConsumerStatefulWidget {
  const IssueTagChip(
      {super.key,
      required this.tagName,
      this.hexColor,
      this.isLoose = false,
      required this.teamId, this.isShowUsedCount = false});
  final String tagName;
  final String? hexColor;
  final bool isLoose;
  final String teamId;
  final bool isShowUsedCount;
  @override
  ConsumerState<IssueTagChip> createState() => _IssueTagChipState();
}

class _IssueTagChipState extends ConsumerState<IssueTagChip> {
  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration.zero,
      () {
        if (ref.read(tagProvider(widget.teamId)).tags.isEmpty) {
          ref.read(tagProvider(widget.teamId).notifier).fetchTags();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tagColor = ref.watch(tagProvider(widget.teamId).select((value) =>
            value.tags
                .where((tag) => tag.name == widget.tagName)
                .firstOrNull
                ?.color)) ??
        Colors.grey.shade300.value.toRadixString(16);
    return Container(
      padding: widget.isLoose
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Color(int.parse('0xff$tagColor')),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.tagName, // black
              style: const TextStyle(
                color: Colors.black,
              )),
          if (widget.isShowUsedCount)
            Text(
              ' (${ref.watch(tagProvider(widget.teamId).select((value) =>
                      value.tags
                          .where((tag) => tag.name == widget.tagName)
                          .firstOrNull
                          ?.usedCount))})',
              style: const TextStyle(
                color: Colors.black,
                // bold
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
