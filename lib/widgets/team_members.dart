import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/auth_controller.dart';
import 'package:smart_collab/services/profile_controller.dart';
import 'package:smart_collab/services/team_controller.dart';
import 'package:smart_collab/widgets/user_avatar.dart';

import '../services/activity_controller.dart';
import '../utils/translation_keys.dart';

class TeamMembers extends ConsumerStatefulWidget {
  const TeamMembers({
    super.key,
    required this.teamId,
  });
  final String teamId;

  @override
  ConsumerState<TeamMembers> createState() => _TeamMembersState();
}

class _TeamMembersState extends ConsumerState<TeamMembers> {
  Future<void> _setAsMember(String email) async {
    await ref
        .read(teamsProvider.notifier)
        .setAsMemeber(email: email, teamId: widget.teamId);
    Navigator.pop(context);
  }

  Future<void> _setAdAdmin(String email) async {
    await ref
        .read(teamsProvider.notifier)
        .setAsAdmin(email: email, teamId: widget.teamId);
    final profile = await ref.read(profileFromEmailProvider(email).future);
    // add to activity
    ref.read(activityProvider(widget.teamId).notifier).addActivity(
          recipientUid: profile.uid!,
          message:
              '${profile.displayName} have been promoted to admin in a team',
          activityType: ActivityType.setAsAdmin,
          teamId: widget.teamId,
        );
    Navigator.pop(context);
  }

  Future<void> _removeFromTeam(String uid) async {
    ref
        .read(teamsProvider.notifier)
        .removeFromTeam(uid: uid, teamId: widget.teamId);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final teamData = ref.watch(teamsProvider.select((value) =>
        value.teams.where((team) => team.id == widget.teamId).firstOrNull));
    if (teamData == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
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
                                      title:  Text(TranslationKeys.setAdMember.tr()),
                                      onTap: () {
                                        _setAsMember(
                                          profileData.email!,
                                        );
                                      },
                                    ),
                                  // set ad admin
                                  if (teamData.roles[role.key] == 'member')
                                    ListTile(
                                      leading: const Icon(
                                          Icons.admin_panel_settings),
                                      title:  Text(TranslationKeys.setAsAdmin.tr(),),
                                      onTap: () {
                                        _setAdAdmin(profileData.email!);
                                      },
                                    ),

                                  // remove from team
                                  ListTile(
                                    leading: const Icon(Icons.delete),
                                    title:  Text(TranslationKeys.removeFromTeam.tr()),
                                    onTap: () {
                                      _removeFromTeam(profileData.uid!);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: UserAvatar(
                          showEmailWhenTapped: true,
                          uid: profileData.uid!,
                        )
                      ),
                      //Text(profileData.displayName ?? ''),
                      Text(role.value.tr()),
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
