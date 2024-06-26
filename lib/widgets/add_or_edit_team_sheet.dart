import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/activity_controller.dart';
import 'package:smart_collab/services/team_controller.dart';
import 'package:smart_collab/widgets/title_text.dart';

import '../services/auth_controller.dart';
import 'team_image_picker.dart';

enum AddorEdit {
  add,
  edit,
  duplicate,
}

class AddTeamSheet extends ConsumerStatefulWidget {
  final AddorEdit addOrEdit;
  final Team? team;
  // image on select
  const AddTeamSheet({
    super.key,
    required this.addOrEdit,
    this.team,
  });

  @override
  ConsumerState<AddTeamSheet> createState() => _AddTeamSheetState();
}

class _AddTeamSheetState extends ConsumerState<AddTeamSheet> {
  // form key
  final _formKey = GlobalKey<FormState>();
  File? _pickedImage;
  String _enteredName = '';
  String _enteredDescription = '';
  // description text editing controller
  final _descriptionController = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (widget.addOrEdit == AddorEdit.edit && widget.team != null) {
      setState(() {
        _enteredName = widget.team!.name!;
        _enteredDescription = widget.team!.description!;
        _descriptionController.text = widget.team!.description!;
      });
    }
  }

  void _imageOnSelect(File selectedImage) async {
    setState(() {
      _pickedImage = selectedImage;
    });
  }

  void _submit() async {
    // check form validation
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      print('invalid form in add team sheet');
      return;
    }
    // save form
    _formKey.currentState!.save();

    // usernmae
    final username = ref.read(authControllerProvider).user!.displayName;
    if (widget.addOrEdit == AddorEdit.add) {
      // add team
      final teamId = await ref.read(teamsProvider.notifier).addTeam(
            Team(
              name: _enteredName,
              description: _enteredDescription,
            ),
            _pickedImage,
          );
      // add activity
      await ref.read(activityProvider(teamId).notifier).addActivity(
            message: '$username created a new team $_enteredName',
            activityType: ActivityType.addTeam,
            teamId: teamId,
            recipientUid: ref.watch(authControllerProvider).user!.uid ?? '',
          );
    } else {
      // update team
      await ref.read(teamsProvider.notifier).editTeam(
            Team(
              name: _enteredName,
              description: _enteredDescription,
              id: widget.team!.id,
              imageUrl: widget.team!.imageUrl,
            ),
            _pickedImage,
          );
      // add activity
      await ref.read(activityProvider(widget.team!.id!).notifier).addActivity(
            message: '$username updated team ${widget.team!.name}',
            activityType: ActivityType.updateTeam,
            teamId: widget.team!.id,
            recipientUid: ref.watch(authControllerProvider).user!.uid ?? '',
          );
    }
    // close bottom sheet
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
        teamsProvider.select((value) => value.apiStatus == ApiStatus.loading));
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // title and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TitleText(widget.addOrEdit == AddorEdit.add
                        ? 'Create a team'
                        : 'Update the team'),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                // team image circular avatar
                TeamImagePicker(
                  imageOnSelect: _imageOnSelect,
                  defaultImageUrl: widget.team?.imageUrl,
                ),
                TextFormField(
                  initialValue: _enteredName,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ),
                  onSaved: (newValue) {
                    setState(() {
                      _enteredName = newValue!;
                    });
                  },
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  minLines: 4,
                  maxLines: 8,
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    suffix: // clear text button
                        IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _descriptionController.clear();
                      },
                    ),
                  ),
                  onSaved: (newValue) {
                    setState(() {
                      _enteredDescription = newValue!;
                    });
                  },
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a description' : null,
                ),

                const SizedBox(height: 20),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(
                      widget.addOrEdit == AddorEdit.add ? 'Add' : 'Update',
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
