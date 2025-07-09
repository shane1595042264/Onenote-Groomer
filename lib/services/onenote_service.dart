import 'dart:io';
import 'dart:typed_data';
import 'dart:ffi';
import 'package:win32/win32.dart';
import '../models/onenote_page.dart';
import 'dart:convert';

class OneNoteService {
  bool _isInitialized = false;
  
  OneNoteService() {
    _initialize();
  }

  void _initialize() {
    try {
      print('Initializing OneNote service...');
      
      // Initialize COM
      final hr = CoInitializeEx(nullptr, COINIT.COINIT_APARTMENTTHREADED);
      if (FAILED(hr) && hr != RPC_E_CHANGED_MODE) {
        print('Warning: COM initialization failed with HRESULT: $hr');
      }
      
      _isInitialized = true;
      print('OneNote service initialized successfully');
    } catch (e) {
      print('Failed to initialize OneNote service: $e');
      _isInitialized = false;
    }
  }

  Future<List<OneNotePage>> readOneNoteFile(String filePath) async {
    final pages = <OneNotePage>[];
    
    if (!_isInitialized) {
      throw Exception('OneNote service not initialized');
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('OneNote file not found: $filePath');
      }

      print('Reading OneNote file: $filePath');
      
      // First try to load from extracted JSON data (if available)
      try {
        final jsonPages = await _loadFromExtractedJson();
        if (jsonPages.isNotEmpty) {
          pages.addAll(jsonPages);
          print('Successfully loaded ${jsonPages.length} pages from extracted JSON data');
          return pages;
        }
      } catch (e) {
        print('JSON data loading failed: $e, trying PowerShell extraction');
      }
      
      // Try PowerShell extraction
      try {
        final psPages = await _extractUsingPowerShell(filePath);
        if (psPages.isNotEmpty) {
          pages.addAll(psPages);
          print('Successfully extracted ${psPages.length} pages using PowerShell');
          return pages;
        }
      } catch (e) {
        print('PowerShell extraction failed: $e, falling back to file parsing');
      }
      
      // Fallback to improved file parsing
      final bytes = await file.readAsBytes();
      final filePages = await _extractUsingAdvancedParsing(bytes, filePath);
      pages.addAll(filePages);
      
      if (pages.isEmpty) {
        pages.add(OneNotePage(
          id: 'error-no-content',
          title: 'No Content Found',
          content: '''Failed to extract content from OneNote file.

This could be due to:
1. The file format is not supported
2. OneNote is not installed on this system
3. The file is corrupted or encrypted

Please ensure:
- OneNote is installed and accessible
- The file is a valid OneNote .one file
- You have read permissions for the file

File: $filePath''',
          createdTime: DateTime.now(),
          lastModifiedTime: DateTime.now(),
          parentSection: 'Error',
        ));
      }
      
    } catch (e) {
      print('Error reading OneNote file: $e');
      pages.add(OneNotePage(
        id: 'error-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Error reading file',
        content: 'Error: $e\n\nFile: $filePath\n\nPlease ensure the file is a valid OneNote file and try again.',
        createdTime: DateTime.now(),
        lastModifiedTime: DateTime.now(),
        parentSection: 'Errors',
      ));
    }

