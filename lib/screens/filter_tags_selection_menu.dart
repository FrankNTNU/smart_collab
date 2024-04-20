import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/tag_controller.dart';

import '../widgets/add_tag_form.dart';
import '../widgets/grey_description.dart';
import '../widgets/issue_tag_chip.dart';
import '../widgets/title_text.dart';

class FilterTagsSelectionMenu extends ConsumerStatefulWidget {
  final Function(String tag) onSelected;
  final List<String> initialTags;
  final String teamId;
  final String title;
  const FilterTagsSelectionMenu(
      {super.key,
      required this.onSelected,
      required this.initialTags,
      required this.teamId, this.title = 'Filter by tags'});

  @override
  ConsumerState<FilterTagsSelectionMenu> createState() =>
      _FilterTagsSelectionMenuState();
}

class _FilterTagsSelectionMenuState
    extends ConsumerState<FilterTagsSelectionMenu> {
  // search term
  String _searchTerm = '';
  // selected tags
  List<String> _selectedTags = [];
  // text edit controller
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _selectedTags = widget.initialTags;
  }

  void openAddTagForm() {
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
    // get tags
    final tags = ref
        .watch(tagProvider(widget.teamId).select((value) => value.tags))
        .where((tag) {
      final lowerCaseTag = tag.name.toLowerCase();
      final lowerCaseSearchTerm = _searchTerm.toLowerCase();
      return lowerCaseTag.contains(lowerCaseSearchTerm);
    }).toList();
    final mergedTagNames =
        <String>{...tags.map((t) => t.name), ...widget.initialTags}.toList();
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      // padding bottoom viewinset
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                TitleText(
                  widget.title,
                ),
                const Spacer(),
                const CloseButton(),
              ],
            ),
          ),
          // small grey description
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: GreyDescription(
              'Tags are useful for organizing and filtering issues.'
            ),
          ),
          Row(
            children: [
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onTapOutside: (event) {
                    FocusScope.of(context).unfocus();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search tags',
                    suffix: // clear
                        IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchTerm = '';
                        });
                      },
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchTerm = value;
                    });
                  },
                ),
              ),
              // clear all button
              TextButton.icon(
                onPressed: () {
                  widget.onSelected('');
                  setState(() {
                    _selectedTags.clear();
                  });
                },
                icon: const Icon(Icons.remove),
                label: const Text('Clear all'),
              ),
            ],
          ),
          Expanded(
            child: mergedTagNames.isEmpty
                ? const Center(
                    child: Text('No tags found'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: mergedTagNames.length,
                    itemBuilder: (context, index) {
                      final tag = mergedTagNames[index];
                      return CheckboxListTile(
                        title: IssueTagChip(
                          tagName: tag,
                          teamId: widget.teamId,
                        ),
                        value: _selectedTags.contains(tag),
                        onChanged: (value) {
                          if (value == null) return;
                          widget.onSelected(tag);
                          setState(() {
                            if (value) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
          if (tags.isNotEmpty)
            ListTile(
              // add tags
              title: const Text('Add new tag'),
              leading: const Icon(Icons.add),
              onTap: () {
                openAddTagForm();
              },
            ),
        ],
      ),
    );
  }
}
