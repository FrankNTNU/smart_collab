import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/utils/time_utils.dart';
import 'package:smart_collab/widgets/user_avatar.dart';

import '../services/comment_controller.dart';
import 'confirm_dialog.dart';

class Comments extends ConsumerStatefulWidget {
  final String issueId;
  final String teamId;
  const Comments({super.key, required this.issueId, required this.teamId});

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
            .read(commentProvider(
                (issueId: widget.issueId, teamId: widget.teamId)).notifier)
            .fetchComments(widget.issueId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(
        commentProvider((issueId: widget.issueId, teamId: widget.teamId))
            .select((value) => value.comments));
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index == 0)
            // show commebnt count
              Text(
                '${comments.length} comments',
               style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
              ),
            ListTile(
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
                                          .read(commentProvider((
                                            issueId: widget.issueId,
                                            teamId: widget.teamId
                                          )).notifier)
                                          .deleteComment(
                                              comments[index].id, widget.issueId);
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
              subtitle: Text(TimeUtils.getFuzzyTime(comments[index].createdAt)),
            ),
          ],
        );
      },
    );
  }
}
