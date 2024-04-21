import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_collab/screens/team_screen.dart';
//import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_collab/services/auth_controller.dart';

import '../services/team_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Function(bool) toggleTheme;
  final bool isDarkMode;
  const HomeScreen(
      {super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isDarkModel = false;
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
    _isDarkModel = widget.isDarkMode;
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
    return TeamScreen(
      team: _selectedTeam,
      onTeamSelected: (team) {
        setState(() {
          _selectedTeam = team;
          storeTeamIdToSharedPrefs(team.id!);
        });
      },
      isDarkMode: _isDarkModel,
      toggleTheme: (isDarkMode) {
        setState(() {
          _isDarkModel = isDarkMode;
          widget.toggleTheme(isDarkMode);
        });
      },
    );
  }
}
