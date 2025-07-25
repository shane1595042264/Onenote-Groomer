# OneNote Groomer - MSIX Package Creator for Microsoft Store
# Creates a deployable MSIX package

param(
    [string]$SourcePath = ".\OneNoteGroomer-Installer",
    [string]$OutputPath = ".\MSIX",
    [string]$AppVersion = "1.0.0.0",
    [string]$PublisherName = "CN=YourCompanyName",
    [switch]$SkipSigning
)

Write-Host "📦 OneNote Groomer - MSIX Package Creator" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# Check prerequisites and find Windows SDK tools
Write-Host "🔍 Searching for Windows SDK tools..." -ForegroundColor Cyan

# Common Windows SDK installation paths
$sdkPaths = @(
    "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64",
    "${env:ProgramFiles}\Windows Kits\10\bin\*\x64",
    "${env:ProgramFiles(x86)}\Windows Kits\10\bin\x64",
    "${env:ProgramFiles}\Windows Kits\10\bin\x64",
    "${env:ProgramFiles(x86)}\Microsoft SDKs\Windows\*\bin\x64",
    "${env:ProgramFiles}\Microsoft SDKs\Windows\*\bin\x64"
)

# Function to find a tool in SDK paths
function Find-SDKTool {
    param([string]$toolName)
    
    # First check if it's already in PATH
    $tool = Get-Command $toolName -ErrorAction SilentlyContinue
    if ($tool) {
        return $tool.Source
    }
    
    # Expand wildcards and search in SDK paths
    foreach ($basePath in $sdkPaths) {
        $expandedPaths = @(Get-ChildItem -Path ($basePath -replace '\*', '') -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
        if ($basePath -like '*\*\x64') {
            $wildcardRoot = $basePath -replace '\*\\x64$', ''
            $expandedPaths = @(Get-ChildItem -Path $wildcardRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object { Join-Path $_.FullName 'x64' })
        } else {
            $expandedPaths = @($basePath)
        }
        foreach ($searchPath in $expandedPaths) {
            $toolPath = Get-ChildItem -Path $searchPath -Filter $toolName -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($toolPath) {
                return $toolPath.FullName
            }
        }
    }
    
    return $null
}

# Find the tools
$makeppri = Find-SDKTool "makepri.exe"
$makeappx = Find-SDKTool "makeappx.exe"
$signtool = Find-SDKTool "signtool.exe"

Write-Host "Tool locations:" -ForegroundColor Gray
Write-Host ("  makepri.exe: " + $(if ($makeppri) { $makeppri } else { 'Not found' })) -ForegroundColor Gray
Write-Host ("  makeappx.exe: " + $(if ($makeappx) { $makeappx } else { 'Not found' })) -ForegroundColor Gray
Write-Host ("  signtool.exe: " + $(if ($signtool) { $signtool } else { 'Not found' })) -ForegroundColor Gray

if (-not $makeppri -or -not $makeappx) {
    Write-Host "❌ Windows SDK tools not found!" -ForegroundColor Red
    Write-Host "Please install Windows 10/11 SDK with the following components:" -ForegroundColor Yellow
    Write-Host "- Windows App Certification Kit" -ForegroundColor White
    Write-Host "- MSBuild Tools" -ForegroundColor White
    Write-Host "- Windows SDK Signing Tools" -ForegroundColor White
    Write-Host "" -ForegroundColor White
    Write-Host "Or add the SDK bin directory to your PATH environment variable." -ForegroundColor Yellow
    Write-Host "Common SDK locations:" -ForegroundColor Yellow
    foreach ($path in $sdkPaths) {
        if (Test-Path $path.Replace('*', '10.0.22621.0')) {
            Write-Host "  $($path.Replace('*', '10.0.22621.0'))" -ForegroundColor White
        }
    }
    exit 1
}

Write-Host "✅ Windows SDK tools found" -ForegroundColor Green

# Create output directory
if (Test-Path $OutputPath) {
    Remove-Item $OutputPath -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
New-Item -ItemType Directory -Path "$OutputPath\Package" -Force | Out-Null

# Step 1: Create App Manifest
Write-Host "📄 Creating Package Manifest..." -ForegroundColor Cyan

 $manifestContent = @"
<?xml version="1.0" encoding="utf-8"?>
<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
         xmlns:mp="http://schemas.microsoft.com/appx/2014/phone/manifest"
         xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
         xmlns:uap3="http://schemas.microsoft.com/appx/manifest/uap/windows10/3"
         xmlns:desktop="http://schemas.microsoft.com/appx/manifest/desktop/windows10"
         xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"
         IgnorableNamespaces="rescap mp uap uap3 desktop">

  <Identity Name="A-PLUS.OnenoteGroomer"
            Publisher="CN=25D94FEB-B89E-4816-BB32-35995EAF1AFB"
            Version="$AppVersion" />

  <mp:PhoneIdentity PhoneProductId="12345678-1234-1234-1234-123456789012" PhonePublisherId="00000000-0000-0000-0000-000000000000"/>

  <Properties>
    <DisplayName>OneNote Groomer</DisplayName>
    <PublisherDisplayName>A-PLUS</PublisherDisplayName>
    <Logo>Images\StoreLogo.png</Logo>
    <Description>Convert OneNote files to Excel using AI. Extract, process, and organize your notes efficiently with built-in AI processing.</Description>
  </Properties>

  <Dependencies>
    <TargetDeviceFamily Name="Windows.Universal" MinVersion="10.0.17763.0" MaxVersionTested="10.0.22621.0" />
  </Dependencies>

  <Resources>
    <Resource Language="en-us"/>
  </Resources>

  <Applications>
    <Application Id="OneNoteGroomer"
                 Executable="onenote_to_excel.exe"
                 EntryPoint="Windows.FullTrustApplication">
      <uap:VisualElements
        DisplayName="OneNote Groomer"
        Description="AI-powered OneNote to Excel converter"
        BackgroundColor="transparent"
        Square150x150Logo="Images\Square150x150Logo.png"
        Square44x44Logo="Images\Square44x44Logo.png">
        <uap:DefaultTile Wide310x150Logo="Images\Wide310x150Logo.png" />
        <uap:SplashScreen Image="Images\SplashScreen.png" />
      </uap:VisualElements>
      
      <Extensions>
        <uap:Extension Category="windows.fileTypeAssociation">
          <uap:FileTypeAssociation Name="onenote">
            <uap:SupportedFileTypes>
              <uap:FileType>.one</uap:FileType>
            </uap:SupportedFileTypes>
          </uap:FileTypeAssociation>
        </uap:Extension>
        
        <desktop:Extension Category="windows.fullTrustProcess" Executable="onenote_to_excel.exe" />
      </Extensions>
    </Application>
  </Applications>

  <Capabilities>
    <Capability Name="internetClient" />
    <uap:Capability Name="removableStorage" />
    <rescap:Capability Name="runFullTrust" />
  </Capabilities>
</Package>
"@

$manifestContent | Out-File -FilePath "$OutputPath\Package\AppxManifest.xml" -Encoding UTF8

Write-Host "✅ Package manifest created" -ForegroundColor Green

# Step 2: Copy application files
Write-Host "📂 Copying application files..." -ForegroundColor Cyan

if (-not (Test-Path $SourcePath)) {
    Write-Host "❌ Source path not found: $SourcePath" -ForegroundColor Red
    Write-Host "Please run create_bundled_installer.ps1 first" -ForegroundColor Yellow
    exit 1
}

Copy-Item "$SourcePath\*" -Destination "$OutputPath\Package" -Recurse -Force
Write-Host "✅ Application files copied" -ForegroundColor Green

# Step 3: Create app icons
Write-Host "🎨 Creating application icons..." -ForegroundColor Cyan

$imagesDir = "$OutputPath\Package\Images"
New-Item -ItemType Directory -Path $imagesDir -Force | Out-Null

# Create placeholder icons (you should replace these with actual icons)
$iconSizes = @(
    @{Name="Square44x44Logo.png"; Size=44},
    @{Name="Square150x150Logo.png"; Size=150},
    @{Name="Wide310x150Logo.png"; Width=310; Height=150},
    @{Name="StoreLogo.png"; Size=50},
    @{Name="SplashScreen.png"; Width=620; Height=300}
)

foreach ($icon in $iconSizes) {
    if ($icon.Width) {
        $width = $icon.Width
        $height = $icon.Height
    } else {
        $width = $height = $icon.Size
    }
    
    # Create a simple colored rectangle as placeholder
    # In production, replace with actual icons
    $iconPath = "$imagesDir\$($icon.Name)"
    
    # Create a simple PNG placeholder (you should replace with actual icons)
    $iconContent = @"
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==
"@
    
    [System.Convert]::FromBase64String($iconContent) | Set-Content -Path $iconPath -Encoding Byte
}

Write-Host "⚠️ Placeholder icons created - replace with actual icons before submission" -ForegroundColor Yellow

# Step 4: Create resource index
Write-Host "📋 Creating resource index..." -ForegroundColor Cyan

try {
    & $makeppri new /pr "$OutputPath\Package" /cf "$OutputPath\Package\priconfig.xml" /of "$OutputPath\Package\resources.pri" /o
    Write-Host "✅ Resource index created" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Resource index creation failed, continuing..." -ForegroundColor Yellow
}

# Step 5: Create MSIX package
Write-Host "📦 Creating MSIX package..." -ForegroundColor Cyan

try {
    & $makeappx pack /d "$OutputPath\Package" /p "$OutputPath\OneNoteGroomer.msix" /o
    Write-Host "✅ MSIX package created successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create MSIX package: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 6: Sign the package (if not skipped)
if (-not $SkipSigning) {
    Write-Host "🔒 Signing MSIX package..." -ForegroundColor Cyan
    
    if (-not $signtool) {
        Write-Host "⚠️ SignTool not found - skipping signing" -ForegroundColor Yellow
        Write-Host "Install Windows SDK or use -SkipSigning parameter" -ForegroundColor Yellow
    } else {
        # Check for certificate
        $certPath = "$OutputPath\TempCert.pfx"
        
        # Create a temporary self-signed certificate for testing
        try {
            $cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject $PublisherName -KeyUsage DigitalSignature -FriendlyName "OneNote Groomer Code Signing" -CertStoreLocation "Cert:\CurrentUser\My"
            $certPassword = ConvertTo-SecureString -String "TempPassword123!" -Force -AsPlainText
            Export-PfxCertificate -Cert $cert -FilePath $certPath -Password $certPassword | Out-Null
            
            & $signtool sign /fd SHA256 /a /f $certPath /p "TempPassword123!" "$OutputPath\OneNoteGroomer.msix"
            
            Remove-Item $certPath -Force
            Remove-Item "Cert:\CurrentUser\My\$($cert.Thumbprint)" -Force
            
            Write-Host "✅ Package signed with temporary certificate" -ForegroundColor Green
            Write-Host "⚠️ For production, use a proper code signing certificate" -ForegroundColor Yellow
        } catch {
            Write-Host "⚠️ Failed to sign package: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "⏭️ Skipping package signing" -ForegroundColor Yellow
}

# Step 7: Create Store submission package
Write-Host "🏪 Creating Store submission package..." -ForegroundColor Cyan

$submissionDir = "$OutputPath\StoreSubmission"
New-Item -ItemType Directory -Path $submissionDir -Force | Out-Null

# Copy MSIX package
Copy-Item "$OutputPath\OneNoteGroomer.msix" -Destination $submissionDir

# Create submission notes
$submissionNotes = @"
# OneNote Groomer - Microsoft Store Submission Package

## 📦 Package Information
- **App Name**: OneNote Groomer
- **Version**: $AppVersion
- **Package Type**: MSIX
- **Target Platforms**: Windows 10 (1809+), Windows 11

## 🎯 App Description
OneNote Groomer is an AI-powered desktop application that converts OneNote files to Excel format. 
Key features:
- Drag & drop OneNote (.one) files
- AI-powered content extraction
- Excel template support
- Local AI processing (bundled Ollama)
- Privacy-focused (no cloud processing)

## 🔧 Technical Details
- **Framework**: Flutter Windows Desktop
- **AI Engine**: Bundled Ollama (local processing)
- **File Support**: .one (OneNote), .xlsx/.xls (Excel)
- **System Requirements**: Windows 10/11 64-bit, 8GB RAM, 5GB storage

## 🔒 Privacy & Security
- All AI processing happens locally
- No data transmitted to external servers
- User files remain private and secure
- Bundled AI engine eliminates external dependencies

## 📋 Store Requirements Checklist
- ✅ MSIX package format
- ✅ Full trust application capability
- ✅ File type associations (.one files)
- ⚠️ Code signing certificate needed for production
- ⚠️ Replace placeholder icons with actual app icons
- ⚠️ Update publisher information

## 🎨 Assets Needed for Store
- App icon (multiple sizes)
- Screenshots (multiple resolutions)
- Store listing images
- App description and features list

## 🚀 Submission Steps
1. Replace placeholder icons with actual app icons
2. Sign with valid code signing certificate
3. Create Microsoft Partner Center account
4. Upload MSIX package
5. Fill out store listing details
6. Submit for certification

Build Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

$submissionNotes | Out-File -FilePath "$submissionDir\SUBMISSION_NOTES.md" -Encoding UTF8

# Calculate package size
$packageSize = (Get-Item "$OutputPath\OneNoteGroomer.msix").Length
$sizeMB = [math]::Round($packageSize / 1MB, 2)

Write-Host "✅ Store submission package created!" -ForegroundColor Green
Write-Host "📍 Location: $submissionDir" -ForegroundColor Cyan
Write-Host "📦 Package size: $sizeMB MB" -ForegroundColor Cyan

Write-Host "`n🚀 Next Steps for Microsoft Store:" -ForegroundColor Yellow
Write-Host "1. Replace placeholder icons in Package\Images\" -ForegroundColor White
Write-Host "2. Get a valid code signing certificate" -ForegroundColor White
Write-Host "3. Re-sign the package with production certificate" -ForegroundColor White
Write-Host "4. Create Microsoft Partner Center account" -ForegroundColor White
Write-Host "5. Upload to Partner Center and complete store listing" -ForegroundColor White

Write-Host "`n📁 Generated Files:" -ForegroundColor Yellow
Write-Host "- OneNoteGroomer.msix (main package)" -ForegroundColor White
Write-Host "- SUBMISSION_NOTES.md (submission guide)" -ForegroundColor White
Write-Host "- Package\ (source files for modifications)" -ForegroundColor White
