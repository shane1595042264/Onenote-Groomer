# OneNote Groomer

<div align="center">
  <img src="docs/images/logo.png" alt="OneNote Groomer Logo" width="200"/>
  <br>
  <em>Transform OneNote files into organized Excel spreadsheets with AI-powered extraction</em>
  <br><br>
</div>

## 🚀 Project Overview

OneNote Groomer is a desktop application that uses AI to extract structured data from OneNote files and convert it into organized Excel spreadsheets. It runs entirely locally, using a bundled Ollama AI engine for privacy-focused content extraction.

### Core Features
- 🔄 Convert OneNote (.one) files to Excel spreadsheets
- 🤖 AI-powered content extraction and structuring
- 📝 Custom extraction prompts with persistence
- 📊 Excel template support
- 🔒 100% local processing (no data leaves your device)
- 🎨 Modern Material Design 3 UI with dark/light mode
- 📦 Microsoft Store ready deployment

## 🛠️ Technical Architecture

### Frontend
- **Framework**: Flutter for Windows desktop
- **UI Design**: Material Design 3 with adaptive theming
- **State Management**: Provider pattern
- **Drag & Drop**: Native Windows file handling

### Backend
- **AI Engine**: Bundled Ollama LLM (Local Large Language Model)
- **File Processing**:
  - OneNote file parsing
  - Excel document generation
  - Smart file conflict resolution
- **Process Management**: Embedded Ollama service with auto-start

### Deployment
- **Packaging**: MSIX for Microsoft Store
- **Installation**: Self-contained with bundled AI
- **Distribution**: Microsoft Store ready
- **Updates**: Store-managed updates

## 📊 Project Structure

```
onenote_to_excel/
├── lib/
│   ├── main.dart             # App entry point
│   ├── models/               # Data models
│   │   ├── excel_template.dart
│   │   └── onenote_page.dart
│   ├── screens/              # UI screens
│   │   └── home_screen.dart
│   ├── services/             # Business logic
│   │   ├── excel_service.dart
│   │   ├── ollama_service.dart
│   │   ├── ollama_service_bundled.dart
│   │   └── onenote_service.dart
│   ├── theme/                # Visual theming
│   │   └── app_theme.dart
│   └── widgets/              # Reusable components
│       ├── file_drop_zone.dart
│       ├── processing_status.dart
│       └── prompt_editor.dart
├── installer/                # Deployment scripts
│   ├── create_bundled_installer.ps1
│   ├── create_msix_package.ps1
│   └── create_simple_installer.ps1
├── docs/                     # Documentation
│   └── PRIVACY_POLICY.md
└── tests/                    # Testing
    ├── test_extraction.dart
    └── test_full_pipeline.dart
```

## 🔍 Key Technical Challenges & Solutions

### 1. Local AI Integration
**Challenge**: Integrating a powerful AI model that runs entirely locally without requiring cloud services.

**Solution**: 
- Bundled Ollama LLM with the app installer
- Created a process management service that auto-starts Ollama
- Implemented error handling for AI failures
- Optimized prompt engineering for extraction accuracy

### 2. OneNote File Parsing
**Challenge**: Reading and parsing OneNote's proprietary format.

**Solution**:
- Developed a specialized parser for OneNote content
- Implemented HTML cleaning and entity decoding
- Created a hierarchical data structure for OneNote content
- Added section/page metadata extraction

### 3. Smart File Handling
**Challenge**: Managing file conflicts and handling locked Excel files.

**Solution**:
- Implemented smart file conflict resolution
- Added auto-renaming for in-use files
- Created intelligent file path handling
- Built file locking detection and management

### 4. MSIX Packaging for Microsoft Store
**Challenge**: Creating a compliant Microsoft Store package with bundled AI.

**Solution**:
- Developed custom PowerShell packaging scripts
- Fixed manifest validation issues
- Implemented correct publisher identity handling
- Resolved capability declarations
- Added proper package signing

### 5. UI/UX Design
**Challenge**: Creating a professional, user-friendly interface.

**Solution**:
- Implemented Material Design 3 with custom theming
- Created dark/light mode toggle with persistence
- Added animated status indicators
- Built drag-and-drop file handling
- Designed responsive layouts

## 🚀 Development Journey

This project involved overcoming several technical hurdles:

1. **Bundling Ollama**: Successfully packaged a 4GB+ AI engine with the app
2. **Windows SDK Integration**: Resolved SDK tool detection for packaging
3. **MSIX Manifest Validation**: Fixed complex manifest schema issues
4. **File System Permissions**: Properly declared and handled file access
5. **Memory Management**: Optimized for processing large documents
6. **Persistent Storage**: Implemented settings and prompt storage

## 🧠 AI Implementation Details

OneNote Groomer uses a locally-running Large Language Model to:

1. **Analyze Document Structure**: Parse OneNote's formatting
2. **Extract Semantic Content**: Identify key business information
3. **Apply Custom Rules**: Use provided prompts to extract specific data
4. **Structure Data**: Organize information into logical tables
5. **Clean Content**: Remove noise and standardize formats

The AI processing pipeline:
```
OneNote Document → Content Extraction → Semantic Analysis → 
Structure Identification → Data Mapping → Excel Generation
```

## 📊 Performance Considerations

- **Memory Usage**: Optimized to handle large documents with batch processing
- **Processing Speed**: Balanced accuracy vs. speed for extraction
- **Storage Requirements**: ~5GB for app + bundled AI model
- **Hardware Requirements**: 8GB RAM minimum, 16GB recommended

## 🔒 Privacy & Security

OneNote Groomer is designed with privacy as a core principle:

- **100% Local Processing**: All data stays on your device
- **No External APIs**: No data transmitted to cloud services
- **No Telemetry**: No usage data collection
- **Minimal Permissions**: Only requests necessary system access

See our [Privacy Policy](docs/PRIVACY_POLICY.md) for details.

## 🚀 Deployment Process

The app uses a sophisticated deployment pipeline:

1. **Build Flutter App**: Compile Windows desktop executable
2. **Bundle Ollama**: Package AI engine with the app
3. **Create MSIX**: Generate Microsoft Store package
4. **Sign Package**: Apply code signing for security
5. **Prepare Store Assets**: Create icons, screenshots, and listings
6. **Submit to Store**: Upload through Partner Center

## 👨‍💻 Development Learnings

Through building OneNote Groomer, I gained experience with:

- **Cross-platform development** with Flutter for desktop
- **AI integration** in desktop applications
- **Local LLM deployment** and optimization
- **Microsoft Store submission** process
- **MSIX packaging** and signing
- **Material Design implementation** with custom theming
- **Document format conversion** techniques
- **Windows SDK integration** for packaging
- **Installer script creation** with PowerShell

## 🔍 Future Enhancements

- **Multi-file Processing**: Batch conversion of multiple files
- **Template Gallery**: Pre-built extraction templates
- **Custom Model Support**: Bring-your-own AI model option
- **Advanced Excel Formatting**: Styling options for output
- **Cloud Integration Option**: Optional cloud backup (while maintaining privacy)
- **Embedded Visualizations**: Charts and graphs from extracted data

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Contact

For questions or feedback, please contact:
- **Developer**: [Your Name]
- **Email**: [your.email@example.com]