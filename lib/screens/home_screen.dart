import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/auth_controller.dart';
import 'package:smart_collab/widgets/confirm_dialog.dart';
import 'package:smart_collab/widgets/profile.dart';
import 'package:smart_collab/widgets/teams.dart';

import '../widgets/add_or_edit_team_sheet.dart';
import '../widgets/title_text.dart';

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
  @override
  void initState() {
    super.initState();
    _isDarkModel = widget.isDarkMode;
  }

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
    final username = ref.watch(authControllerProvider).user?.displayName;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            isScrollControlled: true,
            // show handle
            enableDrag: true,
            showDragHandle: true,
            context: context,
            builder: (context) => const AddTeamSheet(
              addOrEdit: AddorEdit.add,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ListView(
        children: [
          const SizedBox(
            height: 32,
          ),
          // welcome text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TitleText('Welcome back, \n$username!'),
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: StatefulBuilder(
                      builder: (context, setState) => ListTile(
                        leading: const Icon(Icons.brightness_2),
                        title: Text(_isDarkModel ? 'Light Mode' : 'Dark Mode'),
                        onTap: () {
                          setState(() {
                            widget.toggleTheme(!_isDarkModel);
                            _isDarkModel = !_isDarkModel;
                          });
                        },
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Logout'),
                      onTap: _logout,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // show profile information
          const SizedBox(height: 20),
          const Profile(),
          const Divider(),
          const Teams(),
        ],
      ),
    );
  }
}
