import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'hoverable_button.dart';

class FileDropZone extends StatefulWidget {
  final String title;
  final List<String> acceptedExtensions;
  final Function(String) onFileDropped;
  final VoidCallback? onFileCancelled;
  final String? filePath;
  final bool isDisabled;
  final String? disabledReason;

  const FileDropZone({
    super.key,
    required this.title,
    required this.acceptedExtensions,
    required this.onFileDropped,
    this.onFileCancelled,
    this.filePath,
    this.isDisabled = false,
    this.disabledReason,
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
    final theme = Theme.of(context);
    
    // If disabled, show a disabled state with overlay
    if (widget.isDisabled) {
      return Stack(
        children: [
          // Disabled drop zone
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 150,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.block,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title, 
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.disabledReason ?? 'Disabled',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    
    return DropTarget(
      onDragDone: (detail) {
        if (widget.isDisabled) return; // Don't process if disabled
        
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
      onDragEntered: (detail) {
        if (!widget.isDisabled) setState(() => _isDragging = true);
      },
      onDragExited: (detail) {
        if (!widget.isDisabled) setState(() => _isDragging = false);
      },
      child: MouseRegion(
        onEnter: (_) {
          if (!widget.isDisabled) setState(() => _isHovering = true);
        },
        onExit: (_) {
          if (!widget.isDisabled) setState(() => _isHovering = false);
        },
        cursor: widget.isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.isDisabled ? null : _pickFile,
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 150,
                decoration: BoxDecoration(
                  color: widget.filePath != null 
                      ? Theme.of(context).colorScheme.tertiary.withOpacity(_isHovering ? 0.15 : 0.1) 
                      : _isDragging 
                        ? Theme.of(context).colorScheme.surfaceContainer
                        : _isHovering
                          ? Theme.of(context).colorScheme.surfaceContainerHighest
                          : Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: widget.filePath != null
                        ? Theme.of(context).colorScheme.tertiary
                        : _isDragging 
                          ? Theme.of(context).colorScheme.primary
                          : _isHovering
                            ? Theme.of(context).colorScheme.outline
                            : Theme.of(context).colorScheme.outlineVariant,
                    width: widget.filePath != null ? 3 : 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isHovering ? [
                    BoxShadow(
                      color: widget.filePath != null 
                          ? Theme.of(context).colorScheme.tertiary.withOpacity(0.3)
                          : Theme.of(context).colorScheme.primary.withOpacity(0.2),
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
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.title, 
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: widget.filePath != null 
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(context).colorScheme.onSurface,
                          fontWeight: widget.filePath != null ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.filePath != null
                            ? '✓ File loaded successfully'
                            : 'Drag & drop or click to browse',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: widget.filePath != null 
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: widget.filePath != null ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      // Show file name if available
                      if (widget.filePath != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.filePath!.split('\\').last,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.tertiary,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.error.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(_isCancelHovering ? 14 : 12),
                          boxShadow: _isCancelHovering ? [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.error.withOpacity(0.4),
                              spreadRadius: 2,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onError,
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
          HoverableTextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
