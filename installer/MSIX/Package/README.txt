# OneNote Groomer - Installer Package

## 馃殌 Quick Setup

### Option 1: Auto-Setup (Recommended)
1. Run **setup_ollama.bat** - this will download and configure everything automatically
2. Wait for download to complete (~4GB AI model)
3. Run **OneNote Groomer.bat** to start the application

### Option 2: Manual Setup
1. Follow instructions in **ollama\SETUP_INSTRUCTIONS.txt**
2. Download Ollama manually from https://ollama.com/download/windows
3. Place ollama.exe in the ollama folder
4. Run **OneNote Groomer.bat** to start

## 馃幆 What's Included
- OneNote Groomer application (ready to run)
- Ollama folder structure (for AI engine)
- Setup scripts for easy installation
- Start/stop batch files

## 馃摝 After Setup
- **Launch**: Double-click "OneNote Groomer.bat"
- **Stop**: Double-click "Stop OneNote Groomer.bat"
- **Uninstall**: Simply delete this folder

## 馃敡 System Requirements
- Windows 10/11 (64-bit)
- 8GB RAM minimum (16GB recommended)
- 5GB free disk space
- Internet connection (for initial setup only)

## 馃搵 Folder Structure
`
OneNoteGroomer-Installer/
鈹溾攢鈹€ onenote_to_excel.exe          # Main application
鈹溾攢鈹€ OneNote Groomer.bat           # Start application
鈹溾攢鈹€ setup_ollama.bat              # Auto-setup Ollama
鈹溾攢鈹€ Stop OneNote Groomer.bat      # Stop application
鈹溾攢鈹€ start_onenote_groomer.ps1     # PowerShell startup script
鈹斺攢鈹€ ollama/                       # AI engine folder
    鈹溾攢鈹€ SETUP_INSTRUCTIONS.txt    # Manual setup guide
    鈹斺攢鈹€ models/                   # AI models directory
`

## 馃啒 Troubleshooting
1. **Setup fails**: Check internet connection, try manual setup
2. **App won't start**: Run as Administrator
3. **AI not working**: Ensure Ollama setup completed successfully
4. **Performance issues**: Close other applications, ensure 8GB+ RAM

## 馃敀 Privacy
- All AI processing happens locally on your computer
- No data is sent to external servers
- Your OneNote files stay private

## 馃摓 Support
For support and updates, visit: https://github.com/shane1595042264/Onenote-Groomer

Version: 1.0.0
Build Date: 2025-07-25
