// Debug field name matching
void main() async {
  print('Debug field name matching...');
  
  // Simulate what happens in the app
  const responseField = 'Any Follow-up Items';
  final promptFields = [
    'Company/Client Name',
    'Date & Time Information', 
    'Key Decisions / Actions',
    'Financial Information',
    'Contact Details',
    'Status / Outcomes',
    'Follow-up Items'
  ];
  
  print('Response field: "$responseField"');
  print('Prompt fields:');
  for (int i = 0; i < promptFields.length; i++) {
    print('  ${i + 1}. "${promptFields[i]}"');
  }
  
  // Test normalization
  final normalizedResponse = responseField.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  print('\nNormalized response field: "$normalizedResponse"');
  
  for (final promptField in promptFields) {
    final normalizedPrompt = promptField.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    print('Prompt field: "$promptField" -> "$normalizedPrompt"');
    
    final matches = normalizedResponse == normalizedPrompt || 
                   normalizedResponse.contains(normalizedPrompt) || 
                   normalizedPrompt.contains(normalizedResponse);
    print('  Matches: $matches');
    
    if (matches) {
      print('  -> MATCH FOUND!');
      break;
    }
  }
}
