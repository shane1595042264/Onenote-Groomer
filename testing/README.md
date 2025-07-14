# Testing Files

This folder contains all test scripts and testing utilities for the OneNote-to-Excel converter.

## Test Categories:

### Core Functionality Tests:
- `test_full_pipeline_clean.dart` - Clean pipeline test
- `test_extraction.dart` - OneNote extraction tests
- `test_excel_processing.dart` - Excel processing tests
- `test_ai_processing.dart` - AI/Ollama service tests

### UI and Interface Tests:
- `test_hover_effects_verification.dart` - Hover effects verification
- `test_cancel_functionality.dart` - Cancel upload functionality
- `test_updated_gui.dart` - GUI functionality tests
- `test_ui_fixes.dart` - UI fixes verification

### Feature-Specific Tests:
- `test_xlsb_support.dart` - XLSB format handling tests
- `test_excel_features.dart` - Excel feature tests
- `test_field_filtering.dart` - Data field filtering tests
- `test_custom_prompt.dart` - Custom prompt testing

### Debug and Development:
- `debug_*.dart` - Debug utilities
- `simple_drop_test.dart` - Simple file drop testing
- `quick_test.dart` - Quick functionality tests
- `verify_excel_output.dart` - Excel output verification

## Running Tests:
```bash
dart run testing/[test_file_name].dart
```

Note: Make sure Ollama is running before executing AI-related tests.
