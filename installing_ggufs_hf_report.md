# installing_ggufs_hf.ps1: How It Works

This report explains how [installing_ggufs_hf.ps1](installing_ggufs_hf.ps1) works from start to finish.

## Purpose

The script automates local llama.cpp setup on Windows by:

- Choosing a model profile (3B default or 0.5B tiny)
- Downloading llama.cpp Windows CUDA binaries from the latest GitHub release
- Downloading a GGUF model from Hugging Face
- Creating a desktop launcher batch file to run llama-server with safe defaults

## Inputs and Mode Selection

The script accepts three switches:

- ModelOnly
- Small
- Tiny

Behavior by switch:

- Tiny enabled:
  - Repository: Qwen/Qwen2.5-Coder-0.5B-Instruct-GGUF
  - File: qwen2.5-coder-0.5b-instruct-q2_k.gguf
  - Launcher: Start-AI-Server-0.5B.bat
  - Runtime defaults: ctx-size 2048, gpu layers 8, threads 4
- Tiny not enabled:
  - Repository: Qwen/Qwen2.5-Coder-3B-Instruct-GGUF
  - File: qwen2.5-coder-3b-instruct-q4_k_m.gguf
  - Launcher:
    - Start-AI-Server-3B.bat if Small is set
    - Start-AI-Server.bat otherwise
  - Runtime defaults: ctx-size 3072, gpu layers 16, threads 6

What ModelOnly changes:

- If ModelOnly is set, llama.cpp binaries download is skipped.
- Model download and launcher creation still happen.

## Fixed Paths and URLs

The script constructs deployment paths through a typed class:

- llama.cpp folder: C:/llama_cpp
- models folder: C:/AI_Models
- downloaded zip temp file: C:/llama_cpp/llama-win.zip
- model file path: C:/AI_Models/<selected gguf>
- launcher path: Desktop/<selected launcher name>

Remote endpoints:

- Latest llama.cpp release API:
  - https://api.github.com/repos/ggml-org/llama.cpp/releases/latest
- Hugging Face model metadata API:
  - https://huggingface.co/api/models/<selected repository>
- llama.cpp asset filter pattern:
  - ^llama-.*-bin-win-cuda-.*-x64\.zip$

## Data Structures

The script defines two classes for clarity:

- DeploymentPaths
  - Holds all local path decisions in one object
- DownloadResult
  - Holds source URL, output file path, and downloaded size

## Function Responsibilities

### Output and Directory Helpers

- Write-Info
  - Cyan status output
- Write-Success
  - Green success output
- New-RequiredDirectory
  - Creates missing folders idempotently

### Download Validation Helpers

- Test-FileCreatedAndNonEmpty
  - Ensures downloaded file exists and is not zero bytes
- Invoke-FileDownload
  - Performs web download with User-Agent and redirect support
  - Wraps errors with readable messages
  - Returns DownloadResult

### llama.cpp Release Resolution

- Get-LlamaLatestRelease
  - Calls GitHub latest release API
- Select-LlamaWindowsCudaAsset
  - Filters release assets by CUDA x64 zip regex
  - Sorts by name descending and picks first match
- Get-LlamaCppDownloadUrl
  - Combines the previous two to return browser_download_url

### Hugging Face Model Resolution

- Get-HuggingFaceModelDownloadUrl
  - Calls model metadata API
  - Finds exact requested GGUF in siblings list
  - Builds resolve URL with download=true

This avoids hardcoding direct links that may become stale.

### Archive and Cleanup

- Test-ZipArchiveValid
  - Verifies zip integrity by opening it through .NET compression APIs
- Expand-DownloadedArchive
  - Validates then extracts zip with force overwrite
- Remove-FileIfExists
  - Safe, idempotent deletion helper

### Launcher Generation

- New-LauncherScript
  - Writes a desktop .bat file (ASCII)
  - Sets defaults only when env vars are not already defined
  - Verifies llama-server.exe and model file exist before launch
  - Launch command format:
    - llama-server.exe --model <path> --port %LLAMA_PORT% --ctx-size %LLAMA_CTX_SIZE% -ngl %LLAMA_GPU_LAYERS% --threads %LLAMA_THREADS%

### Orchestration Steps

- Initialize-Deployment
  - Ensures C:/llama_cpp and C:/AI_Models exist
- Get-DeploymentDownloadUrls
  - Resolves both binary and model download URLs
- Install-LlamaCppBinaries
  - Downloads zip, extracts to C:/llama_cpp, removes zip
- Get-RemoteFileSizeBytes
  - HEAD request for content length (best effort)
- Start-DownloadProgressJob
  - Background job prints model download progress every 5 seconds
- Install-ModelFile
  - Starts progress job
  - Downloads model
  - Always stops and removes job in finally block
- New-DeploymentLauncher
  - Creates the desktop launcher file

## Main Execution Flow

Main runs these steps in order:

- Initialize deployment directories
- Resolve URLs for llama.cpp and model
- Conditionally install llama.cpp binaries unless ModelOnly
- Install model file
- Create launcher script
- Print final success messages and launcher path

Finally, the script calls Main at the end.

## Error Handling Strategy

The script uses strict and fail-fast behavior:

- Set-StrictMode -Version Latest
- $ErrorActionPreference = Stop

Most network and file operations are wrapped with try/catch and provide clear error text.
Validation checks are applied before downstream steps, such as:

- Downloaded files must exist and be non-empty
- Zip must be structurally valid before extraction
- Launcher checks for missing executable/model before running

## What Gets Created or Changed

Typical run with defaults produces:

- C:/llama_cpp populated with llama.cpp binaries
- C:/AI_Models/qwen2.5-coder-3b-instruct-q4_k_m.gguf
- Desktop/Start-AI-Server.bat

Tiny run produces:

- C:/AI_Models/qwen2.5-coder-0.5b-instruct-q2_k.gguf
- Desktop/Start-AI-Server-0.5B.bat

## Practical Notes

- The script assumes Windows and PowerShell with web access.
- It targets CUDA-enabled llama.cpp Windows binaries.
- Launcher defaults can be overridden by environment variables before start:
  - LLAMA_PORT
  - LLAMA_CTX_SIZE
  - LLAMA_GPU_LAYERS
  - LLAMA_THREADS

## Summary

The script is a structured installer with clear separation between:

- Configuration selection
- URL discovery
- Download and validation
- Extraction and cleanup
- Launcher generation

It is designed to be reliable on repeated runs, with defensive checks and explicit failure messages.