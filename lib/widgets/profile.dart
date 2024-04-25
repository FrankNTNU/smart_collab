import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/auth_controller.dart';

class Profile extends ConsumerWidget {
  const Profile({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.select(
      (value) => value.user,
    ));
    return Row(
      children: [
        const SizedBox(width: 20),
        CircleAvatar(
          radius: 30,
          backgroundImage: user?.photoURL?.isNotEmpty == true
              ? NetworkImage(user!.photoURL!)
              : null,
          child: user?.photoURL?.isEmpty == true
              ? const Icon(Icons.person)
              : null,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: InkWell(
            onTap: () {
              // close current snackbar
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              // show user id in snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(user?.uid ?? ''),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.displayName ?? ''),
                Text(user?.email ?? ''),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
