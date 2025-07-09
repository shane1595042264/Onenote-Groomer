import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/file_drop_zone.dart';
import '../widgets/prompt_editor.dart';
import '../widgets/processing_status.dart';
import '../services/onenote_service.dart' as onenote;
import '../services/ollama_service.dart' as ollama;
import '../services/excel_service.dart' as excel;
import '../models/excel_template.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _oneNoteFilePath;
  String? _excelTemplatePath;
  String? _outputFilePath;
  ExcelTemplate? _excelTemplate;
  String _customPrompt = '''
Extract business data from OneNote pages. Focus on:
- Company/Client name
- Date and time information
- Key decisions or actions
- Financial information
- Contact details
- Status or outcomes
- Any follow-up items

Structure the data appropriately for Excel export.
''';

  bool _isProcessing = false;
  String _statusMessage = '';
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('OneNote to Excel Converter'),
        backgroundColor: const Color(0xFF2D2D30),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1E1E), Color(0xFF2D2D30)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FileDropZone(
                      title: 'OneNote File',
                      acceptedExtensions: const ['.one', '.onepkg'],
                      onFileDropped: (path) {
                        setState(() {
                          _oneNoteFilePath = path;
                        });
                      },
                      filePath: _oneNoteFilePath,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FileDropZone(
                      title: 'Excel Template (Optional)',
                      acceptedExtensions: const ['.xlsx', '.xls'],
                      onFileDropped: (path) async {
                        setState(() {
                          _excelTemplatePath = path;
                        });
                        await _loadExcelTemplate(path);
                      },
                      filePath: _excelTemplatePath,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: PromptEditor(
                  initialPrompt: _customPrompt,
                  onPromptChanged: (prompt) {
                    _customPrompt = prompt;
                  },
                ),
              ),
              const SizedBox(height: 24),
              if (_isProcessing)
                ProcessingStatus(
                  message: _statusMessage,
                  progress: _progress,
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _oneNoteFilePath != null && !_isProcessing
                    ? _processFile
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: const Color(0xFF9B59B6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Process OneNote File',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              // Action buttons row
              if (_outputFilePath != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openExcelFile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF27AE60),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open Excel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveAsExcelFile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF3498DB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.save_as),
                        label: const Text('Save As'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadExcelTemplate(String path) async {
    final excelService = context.read<excel.ExcelService>();
    final template = await excelService.readTemplateFile(path);
    setState(() {
      _excelTemplate = template;
    });
  }

  Future<void> _processFile() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Starting processing...';
      _progress = 0.1;
    });

    try {
      final oneNoteService = context.read<onenote.OneNoteService>();
      final ollamaService = context.read<ollama.OllamaService>();
      final excelService = context.read<excel.ExcelService>();

      setState(() {
        _statusMessage = 'Reading OneNote file...';
        _progress = 0.2;
      });

      final pages = await oneNoteService.readOneNoteFile(_oneNoteFilePath!);

      setState(() {
        _statusMessage = 'Processing ${pages.length} pages...';
        _progress = 0.3;
      });

      final extractedData = <Map<String, dynamic>>[];
      for (int i = 0; i < pages.length; i++) {
        setState(() {
          _statusMessage = 'Processing page ${i + 1} of ${pages.length}...';
          _progress = 0.3 + (0.5 * (i / pages.length));
        });

        final processedData = await ollamaService.processPages(
          [pages[i]],
          _excelTemplate,
          _customPrompt,
        );

        final data = <String, dynamic>{};
        if (processedData.isNotEmpty) {
          data.addAll(Map<String, dynamic>.from(processedData.first));
        }
        
        // Only add technical columns if explicitly requested in the prompt
        if (_customPrompt.toLowerCase().contains('page title') || 
            _customPrompt.toLowerCase().contains('pagetitle') ||
            _customPrompt.toLowerCase().contains('_pagetitle')) {
          data['_pageTitle'] = pages[i].title;
        }
        
        if (_customPrompt.toLowerCase().contains('section') || 
            _customPrompt.toLowerCase().contains('_section')) {
          data['_section'] = pages[i].parentSection;
        }
        
        if (_customPrompt.toLowerCase().contains('created date') || 
            _customPrompt.toLowerCase().contains('createddate') ||
            _customPrompt.toLowerCase().contains('_createddate')) {
          data['_createdDate'] = pages[i].createdTime.toIso8601String();
        }

        extractedData.add(data);
      }

      setState(() {
        _statusMessage = 'Writing Excel file...';
        _progress = 0.9;
      });

      final outputPath = _oneNoteFilePath!
          .replaceAll(RegExp(r'\.(one|onepkg)$'), '_extracted.xlsx');

      await excelService.writeExcelFile(
        outputPath,
        extractedData,
        _excelTemplate?.columns,
      );

      setState(() {
        _statusMessage = 'Complete! File saved to: $outputPath';
        _progress = 1.0;
        _outputFilePath = outputPath;  // Store the output file path
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success!'),
          content:
              Text('Data extracted successfully!\n\nOutput file: $outputPath'),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _openExcelFile();
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Excel'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _saveAsExcelFile();
              },
              icon: const Icon(Icons.save_as),
              label: const Text('Save As'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _openExcelFile() async {
    if (_outputFilePath == null) return;
    
    try {
      final uri = Uri.file(_outputFilePath!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback: Show message with file path
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cannot Open File'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Unable to open the Excel file automatically.'),
                  const SizedBox(height: 8),
                  const Text('File location:'),
                  const SizedBox(height: 4),
                  SelectableText(
                    _outputFilePath!,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Error opening file: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _saveAsExcelFile() async {
    if (_outputFilePath == null) return;
    
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Excel File As',
        fileName: 'extracted_data.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      
      if (result != null) {
        // Copy the file to the new location
        final sourceFile = File(_outputFilePath!);
        
        if (await sourceFile.exists()) {
          await sourceFile.copy(result);
          
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Success!'),
                content: Text('File saved successfully to:\n$result'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        } else {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Error'),
                content: const Text('Source file not found.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Error saving file: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
