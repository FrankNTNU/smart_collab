import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/auth_controller.dart';
import 'package:smart_collab/widgets/confirm_dialog.dart';
import 'package:smart_collab/widgets/profile.dart';
import 'package:smart_collab/widgets/teams.dart';

import '../widgets/add_team_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  void _logout() {
    // confirm logout
    showDialog(
      context: context,
      builder: (context) {
        return ConfirmDialog(
          title: 'Logout',
          content: 'Are you sure you want to logout?',
          onConfirm: () {
            ref.read(authControllerProvider.notifier).signOut();
          },
          confirmText: 'Logout',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          // logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // show profile information
          SizedBox(height: 20),
          Profile(),
          Expanded(child: Teams()),
          AddTeamButton(),
        ],
      ),
    );
  }
}
