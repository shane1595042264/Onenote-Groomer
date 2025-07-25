# OneNote Groomer - Simplified Installer Creator
# Creates installer without auto-downloading Ollama (user downloads manually)

param(
    [string]$AppPath = "..\build\windows\x64\runner\Release",
    [string]$OutputPath = ".\OneNoteGroomer-Installer"
)

Write-Host "🚀 OneNote Groomer - Simplified Installer Creator" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green

# Create output directory
if (Test-Path $OutputPath) {
    Write-Host "🗑️ Cleaning existing installer directory..." -ForegroundColor Yellow
    Remove-Item $OutputPath -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null

# Step 1: Copy main app
Write-Host "📦 Copying OneNote Groomer app..." -ForegroundColor Cyan
if (Test-Path "$AppPath\onenote_to_excel.exe") {
    Copy-Item "$AppPath\*" -Destination $OutputPath -Recurse -Force
    Write-Host "✅ App copied successfully" -ForegroundColor Green
} else {
    Write-Host "❌ App not found at $AppPath. Please build the app first." -ForegroundColor Red
    Write-Host "Run: flutter build windows --release" -ForegroundColor Yellow
    exit 1
}

# Step 2: Create Ollama setup directory
Write-Host "📁 Creating Ollama setup structure..." -ForegroundColor Cyan
$ollamaDir = "$OutputPath\ollama"
New-Item -ItemType Directory -Path $ollamaDir -Force | Out-Null
New-Item -ItemType Directory -Path "$ollamaDir\models" -Force | Out-Null

# Create download instructions for Ollama
$downloadInstructions = @"
# Ollama Setup Instructions

## 🤖 To complete the OneNote Groomer installation:

### Step 1: Download Ollama
1. Visit: https://ollama.com/download/windows
2. Download the Windows installer (ollama-windows-amd64.zip)
3. Extract the zip file
4. Copy 'ollama.exe' to this 'ollama' folder

### Step 2: Download AI Model
1. Open Command Prompt in this directory
2. Run: ollama\ollama.exe pull llama2:7b
3. Wait for the model to download (~4GB)

### Alternative: Auto-Setup Script
Run the 'setup_ollama.bat' file to automatically download and configure Ollama.

### Once setup is complete:
- Run "OneNote Groomer.bat" to start the application
- The app will automatically detect and use the bundled Ollama

For support, visit: https://github.com/shane1595042264/Onenote-Groomer
"@

$downloadInstructions | Out-File -FilePath "$ollamaDir\SETUP_INSTRUCTIONS.txt" -Encoding UTF8

# Create auto-setup script
$autoSetupScript = @"
@echo off
echo 🤖 OneNote Groomer - Ollama Auto-Setup
echo =====================================
echo.
echo This will download and setup Ollama automatically.
echo Press Ctrl+C to cancel, or any key to continue...
pause >nul

echo.
echo 📥 Downloading Ollama...
powershell -Command "& {
    try {
        `$url = 'https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.exe'
        `$output = '.\ollama\ollama.exe'
        Write-Host 'Downloading from: ' + `$url
        Invoke-WebRequest -Uri `$url -OutFile `$output
        Write-Host '✅ Ollama downloaded successfully'
    } catch {
        Write-Host '❌ Download failed: ' + `$_.Exception.Message
        Write-Host 'Please download manually from: https://ollama.com/download/windows'
        pause
        exit 1
    }
}"

if exist ".\ollama\ollama.exe" (
    echo.
    echo 🧠 Downloading AI model (this may take several minutes)...
    echo Please wait while llama2:7b model downloads (~4GB)
    
    set OLLAMA_HOME=%~dp0ollama
    set OLLAMA_MODELS=%~dp0ollama\models
    
    start /wait .\ollama\ollama.exe serve
    timeout /t 3 /nobreak >nul
    .\ollama\ollama.exe pull llama2:7b
    
    echo.
    echo ✅ Setup complete! OneNote Groomer is ready to use.
    echo Run "OneNote Groomer.bat" to start the application.
) else (
    echo.
    echo ❌ Ollama download failed. Please follow manual setup instructions.
    echo See: ollama\SETUP_INSTRUCTIONS.txt
)

echo.
pause
"@

$autoSetupScript | Out-File -FilePath "$OutputPath\setup_ollama.bat" -Encoding ASCII

# Step 3: Create startup scripts
Write-Host "📝 Creating startup scripts..." -ForegroundColor Cyan

# Create PowerShell startup script
$startupScript = @"
# OneNote Groomer - Startup Script
param([switch]`$Silent)

if (-not `$Silent) {
    Write-Host "🤖 Starting OneNote Groomer..." -ForegroundColor Green
}

# Get script directory
`$scriptDir = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$ollamaPath = Join-Path `$scriptDir "ollama\ollama.exe"
`$appPath = Join-Path `$scriptDir "onenote_to_excel.exe"

