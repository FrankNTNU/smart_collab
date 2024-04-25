import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/services/profile_controller.dart';
import 'package:smart_collab/utils/translation_keys.dart';

import '../services/activity_controller.dart';
import '../services/auth_controller.dart';
import '../services/comment_controller.dart';
import '../services/team_controller.dart';

class CommentField extends ConsumerStatefulWidget {
  final String issueId;
  final String teamId;
  const CommentField({
    super.key,
    required this.issueId,
    required this.teamId,
  });

  @override
  ConsumerState<CommentField> createState() => _CommentFieldState();
}

class _CommentFieldState extends ConsumerState<CommentField> {
  String _enteredComment = '';
  // text controller
  final _textController = TextEditingController();
  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration.zero,
      () {
        // reset comment
        ref
            .read(commentProvider(
                (issueId: widget.issueId, teamId: widget.teamId)).notifier)
            .clearErrorMessage();
      },
    );
  }

  Future<void> _addComment() async {
    await ref
        .read(commentProvider((issueId: widget.issueId, teamId: widget.teamId))
            .notifier)
        .addComment(_enteredComment);
    final profile = await ref.read(profileFromEmailProvider(
        ref.read(authControllerProvider).user!.email!).future);
    // get issue data by issue id
    final issueData = ref.watch(issueProvider(widget.teamId).select(
        (value) => value.issueMap[widget.issueId]));
    // add to activity
    ref.read(activityProvider(widget.teamId).notifier).addActivity(
          recipientUid: profile.uid!,
          message: '${profile.displayName} commented on an issue ${issueData?.title ?? ''}',
          activityType: ActivityType.addComment,
          teamId: widget.teamId,
          issueId: widget.issueId,
        );
    // unfocus
    FocusScope.of(context).unfocus();
    // clear the text field
    setState(() {
      _enteredComment = '';
    });
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = ref.watch(
        commentProvider((issueId: widget.issueId, teamId: widget.teamId))
            .select((value) => value.errorMessage));
    ref.listen(
        commentProvider((issueId: widget.issueId, teamId: widget.teamId))
            .select((value) => value.apiStatus), (prev, next) {
      if (next == ApiStatus.error) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'An error occurred'),
          ),
        );
      }
    });
    final isLoading = ref.watch(
        commentProvider((issueId: widget.issueId, teamId: widget.teamId))
            .select((value) =>
                value.apiStatus == ApiStatus.loading &&
                value.performedAction == PerformedAction.add));

    return Container(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
      // bottom padding
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: TextField(
                  controller: _textController,
                  // on tap outside unfocus
                  onTapOutside: (_) {
                    FocusScope.of(context).unfocus();
                  },
                  decoration: InputDecoration(
                    hintText: TranslationKeys.addComment.tr(),
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
            ),
            if (isLoading)
              const CircularProgressIndicator()
            else
              IconButton(
                onPressed: _enteredComment.isEmpty
                    ? null
                    : () async {
                        // add comment
                        _addComment();
                      },
                icon: const Icon(Icons.send),
              ),
          ],
        ),
      ),
    );
  }
}
