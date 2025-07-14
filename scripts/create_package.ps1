# OneNote Groomer - Windows Deployment Script
# This script creates a deployable package for end users

param(
    [string]$OutputDir = ".\OneNote-Groomer-Windows",
    [switch]$IncludeOllama = $false
)

Write-Host "Creating OneNote Groomer deployment package..." -ForegroundColor Green

# Create output directory
if (Test-Path $OutputDir) {
    Remove-Item $OutputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# Copy the built application
$releaseDir = ".\build\windows\x64\runner\Release"
if (Test-Path $releaseDir) {
    Write-Host "Copying application files..." -ForegroundColor Yellow
    Copy-Item "$releaseDir\*" -Destination $OutputDir -Recurse -Force
} else {
    Write-Host "Error: Release build not found. Run 'flutter build windows --release' first." -ForegroundColor Red
    exit 1
}

# Copy documentation
Write-Host "Copying documentation..." -ForegroundColor Yellow
Copy-Item "README.md" -Destination $OutputDir -Force
Copy-Item "SETUP_GUIDE.md" -Destination $OutputDir -Force

# Create a startup script
$startupScript = @"
@echo off
echo Starting OneNote Groomer...
echo.
echo Checking if Ollama is running...
tasklist /FI "IMAGENAME eq ollama.exe" 2>NUL | find /I /N "ollama.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo Ollama is running. Starting OneNote Groomer...
) else (
    echo Starting Ollama service...
    start /B ollama serve
    timeout /t 3 /nobreak >nul
)

echo.
echo Launching OneNote Groomer...
start "" "onenote_to_excel.exe"
"@

Set-Content -Path "$OutputDir\Start OneNote Groomer.bat" -Value $startupScript -Encoding ASCII

# Create quick setup script
$quickSetup = @"
@echo off
echo OneNote Groomer - Quick Setup
echo =============================
echo.
echo This will help you set up OneNote Groomer with AI capabilities.
echo.
pause

echo Step 1: Checking if Ollama is installed...
where ollama >nul 2>nul
if %errorlevel% equ 0 (
    echo Ollama is already installed!
    goto :download_model
) else (
    echo Ollama not found. Please install it first.
    echo.
    echo 1. Go to https://ollama.ai
    echo 2. Download and install Ollama for Windows
    echo 3. Run this script again
    echo.
    pause
    exit /b 1
)

:download_model
echo.
echo Step 2: Installing AI model...
echo Choose your model based on your computer specs:
echo.
echo 1. Phi3.5 (Recommended for most computers - 2.2GB)
echo 2. Llama3.2 (Better quality, requires 8GB+ RAM - 4.7GB)
echo 3. Gemma2:2b (Fastest, for older computers - 1.6GB)
echo 4. Skip (I already have a model)
echo.
set /p choice=Enter your choice (1-4): 

if "%choice%"=="1" (
    echo Installing Phi3.5...
    ollama pull phi3.5
) else if "%choice%"=="2" (
    echo Installing Llama3.2...
    ollama pull llama3.2
) else if "%choice%"=="3" (
    echo Installing Gemma2:2b...
    ollama pull gemma2:2b
) else if "%choice%"=="4" (
    echo Skipping model installation...
) else (
    echo Invalid choice. Please run the script again.
    pause
    exit /b 1
)

echo.
echo Step 3: Testing the installation...
ollama list
if %errorlevel% equ 0 (
    echo.
    echo Setup complete! You can now use OneNote Groomer.
    echo Run "Start OneNote Groomer.bat" to launch the application.
) else (
    echo.
    echo There was an issue with the setup. Please check the installation.
)

echo.
pause
"@

Set-Content -Path "$OutputDir\Quick Setup.bat" -Value $quickSetup -Encoding ASCII

# Create README for the package
$packageReadme = @"
# OneNote Groomer - Windows Package

## Quick Start
1. Run "Quick Setup.bat" to install AI dependencies
2. Run "Start OneNote Groomer.bat" to launch the application

## What's Included
- OneNote Groomer application (onenote_to_excel.exe)
- All required DLL files
- Setup and user guides
- Startup scripts

## System Requirements
- Windows 10/11 (64-bit)
- 4GB+ RAM (8GB+ recommended)
- 2GB+ free disk space
- Internet connection for initial AI model download

## First Time Setup
1. Run "Quick Setup.bat" as Administrator
2. Follow the prompts to install Ollama and AI model
3. Use "Start OneNote Groomer.bat" to launch the app

## Manual Setup (if Quick Setup fails)
1. Install Ollama from https://ollama.ai
2. Open Command Prompt and run: ollama pull phi3.5
3. Double-click onenote_to_excel.exe

## Support
- Read SETUP_GUIDE.md for detailed instructions
- Check README.md for technical information
- Report issues on GitHub

Enjoy using OneNote Groomer! 🚀
"@

Set-Content -Path "$OutputDir\README_PACKAGE.txt" -Value $packageReadme -Encoding UTF8

# Create version info
$versionInfo = @"
OneNote Groomer v1.0.0
Built on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Flutter Version: $(flutter --version | Select-String "Flutter" | Out-String).Trim()
Platform: Windows x64
"@

Set-Content -Path "$OutputDir\version.txt" -Value $versionInfo -Encoding UTF8

Write-Host "Package created successfully in: $OutputDir" -ForegroundColor Green
Write-Host ""
Write-Host "Contents:" -ForegroundColor Cyan
Get-ChildItem $OutputDir | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor White }

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Test the package by running 'Start OneNote Groomer.bat'" -ForegroundColor White
Write-Host "2. Create a ZIP file for distribution" -ForegroundColor White
Write-Host "3. Upload to GitHub Releases" -ForegroundColor White

# Optionally create ZIP file
$createZip = Read-Host "`nCreate ZIP file for distribution? (y/n)"
if ($createZip -eq 'y' -or $createZip -eq 'Y') {
    $zipPath = "OneNote-Groomer-Windows-v1.0.0.zip"
    Write-Host "Creating ZIP file: $zipPath" -ForegroundColor Yellow
    
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    
    Compress-Archive -Path "$OutputDir\*" -DestinationPath $zipPath -CompressionLevel Optimal
    Write-Host "ZIP file created: $zipPath" -ForegroundColor Green
    
    $zipSize = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
    Write-Host "File size: $zipSize MB" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Deployment package ready! 🎉" -ForegroundColor Green
