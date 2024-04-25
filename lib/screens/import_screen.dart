import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:smart_collab/services/auth_controller.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/services/team_controller.dart';
import 'package:smart_collab/widgets/confirm_dialog.dart';
import 'package:smart_collab/widgets/grey_description.dart';
import 'package:smart_collab/widgets/status_info_chip.dart';
import 'package:smart_collab/widgets/title_text.dart';

class ImportedData {
  final String title;
  final String description;
  final DateTime deadline;
  final List<String> tags;
  final bool closesWhenExpired;
  ImportedData({
    required this.title,
    required this.description,
    required this.deadline,
    required this.tags,
    required this.closesWhenExpired,
  });
}

class ImportScreeen extends ConsumerStatefulWidget {
  const ImportScreeen({super.key, required this.teamId});
  final String teamId;
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ImportScreeenState();
}

class _ImportScreeenState extends ConsumerState<ImportScreeen> {
  int _stepIndex = 0;
  bool _viewFullPreview = false;
  final List<ImportedData> _importedData = [];
  String? errorMessage;
  String _selectedFileName = '';

  void _chooseFile() async {
    try {
      setState(() {
        errorMessage = null;
      });
      // choose file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        setState(() {
          _selectedFileName = file.path.split('/').last;
        });
        // read from this csv file
        String csv = await file.readAsString();
        print(csv);
        // parse csv
        List<String> lines = LineSplitter.split(csv).toList();
        // remove header
        lines.removeAt(0);
        List<ImportedData> importedData = [];
        for (String line in lines) {
          List<String> columns = line.split(',');
          if (columns.length != 5) {
            setState(() {
              errorMessage =
                  'Invalid number of columns. Detected ${columns.length} columns. Expected 5';
            });
            return;
          }
          String title = columns[0];
          String description = columns[1];
          if (DateTime.tryParse(columns[2]) == null) {
            setState(() {
              errorMessage =
                  'Invalid deadline date. Input: ${columns[2]}. Expected format: yyyy-MM-dd';
            });
            return;
          }
          DateTime deadline = DateTime.parse(columns[2]);
          List<String> tags = columns[3].split('/');
          bool closesWhenExpired = columns[4] == 'true';
          importedData.add(ImportedData(
            title: title,
            description: description,
            deadline: deadline,
            tags: tags,
            closesWhenExpired: closesWhenExpired,
          ));
        }
        setState(() {
          _importedData.clear();
          _importedData.addAll(importedData);
          _stepIndex++;
        });
      }
    } catch (e) {
      print('Error reading file: $e');
      // error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error reading file'),
        ),
      );
    }
  }

  void _downloadTemplate([bool isComplicatedExample = false]) async {
    String csv =
        'title*|description*|deadline* (yyyy-MM-dd)|tags (separated by /)|closes itself when expired? (true or false)\n'
            .replaceAll('|', ',');
    csv += 'Example issue 1,Description 1,2022-12-31,tag1/tag2,\n';
    if (isComplicatedExample) {
      csv += 'Example issue 2,Description 2,2022-12-31,tag1/tag2,true\n';
      csv += 'Example issue 3,Description 3,2022-12-31,tag1/tag2,false\n';
      csv += 'Example issue 4,Description 4,2022-12-31,tag1/tag2,true\n';
      // add 10 more lines
      for (int i = 5; i <= 14; i++) {
        csv += 'Example issue $i,Description $i,2022-12-31,tag1/tag2,true\n';
      }
    }
    List<int> encodedCsv = utf8.encode(csv);
    Uint8List csvBytesList = Uint8List.fromList(encodedCsv);
    const String fileName = 'smart_collab_upload_template.csv';
    String path = await FileSaver.instance.saveFile(
      name: fileName,
      bytes: csvBytesList,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
    print('File saved at $path');
    await OpenFile.open(path);
  }

  void _importData() async {
    try {
      await ref
          .read(issueProvider(widget.teamId).notifier)
          .importIssues(_importedData);
    } catch (e) {
      print('Error importing data: $e');
      // error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error importing data'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(issueProvider(widget.teamId).select((value) => value.apiStatus),
        (prev, curr) {
      print('Prev: $prev, Curr: $curr');
      final action = ref.read(issueProvider(widget.teamId)
          .select((value) => value.performedAction));
      print('Action: $action');
      if (prev == ApiStatus.loading &&
          curr == ApiStatus.success &&
          action == PerformedAction.bulkAdd) {
        // show snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data uploaded successfully'),
          ),
        );
        // pop
        Navigator.of(context).pop();
      }
    });
    final isBulkAdding = ref.watch(issueProvider(widget.teamId)
        .select((value) => value.apiStatus == ApiStatus.loading));
    print('isBulkAdding: $isBulkAdding');
    return PopScope(
      canPop: !isBulkAdding,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Import Screen'),
        ),
        body: Stepper(
          currentStep: _stepIndex,
          controlsBuilder: (context, details) => Row(
            children: [
              if (_stepIndex < 2)
                OutlinedButton(
                  onPressed: details.onStepContinue,
                  child: const Text('Next'),
                ),
              if (_stepIndex > 0)
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Back'),
                ),
            ],
          ),
          onStepCancel: () {
            if (_stepIndex > 0) {
              setState(() {
                _stepIndex--;
              });
            }
          },
          onStepContinue: () {
            if (_stepIndex < 2) {
              setState(() {
                _stepIndex++;
              });
            }
          },
          onStepTapped: (value) {
            setState(() {
              _stepIndex = value;
            });
          },
          steps: [
            Step(
              title: const Text('Download Template'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TitleText('Download the template and fill the data'),
                  const GreyDescription('Only columns with * are required'),
                  // red text
                  const Text(
                    'Note: Do not change the column headers',
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _downloadTemplate(true),
                    child: const Text('Download Template'),
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Choose a file'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TitleText('Choose a file to upload'),
                  const GreyDescription(
                      'Make sure the file is in CSV format and follows the template'),
                  if (errorMessage != null)
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  if (_selectedFileName.isNotEmpty)
                    Text('Selected file: $_selectedFileName'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      _chooseFile();
                    },
                    child: const Text('Select File'),
                  ),
                ],
              ),
            ),
            // preview
            Step(
              title: const Text('Preview before upload'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TitleText('Preview the data before importing'),
                  StatusInfoChip(
                      status:
                          '${_importedData.length} issue(s) detected from file:\n$_selectedFileName',
                      color: _importedData.isEmpty
                          ? Colors.grey
                          : Colors.green),
                  // show data
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      // make each column narrower
                      columnSpacing: 10,
                      columns: const [
                        DataColumn(label: Text('Title')),
                        DataColumn(label: Text('Description')),
                        DataColumn(label: Text('Deadline')),
                        DataColumn(label: Text('Tags')),
                        DataColumn(label: Text('Closes When Expired')),
                      ],
                      rows: _importedData
                          // if _viewFullPreview is false, show only 5 items
                          .take(_viewFullPreview ? _importedData.length : 5)
                          .map(
                            (data) => DataRow(
                              cells: [
                                DataCell(Text(data.title)),
                                DataCell(Text(data.description)),
                                DataCell(Text(
                                    data.deadline.toString().substring(0, 10))),
                                DataCell(Text(data.tags.join(','))),
                                DataCell(
                                    Text(data.closesWhenExpired.toString())),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  // show more button
                  if (_importedData.length > 5)
                    TextButton.icon(
                      icon: Icon(
                        _viewFullPreview
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        setState(() {
                          _viewFullPreview = !_viewFullPreview;
                        });
                      },
                      label: Text(
                        _viewFullPreview ? 'Show less' : 'Show more',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  if (isBulkAdding)
                    const Center(child: CircularProgressIndicator())
                  else
                    TextButton.icon(
                      onPressed: _importedData.isEmpty
                          ? null
                          : () {
                              showDialog(
                                context: context,
                                builder: (context) => ConfirmDialog(
                                  confirmText: 'Upload',
                                  title: 'Confirm Upload',
                                  content:
                                      'Are you sure you want to upload ${_importedData.length} issues?',
                                  onConfirm: () {
                                    _importData();
                                  },
                                ),
                              );
                            },
                      label: const Text('Upload'),
                      icon: const Icon(Icons.upload),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