# Check if Ollama is available
if (-not (Test-Path `$ollamaPath)) {
    Write-Host "⚠️ Ollama not found. Please run setup_ollama.bat first." -ForegroundColor Yellow
    Write-Host "Or follow instructions in ollama\SETUP_INSTRUCTIONS.txt" -ForegroundColor Yellow
    pause
    exit 1
}

# Set Ollama environment
`$env:OLLAMA_HOME = Join-Path `$scriptDir "ollama"
`$env:OLLAMA_MODELS = Join-Path `$scriptDir "ollama\models"
`$env:OLLAMA_HOST = "127.0.0.1:11434"

# Check if Ollama is already running
`$ollamaRunning = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
if (-not `$ollamaRunning) {
    if (-not `$Silent) {
        Write-Host "Starting Ollama..." -ForegroundColor Cyan
    }
    Start-Process -FilePath `$ollamaPath -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 3
}

# Start main app
if (-not `$Silent) {
    Write-Host "Starting OneNote Groomer..." -ForegroundColor Cyan
}
Start-Process -FilePath `$appPath
"@

$startupScript | Out-File -FilePath "$OutputPath\start_onenote_groomer.ps1" -Encoding UTF8

# Create batch file for easy launching
$batchScript = @"
@echo off
echo Starting OneNote Groomer...
powershell -ExecutionPolicy Bypass -File "%~dp0start_onenote_groomer.ps1" -Silent
"@

$batchScript | Out-File -FilePath "$OutputPath\OneNote Groomer.bat" -Encoding ASCII

# Create uninstaller
$uninstallScript = @"
@echo off
echo Stopping OneNote Groomer...
taskkill /f /im onenote_to_excel.exe 2>nul
taskkill /f /im ollama.exe 2>nul
echo OneNote Groomer stopped.
pause
"@

$uninstallScript | Out-File -FilePath "$OutputPath\Stop OneNote Groomer.bat" -Encoding ASCII

Write-Host "✅ Startup scripts created" -ForegroundColor Green

# Step 4: Create installer documentation
Write-Host "📄 Creating installer documentation..." -ForegroundColor Cyan

$readmeContent = @"
# OneNote Groomer - Installer Package

## 🚀 Quick Setup

### Option 1: Auto-Setup (Recommended)
1. Run **setup_ollama.bat** - this will download and configure everything automatically
2. Wait for download to complete (~4GB AI model)
3. Run **OneNote Groomer.bat** to start the application

### Option 2: Manual Setup
1. Follow instructions in **ollama\SETUP_INSTRUCTIONS.txt**
2. Download Ollama manually from https://ollama.com/download/windows
3. Place ollama.exe in the ollama folder
4. Run **OneNote Groomer.bat** to start

## 🎯 What's Included
- OneNote Groomer application (ready to run)
- Ollama folder structure (for AI engine)
- Setup scripts for easy installation
- Start/stop batch files

## 📦 After Setup
- **Launch**: Double-click "OneNote Groomer.bat"
- **Stop**: Double-click "Stop OneNote Groomer.bat"
- **Uninstall**: Simply delete this folder

## 🔧 System Requirements
- Windows 10/11 (64-bit)
- 8GB RAM minimum (16GB recommended)
- 5GB free disk space
- Internet connection (for initial setup only)

## 📋 Folder Structure
```
OneNoteGroomer-Installer/
├── onenote_to_excel.exe          # Main application
├── OneNote Groomer.bat           # Start application
├── setup_ollama.bat              # Auto-setup Ollama
├── Stop OneNote Groomer.bat      # Stop application
├── start_onenote_groomer.ps1     # PowerShell startup script
└── ollama/                       # AI engine folder
    ├── SETUP_INSTRUCTIONS.txt    # Manual setup guide
    └── models/                   # AI models directory
```

## 🆘 Troubleshooting
1. **Setup fails**: Check internet connection, try manual setup
2. **App won't start**: Run as Administrator
3. **AI not working**: Ensure Ollama setup completed successfully
4. **Performance issues**: Close other applications, ensure 8GB+ RAM

## 🔒 Privacy
- All AI processing happens locally on your computer
- No data is sent to external servers
- Your OneNote files stay private

## 📞 Support
For support and updates, visit: https://github.com/shane1595042264/Onenote-Groomer

Version: 1.0.0
Build Date: $(Get-Date -Format 'yyyy-MM-dd')
"@

$readmeContent | Out-File -FilePath "$OutputPath\README.txt" -Encoding UTF8

# Calculate total size
$totalSize = (Get-ChildItem $OutputPath -Recurse | Measure-Object -Property Length -Sum).Sum
$sizeMB = [math]::Round($totalSize / 1MB, 2)

Write-Host "✅ Installer package created successfully!" -ForegroundColor Green
Write-Host "📍 Location: $OutputPath" -ForegroundColor Cyan
Write-Host "📦 Base size: $sizeMB MB (before Ollama download)" -ForegroundColor Cyan

Write-Host "`n🚀 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Test the auto-setup: Run setup_ollama.bat" -ForegroundColor White
Write-Host "2. Test the app: Run OneNote Groomer.bat" -ForegroundColor White
Write-Host "3. Create MSIX package: .\installer\create_msix_package.ps1" -ForegroundColor White
Write-Host "4. Submit to Microsoft Store" -ForegroundColor White

Write-Host "`n💡 Ready to test the installer!" -ForegroundColor Green
Write-Host "The package includes auto-setup scripts for easy Ollama installation." -ForegroundColor White
