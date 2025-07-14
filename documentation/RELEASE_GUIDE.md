# GitHub Release Guide for OneNote Groomer

## Creating a Release on GitHub

### Step 1: Push Your Code to GitHub
1. Make sure all changes are committed:
   ```bash
   git add .
   git commit -m "Add deployment package and setup guides"
   git push origin main
   ```

### Step 2: Create a Release on GitHub
1. Go to your repository on GitHub
2. Click on "Releases" (in the right sidebar)
3. Click "Create a new release"

### Step 3: Fill in Release Information
- **Tag version**: `v1.0.0`
- **Release title**: `OneNote Groomer v1.0.0 - Windows Release`
- **Description**:
```markdown
# OneNote Groomer v1.0.0 🚀

Transform your OneNote files into structured Excel data using AI!

## What's New
- Complete Windows application with GUI
- AI-powered content extraction using Ollama
- Drag-and-drop OneNote file support
- Custom prompt system for flexible data extraction
- Built-in Excel export with "Open" and "Save As" buttons
- Clean, modern interface

## Download & Install
1. Download `OneNote-Groomer-Windows-v1.0.0.zip` below
2. Extract to any folder
3. Run `Quick Setup.bat` to install AI dependencies
4. Use `Start OneNote Groomer.bat` to launch the app

## System Requirements
- Windows 10/11 (64-bit)
- 4GB+ RAM (8GB+ recommended for better performance)
- 2GB+ free disk space
- Internet connection for initial AI model download

## Features
✅ OneNote (.one, .onepkg) file processing  
✅ AI-powered content structuring  
✅ Custom extraction prompts  
✅ Excel template support  
✅ Drag-and-drop interface  
✅ Local processing (privacy-first)  
✅ No cloud dependencies  

## Quick Start
1. Extract the ZIP file
2. Run "Quick Setup.bat" (one-time setup)
3. Run "Start OneNote Groomer.bat"
4. Drag your OneNote file into the app
5. Click "Process OneNote File"
6. Export to Excel!

## Documentation
- 📖 Read `SETUP_GUIDE.md` for detailed setup instructions
- 💡 Check `README.md` for technical information
- 🔧 Use "Quick Setup.bat" for automated AI setup

## Support
- 🐛 Report bugs in [Issues](https://github.com/YOUR_USERNAME/onenote-to-excel/issues)
- 💬 Ask questions in [Discussions](https://github.com/YOUR_USERNAME/onenote-to-excel/discussions)
- ⭐ Star this repository if you find it useful!

## Privacy
- All processing happens locally on your computer
- No data is sent to external servers
- Your OneNote content stays private

---

**First time using AI tools?** Don't worry! The setup is designed for beginners with step-by-step instructions.
```

### Step 4: Upload the Release File
1. In the "Attach binaries" section, drag and drop:
   - `OneNote-Groomer-Windows-v1.0.0.zip`
2. The file will be uploaded automatically

### Step 5: Publish the Release
1. Choose "Set as the latest release" ✅
2. Click "Publish release"

## After Publishing

### Update README with Download Link
Update your main README.md to include the download link:

```markdown
## Download

📥 **[Download OneNote Groomer v1.0.0 for Windows](https://github.com/YOUR_USERNAME/onenote-to-excel/releases/latest)**

- File: `OneNote-Groomer-Windows-v1.0.0.zip` (10.8 MB)
- Includes: Application + Setup guides + Quick installer
- Requirements: Windows 10/11, 4GB+ RAM
```

### Promote Your Release
1. **Share on social media** with screenshots
2. **Post on relevant forums** (Reddit, Discord, etc.)
3. **Add to software directories** (AlternativeTo, SourceForge, etc.)
4. **Create a demo video** showing the setup and usage

## Version Management

### For Future Updates
1. Update version in `pubspec.yaml`
2. Build new release: `flutter build windows --release`
3. Run packaging script: `.\create_package.ps1`
4. Create new GitHub release with incremented version

### Hotfixes
- Use version format: `v1.0.1`, `v1.0.2`, etc.
- For major updates: `v1.1.0`, `v2.0.0`, etc.

## Release Checklist

Before each release, ensure:
- [ ] Code builds without errors
- [ ] All tests pass
- [ ] Documentation is updated
- [ ] Version numbers are incremented
- [ ] Release notes are comprehensive
- [ ] ZIP file is tested on a clean machine
- [ ] Setup scripts work correctly

## Analytics

Track your release success:
- **Download counts** (visible on GitHub)
- **Star growth** (repository stars)
- **Issue reports** (feedback quality)
- **User discussions** (engagement level)

---

Ready to share your OneNote Groomer with the world! 🌟
