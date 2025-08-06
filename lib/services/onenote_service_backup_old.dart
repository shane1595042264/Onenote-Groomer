import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ffi';
import 'package:win32/win32.dart';
import '../models/onenote_page.dart';

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
      
      // Try to extract using improved binary parsing
      final bytes = await file.readAsBytes();
      final extractedPages = await _extractUsingBinaryParsing(bytes, filePath);
      
      if (extractedPages.isNotEmpty) {
        print('Successfully extracted ${extractedPages.length} pages using binary parsing');
        return extractedPages;
      }
      
      // If all else fails, create a helpful page with instructions
      print('Warning: Could not extract meaningful content from OneNote file');
      pages.add(OneNotePage(
        id: 'placeholder-${DateTime.now().millisecondsSinceEpoch}',
        title: 'OneNote Import Instructions',
        content: '''This OneNote file could not be automatically processed. 

To extract your OneNote content for Excel:

1. Open the OneNote file in Microsoft OneNote
2. Select all content on each page (Ctrl+A)
3. Copy the content (Ctrl+C)
4. Paste into a text file or directly into this application

The OneNote .one file format is proprietary and requires special handling. If you need automated extraction, consider:
- Exporting your OneNote content to a different format first
- Using OneNote's export features to create HTML or Word documents
- Converting through OneNote online or desktop application

File path: $filePath''',
        createdTime: DateTime.now(),
        lastModifiedTime: DateTime.now(),
        parentSection: 'Import Instructions',
      ));
      
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

  Future<List<OneNotePage>> _extractUsingBinaryParsing(List<int> bytes, String filePath) async {
    final pages = <OneNotePage>[];
    
    try {
      print('Using improved binary parsing for OneNote file...');
      
      // OneNote .one files contain structured data - try multiple approaches
      final content = await _parseOneNoteFileStructure(bytes);
      
      if (content.isNotEmpty) {
        pages.addAll(content);
      }
      
    } catch (e) {
      print('Binary parsing error: $e');
    }
    
    return pages;
  }

  Future<List<OneNotePage>> _parseOneNoteFileStructure(List<int> bytes) async {
    final pages = <OneNotePage>[];
    
    try {
      // Try multiple encoding strategies to extract text
      final extractedTexts = <String>[];
      
      // Strategy 1: UTF-8 extraction
      try {
        final utf8Content = utf8.decode(bytes, allowMalformed: true);
        final cleanedUtf8 = _extractMeaningfulContent(utf8Content);
        if (cleanedUtf8.isNotEmpty) {
          extractedTexts.add(cleanedUtf8);
        }
      } catch (e) {
        print('UTF-8 extraction failed: $e');
      }
      
      // Strategy 2: UTF-16 extraction
      try {
        if (bytes.length >= 2) {
          final uint8List = Uint8List.fromList(bytes);
          final uint16List = uint8List.buffer.asUint16List();
          final utf16Content = String.fromCharCodes(uint16List);
          final cleanedUtf16 = _extractMeaningfulContent(utf16Content);
          if (cleanedUtf16.isNotEmpty && !extractedTexts.contains(cleanedUtf16)) {
            extractedTexts.add(cleanedUtf16);
          }
        }
      } catch (e) {
        print('UTF-16 extraction failed: $e');
      }
      
      // Strategy 3: Search for text patterns in the binary data
      final patternContent = _searchForTextPatterns(bytes);
      if (patternContent.isNotEmpty && !extractedTexts.contains(patternContent)) {
        extractedTexts.add(patternContent);
      }
      
      // Process all extracted text content
      for (int i = 0; i < extractedTexts.length; i++) {
        final content = extractedTexts[i];
        final pageContents = _splitIntoPages(content);
        
        for (int j = 0; j < pageContents.length; j++) {
          final pageContent = pageContents[j];
          if (pageContent.trim().isNotEmpty) {
            final lines = pageContent.split('\n').where((line) => line.trim().isNotEmpty).toList();
            String title = 'Extracted Page ${pages.length + 1}';
            String content = pageContent;
            
            // Try to extract a meaningful title
            if (lines.isNotEmpty) {
              final firstLine = lines.first.trim();
              if (firstLine.length >= 3 && firstLine.length <= 100 && _looksLikeTitle(firstLine)) {
                title = firstLine;
                content = lines.skip(1).join('\n');
              }
            }
            
            pages.add(OneNotePage(
              id: 'page-${pages.length + 1}',
              title: title,
              content: content.trim(),
              createdTime: DateTime.now(),
              lastModifiedTime: DateTime.now(),
              parentSection: 'Extracted Content',
            ));
          }
        }
      }
      
    } catch (e) {
      print('Error parsing OneNote file structure: $e');
    }
    
    return pages;
  }

  String _searchForTextPatterns(List<int> bytes) {
    final foundTexts = <String>[];
    
    try {
      // Look for sequences of printable ASCII characters
      final buffer = StringBuffer();
      int consecutivePrintable = 0;
      
      for (int i = 0; i < bytes.length; i++) {
        final byte = bytes[i];
        
        // Check if it's a printable ASCII character or whitespace
        if ((byte >= 32 && byte <= 126) || byte == 9 || byte == 10 || byte == 13) {
          buffer.writeCharCode(byte);
          consecutivePrintable++;
        } else {
          // If we had a good run of printable characters, save it
          if (consecutivePrintable >= 10) {
            final text = buffer.toString().trim();
            if (text.isNotEmpty && _containsMeaningfulWords(text)) {
              foundTexts.add(text);
            }
          }
          buffer.clear();
          consecutivePrintable = 0;
        }
      }
      
      // Check the final buffer
      if (consecutivePrintable >= 10) {
        final text = buffer.toString().trim();
        if (text.isNotEmpty && _containsMeaningfulWords(text)) {
          foundTexts.add(text);
        }
      }
      
    } catch (e) {
      print('Error in pattern search: $e');
    }
    
    return foundTexts.join('\n\n');
  }

  bool _containsMeaningfulWords(String text) {
    // Check if the text contains actual words (not just random characters)
    final words = text.split(RegExp(r'\s+'));
    int meaningfulWords = 0;
    
    for (final word in words) {
      if (word.length >= 3 && word.contains(RegExp(r'[a-zA-Z]'))) {
        meaningfulWords++;
      }
    }
    
    return meaningfulWords >= 2; // At least 2 meaningful words
  }

  String _extractMeaningfulContent(String rawContent) {
    final meaningfulLines = <String>[];
    final lines = rawContent.split(RegExp(r'[\r\n]+'));
    
    for (final line in lines) {
      final cleanLine = line.trim();
      
      // Skip empty lines
      if (cleanLine.isEmpty) continue;
      
      // Skip very short or very long lines
      if (cleanLine.length < 3 || cleanLine.length > 1000) continue;
      
      // Check if line contains readable text
      if (!_hasReadableContent(cleanLine)) continue;
      
      // Skip email headers and metadata
      if (_isEmailOrMetadata(cleanLine)) continue;
      
      // Skip binary artifacts
      if (_isBinaryArtifact(cleanLine)) continue;
      
      // This looks like meaningful content
      meaningfulLines.add(cleanLine);
    }
    
    return meaningfulLines.join('\n');
  }

  bool _hasReadableContent(String line) {
    // Count printable characters
    final printableCount = line.split('').where((char) {
      final code = char.codeUnitAt(0);
      return (code >= 32 && code <= 126) || // ASCII printable
             (code >= 128 && code <= 255) || // Extended ASCII
             char == '\t' || char == ' ';    // Whitespace
    }).length;
    
    // Count alphabetic characters
    final alphaCount = line.split('').where((char) {
      return RegExp(r'[a-zA-Z]').hasMatch(char);
    }).length;
    
    // Count special characters that indicate binary data
    final binaryChars = line.split('').where((char) {
      final code = char.codeUnitAt(0);
      return code < 32 && code != 9 && code != 10 && code != 13; // Control chars except tab, LF, CR
    }).length;
    
    // Reject lines with too many binary characters
    if (binaryChars > line.length * 0.1) return false; // More than 10% binary chars
    
    return printableCount >= line.length * 0.8 && // At least 80% printable
           alphaCount >= line.length * 0.3;        // At least 30% alphabetic
  }

  bool _isEmailOrMetadata(String line) {
    final emailHeaders = [
      'Content-Type:', 'Content-Transfer-Encoding:', 'Content-Disposition:',
      'MIME-Version:', 'Message-ID:', 'Date:', 'From:', 'To:', 'Subject:',
      'Return-Path:', 'Received:', 'DKIM-Signature:', 'X-', 'boundary=',
      'multipart/', 'charset=', 'version=', 'encoding='
    ];
    
    return emailHeaders.any((header) => line.contains(header)) ||
           (line.contains('@') && line.contains('.') && line.length < 100);
  }

  bool _isBinaryArtifact(String line) {
    return line.startsWith('%PDF') ||
           line.contains('<<') && line.contains('>>') ||
           line.contains('/Type') ||
           line.contains('/Filter') ||
           line.contains('stream') ||
           line.contains('endstream') ||
           line.contains('\\x') ||
           line.contains('\u0000') ||
           line.contains('<?xpacket') ||
           line.contains('<</Filter') ||
           line.contains('FlateDecode') ||
           line.contains('/ObjStm>>') ||
           RegExp(r'^[^a-zA-Z0-9\s]{10,}').hasMatch(line) || // Line of mostly special chars
           line.split('').where((c) => c.codeUnitAt(0) < 32).length > line.length * 0.3; // Too many control chars
  }

  bool _looksLikeTitle(String line) {
    // A title typically doesn't end with sentence punctuation
    if (line.endsWith('.') || line.endsWith('!') || line.endsWith('?')) {
      return false;
    }
    
    final words = line.split(RegExp(r'\s+'));
    if (words.length > 10) return false; // Too many words for a title
    
    final alphaCount = line.split('').where((c) => RegExp(r'[a-zA-Z\s]').hasMatch(c)).length;
    return alphaCount >= line.length * 0.8; // Mostly letters and spaces
  }

  List<String> _splitIntoPages(String content) {
    final pages = <String>[];
    
    if (content.trim().isEmpty) return pages;
    
    // More aggressive page detection - look for multiple patterns
    final lines = content.split('\n');
    final potentialPages = <String>[];
    
    // Strategy 1: Look for company/business names (often page headers)
    final businessPatterns = [
      RegExp(r'^[A-Z\s&,-]+(?:LLC|INC|CORP|COMPANY|GROUP|SERVICES?|SYSTEMS?)', caseSensitive: false),
      RegExp(r'^X\s*-\s*[A-Za-z\s&,-]+', caseSensitive: false), // Your naming pattern
      RegExp(r'^\d+\s+[A-Za-z\s]+(?:St|Ave|Rd|Dr|Blvd|Way|Court|Circle)', caseSensitive: false), // Address patterns
      RegExp(r'^[A-Z][a-z]+\s+[A-Z][a-z]+\s+(?:LLC|INC|CORP)', caseSensitive: false), // Company name patterns
      RegExp(r'^(?:Account|Client|Company|Business):\s*[A-Za-z]', caseSensitive: false), // Field patterns
      RegExp(r'(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday)', caseSensitive: false),
      RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}'),
      RegExp(r'(january|february|march|april|may|june|july|august|september|october|november|december)', caseSensitive: false),
    ];
    
    String currentPage = '';
    String currentTitle = '';
    int meaningfulContentCount = 0;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Skip empty lines
      if (line.isEmpty) {
        if (currentPage.isNotEmpty) currentPage += '\n';
        continue;
      }
      
      // Skip obvious noise lines immediately
      if (_isNoiseLine(line)) {
        continue;
      }
      
      // Check if this line looks like a new page header
      bool isNewPageHeader = false;
      for (final pattern in businessPatterns) {
        if (pattern.hasMatch(line) && line.length >= 5 && line.length <= 100) {
          // If we have accumulated meaningful content, save the current page
          if (currentPage.trim().isNotEmpty && meaningfulContentCount >= 3) {
            final pageContent = '$currentTitle\n$currentPage'.trim();
            // Only add pages that look like real business content
            if (_isValidBusinessContent(pageContent)) {
              potentialPages.add(pageContent);
            }
          }
          
          // Start new page
          currentTitle = line;
          currentPage = '';
          meaningfulContentCount = 0;
          isNewPageHeader = true;
          break;
        }
      }
      
      if (!isNewPageHeader) {
        // Check if this line has meaningful content
        if (_isMeaningfulLine(line)) {
          meaningfulContentCount++;
        }
        
        // Add to current page
        if (currentPage.isNotEmpty) currentPage += '\n';
        currentPage += line;
      }
    }
    
    // Add the last page if it has meaningful content
    if (currentPage.trim().isNotEmpty && meaningfulContentCount >= 3) {
      final pageContent = '$currentTitle\n$currentPage'.trim();
      if (_isValidBusinessContent(pageContent)) {
        potentialPages.add(pageContent);
      }
    }
    
    // If we found good pages, use them
    if (potentialPages.isNotEmpty) {
      pages.addAll(potentialPages.where((page) => page.trim().length > 50));
    } else {
      // Fallback: split by larger chunks but still filter
      final sections = content.split(RegExp(r'\n\s*\n\s*\n')); // Triple line breaks
      
      for (final section in sections) {
        if (section.trim().length > 50 && _isValidBusinessContent(section)) {
          pages.add(section.trim());
        }
      }
      
      // If still no good content, try smaller chunks as last resort
      if (pages.isEmpty) {
        const maxPageSize = 800; // Smaller chunks
        final paragraphs = content.split(RegExp(r'\n\s*\n'));
        String currentChunk = '';
        
        for (final paragraph in paragraphs) {
          if (!_containsOnlyNoise(paragraph)) {
            if (currentChunk.length + paragraph.length > maxPageSize && currentChunk.isNotEmpty) {
              if (_isValidBusinessContent(currentChunk)) {
                pages.add(currentChunk.trim());
              }
              currentChunk = paragraph;
            } else {
              if (currentChunk.isNotEmpty) currentChunk += '\n\n';
              currentChunk += paragraph;
            }
          }
        }
      
        if (currentChunk.trim().isNotEmpty && _isValidBusinessContent(currentChunk)) {
          pages.add(currentChunk.trim());
        }
      }
    }
    
    return pages.where((page) => page.trim().isNotEmpty).toList();
  }

  bool _isNoiseLine(String line) {
    final lowerLine = line.toLowerCase();
    
    // Immediate noise rejection
    final noisePatterns = [
      'xmp:', '<xmp:', '</xmp:', 'metadatadate', 'documentid',
      'adobe', 'microsoft reporting services', 'arc-seal:',
      'dkim-signature:', 'received:', 'content-type:',
      'outlook.com', 'exchangelabs', '<?xml', 'xmlns:',
      'uuid:', 'cy8pr14mb', 'namprd14',
    ];
    
    for (final pattern in noisePatterns) {
      if (lowerLine.contains(pattern)) return true;
    }
    
    // Lines that are mostly special characters
    final alphaCount = line.split('').where((c) => RegExp(r'[a-zA-Z]').hasMatch(c)).length;
    if (alphaCount < line.length * 0.3) return true;
    
    return false;
  }

  bool _isMeaningfulLine(String line) {
    if (line.length < 5) return false;
    
    final lowerLine = line.toLowerCase();
    
    // Business content indicators
    final meaningfulPatterns = [
      'account', 'client', 'company', 'business', 'policy',
      'insurance', 'coverage', 'premium', 'broker', 'underwriter',
      'effective', 'renewal', 'quote', 'meeting', 'discussion',
      'terrorism', 'liability', 'property', 'workers', 'comp',
      RegExp(r'\$[\d,]+'), // Dollar amounts
      RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}'), // Dates
      RegExp(r'\b[A-Z][a-z]+ [A-Z][a-z]+'), // Proper names
    ];
    
    for (final pattern in meaningfulPatterns) {
      if (pattern is String && lowerLine.contains(pattern)) return true;
      if (pattern is RegExp && pattern.hasMatch(line)) return true;
    }
    
    return false;
  }

  bool _containsOnlyNoise(String content) {
    final lines = content.split('\n');
    int noiseLines = 0;
    
    for (final line in lines) {
      if (_isNoiseLine(line.trim())) {
        noiseLines++;
      }
    }
    
    return noiseLines > lines.length * 0.7; // More than 70% noise
  }

  bool _isValidBusinessContent(String content) {
    // Check if the content looks like real business/document content
    final lowerContent = content.toLowerCase();
    
    // Strong noise indicators (immediate rejection)
    final strongNoiseIndicators = [
      'xmp:', '<xmp:', '</xmp:', 'metadatadate', 'documentid', 'uuid:',
      'adobe', 'pdf:producer', 'microsoft reporting services',
      'arc-seal:', 'dkim-signature:', 'received:', 'content-transfer-encoding:',
      'content-type:', 'mime-version:', 'message-id:', 'x-ms-exchange',
      'cy8pr14mb6121', 'namprd14.prod.outlook.com', 'outlook.com',
      'exchangelabs', 'administrative group', 'recipients',
      'endobj', 'stream', 'endstream', 'startxref',
      'flatedecode', 'filter', 'procset',
      '<?xml', '<!doctype', '<html', '</html>', '<head>', '</head>',
      'xmlns:', 'encoding=', 'version=', 'standalone=',
    ];
    
    // Check for strong noise indicators
    for (final indicator in strongNoiseIndicators) {
      if (lowerContent.contains(indicator)) {
        return false;
      }
    }
    
    // Check if content is mostly non-readable characters
    final readableRatio = _calculateReadableRatio(content);
    if (readableRatio < 0.8) return false;
    
    // Check for excessive repetition (often indicates form data or templates)
    if (_hasExcessiveRepetition(content)) return false;
    
    // Business/document indicators
    final businessIndicators = [
      'company', 'business', 'llc', 'inc', 'corp', 'corporation',
      'address', 'phone', 'email', 'contact', 'name', 'date',
      'insurance', 'policy', 'underwriter', 'broker', 'client',
      'property', 'risk', 'premium', 'coverage', 'claim',
      'account', 'submission', 'quote', 'renewal', 'effective',
      'general liability', 'property insurance', 'workers comp',
      'terrorism', 'meeting', 'discussion', 'proposal',
      'project', 'agreement', 'contract', 'application',
    ];
    
    // Weak noise indicators (need more context)
    final weakNoiseIndicators = [
      'included', 'max per', 'limit', 'hours', 'scheduled',
    ];
    
    // Count business vs weak noise indicators
    int businessScore = 0;
    int weakNoiseScore = 0;
    
    for (final indicator in businessIndicators) {
      if (lowerContent.contains(indicator)) businessScore++;
    }
    
    for (final indicator in weakNoiseIndicators) {
      if (lowerContent.contains(indicator)) weakNoiseScore++;
    }
    
    // If it's mostly template/form data (lots of "included", "N/A", etc.)
    if (weakNoiseScore > businessScore + 2) return false;
    
    // Content must have some business indicators and reasonable length
    return businessScore > 0 &&
           content.length >= 100 &&
           content.length <= 5000 &&
           !_isFormOrTemplate(content);
  }

  bool _hasExcessiveRepetition(String content) {
    final words = content.toLowerCase().split(RegExp(r'\s+'));
    if (words.length < 10) return false;
    
    final wordCounts = <String, int>{};
    for (final word in words) {
      if (word.length >= 3) {
        wordCounts[word] = (wordCounts[word] ?? 0) + 1;
      }
    }
    
    // Check if any word appears too frequently
    for (final count in wordCounts.values) {
      if (count > words.length * 0.3) return true; // More than 30% repetition
    }
    
    return false;
  }

  bool _isFormOrTemplate(String content) {
    final lowerContent = content.toLowerCase();
    
    // Form/template indicators
    final formIndicators = [
      'included', 'excluded', 'n/a', 'yes', 'no',
      'max per', 'limit', 'deductible', 'subject to',
    ];
    
    int formCount = 0;
    for (final indicator in formIndicators) {
      if (lowerContent.contains(indicator)) formCount++;
    }
    
    // If more than half the indicators are form-related, likely a template
    return formCount >= formIndicators.length / 2;
  }

  double _calculateReadableRatio(String content) {
    if (content.isEmpty) return 0.0;
    
    // Count readable characters (letters, numbers, common punctuation, spaces)
    final readablePattern = RegExp(r'[a-zA-Z0-9\s.,;:!?()-]');
    final readableCount = readablePattern.allMatches(content).length;
    
    return readableCount / content.length;
  }

  void dispose() {
    try {
      CoUninitialize();
    } catch (e) {
      print('Error during COM cleanup: $e');
    }
  }
}
