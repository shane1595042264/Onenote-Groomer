import 'lib/services/ollama_service.dart';

void main() async {
  final ollamaService = OllamaService();
  
  // Test the field extraction from prompt
  const prompt = '''
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
  
  // Test field extraction
  final extractedFields = ollamaService._extractFieldNamesFromPrompt(prompt);
  print('Extracted fields from prompt:');
  for (int i = 0; i < extractedFields.length; i++) {
    print('${i + 1}. ${extractedFields[i]}');
  }
  
  // Test AI response parsing with a sample response
  final sampleResponse = '''
Company/Client name: ABC Corporation
Date and time information: 2024-01-15 10:30 AM
Key decisions or actions: Approved new policy terms
Financial information: Premium $50,000 annually
Contact details: john.doe@abccorp.com
Status or outcomes: Approved
Any follow-up items: Schedule implementation meeting
Extra Field: This should be filtered out
Another Field: This should also be filtered out
''';
  
  print('\nParsing AI response...');
  final result = ollamaService._parseCustomPromptResponse(sampleResponse, prompt);
  print('Parsed result:');
  result.forEach((key, value) {
    print('$key: $value');
  });
  
  print('\nExpected 7 fields, got ${result.keys.length} fields');
  
  ollamaService.dispose();
}
