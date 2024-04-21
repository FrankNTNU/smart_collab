import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/screens/filter_tags_selection_menu.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/widgets/add_or_edit_team_sheet.dart';
import 'package:smart_collab/widgets/issue_tags.dart';
import 'package:smart_collab/widgets/title_text.dart';

import '../services/activity_controller.dart';
import '../services/auth_controller.dart';
import '../utils/translation_keys.dart';

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
  late double _distanceToField;
  // enteredTags
  final List<String> _enteredTags = [];
  // error message
  String? _errorMessage;
  // description editing controller
  final _descriptionController = TextEditingController();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _distanceToField = MediaQuery.of(context).size.width;
  }

  @override
  void initState() {
    super.initState();
    if ( //add
        widget.addOrEdit == AddorEdit.add) {
      setState(() {
        _enteredDeadline = // 7 days from now
            DateTime.now().add(
          const Duration(days: 7),
        );
      });
    }
    if (widget.addOrEdit == AddorEdit.edit) {
      setState(() {
        _enteredTitle = widget.issue!.title;
        _enteredDescription = widget.issue!.description;
        _descriptionController.text = widget.issue!.description;
        _enteredDeadline = widget.issue!.deadline;
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
    if (_enteredDeadline == null) {
      setState(() {
        _errorMessage = TranslationKeys.pleaseEnterSomething.tr(args: [
          TranslationKeys.deadline.tr(),
        ]);
      });
      return;
    }
    // get curent username
    final username = ref.watch(authControllerProvider
        .select((value) => value.user?.displayName ?? ''));
    if (widget.addOrEdit == AddorEdit.edit) {
      await ref.read(issueProvider(widget.teamId).notifier).updateIssue(
          title: _enteredTitle,
          description: _enteredDescription,
          deadline: _enteredDeadline,
          issueId: widget.issue!.id);
      final message = TranslationKeys.xUpdatedTheIssueY.tr(args: [
        username,
        _enteredTitle,
      ]);
      // add to activity
      await ref.read(activityProvider(widget.teamId).notifier).addActivity(
            recipientUid: username,
            message: message,
            activityType: ActivityType.updateIssue,
            teamId: widget.teamId,
            issueId: widget.issue!.id,
          );
    } else {
      final issueId =
          await ref.read(issueProvider(widget.teamId).notifier).addIssue(
                title: _enteredTitle,
                description: _enteredDescription,
                deadline: _enteredDeadline,
              );
      // add tags to isse
      await ref.read(issueProvider(widget.teamId).notifier).addTagsToIssue(
            issueId: issueId,
            tags: _enteredTags,);
      final message = TranslationKeys.xAddedANewIssueY.tr(args: [
        username,
        _enteredTitle,
      ]);
      // add to activity
      await ref.read(activityProvider(widget.teamId).notifier).addActivity(
            recipientUid: username,
            message: message,
            activityType: ActivityType.createIssue,
            teamId: widget.teamId,
            issueId: issueId,
          );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(issueProvider(widget.teamId).select((value) => value.apiStatus),
        (prev, next) {
      if (next == ApiStatus.success) {
        final message = widget.addOrEdit == AddorEdit.add
            ? TranslationKeys.xCreatedSuccessfully
                .tr(args: [TranslationKeys.issue.tr()])
            : TranslationKeys.xUpdatedSuccessfully
                .tr(args: [TranslationKeys.issue.tr()]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
        //Navigator.of(context).pop();
      }
    });
    final isLoading = ref.watch(issueProvider(widget.teamId)
        .select((value) => value.apiStatus == ApiStatus.loading));
    return Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16, // bottom viewinset
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              // header
              Row(
                children: [
                  TitleText(
                    '${widget.addOrEdit == AddorEdit.add ? TranslationKeys.add.tr() : TranslationKeys.edit.tr()} ${TranslationKeys.issue.tr()}',
                  ),
                  const Spacer(),
                  const CloseButton()
                ],
              ),
              // title
              TextFormField(
                initialValue: _enteredTitle,
                decoration:
                    InputDecoration(labelText: TranslationKeys.title.tr()),
                validator: (value) {
                  if (value!.isEmpty) {
                    return TranslationKeys.pleaseEnterSomething.tr(args: [
                      TranslationKeys.title.tr(),
                    ]);
                  }
                  return null;
                },
                onSaved: (value) {
                  _enteredTitle = value!;
                },
              ),
              // descroption
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                    labelText: TranslationKeys.description.tr(),
                    suffix: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _descriptionController.clear();
                      },
                    )),
                maxLines: 12,
                minLines: 6,
                validator: (value) {
                  if (value!.isEmpty) {
                    return TranslationKeys.pleaseEnterSomething.tr(args: [
                      TranslationKeys.description.tr(),
                    ]);
                  }
                  return null;
                },
                onSaved: (value) {
                  _enteredDescription = value!;
                },
              ),
              // height 8
              const SizedBox(height: 8),
              Text(TranslationKeys.deadline.tr()),
              // deadline field
              InkWell(
                onTap: () {
                  final threeYearsFromNow = DateTime.now().add(
                    const Duration(days: 365 * 3),
                  );
                  // date picker
                  showDatePicker(
                    context: context,
                    initialDate: _enteredDeadline ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: threeYearsFromNow,
                  ).then((pickedDate) {
                    if (pickedDate == null) {
                      return;
                    }
                    setState(() {
                      _enteredDeadline = pickedDate;
                    });
                  });
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    errorText: _errorMessage,
                  ),
                  child: Row(
                    children: [
                      // event icon
                      const Icon(Icons.event),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(_enteredDeadline == null
                            ? TranslationKeys.pleaseSelectSomething.tr(
                                args: [TranslationKeys.deadline.tr()],
                              )
                            : _enteredDeadline.toString().substring(0, 10)),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.addOrEdit == AddorEdit.add)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(TranslationKeys.tags.tr()),
                ),
              // tags field
              if (widget.addOrEdit == AddorEdit.add)
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      isScrollControlled: true,
                      enableDrag: true,
                      showDragHandle: true,
                      context: context,
                      builder: (context) {
                        return TagsSelectionMenu(
                            onSelected: (tag) {
                              setState(() {
                                if (_enteredTags.contains(tag)) {
                                  _enteredTags.remove(tag);
                                } else {
                                  _enteredTags.add(tag);
                                }
                              });
                            },
                            initialTags: _enteredTags,
                            teamId: widget.teamId,
                            purpose: TagSelectionPurpose.editIssue);
                      },
                    );
                  },
                  child: IssueTags(
                    tags: _enteredTags,
                    teamId: widget.teamId,
                    isEditable: true,
                  ),
                ),
              const SizedBox(
                height: 16,
              ),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                // submit button
                ElevatedButton(
                  onPressed: () {
                    _submit();
                  },
                  child: Text(
                      '${widget.addOrEdit == AddorEdit.add ? TranslationKeys.add.tr() : TranslationKeys.update.tr()} ${TranslationKeys.issue.tr()}'),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
