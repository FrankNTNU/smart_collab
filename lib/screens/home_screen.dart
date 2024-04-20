import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/main.dart';
import 'package:smart_collab/services/auth_controller.dart';
import 'package:smart_collab/widgets/confirm_dialog.dart';
import 'package:smart_collab/widgets/profile.dart';
import 'package:smart_collab/widgets/teams.dart';

import '../widgets/add_or_edit_team_sheet.dart';

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
    final isDarkMode = ref.watch(isDarkModeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          // dark mode icon
          IconButton(
              onPressed: () {
                ref.read(isDarkModeProvider.notifier).state = !isDarkMode;
              },
              icon: const Icon(Icons.brightness_2)),
          // logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            isScrollControlled: true,
            // show handle
            enableDrag: true,
            showDragHandle: true,
            context: context,
            builder: (context) => Padding(
              padding: MediaQuery.of(context)
                  .viewInsets
                  .copyWith(left: 16, right: 16),
              child: const AddTeamSheet(
                addOrEdit: AddorEdit.add,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ListView(
        children: const [
          // show profile information
          SizedBox(height: 20),
          Profile(),
          Divider(),
          Teams(),
        ],
      ),
    );
  }
}
