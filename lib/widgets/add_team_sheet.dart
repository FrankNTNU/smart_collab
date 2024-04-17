import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/team_controller.dart';

import 'team_image_picker.dart';

class AddTeamSheet extends ConsumerStatefulWidget {
  // image on select
  const AddTeamSheet({
    super.key,
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

  void _imageOnSelect(File selectedImage) async {
    setState(() {
      _pickedImage = selectedImage;
    });
  }

  void _submit() async {
    // check form validation
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }
    // save form
    _formKey.currentState!.save();
    // add team
    ref.read(teamsProvider.notifier).addTeam(
          Team(
            name: _enteredName,
            description: _enteredDescription,
          ),
          _pickedImage,
        );
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
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Add Team',
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
            TeamImagePicker(imageOnSelect: _imageOnSelect),
            TextFormField(
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
              child: const Text('Add Team'),
            ),
          ],
        ),
      ),
    );
  }
}
