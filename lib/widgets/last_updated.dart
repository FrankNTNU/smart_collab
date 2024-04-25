import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/utils/time_utils.dart';
import 'package:smart_collab/utils/translation_keys.dart';

import '../services/issue_controller.dart';
import '../services/profile_controller.dart';
import 'grey_description.dart';

class LastUpdatedAtInfo extends ConsumerWidget {
  final Issue issueData;
  final bool isConcise;
  const LastUpdatedAtInfo(
      {super.key, required this.issueData, this.isConcise = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updatedAtMessage = TranslationKeys.lastUpdatedAt.tr(args: [
          TimeUtils.getFuzzyTime(issueData.updatedAt, context: context)
        ]);
    if (issueData.lastUpdatedBy == null || isConcise) {
      return GreyDescription(
        updatedAtMessage,
      );
    }
    final asyncProfilePicProvider =
        ref.watch(profileDataProvider(issueData.lastUpdatedBy!));

    return asyncProfilePicProvider.when(
      data: (profileData) {
        return GreyDescription(
          '${profileData.displayName} $updatedAtMessage',
        );
      },
      loading: () => GreyDescription(
        updatedAtMessage,
      ),
      error: (error, stack) => GreyDescription(
        updatedAtMessage,
      ),
    );
  }
}
