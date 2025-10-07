<#
.SYNOPSIS
Builds a production-ready Windows distribution of DocFlow AI with a bundled Ollama runtime and model.

.DESCRIPTION
This script compiles the Flutter Windows runner, stages the application alongside a portable
Ollama runtime, bundles the requested language model, and generates a release manifest.
It can either copy an existing Ollama model directory or download the model directly
using the Ollama CLI.

.EXAMPLE
./packaging/create_enterprise_release.ps1 -AllowNetworkModelDownload

.EXAMPLE
./packaging/create_enterprise_release.ps1 -ModelSourcePath 'C:/models/ollama-home'

.PARAMETER OutputDirectory
Root directory that will contain the staged release (defaults to `dist`).

.PARAMETER DistributionName
Name of the folder/zip file generated inside the output directory.

.PARAMETER ModelName
The Ollama model to include. Defaults to `llama2:latest` to match the application code.

.PARAMETER OllamaVersion
The Ollama CLI version to download for the bundled runtime.

.PARAMETER OllamaDownloadUrl
Override URL for the Ollama zip package. When not supplied the official GitHub
release URL for the selected version is used.

.PARAMETER SkipFlutterBuild
Skip rebuilding the Flutter Windows runner (expects `build/windows/x64/runner/Release` to exist).

.PARAMETER SkipCompression
Skip creation of the final `.zip` archive.

.PARAMETER AllowNetworkModelDownload
Download the requested model using the Ollama CLI during packaging. Requires network access.

.PARAMETER ModelSourcePath
Path to an existing Ollama data directory (typically `%OLLAMA_HOME%`). All contents are copied into the bundle.
Set this when you already have the model downloaded and want an offline-only packaging flow.

.NOTES
Run this script from Windows PowerShell 7+ with Flutter, git, and (optionally) 7-Zip installed.
The script must be executed on Windows because the Flutter runner and Ollama binary are Windows specific.
#>

[CmdletBinding()]
param(
    [string]$OutputDirectory = 'dist',
    [string]$DistributionName = 'DocFlowAI-Enterprise',
    [string]$ModelName = 'llama2:latest',
    [string]$OllamaVersion = '0.1.34',
    [string]$OllamaDownloadUrl,
    [switch]$SkipFlutterBuild,
    [switch]$SkipCompression,
    [switch]$AllowNetworkModelDownload,
    [string]$ModelSourcePath
)

$ErrorActionPreference = 'Stop'

