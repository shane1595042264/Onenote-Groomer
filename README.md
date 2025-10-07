# DocFlow AI


## 🚀 Project Overview

DocFlow AI is a desktop application that uses AI to extract structured data from OneNote files and convert it into organized Excel spreadsheets. It runs entirely locally, using a bundled Ollama AI engine for privacy-focused content extraction.

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
- **Packaging**: Offline enterprise bundle orchestrated by `packaging/create_enterprise_release.ps1`
- **Installation**: Self-contained with bundled Ollama runtime and models
- **Distribution**: Signed ZIP/MSIX-ready artifacts for enterprise software catalogs
- **Updates**: IT-managed rollouts via Intune, SCCM, or line-of-business delivery

## 📊 Project Structure

```
docflow_ai/
├── lib/
│   ├── main.dart             # App entry point
│   ├── models/               # Data models
│   ├── screens/              # UI screens
│   ├── services/             # Business logic (Ollama, OneNote, Excel, Word)
│   ├── theme/                # Visual theming helpers
│   └── widgets/              # Reusable components
├── packaging/                # Enterprise packaging tooling
│   ├── README.md
│   └── create_enterprise_release.ps1
├── docs/                     # Product documentation
├── testing/                  # Manual integration scripts
├── test/                     # Flutter unit/widget tests
├── windows/                  # Flutter Windows runner scaffolding
├── pubspec.yaml
└── README.md
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

### 4. Enterprise Packaging Automation
**Challenge**: Delivering a one-stop installer that embeds the Ollama runtime and large models for air-gapped teams.

**Solution**:
- Added `packaging/create_enterprise_release.ps1` to orchestrate the Flutter build, Ollama download, and model bundling
- Implemented cached downloads and environment overrides for reproducible builds
- Generated release manifests with SHA-256 hashes for security and compliance reviews
- Documented offline workflows so enterprises can pre-seed models without internet access

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
3. **Enterprise Packaging Pipeline**: Automated offline distribution with bundled Ollama runtime and manifests
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

The automated enterprise release pipeline executes the following steps:

1. **Build Flutter App** – Compile the Windows desktop runner in release mode.
2. **Stage Runtime** – Copy the binaries into `dist/DocFlowAI-Enterprise/`.
3. **Bundle Ollama** – Download the Windows Ollama CLI and embed it beside the app.
4. **Seed Models** – Pull or copy the `llama2:latest` weights into the portable bundle.
5. **Generate Manifest** – Emit `RELEASE_MANIFEST.json` with version info and SHA-256 hashes.
6. **Distribute** – Zip/sign the folder for Intune, SCCM, or other enterprise channels.

Run the automation with:

```powershell
pwsh ./packaging/create_enterprise_release.ps1 -AllowNetworkModelDownload
```

For offline environments swap in the `-ModelSourcePath` option described in [`packaging/README.md`](packaging/README.md).

## 👨‍💻 Development Learnings

Through building OneNote Groomer, I gained experience with:

- **Cross-platform development** with Flutter for desktop
- **AI integration** in desktop applications
- **Local LLM deployment** and optimization
- **Enterprise release automation** using PowerShell and scripted packaging
- **Material Design implementation** with custom theming
- **Document format conversion** techniques
- **Windows process orchestration** for background services
- **Code-signing readiness** and integrity manifest generation

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
- **Developer**: [Juntao Li]
- **Email**: [shane.juntao.li@gmail.com]
