# macOS Build Guide for DocFlow AI

## Prerequisites (macOS Required)
- macOS 10.15 or later
- Xcode 12.0 or later
- Flutter SDK
- CocoaPods

## Build Steps

### 1. Setup macOS Development Environment
```bash
# Install Xcode from App Store
# Install CocoaPods
sudo gem install cocoapods

# Verify Flutter setup
flutter doctor
```

### 2. Configure Project for macOS
```bash
# Navigate to project directory
cd onenote_to_excel

# Enable macOS support (if not already enabled)
flutter config --enable-macos-desktop
flutter create --platforms=macos .

# Install dependencies
flutter pub get
cd macos && pod install && cd ..
```

### 3. Build for macOS
```bash
# Debug build
flutter run -d macos

# Release build
flutter build macos --release

# The app will be created at:
# build/macos/Build/Products/Release/DocFlowAI.app
```

### 4. Create Distributable Package
```bash
# Create DMG installer (requires additional tools)
# Option 1: Manual packaging
cp -r build/macos/Build/Products/Release/DocFlowAI.app ~/Desktop/

# Option 2: Use create-dmg tool
brew install create-dmg
create-dmg \
  --volname "DocFlow AI Installer" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "DocFlowAI.app" 175 120 \
  --hide-extension "DocFlowAI.app" \
  --app-drop-link 425 120 \
  "DocFlowAI-Installer.dmg" \
  build/macos/Build/Products/Release/
```

## Code Signing & Notarization (For Distribution)
For App Store or public distribution, you need:
1. Apple Developer Account ($99/year)
2. Code signing certificates
3. App notarization through Apple

```bash
# Sign the app
codesign --force --deep --sign "Developer ID Application: Your Name" DocFlowAI.app

# Notarize (requires Apple Developer account)
xcrun notarytool submit DocFlowAI-Installer.dmg \
  --apple-id your-apple-id@email.com \
  --password your-app-specific-password \
  --team-id YOUR_TEAM_ID
```

## Alternative: CI/CD Build
If you don't have a Mac, use GitHub Actions:
```yaml
# .github/workflows/macos-build.yml
name: Build macOS App
on: [push]
jobs:
  build-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build macos --release
      - uses: actions/upload-artifact@v3
        with:
          name: macos-app
          path: build/macos/Build/Products/Release/
```
