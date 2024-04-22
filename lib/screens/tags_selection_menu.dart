import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/tag_controller.dart';
import 'package:smart_collab/widgets/add_or_edit_team_sheet.dart';

import '../utils/translation_keys.dart';
import '../widgets/add_tag_form.dart';
import '../widgets/grey_description.dart';
import '../widgets/issue_tag_chip.dart';
import '../widgets/title_text.dart';

enum TagSelectionPurpose { filterSearch, editIssue, editTags }

class TagsSelectionMenu extends ConsumerStatefulWidget {
  final Function(String tag) onSelected;
  final List<String> initialTags;
  final String teamId;
  final String title;
  final TagSelectionPurpose purpose;
  const TagsSelectionMenu(
      {super.key,
      required this.onSelected,
      required this.initialTags,
      required this.teamId,
      this.title = TranslationKeys.filterByTags,
      required this.purpose});

  @override
  ConsumerState<TagsSelectionMenu> createState() =>
      _FilterTagsSelectionMenuState();
}

class _FilterTagsSelectionMenuState extends ConsumerState<TagsSelectionMenu> {
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
    Future.delayed(Duration.zero, () {
      ref.read(tagProvider(widget.teamId).notifier).fetchTags();
    });
  }

  void openAddTagForm() {
    showModalBottomSheet(
      showDragHandle: true,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16),
          child: AddOrEditTagForm(
            teamId: widget.teamId,
            addOrEdit: AddorEdit.add,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sourceTags =
        ref.watch(tagProvider(widget.teamId).select((value) => value.tags))
          ..sort(
            (a, b) => b.usedCount - a.usedCount,
          )
          ..sort(
            (a, b) =>
                // sort boolean value
                a.isNewlyAdded == b.isNewlyAdded
                    ? 0
                    : a.isNewlyAdded
                        ? -1
                        : 1,
          );
    print('Source tags: ${sourceTags.map((t) => t.name)}');
    // get tags
    final tags = sourceTags.where((tag) {
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
                  widget.title.tr(),
                ),
                TextButton.icon(
                  // add tags
                  label: Text(TranslationKeys.addTag.tr()),
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    openAddTagForm();
                  },
                ),
                const Spacer(),
                const CloseButton(),
              ],
            ),
          ),
          // small grey description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GreyDescription(TranslationKeys.tagDescription.tr()),
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    onTapOutside: (event) {
                      FocusScope.of(context).unfocus();
                    },
                    decoration: InputDecoration(
                      hintText: TranslationKeys.searchSomething
                          .tr(args: [TranslationKeys.tags.tr()]),
                      suffix: // clear search term
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
              ),
              // clear all button
              if (widget.purpose == TagSelectionPurpose.filterSearch)
                TextButton.icon(
                  onPressed: () {
                    widget.onSelected('');
                    setState(() {
                      _selectedTags.clear();
                    });
                  },
                  icon: const Icon(Icons.remove),
                  label: Text(TranslationKeys.clear.tr()),
                ),
            ],
          ),
          Expanded(
            child: mergedTagNames.isEmpty
                ? Center(
                    child: Text(TranslationKeys.somethingNotFound.tr(
                      args: [TranslationKeys.tags.tr()],
                    )),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: mergedTagNames.length,
                    itemBuilder: (context, index) {
                      final tag = mergedTagNames[index];
                      // is tag exist
                      final isTagExist = sourceTags
                          .map((t) => t.name)
                          .contains(mergedTagNames[index]);
                      return CheckboxListTile(
                        secondary: !isTagExist
                            ? const IconButton(
                                onPressed: null,
                                icon: Icon(Icons.do_not_disturb_on))
                            : IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  showModalBottomSheet(
                                    isScrollControlled: true,
                                    enableDrag: true,
                                    showDragHandle: true,
                                    context: context,
                                    builder: (context) => Padding(
                                      padding: EdgeInsets.only(
                                          bottom: MediaQuery.of(context)
                                              .viewInsets
                                              .bottom,
                                          left: 16,
                                          right: 16),
                                      child: AddOrEditTagForm(
                                        teamId: widget.teamId,
                                        addOrEdit: AddorEdit.edit,
                                        initialTag: ref.watch(
                                            tagProvider(widget.teamId).select(
                                                (value) => value.tags
                                                    .where((t) => t.name == tag)
                                                    .firstOrNull)),
                                      ),
                                    ),
                                  );
                                },
                              ),
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
        ],
      ),
    );
  }
}