function Write-Section {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Info {
    param([string]$Message)
    Write-Host "[+] $Message" -ForegroundColor Gray
}

function Ensure-Command {
    param(
        [string]$Name,
        [string]$FriendlyName
    )
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' ($FriendlyName) was not found in PATH."
    }
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repoRoot

if (-not [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
    throw 'The enterprise release workflow is only supported on Windows.'
}

if (-not (Test-Path 'pubspec.yaml')) {
    throw 'pubspec.yaml not found. Run this script from the repository root.'
}

if (-not $SkipFlutterBuild) {
    Ensure-Command -Name 'flutter' -FriendlyName 'Flutter SDK'
}

Ensure-Command -Name 'powershell' -FriendlyName 'PowerShell'

$resolvedOutputRoot = Resolve-Path -Path $OutputDirectory -ErrorAction SilentlyContinue
if (-not $resolvedOutputRoot) {
    $resolvedOutputRoot = New-Item -ItemType Directory -Path $OutputDirectory
}

$resolvedOutputRoot = $resolvedOutputRoot.ProviderPath
$stagingDir = Join-Path $resolvedOutputRoot $DistributionName
$cacheDir = Join-Path $resolvedOutputRoot '.cache'

$releaseBuildPath = Join-Path $repoRoot 'build/windows/x64/runner/Release'

if (-not $SkipFlutterBuild) {
    Write-Section 'Running Flutter build'
    & flutter pub get
    & flutter build windows --release
}

if (-not (Test-Path $releaseBuildPath)) {
    throw "Windows release build not found at $releaseBuildPath. Run 'flutter build windows --release' first or rerun without -SkipFlutterBuild."
}

Write-Section 'Preparing staging directory'
if (Test-Path $stagingDir) {
    Remove-Item -Path $stagingDir -Recurse -Force
}
New-Item -ItemType Directory -Path $stagingDir | Out-Null

Write-Info 'Copying Flutter Windows runner'
Copy-Item -Path (Join-Path $releaseBuildPath '*') -Destination $stagingDir -Recurse -Force

Write-Section 'Fetching Ollama runtime'
if (-not $OllamaDownloadUrl) {
    $OllamaDownloadUrl = "https://github.com/ollama/ollama/releases/download/v$OllamaVersion/ollama-windows-amd64.zip"
}

if (-not (Test-Path $cacheDir)) {
    New-Item -ItemType Directory -Path $cacheDir | Out-Null
}

$ollamaCacheRoot = Join-Path $cacheDir "ollama-$OllamaVersion"
$ollamaZipPath = Join-Path $cacheDir "ollama-$OllamaVersion.zip"

if (-not (Test-Path $ollamaCacheRoot)) {
    Write-Info "Downloading Ollama $OllamaVersion from $OllamaDownloadUrl"
    Invoke-WebRequest -Uri $OllamaDownloadUrl -OutFile $ollamaZipPath
    Write-Info 'Extracting Ollama archive'
    Expand-Archive -Path $ollamaZipPath -DestinationPath $ollamaCacheRoot
}
else {
    Write-Info 'Reusing cached Ollama download'
}

$ollamaExecutable = Get-ChildItem -Path $ollamaCacheRoot -Recurse -Filter 'ollama.exe' | Select-Object -First 1
if (-not $ollamaExecutable) {
    throw "Could not locate ollama.exe within $ollamaCacheRoot"
}

$ollamaBinaryRoot = $ollamaExecutable.Directory.FullName
$stagingOllamaDir = Join-Path $stagingDir 'ollama'
if (Test-Path $stagingOllamaDir) {
    Remove-Item -Path $stagingOllamaDir -Recurse -Force
}

Write-Info 'Staging Ollama runtime'
Copy-Item -Path (Join-Path $ollamaBinaryRoot '*') -Destination $stagingOllamaDir -Recurse -Force

$modelsDir = Join-Path $stagingOllamaDir 'models'
if (-not (Test-Path $modelsDir)) {
    New-Item -ItemType Directory -Path $modelsDir | Out-Null
}

$modelBundled = $false

$previousEnv = @{
    OLLAMA_HOME = $env:OLLAMA_HOME
    OLLAMA_MODELS = $env:OLLAMA_MODELS
    OLLAMA_HOST = $env:OLLAMA_HOST
}

$env:OLLAMA_HOME = $stagingOllamaDir
$env:OLLAMA_MODELS = $modelsDir
$env:OLLAMA_HOST = '127.0.0.1:11434'

try {
    if ($ModelSourcePath) {
        $resolvedModelSource = Resolve-Path $ModelSourcePath -ErrorAction Stop
        $sourceItem = Get-Item $resolvedModelSource
        if (-not $sourceItem.PSIsContainer) {
            throw 'ModelSourcePath must point to a directory containing an Ollama data bundle (models, manifests, blobs, etc).'
        }

        Write-Section "Copying pre-downloaded model data from $resolvedModelSource"
        Copy-Item -Path (Join-Path $resolvedModelSource '*') -Destination $stagingOllamaDir -Recurse -Force
        $modelBundled = $true
    }
    elseif ($AllowNetworkModelDownload) {
        $ollamaExePath = Join-Path $stagingOllamaDir 'ollama.exe'
        if (-not (Test-Path $ollamaExePath)) {
            throw 'ollama.exe was not found in the staging directory after extraction.'
        }

        Write-Section "Starting temporary Ollama service to download $ModelName"
        $ollamaProcess = Start-Process -FilePath $ollamaExePath -ArgumentList 'serve' -WorkingDirectory $stagingOllamaDir -WindowStyle Hidden -PassThru

        try {
            $isReady = $false
            for ($attempt = 0; $attempt -lt 30; $attempt++) {
                Start-Sleep -Seconds 2
                try {
                    Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/tags' -Method Get -UseBasicParsing | Out-Null
                    $isReady = $true
                    break
                } catch {
                    # keep waiting
                }
            }

            if (-not $isReady) {
                throw 'Timed out waiting for the Ollama service to start.'
            }

            Write-Info "Downloading model $ModelName (this may take a while)"
            $pullProcess = Start-Process -FilePath $ollamaExePath -ArgumentList @('pull', $ModelName) -WorkingDirectory $stagingOllamaDir -NoNewWindow -PassThru -Wait
            if ($pullProcess.ExitCode -ne 0) {
                throw "ollama pull exited with code $($pullProcess.ExitCode)."
            }

            $modelBundled = $true
        }
        finally {
            if ($ollamaProcess -and -not $ollamaProcess.HasExited) {
                Write-Info 'Stopping temporary Ollama service'
                Stop-Process -Id $ollamaProcess.Id -Force
                Start-Sleep -Seconds 1
            }
        }
    }
    else {
        Write-Info 'No model source provided; the installer will require a pre-bundled model directory.'
    }
}
finally {
    $env:OLLAMA_HOME = $previousEnv.OLLAMA_HOME
    $env:OLLAMA_MODELS = $previousEnv.OLLAMA_MODELS
    $env:OLLAMA_HOST = $previousEnv.OLLAMA_HOST
}

Write-Section 'Generating release manifest'
$versionLine = Select-String -Path (Join-Path $repoRoot 'pubspec.yaml') -Pattern '^version:\s*(.+)$' | Select-Object -First 1
$appVersion = if ($versionLine) { ($versionLine.Matches[0].Groups[1].Value).Trim() } else { 'unknown' }

$gitCommit = 'unknown'
try {
    $gitCommit = (git rev-parse HEAD).Trim()
} catch {
    Write-Info 'git command not found or repository state unavailable; commit will be marked as unknown.'
}

$flutterVersion = 'not available'
try {
    if (Get-Command flutter -ErrorAction SilentlyContinue) {
        $flutterVersion = (& flutter --version | Out-String).Trim()
    }
} catch {
    $flutterVersion = 'failed to determine'
}

$runnerExe = Get-ChildItem -Path $stagingDir -Filter '*.exe' -Recurse |
    Where-Object { $_.FullName -notlike "*$([IO.Path]::DirectorySeparatorChar)ollama$([IO.Path]::DirectorySeparatorChar)*" } |
    Select-Object -First 1

$runnerHash = $null
if ($runnerExe) {
    $runnerHash = Get-FileHash -Path $runnerExe.FullName -Algorithm SHA256
}

$manifest = [ordered]@{
    app = [ordered]@{
        name = 'DocFlow AI'
        version = $appVersion
    }
    build = [ordered]@{
        generatedAt = (Get-Date).ToString('o')
        flutter = $flutterVersion
        gitCommit = $gitCommit
    }
    model = [ordered]@{
        name = $ModelName
        bundled = $modelBundled
        source = if ($ModelSourcePath) { 'copied' } elseif ($AllowNetworkModelDownload) { 'downloaded' } else { 'external-required' }
    }
}

if ($runnerHash) {
    $manifest.build.runnerExecutable = [ordered]@{
        path = [IO.Path]::GetRelativePath($stagingDir, $runnerExe.FullName)
        sha256 = $runnerHash.Hash
    }
}

$manifestPath = Join-Path $stagingDir 'RELEASE_MANIFEST.json'
$manifest | ConvertTo-Json -Depth 5 | Set-Content -Path $manifestPath -Encoding UTF8

if (-not $SkipCompression) {
    Write-Section 'Creating zip archive'
    $zipPath = Join-Path $resolvedOutputRoot "$DistributionName.zip"
    if (Test-Path $zipPath) {
        Remove-Item -Path $zipPath -Force
    }
    Compress-Archive -Path (Join-Path $stagingDir '*') -DestinationPath $zipPath

    $zipHash = Get-FileHash -Path $zipPath -Algorithm SHA256
    $manifest.archive = [ordered]@{
        file = [IO.Path]::GetRelativePath($resolvedOutputRoot, $zipPath)
        sha256 = $zipHash.Hash
    }
    $manifest | ConvertTo-Json -Depth 5 | Set-Content -Path $manifestPath -Encoding UTF8
}

Write-Section 'Enterprise package created successfully'
Write-Host "Staging directory: $stagingDir" -ForegroundColor Green
if (-not $SkipCompression) {
    Write-Host "Archive: $(Join-Path $resolvedOutputRoot "$DistributionName.zip")" -ForegroundColor Green
}
