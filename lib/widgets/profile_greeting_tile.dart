import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_controller.dart';
import '../utils/translation_keys.dart';
import 'title_text.dart';
import 'user_avatar.dart';

class ProfileGreetingTile extends ConsumerStatefulWidget {
  const ProfileGreetingTile({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ProfileGreetingTileState();
}

class _ProfileGreetingTileState extends ConsumerState<ProfileGreetingTile> {
  @override
  Widget build(BuildContext context) {
    final username = ref.watch(authControllerProvider).user?.displayName;
    final uid =
        ref.watch(authControllerProvider.select((value) => value.user?.uid));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TitleText(
                TranslationKeys.greeting.tr(args: [username ?? 'User'])),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: UserAvatar(showEmailWhenTapped: true, uid: uid!),
        ),
      ],
    );
  }
}
