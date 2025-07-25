# OneNote Groomer

A powerful Flutter application that converts OneNote files to Excel format using AI processing with Ollama/Llama2. This tool extracts raw content from OneNote files and intelligently structures it according to user-provided templates or custom prompts.

## 📥 Download

**[⬇️ Download OneNote Groomer v1.0.0 for Windows](https://github.com/YOUR_USERNAME/onenote-to-excel/releases/latest)**

- **File**: `OneNote-Groomer-Windows-v1.0.0.zip` (10.8 MB)
- **Includes**: Complete application + Setup guides + Quick installer
- **Requirements**: Windows 10/11, 4GB+ RAM

### Quick Start for End Users
1. Download and extract the ZIP file
2. Run `Quick Setup.bat` (installs AI dependencies)
3. Run `Start OneNote Groomer.bat` to launch
4. Drag your OneNote file and process!

## Features

- **OneNote File Processing**: Extracts content from .one and .onepkg files
- **Excel File Processing**: 🆕 Restructures messy Excel data using AI column mapping
- **AI-Powered Structuring**: Uses Ollama/Llama2 to intelligently organize data
- **Custom Prompts**: Define your own extraction criteria and output structure
- **Excel Template Support**: Use existing Excel templates as formatting guides
- **Generic Output**: No domain-specific assumptions - works with any content type
- **Clean Data Export**: Removes trailing whitespace and ensures clean Excel output
- **Modern GUI**: User-friendly interface with drag-and-drop functionality
- **File Management**: Built-in "Open Excel" and "Save As" buttons for convenience

## Prerequisites

- Flutter SDK (3.0.0 or higher)
- Ollama running locally with a language model (e.g., llama2, mistral)
- Windows OS (for OneNote file processing)

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/onenote-to-excel.git
   cd onenote-to-excel
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Make sure Ollama is running:
   ```bash
   ollama serve
   ```

4. Run the application:
   ```bash
   flutter run -d windows
   ```

## Usage

### OneNote Processing
1. **Launch the application**
2. **Drop or select a OneNote file** (.one or .onepkg)
3. **Optionally upload an Excel template** to match its structure
4. **Customize the prompt** to define what data to extract
5. **Click "Process OneNote File"** to start extraction
6. **Review and export** the results to Excel

### Excel Processing 🆕
1. **Launch the application**
2. **Drop or select an Excel file** (.xlsx or .xls) with messy/unstructured data
3. **Review the data preview** showing columns and sample data
4. **Customize the prompt** to define how to restructure the data
5. **Click "Process Excel File"** to start AI-powered column mapping
6. **Export the cleaned data** to a new Excel file

### File Management
- **Use built-in buttons** to open the result or save to another location
- **Drag and drop** support for easy file selection
- **Preview data** before processing to understand the structure

## Custom Prompts

The application supports custom prompts to define exactly what data to extract or how to restructure it.

### OneNote Extraction Example:
```
Extract business data from OneNote pages. Focus on:
- Company/Client name
- Date and time information
- Key decisions or actions
- Financial information
- Contact details
- Status or outcomes
- Any follow-up items
```

### Excel Restructuring Example: 🆕
```
Restructure this messy Excel data by mapping columns to:
- Contact names (first name, last name, full name)
- Email addresses (work, personal)
- Phone numbers (mobile, office)
- Company information
- Job titles or positions
- Addresses (business, personal)
- Clean and standardize the format
```

## Project Structure

The project is organized into the following directories:

- **`lib/`** - Main application source code
- **`windows/`** - Windows-specific build configuration
- **`test/`** - Unit tests for the application
- **`documentation/`** - All project documentation and guides
- **`testing/`** - Test scripts and testing utilities
- **`output_samples/`** - Sample input/output files and examples
- **`scripts/`** - Build, package, and automation scripts
- **`packages/`** - Compiled releases and distribution packages
- **`legacy/`** - Legacy code and deprecated files

Each folder contains a README.md with specific details about its contents.

## Technical Details

- **Architecture**: Clean separation of concerns with services for OneNote, AI processing, and Excel export
- **AI Processing**: Uses local Ollama instance for privacy and control
- **Data Cleanup**: Aggressive whitespace and formatting cleanup ensures clean Excel output
- **Field Filtering**: Only outputs fields explicitly requested in prompts
- **Cross-Platform**: Built with Flutter for Windows desktop

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with Flutter
- AI processing powered by Ollama
- Excel export using the `excel` package
