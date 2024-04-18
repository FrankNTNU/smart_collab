import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/profile_controller.dart';

class UserAvatar extends ConsumerStatefulWidget {
  final String uid;
  const UserAvatar({super.key, required this.uid});

  @override
  ConsumerState<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends ConsumerState<UserAvatar> {
  @override
  Widget build(BuildContext context) {
    final asyncProfilePicProvider = ref.watch(profileDataProvider(widget.uid));
    return asyncProfilePicProvider.when(
      data: (profileData) {
        return CircleAvatar(
          radius: 20,
          backgroundImage: profileData.photoURL?.isNotEmpty == true
              ? NetworkImage(profileData.photoURL!)
              : null,
          child: profileData.photoURL == null ? const Icon(Icons.person) : null,
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => const CircleAvatar(
        radius: 20,
        child: Icon(Icons.error),
      ),
    );
  }
}
