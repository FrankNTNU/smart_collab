import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/auth_controller.dart';
import 'package:smart_collab/services/profile_controller.dart';
import 'package:smart_collab/widgets/cover_image.dart';
import 'package:smart_collab/widgets/invite_to_team.dart';

import '../services/team_controller.dart';

class TeamScreen extends ConsumerStatefulWidget {
  final Team team;
  const TeamScreen({super.key, required this.team});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  @override
  Widget build(BuildContext context) {
    final teamData = ref.watch(teamsProvider.select((value) =>
        value.teams.where((team) => team.id == widget.team.id).first));
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team.name ?? ''),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // show cover image
            if (widget.team.imageUrl != null)
              // network image
              CoverImage(
                imageUrl: widget.team.imageUrl!,
                isRoundedBorder: false,
                height: MediaQuery.of(context).size.height * 0.2,
              ),
            // description about team
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(widget.team.description ?? ''),
            ),
            // add admin button
            ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  isScrollControlled: true,
                  enableDrag: true,
                  showDragHandle: true,
                  context: context,
                  builder: (context) => Padding(
                    padding: MediaQuery.of(context)
                        .viewInsets
                        .copyWith(left: 16, right: 16),
                    child: InviteToTeam(teamId: widget.team.id!),
                  ),
                );
              },
              child: const Text('Invite user to team'),
            ),
            // show a list of admins horizontally
            TeamMembers(
              teamId: teamData.id!,
            )
          ],
        ),
      ),
    );
  }
}

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
                final notYourself =
                    role.key != ref.read(authControllerProvider).user!.uid;
                final isOwner = teamData.roles[role.key] == 'owner';
                final isAdmin = teamData.roles[role.key] == 'admin';
                final canOpenMenu = isOwner || isAdmin && notYourself;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      InkWell(
                        onLongPress: () {
                          if (!canOpenMenu) {
                            return;
                          }
                          if (isOwner) {
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
                                                email: profileData.uid!,
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
              loading: () => const CircularProgressIndicator(),
              error: (error, stackTrace) =>
                  const Text('Error loading profile picture'),
            );
          })
        ],
      ),
    );
  }
}
