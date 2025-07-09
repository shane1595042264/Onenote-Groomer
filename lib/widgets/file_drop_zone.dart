import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';

class FileDropZone extends StatefulWidget {
  final String title;
  final List<String> acceptedExtensions;
  final Function(String) onFileDropped;
  final String? filePath;

  const FileDropZone({
    super.key,
    required this.title,
    required this.acceptedExtensions,
    required this.onFileDropped,
    this.filePath,
  });

  @override
  _FileDropZoneState createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) {
        if (detail.files.isNotEmpty) {
          final file = detail.files.first;
          final extension = file.path.substring(file.path.lastIndexOf('.'));

          if (widget.acceptedExtensions.contains(extension.toLowerCase())) {
            widget.onFileDropped(file.path);
          }
        }
      },
      onDragEntered: (detail) => setState(() => _isDragging = true),
      onDragExited: (detail) => setState(() => _isDragging = false),
      child: GestureDetector(
        onTap: _pickFile,
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            color: _isDragging ? const Color(0xFF3E3E42) : const Color(0xFF2D2D30),
            border: Border.all(
              color: _isDragging ? const Color(0xFF9B59B6) : const Color(0xFF3E3E42),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.filePath != null
                      ? Icons.check_circle
                      : Icons.cloud_upload,
                  size: 48,
                  color: widget.filePath != null
                      ? Colors.green
                      : const Color(0xFF9B59B6),
                ),
                const SizedBox(height: 8),
                Text(widget.title, style: const TextStyle(color: Colors.white)),
                Text(
                  widget.filePath != null
                      ? 'File loaded'
                      : 'Drag & drop or click',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions:
          widget.acceptedExtensions.map((e) => e.substring(1)).toList(),
    );

    if (result != null && result.files.single.path != null) {
      widget.onFileDropped(result.files.single.path!);
    }
  }
}
