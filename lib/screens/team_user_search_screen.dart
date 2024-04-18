import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/services/team_controller.dart';

import '../services/profile_controller.dart';

class TeamUserSearchScreen extends ConsumerStatefulWidget {
  final String teamId;
  final List<String> excludedMembers;
  // onSelected
  final Function(String) onSelected;
  const TeamUserSearchScreen(
      {super.key, required this.teamId, required this.onSelected, this.excludedMembers = const []});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _TeamUserSearchScreenState();
}

class _TeamUserSearchScreenState extends ConsumerState<TeamUserSearchScreen> {
  String _searchTerm = '';
  // current filtered count
  int _filteredCount = 0;

  @override
  Widget build(BuildContext context) {
    final teamData = ref.watch(teamsProvider.select((value) =>
        value.teams.where((team) => team.id == widget.teamId).first));
    final members = teamData.roles.entries.where((role) {
      return !widget.excludedMembers.contains(role.key);
    });
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search for a user',
              ),
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                });
              },
            ),
          ),
          ...members.map((role) {
            final userData = ref.watch(profileDataProvider(role.key));
            return userData.when(
              data: (profileData) {
                if (profileData.displayName
                            ?.toLowerCase()
                            .contains(_searchTerm.toLowerCase()) ==
                        false &&
                    profileData.email
                            ?.toLowerCase()
                            .contains(_searchTerm.toLowerCase()) ==
                        false) {
                  setState(() {
                    if (_filteredCount > 0) {
                      _filteredCount--;
                    }
                  });
                  return const SizedBox.shrink();
                }
                setState(() {
                  if (_filteredCount < members.length) {
                    _filteredCount++;
                  }
                });
                return ListTile(
                  onTap: () {
                    widget.onSelected(role.key);
                    Navigator.of(context).pop();
                  },
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundImage: profileData.photoURL?.isNotEmpty == true
                        ? NetworkImage(profileData.photoURL!)
                        : null,
                    child: profileData.photoURL == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(profileData.displayName ?? 'No name'),
                  subtitle: Text(profileData.email ?? 'No email'),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => const ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  child: Icon(Icons.error),
                ),
                title: Text('Error loading user data'),
              ),
            );
          }),
        ],
      ),
    );
  }
}
