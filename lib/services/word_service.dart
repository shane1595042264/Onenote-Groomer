import 'dart:io';
import 'package:docx_to_text/docx_to_text.dart';

class WordService {
  /// Extract text content from a Word document (.docx)
  static Future<String> extractTextFromFile(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        throw Exception('Word file not found: $filePath');
      }
      
      // Check if file is a .docx file
      if (!filePath.toLowerCase().endsWith('.docx')) {
        throw Exception('Only .docx files are supported. Please convert .doc files to .docx format.');
      }
      
      final bytes = await file.readAsBytes();
      final text = docxToText(bytes);
      
      if (text.trim().isEmpty) {
        throw Exception('No text content found in Word document');
      }
      
      return text.trim();
    } catch (e) {
      if (e.toString().contains('Only .docx files are supported')) {
        rethrow;
      }
      throw Exception('Failed to extract text from Word document: $e');
    }
  }
  
  /// Validate if a file is a supported Word document
  static bool isSupportedWordFile(String filePath) {
    return filePath.toLowerCase().endsWith('.docx');
  }
  
  /// Get supported file extensions
  static List<String> getSupportedExtensions() {
    return ['.docx'];
  }
}
