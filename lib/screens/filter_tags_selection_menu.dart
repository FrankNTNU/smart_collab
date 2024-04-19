import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/tag_controller.dart';

import '../widgets/issue_tag_chip.dart';

class FilterTagsSelectionMenu extends ConsumerStatefulWidget {
  final Function(String tag) onSelected;
  final List<String> initialTags;
  final String teamId;
  const FilterTagsSelectionMenu(
      {super.key,
      required this.onSelected,
      required this.initialTags,
      required this.teamId});

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
  @override
  void initState() {
    super.initState();
    _selectedTags = widget.initialTags;
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      // padding bottoom viewinset
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Filter by tags',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                CloseButton(),
              ],
            ),
          ),
          Row(
            children: [
              const SizedBox(width: 16,),
              Expanded(
                child: TextField(
                  onTapOutside: (event) {
                    FocusScope.of(context).unfocus();
                  
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search tags',
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
            child: tags.isEmpty
                ? const Center(
                    child: Text('No tags found'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: tags.length,
                    itemBuilder: (context, index) {
                      final tag = tags[index];
                      return CheckboxListTile(
                        title: IssueTagChip(
                          tagName: tag.name,
                          teamId: widget.teamId,
                        ),
                        value: _selectedTags.contains(tag.name),
                        onChanged: (value) {
                          if (value == null) return;
                          widget.onSelected(tag.name);
                          setState(() {
                            if (value) {
                              _selectedTags.add(tag.name);
                            } else {
                              _selectedTags.remove(tag.name);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
