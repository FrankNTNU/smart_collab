import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    required this.confirmText,
    this.cancelText = 'Cancel',
  });

  final String title;
  final String content;
  final Function onConfirm;
  final String confirmText;
  final String cancelText;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: Text(confirmText),
        ),
      ],
    );
  }
}
