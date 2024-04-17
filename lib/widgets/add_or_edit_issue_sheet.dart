import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/widgets/add_or_edit_team_sheet.dart';
import 'package:textfield_tags/textfield_tags.dart';

import '../services/auth_controller.dart';

class AddOrEditIssueSheet extends ConsumerStatefulWidget {
  const AddOrEditIssueSheet(
      {super.key, required this.teamId, required this.addOrEdit, this.issue});
  final String teamId;
  final AddorEdit addOrEdit;
  final Issue? issue;
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AddIssueSheetState();
}

class _AddIssueSheetState extends ConsumerState<AddOrEditIssueSheet> {
  // formkey
  final _formKey = GlobalKey<FormState>();
  // enteredTitle
  String _enteredTitle = '';
  // enteredDescription
  String _enteredDescription = '';
  // enteredStatus
  final String _enteredStatus = '';
  // enteredDeadline
  DateTime? _enteredDeadline;
  // enteredTags
  final List<String> _enteredTags = [];
  late double _distanceToField;
  late StringTagController _stringTagController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _distanceToField = MediaQuery.of(context).size.width;
  }

  @override
  void initState() {
    super.initState();
    _stringTagController = StringTagController();
    if (widget.addOrEdit == AddorEdit.update) {
      setState(() {
        _enteredTitle = widget.issue!.title;
        _enteredDescription = widget.issue!.description;
        _enteredTags.addAll(widget.issue!.tags);
      });
    }
  }

  void _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }
    // save form
    _formKey.currentState!.save();
    if (widget.addOrEdit == AddorEdit.update) {
      await ref.read(issueProvider(widget.teamId).notifier).updateIssue(
          title: _enteredTitle,
          description: _enteredDescription,
          tags: _stringTagController.getTags ?? [],
          issueId: widget.issue!.id);
      return;
    } else {
      await ref.read(issueProvider(widget.teamId).notifier).addIssue(
          title: _enteredTitle,
          description: _enteredDescription,
          tags: _stringTagController.getTags ?? []);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(issueProvider(widget.teamId).select((value) => value.apiStatus),
        (prev, next) {
      if (next == ApiStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Issue ${widget.addOrEdit == AddorEdit.add ? 'added' : 'updated'} successfully'),
          ),
        );
        Navigator.of(context).pop();
      }
    });
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // header
            Row(
              children: [
                Text(
                  '${widget.addOrEdit == AddorEdit.add ? 'Add' : 'Edit'} issue',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Spacer(),
                const CloseButton()
              ],
            ),
            // title
            TextFormField(
              initialValue: _enteredTitle,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
              onSaved: (value) {
                _enteredTitle = value!;
              },
            ),
            // descroption
            TextFormField(
              initialValue: _enteredDescription,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 16,
              minLines: 8,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
              onSaved: (value) {
                _enteredDescription = value!;
              },
            ),
            // height 8
            const SizedBox(height: 8),
            // tags
            TextFieldTags<String>(
              textfieldTagsController: _stringTagController,
              initialTags: const ['bug'],
              textSeparators: const [' ', ','],
              letterCase: LetterCase.normal,
              validator: (String tag) {
                if (_stringTagController.getTags!.contains(tag)) {
                  return 'You\'ve already entered that';
                }
                return null;
              },
              inputFieldBuilder: (context, inputFieldValues) {
                return TextField(
                  onTap: () {
                    _stringTagController.getFocusNode?.requestFocus();
                  },
                  controller: inputFieldValues.textEditingController,
                  focusNode: inputFieldValues.focusNode,
                  decoration: InputDecoration(
                    labelText: 'Tags',
                    isDense: true,
                    helperStyle: const TextStyle(
                      color: Color.fromARGB(255, 74, 137, 92),
                    ),
                    hintText:
                        inputFieldValues.tags.isNotEmpty ? '' : "Enter tag...",
                    errorText: inputFieldValues.error,
                    prefixIconConstraints:
                        BoxConstraints(maxWidth: _distanceToField * 0.8),
                    prefixIcon: inputFieldValues.tags.isNotEmpty
                        ? SingleChildScrollView(
                            controller: inputFieldValues.tagScrollController,
                            scrollDirection: Axis.vertical,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 8,
                                left: 8,
                              ),
                              child: Wrap(
                                  runSpacing: 4.0,
                                  spacing: 4.0,
                                  children:
                                      inputFieldValues.tags.map((String tag) {
                                    return Container(
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(20.0),
                                        ),
                                        color: Color.fromARGB(255, 74, 137, 92),
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 5.0),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0, vertical: 5.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            child: Text(
                                              '#$tag',
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                            onTap: () {
                                              //print("$tag selected");
                                            },
                                          ),
                                          const SizedBox(width: 4.0),
                                          InkWell(
                                            child: const Icon(
                                              Icons.cancel,
                                              size: 14.0,
                                              color: Color.fromARGB(
                                                  255, 233, 233, 233),
                                            ),
                                            onTap: () {
                                              inputFieldValues
                                                  .onTagRemoved(tag);
                                            },
                                          )
                                        ],
                                      ),
                                    );
                                  }).toList()),
                            ),
                          )
                        : null,
                  ),
                  onChanged: inputFieldValues.onTagChanged,
                  onSubmitted: inputFieldValues.onTagSubmitted,
                );
              },
            ),
            ElevatedButton(
              onPressed: () {
                _stringTagController.clearTags();
              },
              child: const Text(
                'CLEAR TAGS',
              ),
            ),
            // submit button
            ElevatedButton(
              onPressed: () {
                _submit();
              },
              child: Text(
                  '${widget.addOrEdit == AddorEdit.add ? 'Add' : 'Update'} Issue'),
            ),
          ],
        ),
      ),
    );
  }
}
