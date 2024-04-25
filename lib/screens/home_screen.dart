import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_collab/screens/team_screen.dart';
//import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/team_controller.dart';

class IsDarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    // get shared prefs
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    return isDarkMode;
  }

  void toggleTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', isDarkMode);
    state = AsyncValue.data(isDarkMode);
  }
}
final isDarkModeProvider = AsyncNotifierProvider<IsDarkModeNotifier, bool>(() {
  return IsDarkModeNotifier();
});
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen(
      {super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final bool _isDarkModel = false;
  Team? _selectedTeam;
  Future<void> storeTeamIdToSharedPrefs(String teamId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastVisitedTeamId', teamId);
  }

  Future<void> loadLastVisitedId() async {
    final prefs = await SharedPreferences.getInstance();
    final lastVisitedTeamId = prefs.getString('lastVisitedTeamId');
    if (lastVisitedTeamId != null) {
      final teams = ref.watch(teamsProvider.select(
        (value) => value.teams,
      ));
      final team =
          teams.where((team) => team.id == lastVisitedTeamId).firstOrNull;
      if (team != null) {
        setState(() {
          _selectedTeam = team;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration.zero,
      () async {
        await ref.read(teamsProvider.notifier).fetchTeams();
        await loadLastVisitedId();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Rebuilding home screen...');
    return TeamScreen(
      team: _selectedTeam,
      onTeamSelected: (team) {
        setState(() {
          _selectedTeam = team;
          storeTeamIdToSharedPrefs(team.id!);
        });
      },
    );
  }
}
