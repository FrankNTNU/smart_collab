import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_controller.dart';
import '../services/comment_controller.dart';
import '../services/team_controller.dart';

class CommentField extends ConsumerStatefulWidget {
  final String issueId;
  const CommentField({
    super.key,
    required this.issueId,
  });

  @override
  ConsumerState<CommentField> createState() => _CommentFieldState();
}

class _CommentFieldState extends ConsumerState<CommentField> {
  String _enteredComment = '';
  // text controller
  final _textController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final errorMessage = ref.watch(
        commentProvider(widget.issueId).select((value) => value.errorMessage));
    ref.listen(
        commentProvider(widget.issueId).select((value) => value.apiStatus),
        (prev, next) {
      if (next == ApiStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'An error occurred'),
          ),
        );
      }
    });
    final isLoading = ref.watch(commentProvider(widget.issueId).select(
        (value) =>
            value.apiStatus == ApiStatus.loading &&
            value.performedAction == PerformedAction.add));

    return Container(
      color: Colors.white.withOpacity(0.9),
      // bottom padding
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: 'Add comment',
                  border: const OutlineInputBorder(),
                  errorText: errorMessage,
                ),
                onChanged: (value) {
                  setState(() {
                    _enteredComment = value;
                  });
                },
              ),
            ),
            if (isLoading)
              const CircularProgressIndicator()
            else
              IconButton(
                onPressed: _enteredComment.isEmpty
                    ? null
                    : () async {
                        // add comment
                        await ref
                            .read(commentProvider(widget.issueId).notifier)
                            .addComment(_enteredComment);
                        // unfocus
                        FocusScope.of(context).unfocus();
                        // clear the text field
                        setState(() {
                          _enteredComment = '';
                        });
                        _textController.clear();
                      },
                icon: const Icon(Icons.send),
              ),
          ],
        ),
      ),
    );
  }
}
