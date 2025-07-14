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
