# OneNote Groomer - Startup Script
param([switch]$Silent)

if (-not $Silent) {
    Write-Host "馃 Starting OneNote Groomer..." -ForegroundColor Green
}

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ollamaPath = Join-Path $scriptDir "ollama\ollama.exe"
$appPath = Join-Path $scriptDir "onenote_to_excel.exe"

# Check if Ollama is available
if (-not (Test-Path $ollamaPath)) {
    Write-Host "鈿狅笍 Ollama not found. Please run setup_ollama.bat first." -ForegroundColor Yellow
    Write-Host "Or follow instructions in ollama\SETUP_INSTRUCTIONS.txt" -ForegroundColor Yellow
    pause
    exit 1
}

# Set Ollama environment
$env:OLLAMA_HOME = Join-Path $scriptDir "ollama"
$env:OLLAMA_MODELS = Join-Path $scriptDir "ollama\models"
$env:OLLAMA_HOST = "127.0.0.1:11434"

# Check if Ollama is already running
$ollamaRunning = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
if (-not $ollamaRunning) {
    if (-not $Silent) {
        Write-Host "Starting Ollama..." -ForegroundColor Cyan
    }
    Start-Process -FilePath $ollamaPath -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 3
}

# Start main app
if (-not $Silent) {
    Write-Host "Starting OneNote Groomer..." -ForegroundColor Cyan
}
Start-Process -FilePath $appPath
