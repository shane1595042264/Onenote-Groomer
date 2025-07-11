// Quick test to verify file drop functionality
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Drop Test',
      home: FileDropTest(),
    );
  }
}

class FileDropTest extends StatefulWidget {
  @override
  _FileDropTestState createState() => _FileDropTestState();
}

class _FileDropTestState extends State<FileDropTest> {
  String? _droppedFile;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('File Drop Test')),
      body: Center(
        child: DropTarget(
          onDragDone: (detail) {
            print('File dropped: ${detail.files.length} files');
            if (detail.files.isNotEmpty) {
              final file = detail.files.first;
              print('File path: ${file.path}');
              setState(() {
                _droppedFile = file.path;
              });
            }
          },
          onDragEntered: (detail) {
            print('Drag entered');
            setState(() => _isDragging = true);
          },
          onDragExited: (detail) {
            print('Drag exited');
            setState(() => _isDragging = false);
          },
          child: Container(
            width: 300,
            height: 200,
            decoration: BoxDecoration(
              color: _isDragging ? Colors.blue.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
              border: Border.all(
                color: _isDragging ? Colors.blue : Colors.grey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _droppedFile != null ? Icons.check_circle : Icons.cloud_upload,
                    size: 48,
                    color: _droppedFile != null ? Colors.green : Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text(
                    _droppedFile != null 
                      ? 'File: ${_droppedFile!.split('\\').last}'
                      : 'Drop Excel file here',
                    textAlign: TextAlign.center,
                  ),
                  if (_droppedFile != null) ...[
                    SizedBox(height: 8),
                    Text(
                      'Full path: $_droppedFile',
                      style: TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
