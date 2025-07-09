# OneNote to Excel Converter

A powerful Flutter application that converts OneNote files to Excel format using AI processing with Ollama/Llama2. This tool extracts raw content from OneNote files and intelligently structures it according to user-provided templates or custom prompts.

## Features

- **OneNote File Processing**: Extracts content from .one and .onepkg files
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

1. **Launch the application**
2. **Drop or select a OneNote file** (.one or .onepkg)
3. **Choose processing method**:
   - Use a custom prompt to define what data to extract
   - Upload an Excel template to match its structure
4. **Click "Process OneNote File"** to start extraction
5. **Review and export** the results to Excel
6. **Use built-in buttons** to open the result or save to another location

## Custom Prompts

The application supports custom prompts to define exactly what data to extract. Example:

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
