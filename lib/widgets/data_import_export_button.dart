import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:smart_collab/screens/import_screen.dart';
import 'package:smart_collab/services/auth_controller.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/services/team_controller.dart';

class DataImportExportButton extends ConsumerStatefulWidget {
  const DataImportExportButton({super.key, required this.teamId});
  final String teamId;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DataImportExportButtonState();
}

class _DataImportExportButtonState
    extends ConsumerState<DataImportExportButton> {
  bool _isExporting = false;
  bool _isOpenIssues = true;
  late IssueController _issueController;
  late TeamsController _teamsController;
  @override
  void initState() {
    super.initState();
    _issueController = ref.read(issueProvider(widget.teamId).notifier);
    _teamsController = ref.read(teamsProvider.notifier);
  }

  Future<void> _confirimExportType(BuildContext context) async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Export Data'),
              content: Wrap(
                children: [
                  const Text('Select data to export:'),
                  CheckboxListTile(
                      value: _isOpenIssues,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _isOpenIssues = value;
                          });
                        }
                      },
                      title: const Text('All open issues'),
                      subtitle: const Text('Export all open issues data')),
                  CheckboxListTile(
                      value: !_isOpenIssues,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _isOpenIssues = !value;
                          });
                        }
                      },
                      title: const Text('Closed issues'),
                      subtitle: const Text('Export only closed issues data')),
                ],
              ),
              actions: _isExporting
                  ? [
                      const Center(child: CircularProgressIndicator()),
                    ]
                  : [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await _exportData(_isOpenIssues, setState);
                          // Navigator.pop(context);
                          setState(() {
                            _isExporting = false;
                          });
                        },
                        child: const Text('Export'),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportData(bool isOpen, Function setState) async {
    setState(() {
      _isExporting = true;
    });
    try {
      final issues = await _issueController.fetchIssuesByIsOpen(isOpen);
      final teamMembers = (await _teamsController.fetchTeamMembers(
        widget.teamId,
      ));
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
      // team member map
      final memberMap = teamMembers.fold<Map<String, SmartCollabUser>>(
          <String, SmartCollabUser>{}, (map, member) {
        map[member.uid!] = member;
        return map;
      });
      String csv =
          'isClosed|id|title|description|deadline|tags|created at|updated at|last updated by|creator|creater\'s email\n'
              .replaceAll('|', ',');
      csv += issues.map((issue) {
        final user = memberMap[issue.roles.entries
            .where((entry) {
              return entry.value == 'owner';
            })
            .firstOrNull
            ?.key];
        final lastUpdatedByUsername =
            memberMap[issue.lastUpdatedBy]?.displayName;
        return '${issue.isClosed}|${issue.id}|"${issue.title}"|"${issue.description}"|${issue.deadline}|"${issue.tags.join(',')}"|${issue.createdAt}|${issue.updatedAt}|$lastUpdatedByUsername|"${user?.displayName}"|${user?.email}'
            .replaceAll('|', ',');
      }).join('\n');
      List<int> encodedCsv = utf8.encode(csv);
      Uint8List csvBytesList = Uint8List.fromList(encodedCsv);
      final String fileName =
          'smart_collab_${DateTime.now().toIso8601String()}.csv';
      String path = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: csvBytesList,
        ext: 'csv',
        mimeType: MimeType.csv,
      );
      print('File saved at $path');
      await OpenFile.open(path);
    } catch (e, stackTrace) {
      print('Error exporting data: $e, $stackTrace');
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'export') {
          _confirimExportType(context);
        } else if (value == 'import') {
          // Import
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return ImportScreeen(
                  teamId: widget.teamId,
                );
              },
            ),
          );
        }
      },
      itemBuilder: (context) {
        return [
          const PopupMenuItem(
            value: 'export',
            child: Row(
              children: [
                Icon(Icons.file_download),
                SizedBox(width: 8),
                Text('Export'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'import',
            child: Row(
              children: [
                Icon(Icons.file_upload),
                SizedBox(width: 8),
                Text('Import'),
              ],
            ),
          ),
        ];
      },
    );
  }
}
