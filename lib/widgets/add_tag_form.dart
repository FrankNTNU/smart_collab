import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/tag_controller.dart';
import 'color_pallete.dart';

class AddTagForm extends ConsumerStatefulWidget {
  const AddTagForm({super.key, required this.teamId});
  final String teamId;
  @override
  ConsumerState<AddTagForm> createState() => _AddTagFormState();
}

class _AddTagFormState extends ConsumerState<AddTagForm> {
  // formkey
  final _formKey = GlobalKey<FormState>();
  // selected hex color
  String? _selectedHexColor;
  // entered tag name
  String? _enteredTagName;
  // error message
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    _selectedHexColor = null;
    _enteredTagName = null;
    _errorMessage = null;
  }

  void _submit() {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;
    if (_enteredTagName == null || _enteredTagName!.isEmpty) {
      setState(() {
        _errorMessage = 'Tag name is required';
      });
      return;
    }
    if (_selectedHexColor == null) {
      setState(() {
        _errorMessage = 'Color is required';
      });
      return;
    }
    ref.read(tagProvider(widget.teamId).notifier).addTag(
          name: _enteredTagName!,
          color: _selectedHexColor!,
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Add new tag',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            CloseButton(),
          ],
        ),
        const SizedBox(
          height: 16,
        ),
        Form(
          key: _formKey,
          child: TextFormField(
            decoration: const InputDecoration(
              hintText: 'Tag name',
            ),
            onChanged: (value) {
              setState(() {
                _enteredTagName = value;
                _formKey.currentState!.validate();
              });
            },
            validator: (value) =>
                value!.isEmpty ? 'Tag name is required' : null,
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        const Text('Color'),
        ColorPallete(
          onSelected: (color) {
            setState(() {
              _selectedHexColor = color;
            });
          },
        ),
        if (_errorMessage != null)
          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
        // submit button
        ElevatedButton(
          onPressed: () {
            _submit();
          },
          child: const Text('Add'),
        )
      ],
    );
  }
}
