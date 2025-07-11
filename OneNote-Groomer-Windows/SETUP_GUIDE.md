# OneNote Groomer - Complete Setup Guide

This guide will help you set up and run OneNote Groomer on your Windows computer, even if you've never used AI tools before.

## What You'll Need

- Windows 10 or Windows 11
- At least 4GB of free disk space
- Internet connection for initial setup

## Quick Start (For Experienced Users)

1. Download and extract `OneNote-Groomer-Windows.zip`
2. Install Ollama and pull a language model
3. Run `onenote_to_excel.exe`

## Detailed Setup Instructions

### Step 1: Download OneNote Groomer

1. Go to the [Releases page](https://github.com/YOUR_USERNAME/onenote-to-excel/releases)
2. Download `OneNote-Groomer-Windows.zip`
3. Extract the ZIP file to a folder like `C:\OneNote-Groomer\`

### Step 2: Install Ollama (AI Engine)

Ollama is the AI engine that processes your OneNote content. Here's how to install it:

#### Option A: Download from Website (Recommended)
1. Go to [https://ollama.ai](https://ollama.ai)
2. Click "Download for Windows"
3. Run the downloaded installer (`OllamaSetup.exe`)
4. Follow the installation wizard (accept defaults)
5. Ollama will start automatically after installation

#### Option B: Install via Command Line
1. Open PowerShell as Administrator
2. Run: `winget install Ollama.Ollama`

### Step 3: Install an AI Language Model

After installing Ollama, you need to download an AI model:

1. Open Command Prompt or PowerShell
2. Choose one of these models (start with the smallest):

   **For computers with 8GB+ RAM (Recommended):**
   ```
   ollama pull llama3.2
   ```

   **For computers with 4-6GB RAM:**
   ```
   ollama pull phi3.5
   ```

   **For older/slower computers:**
   ```
   ollama pull gemma2:2b
   ```

3. Wait for the download to complete (this may take 10-30 minutes depending on your internet speed)

### Step 4: Verify Ollama is Working

1. Open Command Prompt or PowerShell
2. Run: `ollama list`
3. You should see your downloaded model listed
4. Test it with: `ollama run llama3.2` (or whichever model you downloaded)
5. Type "Hello" and press Enter - you should get a response
6. Type `/bye` to exit the test

### Step 5: Run OneNote Groomer

1. Navigate to where you extracted OneNote Groomer
2. Double-click `onenote_to_excel.exe`
3. The application should start with a dark-themed interface

## How to Use OneNote Groomer

### Basic Usage

1. **Start the Application**: Double-click `onenote_to_excel.exe`

2. **Load a OneNote File**:
   - Drag and drop a `.one` file onto the interface, OR
   - Click "Select OneNote File" and browse to your file

3. **Configure the Extraction**:
   - Use the default prompt, OR
   - Edit the prompt to specify what data you want to extract
   - Example: "Extract names, dates, and phone numbers"

4. **Process the File**:
   - Click "Process OneNote File"
   - Wait for the AI to analyze your content (may take 1-5 minutes)

5. **Export Results**:
   - Click "Open Excel" to view the results
   - Click "Save As" to save to a specific location

### Custom Prompts

You can customize what data gets extracted by editing the prompt. Here are some examples:

**For Meeting Notes:**
```
Extract from these meeting notes:
- Attendees names
- Meeting date and time
- Action items
- Decisions made
- Next meeting date
```

**For Contact Information:**
```
Extract contact details:
- Full names
- Email addresses
- Phone numbers
- Company names
- Job titles
```

**For Project Planning:**
```
Extract project information:
- Project names
- Due dates
- Assigned team members
- Task status
- Budget information
```

## Troubleshooting

### OneNote Groomer Won't Start
- **Error: "Missing DLL"**: Make sure all files from the ZIP are in the same folder
- **Error: "Cannot find file"**: Run as Administrator
- **Antivirus blocking**: Add the folder to your antivirus exclusions

### Ollama Issues
- **"ollama command not found"**: Restart your computer after installing Ollama
- **Model download fails**: Check your internet connection and try again
- **AI responses are slow**: This is normal for the first use; subsequent uses will be faster

### Processing Issues
- **"Connection failed"**: Make sure Ollama is running (`ollama serve` in Command Prompt)
- **"No data extracted"**: Try a simpler prompt or check if your OneNote file has readable text
- **Application freezes**: Large OneNote files may take several minutes to process

### Performance Tips
- **Faster processing**: Use smaller AI models like `phi3.5` or `gemma2:2b`
- **Better accuracy**: Use larger models like `llama3.2` if you have enough RAM
- **Memory issues**: Close other applications while processing large files

## System Requirements

### Minimum Requirements
- Windows 10 (64-bit)
- 4GB RAM
- 2GB free disk space
- Intel/AMD processor (2015 or newer)

### Recommended Requirements
- Windows 11 (64-bit)
- 8GB+ RAM
- 4GB+ free disk space
- Modern Intel/AMD processor
- SSD storage for faster performance

## Supported File Types

- **OneNote Files**: `.one`, `.onepkg`
- **Export Formats**: `.xlsx` (Excel)

## Privacy and Security

- **Local Processing**: All AI processing happens on your computer
- **No Data Upload**: Your OneNote content never leaves your computer
- **No Internet Required**: After initial setup, works offline

## Getting Help

### Common Questions
- **Q: Why is it slow?** A: AI processing takes time. Larger files and more complex prompts take longer.
- **Q: Can I use other AI models?** A: Yes! Any Ollama-compatible model will work.
- **Q: Does it work with Office 365 OneNote?** A: Only with exported .one files, not cloud-based notebooks.

### Support Resources
- **GitHub Issues**: Report bugs or request features
- **Documentation**: Check the README for technical details
- **Community**: Share tips and tricks with other users

## Advanced Configuration

### Using Different AI Models
```bash
# List available models
ollama list

# Download additional models
ollama pull mistral
ollama pull codellama

# Use a specific model (modify the application if needed)
ollama run mistral
```

### Command Line Usage
For power users, you can also run the processing scripts directly:
```bash
dart run test_full_pipeline_clean.dart
```

## Updates

To update OneNote Groomer:
1. Download the latest release
2. Replace the old files with the new ones
3. Your settings and preferences will be preserved

To update Ollama:
```bash
ollama update
```

## Uninstalling

To remove OneNote Groomer:
1. Delete the application folder
2. Optionally uninstall Ollama from Windows "Add or Remove Programs"
3. Delete downloaded AI models: `ollama rm model-name`

---

**Enjoy using OneNote Groomer!** 🚀

For technical support or feature requests, visit our [GitHub repository](https://github.com/YOUR_USERNAME/onenote-to-excel).