    return pages;
  }

  Future<List<OneNotePage>> _extractUsingCOM(String filePath) async {
    final pages = <OneNotePage>[];
    
    try {
      print('Attempting COM automation extraction...');
      
      // Try to use PowerShell to access OneNote COM object
      final result = await Process.run('powershell', [
        '-Command',
        '''
        try {
          \$oneNote = New-Object -ComObject OneNote.Application
          \$notebookXml = ""
          \$oneNote.GetHierarchy("", [Microsoft.Office.Interop.OneNote.HierarchyScope]::hsNotebooks, [ref]\$notebookXml)
          
          # Open the specific file (if it's a .one file, we need to import it first)
          \$filePath = "${filePath.replaceAll('\\', '\\\\')}"
          
          if (\$filePath.EndsWith(".one")) {
            # For .one files, try to import or open
            Write-Host "Processing .one file: \$filePath"
            
            # Try to read file content directly using .NET
            \$bytes = [System.IO.File]::ReadAllBytes(\$filePath)
            \$text = [System.Text.Encoding]::UTF8.GetString(\$bytes) -replace '[\\x00-\\x1F]', ' '
            \$text = \$text -replace '\\s+', ' '
            
            # Output the raw text for parsing
            Write-Host "CONTENT_START"
            Write-Host \$text
            Write-Host "CONTENT_END"
          }
          
          Write-Host "SUCCESS"
        } catch {
          Write-Host "ERROR: \$(\$_.Exception.Message)"
        }
        '''
      ]);
      
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        if (output.contains('CONTENT_START') && output.contains('CONTENT_END')) {
          final contentStart = output.indexOf('CONTENT_START') + 'CONTENT_START'.length;
          final contentEnd = output.indexOf('CONTENT_END');
          if (contentEnd > contentStart) {
            final content = output.substring(contentStart, contentEnd).trim();
            if (content.isNotEmpty) {
              final parsedPages = await _parseExtractedContent(content, filePath);
              pages.addAll(parsedPages);
            }
          }
        }
      } else {
        throw Exception('PowerShell COM extraction failed: ${result.stderr}');
      }
      
    } catch (e) {
      print('COM extraction error: $e');
      rethrow;
    }
    
    return pages;
  }

  Future<List<OneNotePage>> _extractUsingAdvancedParsing(List<int> bytes, String filePath) async {
    final pages = <OneNotePage>[];
    
    try {
      print('Using advanced file parsing for OneNote file...');
      
      // OneNote .one files have a specific binary structure
      // Let's try multiple extraction strategies
      
      // Strategy 1: Search for embedded XML content (OneNote stores content as XML)
      final xmlContent = await _extractXMLContent(bytes);
      if (xmlContent.isNotEmpty) {
        final xmlPages = await _parseXMLContent(xmlContent);
        pages.addAll(xmlPages);
      }
      
      // Strategy 2: Look for UTF-16 encoded text (common in OneNote)
      final utf16Content = await _extractUTF16Content(bytes);
      if (utf16Content.isNotEmpty) {
        final textPages = await _parseExtractedContent(utf16Content, filePath);
        pages.addAll(textPages);
      }
      
      // Strategy 3: Search for text patterns that indicate business data
      final businessContent = await _extractBusinessPatterns(bytes);
      if (businessContent.isNotEmpty) {
        final businessPages = await _parseExtractedContent(businessContent, filePath);
        pages.addAll(businessPages);
      }
      
    } catch (e) {
      print('Advanced parsing error: $e');
    }
    
    return pages;
  }

  Future<String> _extractXMLContent(List<int> bytes) async {
    final xmlPatterns = <String>[];
    
    try {
      // Look for XML-like content in the binary data
      final content = String.fromCharCodes(bytes.where((b) => b >= 32 && b <= 126));
      
      // Find XML fragments
      final xmlRegex = RegExp(r'<[^>]+>.*?</[^>]+>', multiLine: true, dotAll: true);
      final matches = xmlRegex.allMatches(content);
      
      for (final match in matches) {
        final xmlFragment = match.group(0);
        if (xmlFragment != null && xmlFragment.length > 50) {
          xmlPatterns.add(xmlFragment);
        }
      }
      
    } catch (e) {
      print('XML extraction error: $e');
    }
    
    return xmlPatterns.join('\n');
  }

  Future<String> _extractUTF16Content(List<int> bytes) async {
    try {
      final uint8List = Uint8List.fromList(bytes);
      
      // Try both little-endian and big-endian UTF-16
      final patterns = <String>[];
      
      // Little-endian UTF-16
      if (bytes.length >= 2) {
        final uint16List = uint8List.buffer.asUint16List();
        final utf16Content = String.fromCharCodes(uint16List.where((c) => 
          (c >= 32 && c <= 126) || c == 9 || c == 10 || c == 13 || (c >= 160 && c <= 255)
        ));
        if (utf16Content.length > 100) {
          patterns.add(utf16Content);
        }
      }
      
      return patterns.join('\n');
    } catch (e) {
      print('UTF-16 extraction error: $e');
      return '';
    }
  }

  Future<String> _extractBusinessPatterns(List<int> bytes) async {
    final businessTexts = <String>[];
    
    try {
      // Convert bytes to string with error handling
      final rawText = String.fromCharCodes(bytes.where((b) => 
        (b >= 32 && b <= 126) || b == 9 || b == 10 || b == 13
      ));
      
      // Look for business-related patterns
      final businessRegexes = [
        RegExp(r'(?:underwriter|broker|agent):\s*([A-Za-z\s&,.\''-]+)', caseSensitive: false),
        RegExp(r'(?:company|business|client|account):\s*([A-Za-z\s&,.\''-]+)', caseSensitive: false),
        RegExp(r'(?:date|effective|expiration):\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})', caseSensitive: false),
        RegExp(r'([A-Z][a-z]+\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\s*(?:LLC|INC|CORP|COMPANY|GROUP)', caseSensitive: false),
        RegExp(r'\$[\d,]+(?:\.\d{2})?', caseSensitive: false), // Money amounts
        RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b'), // Dates
        RegExp(r'\b[A-Z]{2,3}\b'), // State codes, etc.
      ];
      
      final foundPatterns = <String>{};
      
      for (final regex in businessRegexes) {
        final matches = regex.allMatches(rawText);
        for (final match in matches) {
          final fullMatch = match.group(0);
          if (fullMatch != null && fullMatch.trim().isNotEmpty) {
            foundPatterns.add(fullMatch.trim());
          }
        }
      }
      
      if (foundPatterns.isNotEmpty) {
        businessTexts.add(foundPatterns.join('\n'));
      }
      
    } catch (e) {
      print('Business pattern extraction error: $e');
    }
    
    return businessTexts.join('\n\n');
  }

  Future<List<OneNotePage>> _parseXMLContent(String xmlContent) async {
    final pages = <OneNotePage>[];
    
    try {
      // Parse XML content to extract meaningful information
      final lines = xmlContent.split('\n');
      String currentContent = '';
      
      for (final line in lines) {
        final cleanLine = line.trim();
        if (cleanLine.isNotEmpty && !cleanLine.startsWith('<') && !cleanLine.endsWith('>')) {
          currentContent += '$cleanLine\n';
        }
      }
      
      if (currentContent.trim().isNotEmpty) {
        final parsedPages = await _parseExtractedContent(currentContent, 'XML Content');
        pages.addAll(parsedPages);
      }
      
    } catch (e) {
      print('XML parsing error: $e');
    }
    
    return pages;
  }

  Future<List<OneNotePage>> _parseExtractedContent(String content, String source) async {
    final pages = <OneNotePage>[];
    
    try {
      print('Parsing extracted content from: $source');
      print('Content length: ${content.length} characters');
      
      // Clean up the content
      final cleanContent = _cleanExtractedContent(content);
      if (cleanContent.trim().isEmpty) {
        return pages;
      }
      
      // Chunk content based on business entities (underwriters, brokers, companies)
      final chunks = _chunkByBusinessEntities(cleanContent);
      
      for (int i = 0; i < chunks.length; i++) {
        final chunk = chunks[i];
        if (_isValidBusinessEntry(chunk)) {
          final metadata = _extractBusinessMetadata(chunk);
          
          pages.add(OneNotePage(
            id: 'page-${pages.length + 1}',
            title: metadata['title'] ?? 'Business Entry ${pages.length + 1}',
            content: chunk.trim(),
            createdTime: DateTime.now(),
            lastModifiedTime: DateTime.now(),
            parentSection: metadata['section'] ?? 'Extracted Content',
          ));
        }
      }
      
    } catch (e) {
      print('Content parsing error: $e');
    }
    
    return pages;
  }

  String _cleanExtractedContent(String content) {
    String cleaned = content;
    
    // Remove binary artifacts
    cleaned = cleaned.replaceAll(RegExp(r'[^\x20-\x7E\s]'), '');
    
    // Remove excessive whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove common noise patterns
    cleaned = cleaned.replaceAll(RegExp(r'(?:Content-Type|MIME-Version|boundary=)[^\n]*', caseSensitive: false), '');
    
    // Split into lines and filter meaningful ones
    final lines = cleaned.split('\n');
    final meaningfulLines = lines.where((line) {
      final trimmed = line.trim();
      return trimmed.length >= 3 && 
             trimmed.length <= 500 &&
             _hasBusinessContent(trimmed);
    }).toList();
    
    return meaningfulLines.join('\n');
  }

  bool _hasBusinessContent(String line) {
    final businessKeywords = [
      'underwriter', 'broker', 'agent', 'company', 'business', 'client', 
      'account', 'policy', 'premium', 'date', 'effective', 'expiration',
      'inc', 'llc', 'corp', 'ltd', 'group', 'services', 'insurance',
      'coverage', 'limit', 'deductible'
    ];
    
    final lowerLine = line.toLowerCase();
    return businessKeywords.any((keyword) => lowerLine.contains(keyword)) ||
           RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(line) || // Date
           RegExp(r'\$[\d,]+(?:\.\d{2})?').hasMatch(line) || // Money
           RegExp(r'\b[A-Z]{2,3}\b').hasMatch(line); // State codes
  }

  List<String> _chunkByBusinessEntities(String content) {
    final chunks = <String>[];
    
    try {
      final lines = content.split('\n');
      final entityMarkers = [
        RegExp(r'(?:underwriter|broker|agent):\s*([A-Za-z\s&,.\''-]+)', caseSensitive: false),
        RegExp(r'(?:company|business|client|account):\s*([A-Za-z\s&,.\''-]+)', caseSensitive: false),
        RegExp(r'^([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\s*(?:LLC|INC|CORP|COMPANY|GROUP)', caseSensitive: false),
      ];
      
      String currentChunk = '';
      bool foundEntity = false;
      
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty) continue;
        
        // Check if this line starts a new business entity
        for (final marker in entityMarkers) {
          if (marker.hasMatch(trimmedLine)) {
            // If we have accumulated content and found a new entity, save the current chunk
            if (currentChunk.isNotEmpty && foundEntity) {
              chunks.add(currentChunk.trim());
              currentChunk = '';
            }
            foundEntity = true;
            break;
          }
        }
        
        currentChunk += '$trimmedLine\n';
        
        // If this chunk gets too long without finding an entity, split it
        if (currentChunk.length > 1000 && !foundEntity) {
          chunks.add(currentChunk.trim());
          currentChunk = '';
        }
      }
      
      // Add the last chunk
      if (currentChunk.trim().isNotEmpty) {
        chunks.add(currentChunk.trim());
      }
      
    } catch (e) {
      print('Chunking error: $e');
      // Fallback: split by paragraphs
      chunks.addAll(content.split(RegExp(r'\n\s*\n')).where((c) => c.trim().isNotEmpty));
    }
    
    return chunks.where((chunk) => chunk.trim().length > 50).toList();
  }

  bool _isValidBusinessEntry(String chunk) {
    final lowerChunk = chunk.toLowerCase();
    
    // Must have at least one of these key elements
    final hasUnderwriter = lowerChunk.contains('underwriter') && !lowerChunk.contains('n/a');
    final hasBroker = lowerChunk.contains('broker') && !lowerChunk.contains('n/a');
    final hasCompany = RegExp(r'(?:company|business|client|account):\s*[a-z]', caseSensitive: false).hasMatch(chunk);
    final hasDate = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(chunk);
    
    // If underwriter exists and is not N/A, it's valid
    if (hasUnderwriter) return true;
    
    // Otherwise, need at least broker/company AND date
    return (hasBroker || hasCompany) && hasDate;
  }

  Map<String, String> _extractBusinessMetadata(String chunk) {
    final metadata = <String, String>{};
    
    // Extract primary contact (previously underwriter)
    final underwriterMatch = RegExp(r'(?:underwriter|primary contact|contact):\s*([A-Za-z\s&,.\''-]+)', caseSensitive: false).firstMatch(chunk);
    if (underwriterMatch != null) {
      metadata['underwriter'] = underwriterMatch.group(1)?.trim() ?? '';
    }
    
    // Extract business/company name
    final companyMatch = RegExp(r'(?:company|business|client|account|business name):\s*([A-Za-z\s&,.\''-]+)', caseSensitive: false).firstMatch(chunk);
    if (companyMatch != null) {
      metadata['company'] = companyMatch.group(1)?.trim() ?? '';
    }
    
    // Extract secondary contact (previously broker)
    final brokerMatch = RegExp(r'(?:broker|secondary contact|agent):\s*([A-Za-z\s&,.\''-]+)', caseSensitive: false).firstMatch(chunk);
    if (brokerMatch != null) {
      metadata['broker'] = brokerMatch.group(1)?.trim() ?? '';
    }
    
    // Create title based on available information (using generic terms)
    String title = 'Business Entry';
    if (metadata.containsKey('company') && metadata['company']!.isNotEmpty) {
      title = metadata['company']!;
      metadata['section'] = 'Business Records';
    } else if (metadata.containsKey('underwriter') && metadata['underwriter']!.isNotEmpty && metadata['underwriter']!.toLowerCase() != 'n/a') {
      title = 'Entry: ${metadata['underwriter']}';
      metadata['section'] = 'Business Records';
    } else if (metadata.containsKey('broker') && metadata['broker']!.isNotEmpty) {
      title = 'Entry: ${metadata['broker']}';
      metadata['section'] = 'Business Records';
    }
    
    metadata['title'] = title;
    
    return metadata;
  }

  Future<List<OneNotePage>> _loadFromExtractedJson() async {
    final pages = <OneNotePage>[];
    
    try {
      // Check for the extracted business data JSON file
      final jsonFile = File('extracted_business_data.json');
      if (!await jsonFile.exists()) {
        print('No extracted JSON data found');
        return pages;
      }
      
      final jsonContent = await jsonFile.readAsString();
      final jsonData = jsonDecode(jsonContent) as List<dynamic>;
      
      print('Loading ${jsonData.length} business entries from JSON');
      
      for (final entry in jsonData) {
        final businessData = entry as Map<String, dynamic>;
        
        // Extract key information
        final pageName = businessData['PageName'] ?? 'Unknown Page';
        final sectionName = businessData['SectionName'] ?? 'Unknown Section';
        final content = businessData['Content'] ?? '';
        
        // Clean up HTML entities and tags from content only
        final cleanContent = _cleanHtmlContent(content);
        
        // Only add pages that have meaningful content
        if (cleanContent.isNotEmpty && cleanContent.trim().length > 10) {
          pages.add(OneNotePage(
            id: 'page-${DateTime.now().millisecondsSinceEpoch}-${pages.length}',
            title: pageName.isNotEmpty ? pageName : 'Page ${pages.length + 1}',
            content: cleanContent,  // RAW content only - let AI do the work
            createdTime: DateTime.now(),
            lastModifiedTime: DateTime.now(),
            parentSection: sectionName,
          ));
        }
      }
      
      print('Successfully loaded ${pages.length} valid business pages');
      
    } catch (e) {
      print('Error loading extracted JSON data: $e');
    }
    
    return pages;
  }

  Future<List<OneNotePage>> _extractUsingPowerShell(String filePath) async {
    final pages = <OneNotePage>[];
    
    try {
      print('Running PowerShell extraction script...');
      
      // Run the PowerShell extraction script
      final result = await Process.run(
        'powershell',
        [
          '-ExecutionPolicy', 'Bypass',
          '-File', 'extract_all_business_data.ps1'
        ],
        workingDirectory: Directory.current.path,
      );
      
      if (result.exitCode == 0) {
        print('PowerShell extraction completed successfully');
        // Load the results from the JSON file created by the script
        return await _loadFromExtractedJson();
      } else {
        print('PowerShell extraction failed: ${result.stderr}');
      }
      
    } catch (e) {
      print('Error running PowerShell extraction: $e');
    }
    
    return pages;
  }

  String _cleanHtmlContent(String content) {
    if (content.isEmpty) return '';
    
    // Remove HTML entities
    String cleaned = content
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(r'\u003c', '<')
        .replaceAll(r'\u003e', '>')
        .replaceAll(r'\u0027', "'")
        .replaceAll(r'\u0026', '&');
    
    // Remove HTML tags
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Clean up whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return cleaned;
  }

  void dispose() {
    try {
      if (_isInitialized) {
        CoUninitialize();
        _isInitialized = false;
      }
    } catch (e) {
      print('Error disposing OneNote service: $e');
    }
  }
}
