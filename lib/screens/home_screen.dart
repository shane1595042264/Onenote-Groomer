import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/file_drop_zone.dart';
import '../widgets/prompt_editor.dart';
import '../widgets/processing_status.dart';
import '../widgets/hoverable_button.dart';
import '../services/onenote_service.dart' as onenote;
import '../services/ollama_service.dart' as ollama;
import '../services/excel_service.dart' as excel;
import '../models/excel_template.dart';
import '../theme/app_theme.dart';

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
  void initState() {
    super.initState();
    _loadSavedPrompt();
  }

  /// Load the saved custom prompt from SharedPreferences
  Future<void> _loadSavedPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPrompt = prefs.getString('custom_ai_prompt');
      if (savedPrompt != null && savedPrompt.isNotEmpty) {
        setState(() {
          _customPrompt = savedPrompt;
        });
        print('Loaded saved custom prompt: ${savedPrompt.length} characters');
      }
    } catch (e) {
      print('Error loading saved prompt: $e');
    }
  }

  /// Save the custom prompt to SharedPreferences
  Future<void> _saveCustomPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_ai_prompt', _customPrompt);
      print('Saved custom prompt: ${_customPrompt.length} characters');
    } catch (e) {
      print('Error saving custom prompt: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.transform,
              color: theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('OneNote to Excel Converter'),
          ],
        ),
        actions: [
          // Color preset dropdown
          Tooltip(
            message: 'Choose color theme',
            child: PopupMenuButton<ColorPreset>(
              onSelected: (ColorPreset preset) {
                themeProvider.setColorPreset(preset);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Switched to ${preset.displayName} theme'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: theme.colorScheme.primary,
                  ),
                );
              },
              icon: Icon(
                Icons.palette,
                color: theme.colorScheme.primary,
              ),
              itemBuilder: (BuildContext context) {
                return ColorPreset.values.map((ColorPreset preset) {
                  return PopupMenuItem<ColorPreset>(
                    value: preset,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getPresetColor(preset),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                preset.displayName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: themeProvider.colorPreset == preset 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                                ),
                              ),
                              Text(
                                preset.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (themeProvider.colorPreset == preset)
                          Icon(
                            Icons.check,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                      ],
                    ),
                  );
                }).toList();
              },
            ),
          ),
          const SizedBox(width: 8),
          // Theme toggle button
          Tooltip(
            message: themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            child: IconButton(
              onPressed: () {
                themeProvider.toggleTheme();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Switched to ${themeProvider.isDarkMode ? 'Dark' : 'Light'} Mode',
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: theme.colorScheme.primary,
                  ),
                );
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  key: ValueKey(themeProvider.isDarkMode),
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
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
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              // Mode Indicator
              if (_oneNoteFilePath != null || _excelInputFilePath != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _oneNoteFilePath != null 
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : theme.colorScheme.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _oneNoteFilePath != null 
                        ? theme.colorScheme.primary.withOpacity(0.3)
                        : theme.colorScheme.tertiary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _oneNoteFilePath != null ? Icons.description : Icons.table_chart,
                        color: _oneNoteFilePath != null 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.tertiary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _oneNoteFilePath != null ? 'OneNote Processing Mode' : 'Excel Processing Mode',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: _oneNoteFilePath != null 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FileDropZone(
                      title: 'OneNote File',
                      acceptedExtensions: const ['.one', '.onepkg'],
                      isDisabled: _excelInputFilePath != null,
                      disabledReason: _excelInputFilePath != null 
                        ? 'Clear Excel file to use OneNote mode'
                        : null,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'OR',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FileDropZone(
                      title: 'Excel File to Process',
                      acceptedExtensions: const ['.xlsx', '.xls'],
                      isDisabled: _oneNoteFilePath != null,
                      disabledReason: _oneNoteFilePath != null 
                        ? 'Clear OneNote file to use Excel mode'
                        : null,
                      onFileDropped: (path) async {
                        print('Excel file dropped: $path'); // Debug log
                        
                        // First, immediately update the UI to show the file is selected
                        setState(() {
                          _excelInputFilePath = path;
                          _oneNoteFilePath = null; // Clear OneNote when Excel is selected
                          _isLoadingExcelInput = true; // Show loading state
                        });
                        
                        // Force a brief UI update to show visual feedback
                        await Future.delayed(const Duration(milliseconds: 100));
                        
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
                style: const TextStyle(
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
                const Text(
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
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: PromptEditor(
                  initialPrompt: _customPrompt,
                  onPromptChanged: (prompt) {
                    _customPrompt = prompt;
                    // Save the prompt automatically when it changes
                    _saveCustomPrompt();
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
        // Create user-friendly error message
        String userMessage = '';
        String title = 'Unable to Process Excel File';
        
        if (e.toString().contains('Null check operator used on a null value')) {
          userMessage = 'The Excel file appears to be corrupted or empty. Please check that:\n\n'
              '• The file contains data in the first worksheet\n'
              '• The file is not password protected\n'
              '• The file is a valid Excel format (.xlsx or .xls)';
        } else if (e.toString().contains('FormatException')) {
          userMessage = 'The file format is not supported or the file is corrupted. Please:\n\n'
              '• Make sure it\'s a valid Excel file (.xlsx or .xls)\n'
              '• Try re-saving the file in Excel\n'
              '• Check if the file is password protected';
        } else if (e.toString().contains('FileSystemException')) {
          userMessage = 'Cannot access the Excel file. Please check that:\n\n'
              '• The file is not open in another program\n'
              '• You have permission to read the file\n'
              '• The file path is correct';
        } else {
          userMessage = 'An unexpected error occurred while reading the Excel file.\n\n'
              'Error details: ${e.toString()}\n\n'
              'Please try:\n'
              '• Using a different Excel file\n'
              '• Re-saving your Excel file\n'
              '• Closing the file in other programs';
        }
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You can only process one file type at a time. Choose either OneNote extraction or Excel restructuring.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Try Another File',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              FilledButton(
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

      final actualOutputPath = await excelService.writeExcelFile(
        outputPath,
        extractedData,
        _excelTemplate?.columns,
      );

      setState(() {
        _statusMessage = 'Complete! File saved to: $actualOutputPath';
        _progress = 1.0;
        _outputFilePath = actualOutputPath;  // Store the actual output file path
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success!'),
          content: Text('Data ${_excelInputFilePath != null ? "restructured" : "extracted"} successfully!\n\nOutput file: $actualOutputPath'),
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

  // Helper method to get preview color for each preset
  Color _getPresetColor(ColorPreset preset) {
    switch (preset) {
      case ColorPreset.arch:
        return const Color(0xFF0057B8); // Arch blue
      case ColorPreset.originalPurple:
        return const Color(0xFF9B59B6); // Purple
      case ColorPreset.forest:
        return const Color(0xFF4CAF50); // Green
      case ColorPreset.ocean:
        return const Color(0xFF2196F3); // Blue
      case ColorPreset.sunset:
        return const Color(0xFFFF5722); // Orange
      case ColorPreset.midnight:
        return const Color(0xFF3F51B5); // Indigo
      case ColorPreset.cherry:
        return const Color(0xFFE91E63); // Pink
      case ColorPreset.lavender:
        return const Color(0xFFB39DDB); // Light purple
      case ColorPreset.ember:
        return const Color(0xFFFF7043); // Orange-red
      case ColorPreset.mint:
        return const Color(0xFF26A69A); // Teal
      case ColorPreset.storm:
        return const Color(0xFF607D8B); // Blue-gray
    }
  }

  void _showModeConflictDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Choose One Mode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You can only choose one mode of converting at a time.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Please choose either:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, color: Colors.blue[300]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'OneNote Mode: Extract data from OneNote files and organize into Excel',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green[300]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Excel Mode: Restructure and reorganize existing Excel data',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'To switch modes, simply clear the current file and select a different file type.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
