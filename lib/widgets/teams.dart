import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/screens/team.dart';

import '../services/auth_controller.dart';
import '../services/team_controller.dart';

class Teams extends ConsumerStatefulWidget {
  const Teams({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TeamsState();
}

class _TeamsState extends ConsumerState<Teams> {
  @override
  void initState() {
    super.initState();
    Future.delayed(
        Duration.zero, () => ref.read(teamsProvider.notifier).fetchTeams());
  }

  @override
  Widget build(BuildContext context) {
    final teams = ref.watch(teamsProvider.select(
      (value) => value.teams,
    ));
    final isLoading = ref.watch(teamsProvider.select(
      (value) => value.apiStatus == ApiStatus.loading,
    ));
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (teams.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No teams found'),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async =>
          await ref.read(teamsProvider.notifier).fetchTeams(),
      child: ListView.builder(
        itemCount: teams.length,
        itemBuilder: (context, index) {
          return InkWell(
            // long press to show bottom menu option
            onLongPress: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Edit'),
                        onTap: () {
                          // go to team screen
                          //Navigator.pushNamed(context, '/team', arguments: teams[index]);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeamScreen(
                                team: teams[index],
                              ),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete),
                        title: const Text('Delete'),
                        onTap: () {
                          //ref.read(teamsProvider.notifier).deleteTeam(teams[index]);
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Delete Team'),
                                content: const Text(
                                    'Are you sure you want to delete this team?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      ref.read(teamsProvider.notifier)
                                          .deleteTeam(teams[index].id!);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              width: MediaQuery.of(context).size.width * 0.6,
              child: Column(
                children: [
                  // large image
                  if (teams[index].imageUrl?.isNotEmpty == true)
                    ClipPath(
                      clipper: ShapeBorderClipper(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Image.network(
                        teams[index].imageUrl!,
                        height: 128,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      height: 128,
                      width: double.infinity,
                      // border radius
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.image),
                    ),
                  ListTile(
                    title: Text(teams[index].name ?? ''),
                    subtitle: Text(teams[index].description ?? ''),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
