@echo off
echo Stopping OneNote Groomer...
taskkill /f /im onenote_to_excel.exe 2>nul
taskkill /f /im ollama.exe 2>nul
echo OneNote Groomer stopped.
pause
