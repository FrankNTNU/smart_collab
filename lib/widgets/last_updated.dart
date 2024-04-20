import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/utils/time_utils.dart';

import '../services/issue_controller.dart';
import '../services/profile_controller.dart';
import 'grey_description.dart';

class LastUpdatedAtInfo extends ConsumerWidget {
  final Issue issueData;
  final bool isConcise;
  const LastUpdatedAtInfo({super.key, required this.issueData, this.isConcise = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updatedAtMessage = TimeUtils.getFuzzyTime(issueData.updatedAt);
    if (issueData.lastUpdatedBy == null || isConcise) {
      return GreyDescription(
        'Last updated $updatedAtMessage',
      );
    }
    final asyncProfilePicProvider =
        ref.watch(profileDataProvider(issueData.lastUpdatedBy!));

    return asyncProfilePicProvider.when(
      data: (profileData) {
        return GreyDescription(
          'Last updated by ${profileData.displayName} $updatedAtMessage',
        );
      },
      loading: () =>  GreyDescription(
        'Last updated $updatedAtMessage',
      ),
      error: (error, stack) =>  GreyDescription(
        'Last updated $updatedAtMessage',
      ),
    );
  }
}
