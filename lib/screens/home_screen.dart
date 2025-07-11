import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/file_drop_zone.dart';
import '../widgets/prompt_editor.dart';
import '../widgets/processing_status.dart';
import '../widgets/hoverable_button.dart';
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
  String? _excelInputFilePath;  // New: Excel file to process
  String? _excelTemplatePath;
  String? _outputFilePath;
  ExcelTemplate? _excelTemplate;
  Map<String, dynamic>? _excelInputData;  // New: Analyzed Excel data
  bool _isLoadingExcelInput = false;  // New: Loading state for Excel file
  
  // Hover states for containers
  bool _isHoveringOneNoteInfo = false;
  bool _isHoveringExcelInfo = false;
  bool _isHoveringExcelPreview = false;
  
  String _customPrompt = '''
Extract and restructure data focusing on:
- Company/Client name
- Date and time information
- Key decisions or actions
- Financial information
- Contact details
- Status or outcomes
- Any follow-up items

Map the existing columns to these requested fields.
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Input Files Section
              Text(
                'Input Files',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              // Mode Indicator
              if (_oneNoteFilePath != null || _excelInputFilePath != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _oneNoteFilePath != null ? Colors.blue.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _oneNoteFilePath != null ? Colors.blue.withOpacity(0.5) : Colors.green.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    _oneNoteFilePath != null ? '📄 OneNote Processing Mode' : '📊 Excel Processing Mode',
                    style: TextStyle(
                      color: _oneNoteFilePath != null ? Colors.blue[300] : Colors.green[300],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FileDropZone(
                      title: 'OneNote File',
                      acceptedExtensions: const ['.one', '.onepkg'],
                      onFileDropped: (path) {
                        setState(() {
                          _oneNoteFilePath = path;
                          _excelInputFilePath = null; // Clear Excel input when OneNote is selected
                          _excelInputData = null;
                        });
                      },
                      onFileCancelled: () {
                        setState(() {
                          _oneNoteFilePath = null;
                        });
                      },
                      filePath: _oneNoteFilePath,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'OR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FileDropZone(
                      title: 'Excel File to Process',
                      acceptedExtensions: const ['.xlsx', '.xls'],
                      onFileDropped: (path) async {
                        print('Excel file dropped: $path'); // Debug log
                        
                        // First, immediately update the UI to show the file is selected
                        setState(() {
                          _excelInputFilePath = path;
                          _oneNoteFilePath = null; // Clear OneNote when Excel is selected
                          _isLoadingExcelInput = true; // Show loading state
                        });
                        
                        // Force a brief UI update to show visual feedback
                        await Future.delayed(Duration(milliseconds: 100));
                        
                        // Then load the Excel data
                        await _loadExcelInput(path);
                      },
                      onFileCancelled: () {
                        setState(() {
                          _excelInputFilePath = null;
                          _excelInputData = null;
                          _isLoadingExcelInput = false;
                        });
                      },
                      filePath: _excelInputFilePath,
                    ),
                  ),
                ],
              ),
              
              // File Selection Feedback
              if (_oneNoteFilePath != null || _excelInputFilePath != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_oneNoteFilePath != null) 
                      Expanded(
                        child: MouseRegion(
                          onEnter: (_) => setState(() => _isHoveringOneNoteInfo = true),
                          onExit: (_) => setState(() => _isHoveringOneNoteInfo = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(_isHoveringOneNoteInfo ? 0.15 : 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(_isHoveringOneNoteInfo ? 0.5 : 0.3)),
                              boxShadow: _isHoveringOneNoteInfo ? [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📄 OneNote File Selected:',
                                style: TextStyle(
                                  color: Colors.blue[300],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _oneNoteFilePath!.split('\\').last,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        ),
                      )
                    else 
                      const Expanded(child: SizedBox()),
                    
                    if (_oneNoteFilePath != null && _excelInputFilePath != null)
                      const SizedBox(width: 16),
                    
                    if (_excelInputFilePath != null)
                      Expanded(
                        child: MouseRegion(
                          onEnter: (_) => setState(() => _isHoveringExcelInfo = true),
                          onExit: (_) => setState(() => _isHoveringExcelInfo = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(_isHoveringExcelInfo ? 0.15 : 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.withOpacity(_isHoveringExcelInfo ? 0.5 : 0.3)),
                              boxShadow: _isHoveringExcelInfo ? [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📊 Excel File Selected:',
                                style: TextStyle(
                                  color: Colors.green[300],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _excelInputFilePath!.split('\\').last,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_isLoadingExcelInput) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green[400]!),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Loading...',
                                      style: TextStyle(
                                        color: Colors.green[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else if (_excelInputData != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 12,
                                      color: Colors.green[400],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Ready to process!',
                                      style: TextStyle(
                                        color: Colors.green[400],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        ),
                      )
                    else 
                      const Expanded(child: SizedBox()),
                  ],
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Template Section (available for both modes)
              Text(
                _oneNoteFilePath != null 
                  ? 'Excel Template (Optional)' 
                  : _excelInputFilePath != null 
                    ? 'Excel Template (Optional) - Use for output structure'
                    : 'Excel Template (Optional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              FileDropZone(
                title: _oneNoteFilePath != null 
                  ? 'Excel Template - Structure for OneNote output'
                  : _excelInputFilePath != null 
                    ? 'Excel Template - Target structure for processed data'
                    : 'Excel Template',
                acceptedExtensions: const ['.xlsx', '.xls'],
                onFileDropped: (path) async {
                  setState(() {
                    _excelTemplatePath = path;
                  });
                  await _loadExcelTemplate(path);
                },
                onFileCancelled: () {
                  setState(() {
                    _excelTemplatePath = null;
                    _excelTemplate = null;
                  });
                },
                filePath: _excelTemplatePath,
              ),
              const SizedBox(height: 24),
              
              // Excel Data Preview (only show if Excel input is loaded)
              if (_excelInputData != null) ...[
                Text(
                  'Excel Data Preview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                MouseRegion(
                  onEnter: (_) => setState(() => _isHoveringExcelPreview = true),
                  onExit: (_) => setState(() => _isHoveringExcelPreview = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isHoveringExcelPreview ? const Color(0xFF454545) : const Color(0xFF3C3C3C),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _isHoveringExcelPreview ? Colors.white38 : Colors.white24),
                      boxShadow: _isHoveringExcelPreview ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'File: ${_excelInputData!['sheetName']}',
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rows: ${_excelInputData!['totalRows']}, Columns: ${_excelInputData!['columns']}',
                        style: const TextStyle(color: Colors.white54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Columns: ${(_excelInputData!['headers'] as List<String>).join(', ')}',
                        style: const TextStyle(color: Colors.white54),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Prompt Editor Section
              Text(
                'AI Processing Prompt',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 300,
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
              // Process Button
              HoverableButton(
                onPressed: (_oneNoteFilePath != null || _excelInputFilePath != null) && !_isProcessing
                    ? _processFile
                    : null,
                backgroundColor: const Color(0xFF9B59B6),
                hoverColor: const Color(0xFFB866D9),
                foregroundColor: Colors.white,
                hoverForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                borderRadius: BorderRadius.circular(12),
                elevation: 4,
                hoverElevation: 8,
                child: Text(
                  _isProcessing 
                    ? 'Processing...' 
                    : _excelInputFilePath != null 
                      ? 'Process Excel File' 
                      : _oneNoteFilePath != null
                        ? 'Process OneNote File'
                        : 'Select a file to process',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              // Action buttons row
              if (_outputFilePath != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: HoverableButton(
                        onPressed: _openExcelFile,
                        backgroundColor: const Color(0xFF27AE60),
                        hoverColor: const Color(0xFF2ECC71),
                        foregroundColor: Colors.white,
                        hoverForegroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        borderRadius: BorderRadius.circular(12),
                        elevation: 4,
                        hoverElevation: 8,
                        isIcon: true,
                        icon: Icons.open_in_new,
                        label: 'Open Excel',
                        child: const Text('Open Excel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: HoverableButton(
                        onPressed: _saveAsExcelFile,
                        backgroundColor: const Color(0xFF3498DB),
                        hoverColor: const Color(0xFF5DADE2),
                        foregroundColor: Colors.white,
                        hoverForegroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        borderRadius: BorderRadius.circular(12),
                        elevation: 4,
                        hoverElevation: 8,
                        isIcon: true,
                        icon: Icons.save_as,
                        label: 'Save As',
                        child: const Text('Save As'),
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

  Future<void> _loadExcelInput(String path) async {
    print('_loadExcelInput called with: $path'); // Debug log
    
    // Get the service reference before any async operations
    final excelService = context.read<excel.ExcelService>();
    
    try {
      print('ExcelService obtained, reading file...'); // Debug log
      final inputData = await excelService.readExcelFile(path);
      print('Excel file read successfully: $inputData'); // Debug log
      
      if (mounted) {
        setState(() {
          _excelInputData = inputData;
          _isLoadingExcelInput = false; // Clear loading state
        });
        print('State updated with Excel data'); // Debug log
      }
    } catch (e) {
      print('Error loading Excel file: $e'); // Debug log
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to read Excel file: $e'),
            actions: [
              HoverableTextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        
        // Clear the file path if there was an error
        setState(() {
          _excelInputFilePath = null;
          _excelInputData = null;
          _isLoadingExcelInput = false; // Clear loading state
        });
      }
    }
  }

  Future<void> _processFile() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Starting processing...';
      _progress = 0.1;
    });

    try {
      final ollamaService = context.read<ollama.OllamaService>();
      final excelService = context.read<excel.ExcelService>();

      List<Map<String, dynamic>> extractedData;
      String outputPath;

      if (_excelInputFilePath != null) {
        // Process Excel file
        setState(() {
          _statusMessage = 'Processing Excel data...';
          _progress = 0.3;
        });

        extractedData = await ollamaService.processExcelData(
          _excelInputData!,
          _customPrompt,
          maxRows: 1000, // Limit for large files
        );

        outputPath = _excelInputFilePath!
            .replaceAll(RegExp(r'\.(xlsx|xls)$'), '_processed.xlsx');

      } else {
        // Process OneNote file (existing logic)
        final oneNoteService = context.read<onenote.OneNoteService>();
        
        setState(() {
          _statusMessage = 'Reading OneNote file...';
          _progress = 0.2;
        });

        final pages = await oneNoteService.readOneNoteFile(_oneNoteFilePath!);

        setState(() {
          _statusMessage = 'Processing ${pages.length} pages...';
          _progress = 0.3;
        });

        extractedData = <Map<String, dynamic>>[];
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

        outputPath = _oneNoteFilePath!
            .replaceAll(RegExp(r'\.(one|onepkg)$'), '_extracted.xlsx');
      }

      setState(() {
        _statusMessage = 'Writing Excel file...';
        _progress = 0.9;
      });

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
          content: Text('Data ${_excelInputFilePath != null ? "restructured" : "extracted"} successfully!\n\nOutput file: $outputPath'),
          actions: [
            HoverableTextButton(
              onPressed: () {
                Navigator.pop(context);
                _openExcelFile();
              },
              isIcon: true,
              icon: Icons.open_in_new,
              label: 'Open Excel',
              child: const Text('Open Excel'),
            ),
            HoverableTextButton(
              onPressed: () {
                Navigator.pop(context);
                _saveAsExcelFile();
              },
              isIcon: true,
              icon: Icons.save_as,
              label: 'Save As',
              child: const Text('Save As'),
            ),
            HoverableTextButton(
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
            HoverableTextButton(
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
              HoverableTextButton(
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
                  HoverableTextButton(
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
                  HoverableTextButton(
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
              HoverableTextButton(
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
