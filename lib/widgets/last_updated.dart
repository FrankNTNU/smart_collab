import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/issue_controller.dart';
import '../services/profile_controller.dart';

class LastUpdatedAtInfo extends ConsumerWidget {
  final Issue issueData;
  final bool isConcise;
  const LastUpdatedAtInfo({super.key, required this.issueData, this.isConcise = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (issueData.lastUpdatedBy == null || isConcise) {
      return Text(
        'Last updated at ${issueData.updatedAt.toString().substring(0, 16)}',
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
          'Last updated by ${profileData.displayName} at ${issueData.updatedAt.toString().substring(0, 16)}',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        );
      },
      loading: () =>  Text(
        'Last updated at ${issueData.updatedAt.toString().substring(0, 16)}',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      error: (error, stack) =>  Text(
        'Last updated at ${issueData.updatedAt.toString().substring(0, 16)}',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
    );
  }
}
