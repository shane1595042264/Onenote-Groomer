# OneNote Groomer - Smart Installer Script
# Downloads and bundles Ollama with the app

param(
    [string]$AppPath = "..\build\windows\x64\runner\Release",
    [string]$OutputPath = ".\OneNoteGroomer-Installer",
    [string]$OllamaVersion = "latest"
)

Write-Host "🚀 OneNote Groomer - Bundled Installer Creator" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green

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

# Step 2: Download Ollama
Write-Host "🤖 Downloading Ollama..." -ForegroundColor Cyan
$ollamaDir = "$OutputPath\ollama"
New-Item -ItemType Directory -Path $ollamaDir -Force | Out-Null

try {
    # Download Ollama Windows binary
    $ollamaUrl = "https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip"
    $ollamaZip = "$ollamaDir\ollama.zip"
    
    Write-Host "Downloading from: $ollamaUrl" -ForegroundColor Gray
    Invoke-WebRequest -Uri $ollamaUrl -OutFile $ollamaZip
    
    # Extract Ollama
    Expand-Archive -Path $ollamaZip -DestinationPath $ollamaDir -Force
    Remove-Item $ollamaZip
    
    Write-Host "✅ Ollama downloaded and extracted" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to download Ollama: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Create Ollama configuration
Write-Host "⚙️ Creating Ollama configuration..." -ForegroundColor Cyan

# Create models directory
$modelsDir = "$ollamaDir\models"
New-Item -ItemType Directory -Path $modelsDir -Force | Out-Null

# Create Ollama config
$ollamaConfig = @"
{
  "host": "127.0.0.1:11434",
  "origins": ["*"],
  "models": "$modelsDir"
}
"@

$ollamaConfig | Out-File -FilePath "$ollamaDir\config.json" -Encoding UTF8

Write-Host "✅ Ollama configuration created" -ForegroundColor Green

# Step 4: Download default model (optional - can be large)
$downloadModel = Read-Host "📥 Download llama2:7b model? (~4GB) [y/N]"
if ($downloadModel -eq "y" -or $downloadModel -eq "Y") {
    Write-Host "🧠 Downloading llama2:7b model..." -ForegroundColor Cyan
    Write-Host "⚠️ This will take several minutes and requires ~4GB space" -ForegroundColor Yellow
    
    try {
        # Start Ollama temporarily to download model
        $ollamaProcess = Start-Process -FilePath "$ollamaDir\ollama.exe" -ArgumentList "serve" -PassThru -WindowStyle Hidden
        Start-Sleep -Seconds 5
        
        # Download model
        & "$ollamaDir\ollama.exe" pull llama2:7b
        
        # Stop Ollama
        Stop-Process -Id $ollamaProcess.Id -Force
        
        Write-Host "✅ Model downloaded successfully" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Could not download model automatically. Users can download it later." -ForegroundColor Yellow
    }
} else {
    Write-Host "⏭️ Skipping model download. Users will download on first use." -ForegroundColor Yellow
}

# Step 5: Create startup scripts
Write-Host "📝 Creating startup scripts..." -ForegroundColor Cyan

# Create PowerShell startup script
$startupScript = @"
# OneNote Groomer - Ollama Startup Script
param([switch]`$Silent)

if (-not `$Silent) {
    Write-Host "🤖 Starting OneNote Groomer with bundled Ollama..." -ForegroundColor Green
}

# Get script directory
`$scriptDir = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$ollamaPath = Join-Path `$scriptDir "ollama\ollama.exe"
`$appPath = Join-Path `$scriptDir "onenote_to_excel.exe"

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

# Step 6: Create installer info
Write-Host "📄 Creating installer documentation..." -ForegroundColor Cyan

$readmeContent = @"
# OneNote Groomer - Bundled Installer

## 🚀 What's Included
- OneNote Groomer application
- Bundled Ollama AI engine
- Pre-configured setup (no technical knowledge required)

## 📦 Installation
1. Extract this folder to your desired location (e.g., C:\Program Files\OneNote Groomer)
2. Run "OneNote Groomer.bat" to start the application
3. On first run, Ollama will automatically set up (may take a few minutes)

## 🎯 Quick Start
- **Launch**: Double-click "OneNote Groomer.bat"
- **Stop**: Double-click "Stop OneNote Groomer.bat"
- **Uninstall**: Simply delete this folder

## 🔧 System Requirements
- Windows 10/11 (64-bit)
- 8GB RAM minimum (16GB recommended)
- 5GB free disk space
- Internet connection (for initial AI model download)

## 📋 Folder Structure
```
OneNoteGroomer-Installer/
├── onenote_to_excel.exe          # Main application
├── OneNote Groomer.bat           # Start application
├── Stop OneNote Groomer.bat      # Stop application
├── start_onenote_groomer.ps1     # PowerShell startup script
├── ollama/                       # Bundled AI engine
│   ├── ollama.exe               # Ollama executable
│   ├── config.json              # Ollama configuration
│   └── models/                  # AI models directory
└── README.txt                   # This file
```

## 🆘 Troubleshooting
1. **App won't start**: Run as Administrator
2. **AI not working**: Check Windows Defender/Antivirus settings
3. **Performance issues**: Close other applications, ensure 8GB+ RAM
4. **Model download fails**: Check internet connection

## 📞 Support
For support, visit: [Your Support URL]

## 🔒 Privacy
- All AI processing happens locally on your computer
- No data is sent to external servers
- Your OneNote files stay private

Version: 1.0.0
Build Date: $(Get-Date -Format 'yyyy-MM-dd')
"@

$readmeContent | Out-File -FilePath "$OutputPath\README.txt" -Encoding UTF8

# Step 7: Calculate total size
$totalSize = (Get-ChildItem $OutputPath -Recurse | Measure-Object -Property Length -Sum).Sum
$sizeGB = [math]::Round($totalSize / 1GB, 2)

Write-Host "✅ Installer package created successfully!" -ForegroundColor Green
Write-Host "📍 Location: $OutputPath" -ForegroundColor Cyan
Write-Host "📦 Total size: $sizeGB GB" -ForegroundColor Cyan
Write-Host "🎯 Ready for distribution!" -ForegroundColor Green

Write-Host "`n🚀 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Test the installer on a clean Windows machine" -ForegroundColor White
Write-Host "2. Create MSIX package for Microsoft Store" -ForegroundColor White
Write-Host "3. Sign the executable with code signing certificate" -ForegroundColor White
Write-Host "4. Submit to Microsoft Store for review" -ForegroundColor White

Write-Host "`n💡 For Microsoft Store submission:" -ForegroundColor Yellow
Write-Host "Run: .\create_msix_package.ps1" -ForegroundColor White
