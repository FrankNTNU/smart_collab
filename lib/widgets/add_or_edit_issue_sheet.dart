import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/widgets/add_or_edit_team_sheet.dart';
import 'package:smart_collab/widgets/title_text.dart';

import '../services/activity_controller.dart';
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
  late double _distanceToField;
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
    if (widget.addOrEdit == AddorEdit.update) {
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
        _errorMessage = 'Please select a deadline';
      });
      return;
    }
    // get curent username
    final username = ref.watch(authControllerProvider
        .select((value) => value.user?.displayName ?? ''));
    if (widget.addOrEdit == AddorEdit.update) {
      await ref.read(issueProvider(widget.teamId).notifier).updateIssue(
          title: _enteredTitle,
          description: _enteredDescription,
          deadline: _enteredDeadline,
          issueId: widget.issue!.id);
      // add to activity
      await ref.read(activityProvider(widget.teamId).notifier).addActivity(
            recipientUid: username,
            message: '$username updated an issue $_enteredTitle',
            activityType: ActivityyType.updateIssue,
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
      // add to activity
      await ref.read(activityProvider(widget.teamId).notifier).addActivity(
            recipientUid: username,
            message: '$username added an issue $_enteredTitle',
            activityType: ActivityyType.createIssue,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Issue ${widget.addOrEdit == AddorEdit.add ? 'added' : 'updated'} successfully'),
          ),
        );
        //Navigator.of(context).pop();
      }
    });
    return Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16, // bottom viewinset
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              // header
              Row(
                children: [
                  TitleText(
                    '${widget.addOrEdit == AddorEdit.add ? 'Add' : 'Edit'} issue',
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
                controller: _descriptionController,
                decoration: InputDecoration(
                    labelText: 'Description',
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
              const Text('Deadline'),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(_enteredDeadline == null
                        ? 'Select the deadline'
                        : _enteredDeadline.toString().substring(0, 10)),
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),

              // submit button
              ElevatedButton(
                onPressed: () {
                  _submit();
                },
                child: Text(
                    '${widget.addOrEdit == AddorEdit.add ? 'Add' : 'Update'} Issue'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
