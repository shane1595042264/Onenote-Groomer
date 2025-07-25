@echo off
echo ?? OneNote Groomer - Ollama Auto-Setup
echo =====================================
echo.
echo This will download and setup Ollama automatically.
echo Press Ctrl+C to cancel, or any key to continue...
pause >nul

echo.
echo ?? Downloading Ollama...
powershell -Command "& {
    try {
        $url = 'https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.exe'
        $output = '.\ollama\ollama.exe'
        Write-Host 'Downloading from: ' + $url
        Invoke-WebRequest -Uri $url -OutFile $output
        Write-Host '??Ollama downloaded successfully'
    } catch {
        Write-Host '??Download failed: ' + $_.Exception.Message
        Write-Host 'Please download manually from: https://ollama.com/download/windows'
        pause
        exit 1
    }
}"

if exist ".\ollama\ollama.exe" (
    echo.
    echo ?? Downloading AI model (this may take several minutes)...
    echo Please wait while llama2:7b model downloads (~4GB)
    
    set OLLAMA_HOME=%~dp0ollama
    set OLLAMA_MODELS=%~dp0ollama\models
    
    start /wait .\ollama\ollama.exe serve
    timeout /t 3 /nobreak >nul
    .\ollama\ollama.exe pull llama2:7b
    
    echo.
    echo ??Setup complete! OneNote Groomer is ready to use.
    echo Run "OneNote Groomer.bat" to start the application.
) else (
    echo.
    echo ??Ollama download failed. Please follow manual setup instructions.
    echo See: ollama\SETUP_INSTRUCTIONS.txt
)

echo.
pause
