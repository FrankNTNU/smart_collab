import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/team_controller.dart';

import 'team_image_picker.dart';

enum AddorEdit {
  add,
  update,
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
  @override
  void initState() {
    super.initState();
    if (widget.addOrEdit == AddorEdit.update) {
      setState(() {
        _enteredName = widget.team!.name!;
        _enteredDescription = widget.team!.description!;
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
    if (widget.addOrEdit == AddorEdit.add) {
      // add team
      await ref.read(teamsProvider.notifier).addTeam(
            Team(
              name: _enteredName,
              description: _enteredDescription,
            ),
            _pickedImage,
          );
    } else {
      // update team
      await ref.read(teamsProvider.notifier).editTeam(
            Team(
              name: _enteredName,
              description: _enteredDescription,
              id: widget.team!.id,
            ),
            _pickedImage,
          );
    }
    // close bottom sheet
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    widget.addOrEdit == AddorEdit.add
                        ? 'Add Team'
                        : 'Update Team',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
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
              minLines: 8,
              maxLines: 16,
              initialValue: _enteredDescription,
              decoration: const InputDecoration(
                labelText: 'Description',
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
    );
  }
}
