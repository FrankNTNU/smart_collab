import 'package:smart_collab/services/auth_controller.dart';

class FileItem {
  final String fileName;
  final String url;
  final int size;
  // ctor
  FileItem({required this.fileName, required this.url, this.size = 0});
  // copyWith
  FileItem copyWith({
    String? fileName,
    String? url,
    int? size,
  }) {
    return FileItem(
      fileName: fileName ?? this.fileName,
      url: url ?? this.url,
      size: size ?? this.size,
    );
  }
}

class FilesState {
  final List<FileItem> files;
  final ApiStatus status;
  final String teamId;
  final String issueId;
  // ctor
  FilesState(
      {required this.files,
      this.status = ApiStatus.idle,
      required this.teamId,
      required this.issueId});
  // copyWith
  FilesState copyWith({
    List<FileItem>? files,
    ApiStatus? status,
    String? teamId,
    String? issueId,
  }) {
    return FilesState(
      files: files ?? this.files,
      status: status ?? this.status,
      teamId: teamId ?? this.teamId,
      issueId: issueId ?? this.issueId,
    );
  }
}

typedef FileControllerParam = (
  String teamId,
  String issueId,
);

