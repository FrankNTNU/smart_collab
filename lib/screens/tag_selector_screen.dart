import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/widgets/add_tag_form.dart';
import 'package:smart_collab/widgets/confirm_dialog.dart';
import 'package:smart_collab/widgets/issue_tag_chip.dart';

import '../services/tag_controller.dart';

class TagSelectorScreen extends ConsumerStatefulWidget {
  final String teamId;
  final String issueId;
  // initial tags
  final List<String> initialTags;
  const TagSelectorScreen(
      {super.key,
      required this.teamId,
      required this.issueId,
      required this.initialTags});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _TagSelectorScreenState();
}

class _TagSelectorScreenState extends ConsumerState<TagSelectorScreen> {
  // selected tags
  List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    print('init state tag selector screen');
    // init selected tags
    _selectedTags = widget.initialTags;
    print('initial tags: ${widget.initialTags}');
    Future.delayed(
      Duration.zero,
      () {
        ref.read(tagProvider(widget.teamId).notifier).fetchTags();
      },
    );
  }

  void _openAddTagForm() {
    showModalBottomSheet(
      showDragHandle: true,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(16),
          child: AddTagForm(
            teamId: widget.teamId,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tags =
        ref.watch(tagProvider(widget.teamId).select((value) => value.tags));
    final mergedTagNames =
        <String>{...tags.map((t) => t.name), ...widget.initialTags}.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Tags'),
        actions: [
          IconButton(
            onPressed: () {
              // bottom sheet
              _openAddTagForm();
            },
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                ...mergedTagNames.map(
                  (tag) {
                    final tagId =
                        tags.where((t) => t.name == tag).firstOrNull?.id;
                    return Dismissible(
                      direction: tagId == null
                          ? DismissDirection.none
                          : DismissDirection.endToStart,
                      key: // using name and color as key
                          ValueKey(
                              '${tagId ?? 'new'}-${tag.replaceAll(' ', '')}'
                          ),
                      confirmDismiss: tagId == null
                          ? null
                          : (direction) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (context) => ConfirmDialog(
                                  title: 'Delete Tag',
                                  content:
                                      'Are you sure you want to delete this tag?',
                                  confirmText: 'Delete',
                                  onConfirm: () => ref
                                      .read(tagProvider(widget.teamId).notifier)
                                      .removeTag(tagId),
                                ),
                              );
                            },
                      background: Container(
                        color: Colors.red,
                        child: const Icon(Icons.delete),
                      ),
                      child: CheckboxListTile(
                        title: IssueTagChip(
                          tagName: tag,
                          teamId: widget.teamId,
                        ),
                        value: _selectedTags.contains(tag),
                        onChanged: (value) {
                          if (value == null) return;
                          // add to selected tags
                          if (value) {
                            setState(() {
                              _selectedTags.add(tag);
                            });
                            ref
                                .read(issueProvider(widget.teamId).notifier)
                                .addTagToIssue(
                                    issueId: widget.issueId, tag: tag);
                          } else {
                            // remove from selected tags
                            setState(() {
                              _selectedTags.remove(tag);
                            });
                            ref
                                .read(issueProvider(widget.teamId).notifier)
                                .removeTagFromIssue(
                                    issueId: widget.issueId, tag: tag);
                          }
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(
                  height: 64,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
