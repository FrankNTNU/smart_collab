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
  // selected hex color
  String? _selectedHexColor;
  // entered tag name
  String? _enteredTagName;
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
        TextField(
          decoration: const InputDecoration(
            hintText: 'Tag name',
          ),
          onChanged: (value) {
            setState(() {
              _enteredTagName = value;
            });
          },
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
        // submit button
        ElevatedButton(
          onPressed: () {
            ref.read(tagProvider(widget.teamId).notifier).addTag(
                  name: _enteredTagName!,
                  color: _selectedHexColor!,
                );
            Navigator.pop(context);
          },
          child: const Text('Add'),
        )
      ],
    );
  }
}
