import 'package:flutter/material.dart';

import '../services/team_controller.dart';

class TeamScreen extends StatefulWidget {
  final Team team;
  const TeamScreen({super.key, required this.team});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team.name ?? ''),
      ),
      body: Center(
        child: Text(widget.team.description ?? ''),
      ),
    );
  }
}
