@echo off
echo OneNote Groomer - Package Verification Test
echo ==========================================
echo.

cd /d "%~dp0OneNote-Groomer-Windows"

echo Testing package contents...
echo.

echo Checking required files:
if exist "onenote_to_excel.exe" (
    echo [✓] Main executable found
) else (
    echo [✗] Main executable missing
    goto :error
)

if exist "flutter_windows.dll" (
    echo [✓] Flutter runtime found
) else (
    echo [✗] Flutter runtime missing
    goto :error
)

if exist "data\" (
    echo [✓] Data folder found
) else (
    echo [✗] Data folder missing
    goto :error
)

if exist "Quick Setup.bat" (
    echo [✓] Quick Setup script found
) else (
    echo [✗] Quick Setup script missing
    goto :error
)

if exist "Start OneNote Groomer.bat" (
    echo [✓] Startup script found
) else (
    echo [✗] Startup script missing
    goto :error
)

if exist "SETUP_GUIDE.md" (
    echo [✓] Setup guide found
) else (
    echo [✗] Setup guide missing
    goto :error
)

echo.
echo [✓] All required files present!
echo.
echo Testing application startup...
echo Note: This will launch the app briefly to test if it runs.
echo Close the app window when it appears.
echo.
pause

start "" "onenote_to_excel.exe"
timeout /t 3 /nobreak >nul

echo.
echo Package verification complete!
echo.
echo The package is ready for distribution.
echo You can now:
echo 1. Upload OneNote-Groomer-Windows-v1.0.0.zip to GitHub Releases
echo 2. Share the download link with users
echo 3. Test the Quick Setup on a different computer
echo.
pause
goto :end

:error
echo.
echo [✗] Package verification failed!
echo Please rebuild the package and try again.
echo.
pause

:end
