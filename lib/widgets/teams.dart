import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/screens/team_screen.dart';
import 'package:smart_collab/utils/translation_keys.dart';
import 'package:smart_collab/widgets/cover_image.dart';
import 'package:smart_collab/widgets/team_tile.dart';

import '../services/auth_controller.dart';
import '../services/team_controller.dart';
import 'title_text.dart';

class Teams extends ConsumerStatefulWidget {
  const Teams({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TeamsState();
}

class _TeamsState extends ConsumerState<Teams> {
  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration.zero,
      () {
        ref.read(teamsProvider.notifier).fetchTeams();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(teamsProvider.select((value) => value.apiStatus), (prev, next) {
      final action =
          ref.watch(teamsProvider.select((value) => value.performedAction));
      if (next == ApiStatus.success) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        // a switch statement to show different snackbar messages
        String message = '';
        switch (action) {
          case PerformedAction.add:
            message = TranslationKeys.xFetchedSuccessfully.tr(
              args: [TranslationKeys.team.tr()],
            );
            break;
          case PerformedAction.update:
            message = TranslationKeys.xUpdatedSuccessfully.tr(
              args: [TranslationKeys.team.tr()],
            );
            break;
          case PerformedAction.delete:
            message = TranslationKeys.xDeletedSuccessfully.tr(
              args: [TranslationKeys.team.tr()],
            );
            break;
          case PerformedAction.fetch:
            message = TranslationKeys.xFetchedSuccessfully.tr(
              args: [TranslationKeys.teams.tr()],
            );
            break;
          default:
            message = '';
        }
        if (message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
            ),
          );
        }
      }
    });
    final teams = ref.watch(teamsProvider.select(
      (value) => value.teams,
    ));
    final isLoading = ref.watch(teamsProvider.select(
      (value) => value.apiStatus == ApiStatus.loading,
    ));

    if (teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(TranslationKeys.somethingNotFound.tr(
              args: [TranslationKeys.teams.tr()],
            )),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLoading) const Center(child: CircularProgressIndicator()),
        // header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: TitleText(TranslationKeys.myTeams.tr()),
        ),
        RefreshIndicator(
          onRefresh: () async =>
              await ref.read(teamsProvider.notifier).fetchTeams(),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              return TeamTile(
                team: teams[index],
              );
            },
          ),
        ),
      ],
    );
  }
}
