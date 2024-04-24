import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/widgets/data_import_export_button.dart';
import 'package:smart_collab/widgets/title_text.dart';
import 'package:cloud_functions/cloud_functions.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, required this.teamId});
  final String teamId;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;
  Future<void> _triggerAutoClosing() async {
    setState(() {
      _isLoading = true;
    });
    HttpsCallable callable = FirebaseFunctions.instance.httpsCallableFromUri(
        Uri.parse(
            'https://us-central1-smart-collab-fd262.cloudfunctions.net/manuallyCloseExpiredIssues'));
    try {
      var res = await callable.call();
      print('Auto close issues triggered: ${res.data}');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Auto close issues triggered'),
      ));
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error triggering auto close issues: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to trigger auto close issues'),
      ));
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const TitleText('Settings'),
              DataImportExportButton(teamId: widget.teamId),
            ],
          ),
        ),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          title: const Text('Trigger auto close issues'),
          leading: _isLoading
              ? const CircularProgressIndicator()
              : const Icon(Icons.timer),
          onTap: () async {
            await _triggerAutoClosing();
          },
        ),
     
      ],
    );
  }
}
