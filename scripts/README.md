# Scripts

This folder contains automation scripts and utilities for building, packaging, and managing the OneNote-to-Excel converter.

## PowerShell Scripts (.ps1):
- `create_package.ps1` - Package the app for distribution
- `setup_github.ps1` - GitHub repository setup
- `debug_onenote.ps1` - OneNote debugging utilities
- `extract_*.ps1` - Data extraction scripts
- `examine_onenote.ps1` - OneNote file examination

## Batch Files (.bat):
- `test_package.bat` - Package testing script

## Usage:
Run PowerShell scripts from the project root:
```powershell
.\scripts\[script_name].ps1
```

Run batch files:
```cmd
scripts\[script_name].bat
```

Note: Some scripts may require elevated permissions or specific software installations (OneNote, Excel, etc.).
