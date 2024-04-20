import 'package:flutter/material.dart';

class DeleteConfirmDialog extends StatefulWidget {
  const DeleteConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    required this.confirmText,
    this.deleteValidationText,
    this.cancelText = 'Cancel',
  });

  final String title;
  final String content;
  final Function onConfirm;
  final String confirmText;
  final String cancelText;
  final String? deleteValidationText;

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
      Navigator.pop(context);
    }
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Text(widget.content),
      actions: [
        if (widget.deleteValidationText?.isNotEmpty == true)
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _deleteValidationController,
              decoration: InputDecoration(
                labelText: 'Type "${widget.deleteValidationText}" to confirm',
              ),
              onChanged: (value) {
                setState(() {
                  _enteredDeleteValidationText = value;
                });
              },
              validator: (value) => value == widget.deleteValidationText
                  ? null
                  : 'Please type "${widget.deleteValidationText}" to confirm',
            ),
          ),
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
