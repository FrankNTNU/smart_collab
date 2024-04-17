import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/team_controller.dart';

import '../services/auth_controller.dart';

class InviteToTeam extends ConsumerStatefulWidget {
  final String teamId;
  const InviteToTeam({super.key, required this.teamId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SetAdminSheetState();
}

class _SetAdminSheetState extends ConsumerState<InviteToTeam> {
  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration.zero,
      () {
        // empty the error message
        ref.read(teamsProvider.notifier).clearErrorMessage();
      },
    );
  }

  // formkey
  final _formKey = GlobalKey<FormState>();
  String _enteredAdminEmail = '';
  void _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }
    // save form
    _formKey.currentState!.save();
    // call set admin
    ref
        .read(teamsProvider.notifier)
        .setAsMemeber(email: _enteredAdminEmail, teamId: widget.teamId);
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage =
        ref.watch(teamsProvider.select((value) => value.errorMessage));
    ref.listen(teamsProvider.select((value) => value.apiStatus), (prev, next) {
      if (next == ApiStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User added successfully'),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Failed to add user'),
          ),
        );
      }
    });
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // title
        const Row(
          children: [
            Text('Invite user to team', style: TextStyle(fontSize: 20)),
            Spacer(),
            CloseButton()
          ],
        ),
        Form(
          key: _formKey,
          child: TextFormField(
            // email field properties
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Enter User\'s Email',
              errorText: errorMessage,
              
            ),
            onChanged: (value) {
              setState(() {
                _enteredAdminEmail = value;
              });
            },

            validator: (value) =>
                // validate email input
                value!.isEmpty
                    ? 'Please enter an email'
                    : value.contains('@')
                        ? null
                        : 'Please enter a valid email',
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Invite user'),
        ),
      ],
    );
  }
}
