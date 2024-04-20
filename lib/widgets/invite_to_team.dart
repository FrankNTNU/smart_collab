import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_collab/services/activity_controller.dart';
import 'package:smart_collab/services/profile_controller.dart';
import 'package:smart_collab/services/team_controller.dart';

import '../services/auth_controller.dart';
import 'grey_description.dart';
import 'title_text.dart';

class InviteToTeam extends ConsumerStatefulWidget {
  final String teamId;
  const InviteToTeam({super.key, required this.teamId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SetAdminSheetState();
}

class _SetAdminSheetState extends ConsumerState<InviteToTeam> {
  // email text editing controller
  final _emailController = TextEditingController();
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
    final uid = await ref
        .read(teamsProvider.notifier)
        .setAsMemeber(email: _enteredAdminEmail, teamId: widget.teamId);
    if (uid == null || uid.isEmpty) {
      return;
    }
    // get profile from email
    final profile =
        await ref.read(profileFromEmailProvider(_enteredAdminEmail).future);
    final currentUsername = ref.watch(authControllerProvider).user!.displayName;
    final message = '$currentUsername added ${profile.displayName} to a team';
    // log this acitivty
    ref.read(activityProvider(widget.teamId).notifier).addActivity(
          message: message,
          recipientUid: profile.uid!,
          activityType: ActivityyType.addToTeam,
          teamId: widget.teamId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage =
        ref.watch(teamsProvider.select((value) => value.errorMessage));
    ref.listen(teamsProvider.select((value) => value.apiStatus), (prev, next) {
      if (next == ApiStatus.success) {
        // close currently showing the snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User added successfully'),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Failed to add user'),
          ),
        );
      }
    });
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title
          const Row(
            children: [
              TitleText('Invite user to team'),
              Spacer(),
              CloseButton()
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _emailController,
                    // email field properties
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Enter User\'s Email',
                      errorText: errorMessage,
                      suffix: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _emailController.clear();
                        },
                      ),
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
              ),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Invite user'),
              ),
            ],
          ),
          TextButton.icon(
            label: const Text('Or show them the QR code'),
            onPressed: () {
              // open qr code scanner
              showModalBottomSheet(
                isScrollControlled: true,
                enableDrag: true,
                showDragHandle: true,
                context: context,
                builder: (context) {
                  final tenMinutesFromNow = DateTime.now()
                      .add(const Duration(minutes: 10))
                      .toString()
                      .substring(0, 16);
                  return Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.75,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: TitleText(
                                    'Scan this QR code to join the team')),
                            CloseButton()
                          ],
                        ),
                        // a small grey description
                        GreyDescription(
                            'This QR code is only valid for 10 minutes. Expiring at $tenMinutesFromNow'),
                        Expanded(
                          child: Align(
                            // center
                            alignment: Alignment.center,
                            child: QrImageView(
                                data: '${widget.teamId}_$tenMinutesFromNow',
                                version: QrVersions.auto,
                                backgroundColor: Colors.white,
                                size:
                                    MediaQuery.of(context).size.height * 0.35),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            icon: const Icon(Icons.qr_code),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
