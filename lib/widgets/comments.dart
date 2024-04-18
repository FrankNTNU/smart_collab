import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/widgets/user_avatar.dart';

import '../services/comment_controller.dart';
import 'confirm_dialog.dart';

class Comments extends ConsumerStatefulWidget {
  final String issueId;
  const Comments({super.key, required this.issueId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CommentsState();
}

class _CommentsState extends ConsumerState<Comments> {
  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration.zero,
      () {
        ref
            .read(commentProvider(widget.issueId).notifier)
            .fetchComments(widget.issueId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(
        commentProvider(widget.issueId).select((value) => value.comments));
    if (comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: Text('No comments found'),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        return ListTile(
          onLongPress: () {
            // show bottom menu
            showModalBottomSheet(
              context: context,
              builder: (context) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.delete),
                        title: const Text('Delete'),
                        onTap: () {
                          //ref.read(teamsProvider.notifier).deleteTeam(teams[index]);
                          showDialog(
                            context: context,
                            builder: (context) {
                              return ConfirmDialog(
                                title: 'Delete Comment',
                                content:
                                    'Are you sure you want to delete this comment?',
                                onConfirm: () {
                                  ref
                                      .read(commentProvider(widget.issueId)
                                          .notifier)
                                      .deleteComment(comments[index].id, widget.issueId);
                                  Navigator.pop(context);
                                },
                                confirmText: 'Delete',
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
          contentPadding: const EdgeInsets.all(0),
          leading: UserAvatar(uid: comments[index].userId),
          title: Text(comments[index].content),
          subtitle: Text(comments[index].createdAt.toString()),
        );
      },
    );
  }
}
