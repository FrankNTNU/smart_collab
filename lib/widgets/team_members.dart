import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/auth_controller.dart';
import 'package:smart_collab/services/profile_controller.dart';
import 'package:smart_collab/services/team_controller.dart';

class TeamMembers extends ConsumerWidget {
  const TeamMembers({
    super.key,
    required this.teamId,
  });
  final String teamId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamData = ref.watch(teamsProvider.select(
        (value) => value.teams.where((team) => team.id == teamId).first));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...teamData.roles.entries.map((role) {
            final asyncProfilePicProvider =
                ref.watch(profileDataProvider(role.key));
            return asyncProfilePicProvider.when(
              data: (profileData) {
                final isThisMemberYourself =
                    role.key == ref.watch(authControllerProvider).user!.uid;
                final isThisMemberTheOwner =
                    teamData.roles[role.key] == 'owner';
                final isYourselfTheOnwer = teamData
                        .roles[ref.watch(authControllerProvider).user!.uid] ==
                    'owner';
                final isYourselfAnAdmin = teamData
                        .roles[ref.watch(authControllerProvider).user!.uid] ==
                    'admin';
                final canOpenMenu = (isYourselfTheOnwer ||
                        (isYourselfAnAdmin && !isThisMemberYourself)) &&
                    !isThisMemberTheOwner;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      InkWell(
                        onLongPress: () {
                          if (!canOpenMenu) {
                            print('Cannot open menu');
                            return;
                          }
                          // show bottom menu sheet
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (teamData.roles[role.key] == 'admin')
                                    ListTile(
                                      leading: const Icon(Icons.person),
                                      title: const Text('Set as member'),
                                      onTap: () {
                                        ref
                                            .read(teamsProvider.notifier)
                                            .setAsMemeber(
                                                email: profileData.email!,
                                                teamId: teamId);
                                        Navigator.pop(context);
                                      },
                                    ),
                                  // set ad admin
                                  if (teamData.roles[role.key] == 'member')
                                    ListTile(
                                      leading: const Icon(
                                          Icons.admin_panel_settings),
                                      title: const Text('Set as admin'),
                                      onTap: () {
                                        ref
                                            .read(teamsProvider.notifier)
                                            .setAsAdmin(
                                                email: profileData.email!,
                                                teamId: teamId);
                                        Navigator.pop(context);
                                      },
                                    ),

                                  // remove from team
                                  ListTile(
                                    leading: const Icon(Icons.delete),
                                    title: const Text('Remove from team'),
                                    onTap: () {
                                      ref
                                          .read(teamsProvider.notifier)
                                          .removeFromTeam(
                                              uid: profileData.uid!,
                                              teamId: teamId);
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage:
                              profileData.photoURL?.isNotEmpty == true
                                  ? NetworkImage(profileData.photoURL!)
                                  : null,
                        ),
                      ),
                      Text(profileData.displayName ?? ''),
                      Text(role.value),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  const Text('Error loading profile picture'),
            );
          })
        ],
      ),
    );
  }
}
