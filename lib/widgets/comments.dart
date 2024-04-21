import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/utils/time_utils.dart';
import 'package:smart_collab/utils/translation_keys.dart';
import 'package:smart_collab/widgets/user_avatar.dart';

import '../services/comment_controller.dart';
import 'confirm_dialog.dart';
import 'grey_description.dart';

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
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Text(
            TranslationKeys.somethingNotFound.tr(args: [
              TranslationKeys.comments.tr(),
            ]),
          ),
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
              GreyDescription(
                '${comments.length} ${TranslationKeys.comments.tr()}',
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                  child: UserAvatar(uid: comments[index].userId),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(comments[index].content),
                      Row(
                        children: [
                          Expanded(
                            child: GreyDescription(TimeUtils.getFuzzyTime(
                                comments[index].createdAt,
                                context: context)),
                          ),
                          InkWell(
                              onTap: () {
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
                                            title: Text(
                                                TranslationKeys.delete.tr()),
                                            onTap: () {
                                              //ref.read(teamsProvider.notifier).deleteTeam(teams[index]);
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return ConfirmDialog(
                                                    title: TranslationKeys
                                                        .delete
                                                        .tr(),
                                                    content: TranslationKeys
                                                        .confirmSomething
                                                        .tr(args: [
                                                      TranslationKeys.comment
                                                          .tr(),
                                                    ]),
                                                    onConfirm: () {
                                                      ref
                                                          .read(
                                                              commentProvider((
                                                            issueId:
                                                                widget.issueId,
                                                            teamId:
                                                                widget.teamId
                                                          )).notifier)
                                                          .deleteComment(
                                                              comments[index]
                                                                  .id,
                                                              widget.issueId);
                                                      Navigator.pop(context);
                                                    },
                                                    confirmText: TranslationKeys
                                                        .delete
                                                        .tr(),
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
                              child: const Icon(Icons.more_horiz)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
