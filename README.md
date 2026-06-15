# LLAMA-VSCODE

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![Platform](https://img.shields.io/badge/Platform-Windows-0078D6?logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![Runtime](https://img.shields.io/badge/llama.cpp-CUDA%20build-success)](https://github.com/ggml-org/llama.cpp)
[![Model](https://img.shields.io/badge/Models-Qwen2.5--Coder--3B%20%7C%200.5B-orange)](https://huggingface.co/Qwen)

Professional Windows deployment automation for a local **llama.cpp** server using **Hugging Face GGUF** models. This project now uses a profile-driven workflow centered on `installing_ggufs_hf.ps1`, letting you run either built-in profiles or arbitrary Hugging Face GGUF repositories with safe defaults.

## Overview

The deployment script automates the following:

- Creates required directories:
	- `C:\llama_cpp`
	- `C:\AI_Models`
- Detects the latest `llama.cpp` Windows CUDA x64 release from GitHub
- Downloads the selected release ZIP
- Extracts the binaries into `C:\llama_cpp`
- Resolves the exact model file from Hugging Face metadata
- Downloads a model from either:
	- a local profile in `models/*.json`
	- direct parameters `-HfRepo` and `-HfFile`
- Creates desktop launchers:
	- `Start-AI-Server.bat` (3-endpoint stack)
	- `Start-AI-Server-3B.bat` (3B wrapper)
	- `Start-AI-Server-0.5B.bat` (0.5B wrapper)
- Starts `llama-server.exe` with predefined runtime arguments on all required llama-vscode endpoints

## Included Deployment Targets

Built-in starter profiles:

- **Profile:** `models/qwen2.5-3b.json`
- **Profile:** `models/qwen2.5-0.5b.json`
- **Server port:** `8009`
- **Safe default context size:** `3072` (3B), `2048` (0.5B)
- **Safe default GPU layers:** `16` (3B), `8` (0.5B)
- **Safe default threads:** `6` (3B), `4` (0.5B)

## Features

- Automatic GitHub release discovery for `llama.cpp`
- Automatic Hugging Face model file resolution
- ZIP integrity validation before extraction
- File existence and non-empty download validation
- Periodic model download progress reporting
- Desktop launcher generation for one-click startup
- Structured helper functions and defensive error handling

## Repository Layout

```text
LLAMA-VSCODE/
├─ models/model-profile.schema.json
├─ models/qwen2.5-3b.json
├─ models/qwen2.5-0.5b.json
├─ scripts/Configure-LlamaVscode.ps1
├─ scripts/Validate-ModelProfile.ps1
├─ scripts/Find-HuggingFaceGGUF.ps1
├─ tests/InstallerBehavior.Tests.ps1
├─ tests/ModelProfileValidation.Tests.ps1
├─ Start-AI-Server.bat
├─ Start-AI-Server-3B.bat
├─ Start-AI-Server-0.5B.bat
├─ installing_ggufs_hf.ps1
├─ USER-GUIDE.md
└─ README.md
```

## Requirements

Before running the script, ensure the following are available:

### System

- Windows
- PowerShell 5.1 or newer
- Internet access
- Sufficient disk space for:
	- extracted `llama.cpp` binaries
	- the GGUF model file

### Hardware

- NVIDIA GPU recommended
- CUDA-compatible environment expected by the selected `llama.cpp` Windows CUDA build

### Permissions

The script writes to:

- `C:\llama_cpp`
- `C:\AI_Models`
- `%USERPROFILE%\Desktop`

If your system restricts writes to these locations, run PowerShell with appropriate permissions or adjust the script paths.

## Quick Start

Open PowerShell and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\installing_ggufs_hf.ps1
```

Install by profile name:

```powershell
.\installing_ggufs_hf.ps1 -Profile qwen2.5-3b
```

Install any GGUF model directly from Hugging Face:

```powershell
.\installing_ggufs_hf.ps1 -HfRepo "TheBloke/Mistral-7B-Instruct-v0.2-GGUF" -HfFile "mistral-7b-instruct-v0.2.Q4_K_M.gguf" -ProfileName "mistral-7b"
```

After completion, use the generated desktop shortcut batch file:

```text
Start-AI-Server.bat
```

This launcher starts:

```text
tools      -> http://localhost:8009
chat       -> http://localhost:8011
completion -> http://localhost:8012
```

The generated launcher uses conservative defaults for Windows laptops:

- `LLAMA_PORT=8009`
- `LLAMA_CTX_SIZE=3072`
- `LLAMA_GPU_LAYERS=16`
- `LLAMA_THREADS=6`

Each run also applies a llama-vscode bootstrap in user settings so agent/model selection does not require manual reconfiguration.

For the tiny fallback model, use:

```powershell
.\installing_ggufs_hf.ps1 -Tiny -ModelOnly
```

Then launch with:

```text
Start-AI-Server-0.5B.bat
```

You can override them per launch before starting the batch file, for example:

```powershell
$env:LLAMA_GPU_LAYERS = '28'
$env:LLAMA_CTX_SIZE = '3072'
$env:LLAMA_THREADS = '8'
./Start-AI-Server.bat
```

Start using a profile at runtime:

```batch
Start-AI-Server.bat -Profile qwen2.5-3b
```

Start watcher using a profile:

```batch
Start-AI-Server-AutoWatcher.bat -Profile qwen2.5-3b
```

Register scheduled task for a profile:

```powershell
cd .\scripts
.\Register-LlamaServerTask.ps1 -Profile qwen2.5-3b
```

Discover GGUF repositories and files:

```powershell
cd .\scripts
.\Find-HuggingFaceGGUF.ps1 -Query "phi 3 mini instruct" -Author "microsoft"
.\Find-HuggingFaceGGUF.ps1 -Query "mistral instruct gguf" -Author "TheBloke"
.\Find-HuggingFaceGGUF.ps1 -Query "mistral" -Repository "TheBloke/Mistral-7B-Instruct-v0.2-GGUF"
```

## Profile Schema and Validation Gate

Profile files are validated before use.

- JSON schema: `models/model-profile.schema.json`
- Validation script: `scripts/Validate-ModelProfile.ps1`

Validate one profile:

```powershell
. .\scripts\Validate-ModelProfile.ps1
Test-ModelProfileFile -ProfilePath .\models\qwen2.5-3b.json -SchemaPath .\models\model-profile.schema.json
```

Validate all profiles:

```powershell
. .\scripts\Validate-ModelProfile.ps1
Get-ChildItem .\models -Filter *.json |
	Where-Object { $_.Name -ne 'model-profile.schema.json' } |
	ForEach-Object { Test-ModelProfileFile -ProfilePath $_.FullName -SchemaPath .\models\model-profile.schema.json }
```

## Tests and Local Quality Checks

Run Pester tests:

```powershell
Invoke-Pester -Path .\tests
```

Run script parse check:

```powershell
Get-ChildItem -Recurse -Filter *.ps1 |
	Where-Object { $_.FullName -notmatch '\\.history\\' } |
	ForEach-Object {
		$tokens = $null
		$errors = $null
		[void][System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors)
		if ($errors) { throw "Parse failed: $($_.FullName)" }
	}
```

PR CI runs these checks automatically via `.github/workflows/powershell-quality.yml`.

For full operator instructions, see `USER-GUIDE.md`.

## What the Script Does Internally

### 1. Initializes deployment paths

The script encapsulates deployment locations in a `DeploymentPaths` class and standardizes output through helper functions.

### 2. Resolves latest `llama.cpp` CUDA binary

It queries:

- `https://api.github.com/repos/ggml-org/llama.cpp/releases/latest`

Then selects a matching asset using this pattern:

```regex
^llama-.*-bin-win-cuda-.*-x64\.zip$
```

### 3. Resolves the Hugging Face GGUF file dynamically

Instead of hardcoding a direct model download link, it queries:

- `https://huggingface.co/api/models/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF`

This reduces failures caused by stale URLs or repository-side changes.

### 4. Validates downloads

The script checks whether downloaded files:

- exist
- are non-empty
- are valid ZIP archives before extraction

### 5. Creates the launcher

The generated batch launcher:

- changes into the `llama.cpp` directory
- verifies `llama-server.exe` exists
- verifies the model file exists
- starts the server with the configured options

## Default Output Paths

| Item | Path |
|---|---|
| llama.cpp directory | `C:\llama_cpp` |
| model directory | `C:\AI_Models` |
| downloaded ZIP | `C:\llama_cpp\llama-win.zip` |
| model file (default) | `C:\AI_Models\qwen2.5-coder-3b-instruct-q4_k_m.gguf` |
| model file (tiny fallback) | `C:\AI_Models\qwen2.5-coder-0.5b-instruct-q2_k.gguf` |
| launcher | `%USERPROFILE%\Desktop\Start-AI-Server.bat` |

## Known Considerations and Subsidiary Issues

The script is solidly structured, but deployment success still depends on external conditions.

### 1. CUDA build compatibility

The script explicitly selects a Windows CUDA build of `llama.cpp`. Systems without compatible NVIDIA/CUDA support may not run the downloaded binaries successfully.

### 2. Release asset naming assumptions

The binary selection depends on the GitHub asset naming convention matching:

```regex
^llama-.*-bin-win-cuda-.*-x64\.zip$
```

If upstream naming changes, the script may fail to locate a valid artifact.

### 3. Hardcoded deployment paths

The script currently uses fixed paths:

- `C:\llama_cpp`
- `C:\AI_Models`

This is convenient for a single-machine setup but may be unsuitable in managed, portable, or low-permission environments.

### 4. Launcher assumes `llama-server.exe`

The desktop launcher expects `llama-server.exe` to be present directly in the deployment directory after extraction. If upstream packaging changes folder layout, the launcher may need adjustment.

### 5. Port binding

The server is configured to use port `8009`. If another application already uses that port, startup will fail.

### 6. Large model downloads

The model download may take a significant amount of time depending on bandwidth and storage performance. The script includes a background progress job, but transient network issues can still interrupt the process.

### 7. PowerShell execution policy

Some Windows configurations block script execution by default. Running with a temporary process-scoped execution policy bypass is often sufficient.

### 8. Antivirus or endpoint controls

Enterprise security tools may interfere with:

- direct file downloads
- ZIP extraction
- executable launch from user-created directories

## Troubleshooting

### Script cannot run

Use:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

### Download failed

Check:

- internet connectivity
- GitHub API availability
- Hugging Face availability
- local disk space
- endpoint security restrictions

### ZIP extraction failed

Possible causes:

- incomplete download
- corrupted archive
- antivirus lock
- insufficient filesystem permissions

### `llama-server.exe` not found

This usually indicates an upstream packaging layout change in the downloaded `llama.cpp` release.

### Model file not found

Confirm the expected file exists:

```text
C:\AI_Models\qwen2.5-coder-3b-instruct-q4_k_m.gguf
```

## Customization

You can adapt the script by editing these values near the top of `installing_ggufs_hf.ps1`:

- deployment directories
- model filename
- launcher filename
- Hugging Face repository
- server arguments such as port, context size, and GPU layers

## Security and Operational Notes

- The script pulls binaries from GitHub releases and model files from Hugging Face at runtime.
- It relies on live upstream metadata rather than vendored artifacts.
- Review downloaded sources and runtime flags before production or sensitive-environment use.

## Recommended Use Case

This project is best suited for:

- local Windows AI experimentation
- rapid `llama.cpp` server deployment
- GGUF-based coding assistant backends
- developer workstations with NVIDIA GPUs

## License

No license file is currently included in this repository. Add one if you intend to publish or distribute the project.

## Acknowledgments

- [ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp)
- [Qwen on Hugging Face](https://huggingface.co/Qwen)
