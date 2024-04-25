import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:smart_collab/services/file_controller.dart';
import 'package:smart_collab/services/issue_controller.dart';
import 'package:smart_collab/widgets/confirm_dialog.dart';
import 'package:smart_collab/widgets/title_text.dart';

import 'status_info_chip.dart';

class Attachments extends ConsumerStatefulWidget {
  const Attachments({
    super.key,
    required this.teamId,
    required this.issueId,
  });
  final String teamId;
  final String issueId;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AttachmentsState();
}

class _AttachmentsState extends ConsumerState<Attachments> {
  final List<File> _files = [];
  void _filePicker() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        File file = File(result.files.single.path!);
        setState(() {
          _files.add(file);
        });
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }

  void _uploadFiles() async {
    final validFiles = _files.where((file) => !isMoreThan3MB(file)).toList();
    // upload files
    await ref
        .read(issueProvider(widget.teamId).notifier)
        .uploadFiles(validFiles, widget.issueId);
    // clear files
    setState(() {
      _files.clear();
    });
    Navigator.pop(context);
  }

  void _deleteFile(FileItem fileItem) async {
    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        confirmText: 'Delete',
        title: 'Delete File',
        content: 'Are you sure you want to delete this file?',
        onConfirm: () {
          ref
              .read(issueProvider(widget.teamId).notifier)
              .removeFile(fileItem, widget.issueId);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialFiles = ref
            .watch(issueProvider(widget.teamId)
                .select((value) => value.issueMap[widget.issueId]))
            ?.files ??
        [];
    final totalFileCount = _files.where((file) => !isMoreThan3MB(file)).length +
        initialFiles.length;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const TitleText('Files'),
              if (totalFileCount < 3)
                IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      _filePicker();
                    })
            ],
          ),
          if (_files.length + initialFiles.length == 0)
            const Center(child: Text('No files attached')),
          Wrap(
            runSpacing: 8,
            children: [
              if (totalFileCount == 3)
                const StatusInfoChip(
                    status: 'You can upload up to 3 files', color: Colors.blue),
            ],
          ),
          Column(
            children: [
              ...initialFiles.map((file) => ListTile(
                  contentPadding: const EdgeInsets.all(0),
                  leading: const Icon(Icons.attach_file),
                  title: Wrap(
                    children: [
                      Text(file.fileName),
                    ],
                  ),
                  subtitle: Text(normalizeFileSize(file.size)),
                  onTap: () {
                    OpenFile.open(file.fileName);
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle),
                    onPressed: () {
                      _deleteFile(file);
                    },
                  ))),
              ..._files.map((file) {
                final isTooLarge = isMoreThan3MB(file);
                final fileName = getFileName(file);
                return ListTile(
                  contentPadding: const EdgeInsets.all(0),
                  leading: isTooLarge
                      ? const Icon(Icons.error, color: Colors.red)
                      : const Icon(Icons.attach_file),
                  title: Wrap(
                    children: [
                      Text(
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          fileName, // if more than three mb than show strike
                          style: TextStyle(
                              decoration: isTooLarge
                                  ? TextDecoration.lineThrough
                                  : null)),
                    ],
                  ),
                  // show file size in subtitle
                  subtitle: Wrap(
                    children: [
                      Text(
                          getFileSize(file), // if more than 3 MB show red color
                          style:
                              TextStyle(color: isTooLarge ? Colors.red : null)),
                      if (isTooLarge)
                        const Text(' (more than 3 MB)',
                            style: TextStyle(color: Colors.red)),
                      if (!isTooLarge)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: const StatusInfoChip(
                              isSmall: true,
                              status: 'New',
                              color: Colors.green),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle),
                    onPressed: () {
                      setState(() {
                        _files.remove(file);
                      });
                    },
                  ),
                  onTap: () {
                    OpenFile.open(file.path);
                  },
                );
              })
            ],
          ),

          // upload button
          if (_files.where((file) => !isMoreThan3MB(file)).isNotEmpty)
            ElevatedButton(
              onPressed: () {
                // upload files
                showDialog(
                  context: context,
                  builder: (context) {
                    return ConfirmDialog(
                      confirmText: 'Upload',
                      title: 'Upload Files',
                      content:
                          'Are you sure you want to upload ${totalFileCount - initialFiles.length} files?',
                      onConfirm: () {
                        _uploadFiles();
                      },
                    );
                  },
                );
              },
              child: const Text('Save'),
            )
        ],
      ),
    );
  }
}

// get file size in KB function
double getFileSizeInKB(File file) {
  double fileSizeInKB = file.lengthSync() / 1024;
  return double.parse(fileSizeInKB.toStringAsFixed(2));
}

String getFileSize(File file) {
  double fileSizeInKB = file.lengthSync() / 1024;
  if (fileSizeInKB < 1024) {
    return '${fileSizeInKB.toStringAsFixed(2)} KB';
  } else {
    double fileSizeInMB = fileSizeInKB / 1024;
    return '${fileSizeInMB.toStringAsFixed(2)} MB';
  }
}

// is more than 3 MB
bool isMoreThan3MB(File file) {
  return getFileSizeInKB(file) > 3072;
}

// get file name
String getFileName(File file) {
  return file.path.split('/').last;
}

// normalize file size
String normalizeFileSize(int fileSize) {
  if (fileSize < 1024) {
    return '$fileSize KB';
  } else {
    double fileSizeInMB = fileSize / 1024;
    return '${fileSizeInMB.toStringAsFixed(2)} MB';
  }
}
