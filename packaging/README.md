# Enterprise Release Packaging

This directory contains the automated tooling that assembles a production-ready Windows
build of **DocFlow AI** together with a portable Ollama runtime and the required
`llama2:latest` model.

The primary entry point is [`create_enterprise_release.ps1`](create_enterprise_release.ps1),
a PowerShell script that drives the entire process end-to-end:

1. Compile the Windows Flutter runner (`flutter build windows --release`).
2. Stage the compiled binaries in a clean distribution directory.
3. Download the Ollama CLI for Windows and place it beside the application.
4. Bundle the requested Ollama model (either by downloading it or by copying a
   pre-seeded model directory).
5. Generate a `RELEASE_MANIFEST.json` with hashes and build metadata.
6. Produce a distributable `.zip` archive (can be skipped when desired).

## Prerequisites

- Windows 11 or Windows Server 2022 build machine.
- PowerShell 7.4+ with script execution enabled for the repository.
- Flutter SDK (if you are not using the `-SkipFlutterBuild` flag).
- Git (optional, but recommended for commit metadata).
- Network access when using `-AllowNetworkModelDownload`.
- 25 GB of free disk space (Flutter build + Ollama model cache).

## Usage

```powershell
# From the repository root
pwsh ./packaging/create_enterprise_release.ps1 -AllowNetworkModelDownload
```

The command above downloads the Ollama runtime, starts a temporary Ollama service,
pulls the `llama2:latest` model, and creates a zipped package in `dist/`.

### Offline Packaging

If the build environment cannot access the internet, prepare the model on another
machine that already has Ollama installed:

```powershell
# On a connected machine
$env:OLLAMA_HOME = 'C:/ollama-offline-cache'
ollama pull llama2:latest
```

Copy the resulting directory (`C:/ollama-offline-cache`) to the build machine and
run the release script with the `-ModelSourcePath` parameter:

```powershell
pwsh ./packaging/create_enterprise_release.ps1 -ModelSourcePath 'C:/ollama-offline-cache'
```

### Useful Flags

| Flag | Description |
| ---- | ----------- |
| `-SkipFlutterBuild` | Reuse the most recent `flutter build windows` artifacts. |
| `-SkipCompression` | Skip zip creation and leave an uncompressed folder in `dist/`. |
| `-ModelName` | Override the model to bundle (defaults to `llama2:latest`). |
| `-OllamaVersion` | Pin a specific Ollama release. |
| `-OllamaDownloadUrl` | Provide a custom download URL for the Ollama CLI. |

## Output Layout

After a successful run the `dist/DocFlowAI-Enterprise/` directory contains:

```
DocFlowAI-Enterprise/
├── DocFlow AI.exe          # Flutter Windows runner
├── data/                   # Flutter asset/data folder
├── ollama/                 # Portable Ollama runtime
│   ├── ollama.exe
│   ├── models/             # Bundled model weights
│   └── manifests/          # Model manifest metadata
├── RELEASE_MANIFEST.json   # Build + hash metadata
└── (other Flutter runtime files)
```

If `-SkipCompression` is omitted, a `DocFlowAI-Enterprise.zip` archive and a SHA-256 hash
are generated in the same `dist/` folder for distribution or code-signing pipelines.

## Validating the Bundle

1. Extract the archive onto a clean Windows workstation.
2. Double-click `DocFlow AI.exe`; the application automatically launches the bundled
   Ollama runtime and verifies that the `llama2:latest` model is present.
3. Use Windows Task Manager to confirm that `ollama.exe` starts/stops with the app.
4. Inspect `RELEASE_MANIFEST.json` to verify the build metadata and SHA-256 hashes.

Keep the `dist/.cache/` directory if you routinely build releases—the Ollama download
is cached there to speed up future packaging runs.
