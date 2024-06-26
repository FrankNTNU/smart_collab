import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/profile_controller.dart';

class UserAvatar extends ConsumerStatefulWidget {
  final String uid;
  final double radius;
  final bool showEmailWhenTapped;
  const UserAvatar(
      {super.key,
      required this.uid,
      this.radius = 50,
      this.showEmailWhenTapped = false});

  @override
  ConsumerState<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends ConsumerState<UserAvatar> {
  @override
  Widget build(BuildContext context) {
    final asyncProfilePicProvider = ref.watch(profileDataProvider(widget.uid));
    return asyncProfilePicProvider.when(
      data: (profileData) {
        return Tooltip(
            message:
                '${profileData.displayName}${widget.showEmailWhenTapped ? '\n${profileData.email}' : ''}',
            triggerMode: TooltipTriggerMode.tap,
            child: profileData.photoURL == null
                ? const Icon(Icons.person)
                : CachedNetworkImage(
                    imageUrl: profileData.photoURL!,
                    imageBuilder: (context, imageProvider) => Container(
                      width: widget.radius,
                      height: widget.radius,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                            image: imageProvider, fit: BoxFit.cover),
                      ),
                    ),
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  )

            // child: CircleAvatar(
            //   radius: 20,
            //   backgroundImage: profileData.photoURL?.isNotEmpty == true
            //       ? NetworkImage(profileData.photoURL!)
            //       : null,
            //   child: profileData.photoURL == null ? const Icon(Icons.person) : null,
            // ),
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
