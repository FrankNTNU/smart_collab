import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/utils/time_utils.dart';

import '../services/issue_controller.dart';
import '../services/profile_controller.dart';

class LastUpdatedAtInfo extends ConsumerWidget {
  final Issue issueData;
  final bool isConcise;
  const LastUpdatedAtInfo({super.key, required this.issueData, this.isConcise = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updatedAtMessage = TimeUtils.getFuzzyTime(issueData.updatedAt);
    if (issueData.lastUpdatedBy == null || isConcise) {
      return Text(
        'Last updated $updatedAtMessage',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      );
    }
    final asyncProfilePicProvider =
        ref.watch(profileDataProvider(issueData.lastUpdatedBy!));

    return asyncProfilePicProvider.when(
      data: (profileData) {
        return Text(
          'Last updated by ${profileData.displayName} $updatedAtMessage',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        );
      },
      loading: () =>  Text(
        'Last updated $updatedAtMessage',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      error: (error, stack) =>  Text(
        'Last updated $updatedAtMessage',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
    );
  }
}
