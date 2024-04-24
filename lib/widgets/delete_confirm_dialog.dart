import 'package:flutter/material.dart';
import 'package:smart_collab/widgets/grey_description.dart';

class DeleteConfirmDialog extends StatefulWidget {
  const DeleteConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    required this.confirmText,
    this.deleteValidationText,
    this.description,
    this.cancelText = 'Cancel',
  });

  final String title;
  final String content;
  final Function onConfirm;
  final String confirmText;
  final String cancelText;
  final String? deleteValidationText;
  final String? description;
  @override
  State<DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<DeleteConfirmDialog> {
  // delete validation text edit controller
  final TextEditingController _deleteValidationController =
      TextEditingController();
  // entered delete validation text
  String _enteredDeleteValidationText = '';
  // formkey
  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
  }

  void _deleteOnPressed() {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }
    if (_enteredDeleteValidationText == widget.deleteValidationText ||
        widget.deleteValidationText == null) {
      widget.onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final trimmedValidationText = widget.deleteValidationText != null &&
            widget.deleteValidationText!.length > 10
        ? widget.deleteValidationText!.substring(0, 10)
        : widget.deleteValidationText;
    return AlertDialog(
      title: Text(widget.title),
      content: Wrap(
        children: [
          Text(widget.content),
          if (widget.description != null) GreyDescription(widget.description!),
          if (widget.deleteValidationText?.isNotEmpty == true)
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _deleteValidationController,
                decoration: InputDecoration(
                  labelText: 'Type "$trimmedValidationText" to confirm',
                ),
                onChanged: (value) {
                  setState(() {
                    _enteredDeleteValidationText = value;
                  });
                },
                validator: (value) => value == trimmedValidationText
                    ? null
                    : 'Please type "$trimmedValidationText" to confirm',
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(widget.cancelText),
        ),
        TextButton(
          onPressed: () {
            _deleteOnPressed();
          },
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}
