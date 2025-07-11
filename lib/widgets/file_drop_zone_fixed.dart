import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';

class FileDropZone extends StatefulWidget {
  final String title;
  final List<String> acceptedExtensions;
  final Function(String) onFileDropped;
  final VoidCallback? onFileCancelled;
  final String? filePath;

  const FileDropZone({
    super.key,
    required this.title,
    required this.acceptedExtensions,
    required this.onFileDropped,
    this.onFileCancelled,
    this.filePath,
  });

  @override
  _FileDropZoneState createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone> {
  bool _isDragging = false;
  bool _isHovering = false;
  bool _isCancelHovering = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) {
        print('File dropped: ${detail.files.length} files'); // Debug log
        if (detail.files.isNotEmpty) {
          final file = detail.files.first;
          final extension = file.path.substring(file.path.lastIndexOf('.'));
          print('File extension: $extension, Accepted: ${widget.acceptedExtensions}'); // Debug log

          if (widget.acceptedExtensions.contains(extension.toLowerCase())) {
            print('File accepted, calling onFileDropped'); // Debug log
            widget.onFileDropped(file.path);
          } else {
            print('File rejected - wrong extension'); // Debug log
            // Show helpful error message for specific unsupported formats
            if (extension.toLowerCase() == '.xlsb') {
              _showUnsupportedFormatDialog('Excel Binary (.xlsb) files are not supported. Please convert your file to .xlsx format and try again.');
            } else {
              _showUnsupportedFormatDialog('File format $extension is not supported. Accepted formats: ${widget.acceptedExtensions.join(', ')}');
            }
          }
        }
      },
      onDragEntered: (detail) => setState(() => _isDragging = true),
      onDragExited: (detail) => setState(() => _isDragging = false),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _pickFile,
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 150,
                decoration: BoxDecoration(
                  color: widget.filePath != null 
                      ? Colors.green.withOpacity(_isHovering ? 0.15 : 0.1) 
                      : _isDragging 
                        ? const Color(0xFF3E3E42) 
                        : _isHovering
                          ? const Color(0xFF363636)
                          : const Color(0xFF2D2D30),
                  border: Border.all(
                    color: widget.filePath != null
                        ? Colors.green
                        : _isDragging 
                          ? const Color(0xFF9B59B6) 
                          : _isHovering
                            ? const Color(0xFF555555)
                            : const Color(0xFF3E3E42),
                    width: widget.filePath != null ? 3 : 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isHovering ? [
                    BoxShadow(
                      color: widget.filePath != null 
                          ? Colors.green.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
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
                      Text(widget.title, style: TextStyle(
                        color: widget.filePath != null ? Colors.green[300] : Colors.white,
                        fontWeight: widget.filePath != null ? FontWeight.bold : FontWeight.normal,
                      )),
                      Text(
                        widget.filePath != null
                            ? '✓ File loaded successfully'
                            : 'Drag & drop or click',
                        style: TextStyle(
                          color: widget.filePath != null ? Colors.green[400] : Colors.grey,
                          fontWeight: widget.filePath != null ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      // Show file name if available
                      if (widget.filePath != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            widget.filePath!.split('\\').last,
                            style: TextStyle(
                              color: Colors.green[300],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Cancel button (X) in top-right corner when file is loaded
              if (widget.filePath != null && widget.onFileCancelled != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isCancelHovering = true),
                    onExit: (_) => setState(() => _isCancelHovering = false),
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        widget.onFileCancelled!();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _isCancelHovering ? 28 : 24,
                        height: _isCancelHovering ? 28 : 24,
                        decoration: BoxDecoration(
                          color: _isCancelHovering 
                              ? Colors.red.withOpacity(1.0)
                              : Colors.red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(_isCancelHovering ? 14 : 12),
                          boxShadow: _isCancelHovering ? [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              spreadRadius: 2,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: _isCancelHovering ? 18 : 16,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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

  void _showUnsupportedFormatDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsupported File Format'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
