[CmdletBinding()]
param(
    [switch]$ModelOnly,
    [string]$HfRepo,
    [string]$HfFile,
    [string]$Profile,
    [string]$ProfileName,
    [switch]$Small,
    [switch]$Tiny
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

class DeploymentPaths {
    [string]$LlamaCppDirectory
    [string]$LlamaZipPath
    [string]$ModelPath
    [string]$LauncherPath

    DeploymentPaths([string]$llamaCppDirectory, [string]$modelPath, [string]$launcherFileName) {
        $this.LlamaCppDirectory = $llamaCppDirectory
        $this.LlamaZipPath = Join-Path $llamaCppDirectory 'llama-win.zip'
        $this.ModelPath = $modelPath
        $this.LauncherPath = Join-Path ([Environment]::GetFolderPath('UserProfile')) ("Desktop\" + $launcherFileName)
    }
}

class DownloadResult {
    [string]$Source
    [string]$OutputFile
    [Int64]$SizeBytes

    DownloadResult([string]$source, [string]$outputFile, [Int64]$sizeBytes) {
        $this.Source = $source
        $this.OutputFile = $outputFile
        $this.SizeBytes = $sizeBytes
    }
}

class ModelProfile {
    [string]$Name
    [string]$HfRepo
    [string]$HfFile
    [string]$ModelPath
    [int]$CtxSize
    [int]$GpuLayers
    [int]$Threads
    [string]$Notes

    ModelProfile([string]$name, [string]$hfRepo, [string]$hfFile, [string]$modelPath, [int]$ctxSize, [int]$gpuLayers, [int]$threads, [string]$notes) {
        $this.Name = $name
        $this.HfRepo = $hfRepo
        $this.HfFile = $hfFile
        $this.ModelPath = $modelPath
        $this.CtxSize = $ctxSize
        $this.GpuLayers = $gpuLayers
        $this.Threads = $threads
        $this.Notes = $notes
    }
}

# Load profile if specified
$ProfileObj = $null
if ($Profile) {
    $profilePath = Join-Path $PSScriptRoot "models\$Profile.json"
    if (-not (Test-Path $profilePath)) {
        throw "Profile file not found: $profilePath"
    }
    $profileJson = Get-Content $profilePath -Raw | ConvertFrom-Json
    $ProfileObj = [ModelProfile]::new(
        $profileJson.name,
        $profileJson.hf_repo,
        $profileJson.hf_file,
        $profileJson.model_path,
        $profileJson.ctx_size,
        $profileJson.gpu_layers,
        $profileJson.threads,
        $profileJson.notes
    )
}

# Determine model configuration
if ($ProfileObj) {
    $ModelRepository = $ProfileObj.HfRepo
    $ModelFileName = $ProfileObj.HfFile
    $ModelPath = $ProfileObj.ModelPath
    $DefaultCtxSize = $ProfileObj.CtxSize
    $DefaultGpuLayers = $ProfileObj.GpuLayers
    $DefaultThreads = $ProfileObj.Threads
    $ProfileDisplayName = $ProfileObj.Name
} elseif ($HfRepo -and $HfFile) {
    $ModelRepository = $HfRepo
    $ModelFileName = $HfFile
    $ModelPath = Join-Path 'C:\AI_Models' $ModelFileName
    $ProfileDisplayName = if ($ProfileName) { $ProfileName } else { [System.IO.Path]::GetFileNameWithoutExtension($ModelFileName) }
    # Auto-detect safe runtime defaults from file size (will be applied after download)
    $DefaultCtxSize = 3072
    $DefaultGpuLayers = 16
    $DefaultThreads = 6
} elseif ($Tiny) {
    $ModelRepository = 'Qwen/Qwen2.5-Coder-0.5B-Instruct-GGUF'
    $ModelFileName = 'qwen2.5-coder-0.5b-instruct-q2_k.gguf'
    $ModelPath = 'C:\AI_Models\qwen2.5-coder-0.5b-instruct-q2_k.gguf'
    $ProfileDisplayName = 'Qwen2.5-Coder-0.5B'
    $DefaultCtxSize = 2048
    $DefaultGpuLayers = 8
    $DefaultThreads = 4
} else {
    $ModelRepository = 'Qwen/Qwen2.5-Coder-3B-Instruct-GGUF'
    $ModelFileName = 'qwen2.5-coder-3b-instruct-q4_k_m.gguf'
    $ModelPath = 'C:\AI_Models\qwen2.5-coder-3b-instruct-q4_k_m.gguf'
    $ProfileDisplayName = 'Qwen2.5-Coder-3B'
    $DefaultCtxSize = 3072
    $DefaultGpuLayers = 16
    $DefaultThreads = 6
}

$launcherSlug = ($ProfileDisplayName.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
$LauncherFileName = if ($ProfileObj -or ($HfRepo -and $HfFile)) { "Start-AI-Server-$launcherSlug.bat" } elseif ($Small) { 'Start-AI-Server-3B.bat' } elseif ($Tiny) { 'Start-AI-Server-0.5B.bat' } else { 'Start-AI-Server.bat' }

$Paths = [DeploymentPaths]::new('C:\llama_cpp', $ModelPath, $LauncherFileName)

$HuggingFaceModelApiUrl = "https://huggingface.co/api/models/$ModelRepository"
$LlamaReleaseApiUrl = 'https://api.github.com/repos/ggml-org/llama.cpp/releases/latest'
$LlamaWindowsCudaZipPattern = '^llama-.*-bin-win-cuda-.*-x64\.zip$'

function Write-Info {
    <#
    .SYNOPSIS
    WHAT: Writes informational status output.
    WHY: Centralizes output formatting and color behavior.
    HOW: Calls Write-Host with a fixed foreground color.

    .PARAMETER Message
    Message to display.

    .OUTPUTS
    None.

    .NOTES
    THROWS/EXCEPTIONS: None expected.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host $Message -ForegroundColor Cyan
}

function Write-Success {
    <#
.SYNOPSIS
WHAT: Writes success output.
WHY: Keeps success messages consistent.
HOW: Calls Write-Host using green foreground.

.PARAMETER Message
Success message.

.OUTPUTS
None.

.NOTES
THROWS/EXCEPTIONS: None expected.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host $Message -ForegroundColor Green
}

function New-RequiredDirectory {
    <#
.SYNOPSIS
WHAT: Ensures a directory exists.
WHY: Later file operations require guaranteed folder paths.
HOW: Uses New-Item -Force to create or keep directory.

.PARAMETER Path
Directory path to create/ensure.

.OUTPUTS
[System.IO.DirectoryInfo] via New-Item, suppressed by caller when needed.

.NOTES
THROWS/EXCEPTIONS: Throws on permission/path failures from New-Item.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Test-FileCreatedAndNonEmpty {
    <#
.SYNOPSIS
WHAT: Validates a downloaded file exists and has content.
WHY: Prevents using missing or empty files downstream.
HOW: Checks Test-Path and file Length.

.PARAMETER Path
File path to validate.

.OUTPUTS
None.

.NOTES
THROWS/EXCEPTIONS: Throws if file is missing or empty.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        throw "Download failed: $Path was not created."
    }

    if ((Get-Item -Path $Path).Length -eq 0) {
        throw "Download failed: $Path is empty."
    }
}

function Invoke-FileDownload {
    <#
.SYNOPSIS
WHAT: Downloads a file from URL to local path.
WHY: Isolates transfer logic and error wrapping.
HOW: Uses Invoke-WebRequest and post-validates output file.

.PARAMETER Uri
Source URL.

.PARAMETER OutFile
Local destination file path.

.OUTPUTS
[DownloadResult] metadata for the completed download.

.NOTES
THROWS/EXCEPTIONS:
- Throws wrapped network/protocol errors from Invoke-WebRequest.
- Throws validation errors when output file is absent/empty.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Uri,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutFile
    )

    try {
        Invoke-WebRequest -Uri $Uri -OutFile $OutFile -Headers @{ 'User-Agent' = 'PowerShell' } -MaximumRedirection 10
    } catch {
        throw "Download failed for '$Uri'. $($_.Exception.Message)"
    }

    Test-FileCreatedAndNonEmpty -Path $OutFile
    $item = Get-Item -Path $OutFile
    return [DownloadResult]::new($Uri, $OutFile, $item.Length)
}

function Get-LlamaLatestRelease {
    <#
.SYNOPSIS
WHAT: Fetches latest llama.cpp release metadata.
WHY: Enables selecting the newest compatible Windows CUDA ZIP.
HOW: Calls GitHub Releases API via Invoke-RestMethod.

.PARAMETER ReleaseApiUrl
GitHub API endpoint for latest release metadata.

.OUTPUTS
[pscustomobject] release JSON object.

.NOTES
THROWS/EXCEPTIONS: Throws wrapped REST/API failures.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ReleaseApiUrl
    )

    try {
        return Invoke-RestMethod -Uri $ReleaseApiUrl -Headers @{ 'User-Agent' = 'PowerShell' }
    } catch {
        throw "Failed to query llama.cpp releases from GitHub. $($_.Exception.Message)"
    }
}

function Select-LlamaWindowsCudaAsset {
    <#
.SYNOPSIS
WHAT: Selects latest Windows CUDA x64 ZIP asset from release assets.
WHY: Keeps binary selection logic separate from API retrieval.
HOW: Filters by regex, sorts by name descending, takes first.

.PARAMETER Assets
Collection of release assets from GitHub release payload.

.PARAMETER NamePattern
Regex for desired artifact filename.

.OUTPUTS
[pscustomobject] matching asset object.

.NOTES
THROWS/EXCEPTIONS: Throws if no matching asset exists.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object[]]$Assets,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$NamePattern
    )

    $asset = $Assets |
    Where-Object { $_.name -match $NamePattern } |
    Sort-Object name -Descending |
    Select-Object -First 1

    if (-not $asset) {
        throw 'Could not find a Windows CUDA x64 llama.cpp ZIP asset in the latest GitHub release.'
    }

    return $asset
}

function Get-LlamaCppDownloadUrl {
    <#
.SYNOPSIS
WHAT: Resolves direct download URL for llama.cpp Windows CUDA ZIP.
WHY: Provides a single URL value for download routine.
HOW: Combines release retrieval and asset selection helpers.

.PARAMETER ReleaseApiUrl
GitHub API endpoint for latest release.

.PARAMETER NamePattern
Regex pattern for compatible asset names.

.OUTPUTS
[string] browser_download_url.

.NOTES
THROWS/EXCEPTIONS:
- Throws from Get-LlamaLatestRelease on API failures.
- Throws from Select-LlamaWindowsCudaAsset when no asset matches.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ReleaseApiUrl,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$NamePattern
    )

    $release = Get-LlamaLatestRelease -ReleaseApiUrl $ReleaseApiUrl
    $asset = Select-LlamaWindowsCudaAsset -Assets $release.assets -NamePattern $NamePattern
    return $asset.browser_download_url
}

function Get-HuggingFaceModelDownloadUrl {
    <#
.SYNOPSIS
WHAT: Resolves the exact Hugging Face GGUF download URL from model metadata.
WHY: Avoids hardcoding stale direct links that can return 404.
HOW: Queries the Hugging Face model API, finds the requested file, and builds a resolve URL.

.PARAMETER ModelApiUrl
Hugging Face API endpoint for the model repository.

.PARAMETER Repository
Repository path in owner/name format.

.PARAMETER FileName
Exact GGUF filename to download.

.OUTPUTS
[string] direct resolve URL for the requested file.

.NOTES
THROWS/EXCEPTIONS:
- Throws on API failures.
- Throws when the requested file does not exist in the repository.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ModelApiUrl,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Repository,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FileName
    )

    try {
        $modelMetadata = Invoke-RestMethod -Uri $ModelApiUrl -Headers @{ 'User-Agent' = 'PowerShell' }
    } catch {
        throw "Failed to query Hugging Face model metadata for '$Repository'. $($_.Exception.Message)"
    }

    $matchingFile = $modelMetadata.siblings |
    Where-Object { $_.rfilename -eq $FileName } |
    Select-Object -First 1

    if (-not $matchingFile) {
        throw "Could not find model file '$FileName' in Hugging Face repository '$Repository'."
    }

    return "https://huggingface.co/$Repository/resolve/main/$($matchingFile.rfilename)?download=true"
}

function Test-ZipArchiveValid {
    <#
.SYNOPSIS
WHAT: Verifies that a file is a readable ZIP archive.
WHY: Prevents extraction attempts on invalid/corrupt downloads.
HOW: Opens ZIP via System.IO.Compression and disposes handle.

.PARAMETER Path
ZIP file path to validate.

.OUTPUTS
None.

.NOTES
THROWS/EXCEPTIONS: Throws when archive cannot be opened.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    try {
        [System.IO.Compression.ZipFile]::OpenRead($Path).Dispose()
    } catch {
        throw "Downloaded file is not a valid ZIP archive: $Path"
    }
}

function Expand-DownloadedArchive {
    <#
.SYNOPSIS
WHAT: Extracts a validated ZIP archive to destination.
WHY: Encapsulates unzip workflow with pre-validation.
HOW: Calls Test-ZipArchiveValid then Expand-Archive -Force.

.PARAMETER Path
ZIP file path.

.PARAMETER DestinationPath
Directory where archive contents are extracted.

.OUTPUTS
None.

.NOTES
THROWS/EXCEPTIONS:
- Throws from Test-ZipArchiveValid if invalid ZIP.
- Throws from Expand-Archive on extraction errors.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationPath
    )

    Test-ZipArchiveValid -Path $Path

    try {
        Expand-Archive -Path $Path -DestinationPath $DestinationPath -Force
    } catch {
        throw "Failed to extract ZIP '$Path' to '$DestinationPath'. $($_.Exception.Message)"
    }
}

function Remove-FileIfExists {
    <#
.SYNOPSIS
WHAT: Removes file when present.
WHY: Keeps cleanup idempotent and safe.
HOW: Checks path existence before Remove-Item.

.PARAMETER Path
File path to remove.

.OUTPUTS
None.

.NOTES
THROWS/EXCEPTIONS: Throws wrapped delete errors.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        return
    }

    try {
        Remove-Item -Path $Path -Force
    } catch {
        throw "Failed to remove file '$Path'. $($_.Exception.Message)"
    }
}

function New-LauncherScript {
    <#
.SYNOPSIS
WHAT: Creates desktop batch launcher for llama-server.
WHY: Simplifies startup into one clickable entrypoint.
HOW: Writes a .bat file with existence checks and run command.

.PARAMETER Path
Output .bat path.

.PARAMETER WorkingDirectory
Directory containing llama-server.exe.

.PARAMETER ModelFile
Absolute path to model .gguf file.

.PARAMETER DefaultCtxSize
Default context size for generated launcher.

.PARAMETER DefaultGpuLayers
Default GPU layer offload value for generated launcher.

.PARAMETER DefaultThreads
Default CPU thread count for generated launcher.

.OUTPUTS
None.

.NOTES
THROWS/EXCEPTIONS: Throws wrapped filesystem write failures.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$WorkingDirectory,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ModelFile,

        [Parameter(Mandatory)]
        [ValidateRange(256, 32768)]
        [int]$DefaultCtxSize,

        [Parameter(Mandatory)]
        [ValidateRange(0, 200)]
        [int]$DefaultGpuLayers,

        [Parameter(Mandatory)]
        [ValidateRange(1, 128)]
        [int]$DefaultThreads
    )

    $content = @"
@echo off
setlocal
cd /d "$WorkingDirectory"
title Local AI Server
if not defined LLAMA_PORT set "LLAMA_PORT=8009"
if not defined LLAMA_CTX_SIZE set "LLAMA_CTX_SIZE=$DefaultCtxSize"
if not defined LLAMA_GPU_LAYERS set "LLAMA_GPU_LAYERS=$DefaultGpuLayers"
if not defined LLAMA_THREADS set "LLAMA_THREADS=$DefaultThreads"
if not exist "llama-server.exe" (
	echo llama-server.exe was not found in "$WorkingDirectory".
	pause
	exit /b 1
)
if not exist "$ModelFile" (
	echo Model file was not found: "$ModelFile"
	pause
	exit /b 1
)
echo Starting llama.cpp with port %LLAMA_PORT%, context %LLAMA_CTX_SIZE%, GPU layers %LLAMA_GPU_LAYERS%, threads %LLAMA_THREADS%.
llama-server.exe --model "$ModelFile" --port %LLAMA_PORT% --ctx-size %LLAMA_CTX_SIZE% -ngl %LLAMA_GPU_LAYERS% --threads %LLAMA_THREADS%
pause
"@

    try {
        Set-Content -Path $Path -Value $content -Encoding ASCII
    } catch {
        throw "Failed to create launcher script '$Path'. $($_.Exception.Message)"
    }
}

function Initialize-Deployment {
    [CmdletBinding()]
    param()

    New-RequiredDirectory -Path $Paths.LlamaCppDirectory
    New-RequiredDirectory -Path (Split-Path -Path $Paths.ModelPath -Parent)
    New-RequiredDirectory -Path (Join-Path $PSScriptRoot 'models')
}

function Get-SafeRuntimeDefaults {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ModelPath
    )

    $sizeGB = (Get-Item -Path $ModelPath).Length / 1GB

    if ($sizeGB -lt 0.8) {
        return @{ Ctx = 2048; Ngl = 8; Threads = 4 }
    }

    if ($sizeGB -lt 2.0) {
        return @{ Ctx = 2048; Ngl = 12; Threads = 5 }
    }

    if ($sizeGB -lt 4.0) {
        return @{ Ctx = 3072; Ngl = 16; Threads = 6 }
    }

    if ($sizeGB -lt 7.0) {
        return @{ Ctx = 2048; Ngl = 10; Threads = 6 }
    }

    return @{ Ctx = 1024; Ngl = 6; Threads = 4 }
}

function Convert-ToSlug {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Text
    )

    return ($Text.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
}

function Save-ModelProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Repository,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FileName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ResolvedModelPath,

        [Parameter(Mandatory)]
        [ValidateRange(256, 32768)]
        [int]$CtxSize,

        [Parameter(Mandatory)]
        [ValidateRange(0, 200)]
        [int]$GpuLayers,

        [Parameter(Mandatory)]
        [ValidateRange(1, 128)]
        [int]$Threads
    )

    $slug = Convert-ToSlug -Text $Name
    $profilePath = Join-Path $PSScriptRoot ("models\$slug.json")
    $profileObj = [ordered]@{
        name       = $Name
        hf_repo    = $Repository
        hf_file    = $FileName
        model_path = $ResolvedModelPath
        ctx_size   = $CtxSize
        gpu_layers = $GpuLayers
        threads    = $Threads
        notes      = 'Auto-generated profile from installer.'
    }

    $profileObj | ConvertTo-Json -Depth 4 | Set-Content -Path $profilePath -Encoding ASCII
    return $profilePath
}

function New-ModelAgentFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ProfileName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ModelFileName
    )

    $slug = Convert-ToSlug -Text $ProfileName
    $agentName = "llama-$slug"
    $agentFileName = "$agentName.agent.md"
    $workspaceAgentDir = Join-Path $PSScriptRoot '.github\agents'
    $workspaceAgentPath = Join-Path $workspaceAgentDir $agentFileName
    $userAgentDir = Join-Path $env:APPDATA 'Code\User\prompts\agents'
    $userAgentPath = Join-Path $userAgentDir $agentFileName

    New-RequiredDirectory -Path $workspaceAgentDir
    New-RequiredDirectory -Path $userAgentDir

    $content = @"
---
name: $agentName
description: Local llama.cpp profile for $ProfileName.
argument-hint: Describe the model issue or llama.cpp setup you want to troubleshoot.
user-invocable: true
tools: [execute, read, search, edit]
---
You are a local llama.cpp specialist for profile '$ProfileName'.

Primary model file:
- $ModelFileName

Endpoints expected by llama-vscode:
- tools: http://localhost:8009
- chat: http://localhost:8011
- completion: http://localhost:8012
"@

    Set-Content -Path $workspaceAgentPath -Value $content -Encoding ASCII
    Copy-Item -Path $workspaceAgentPath -Destination $userAgentPath -Force
    return $workspaceAgentPath
}

function Get-DeploymentDownloadUrls {
    [CmdletBinding()]
    param()

    [pscustomobject]@{
        Llama = Get-LlamaCppDownloadUrl -ReleaseApiUrl $LlamaReleaseApiUrl -NamePattern $LlamaWindowsCudaZipPattern
        Model = Get-HuggingFaceModelDownloadUrl -ModelApiUrl $HuggingFaceModelApiUrl -Repository $ModelRepository -FileName ([System.IO.Path]::GetFileName($Paths.ModelPath))
    }
}

function Install-LlamaCppBinaries {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DownloadUrl
    )

    Write-Info 'Downloading llama.cpp CUDA binaries...'
    [void](Invoke-FileDownload -Uri $DownloadUrl -OutFile $Paths.LlamaZipPath)

    Write-Info 'Extracting files...'
    Expand-DownloadedArchive -Path $Paths.LlamaZipPath -DestinationPath $Paths.LlamaCppDirectory
    Remove-FileIfExists -Path $Paths.LlamaZipPath
}

function Get-RemoteFileSizeBytes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Uri
    )

    try {
        $headResponse = Invoke-WebRequest -Uri $Uri -Method Head -Headers @{ 'User-Agent' = 'PowerShell' } -MaximumRedirection 10
        if ($headResponse.Headers['Content-Length']) {
            return [Int64]$headResponse.Headers['Content-Length']
        }
    } catch { }

    return $null
}

function Start-DownloadProgressJob {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutFile,

        [Nullable[Int64]]$TotalBytes
    )

    Start-Job -ScriptBlock {
        param($outFile, $totalBytes)
        while ($true) {
            Start-Sleep -Seconds 5
            if ($totalBytes -and (Test-Path $outFile -PathType Leaf)) {
                $currentSize = (Get-Item $outFile).Length
                if ($currentSize -gt 0) {
                    $pct = [Math]::Round($currentSize / $totalBytes * 100, 1)
                    Write-Host ("  Downloaded {0} MB / {1} MB ({2}%)" -f ([Math]::Round($currentSize / 1MB, 1)), ([Math]::Round($totalBytes / 1MB, 1)), $pct) -ForegroundColor DarkCyan
                }
            }
        }
    } -ArgumentList $OutFile, $TotalBytes
}

function Install-ModelFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DownloadUrl
    )

    $modelLabel = $ProfileDisplayName
    Write-Info "Downloading $modelLabel GGUF directly from Hugging Face..."

    $modelTotalBytes = Get-RemoteFileSizeBytes -Uri $DownloadUrl
    $timerJob = Start-DownloadProgressJob -OutFile $Paths.ModelPath -TotalBytes $modelTotalBytes

    try {
        [void](Invoke-FileDownload -Uri $DownloadUrl -OutFile $Paths.ModelPath)
    } finally {
        Stop-Job -Job $timerJob -ErrorAction SilentlyContinue
        Remove-Job -Job $timerJob -Force -ErrorAction SilentlyContinue
        Receive-Job -Job $timerJob -ErrorAction SilentlyContinue | Out-Null
    }

    Write-Success 'Model download complete.'
}

function New-DeploymentLauncher {
    [CmdletBinding()]
    param()

    New-LauncherScript -Path $Paths.LauncherPath -WorkingDirectory $Paths.LlamaCppDirectory -ModelFile $Paths.ModelPath -DefaultCtxSize $DefaultCtxSize -DefaultGpuLayers $DefaultGpuLayers -DefaultThreads $DefaultThreads
}

function Resolve-RuntimeDefaults {
    [CmdletBinding()]
    param()

    if ($ProfileObj -or $Tiny -or $Small -or (-not ($HfRepo -and $HfFile))) {
        return
    }

    $safeDefaults = Get-SafeRuntimeDefaults -ModelPath $Paths.ModelPath
    $script:DefaultCtxSize = [int]$safeDefaults.Ctx
    $script:DefaultGpuLayers = [int]$safeDefaults.Ngl
    $script:DefaultThreads = [int]$safeDefaults.Threads
    Write-Info "Auto-safe defaults selected from file size: ctx=$DefaultCtxSize ngl=$DefaultGpuLayers threads=$DefaultThreads"
}

function Finalize-GeneralizedArtifacts {
    [CmdletBinding()]
    param()

    $savedProfilePath = Save-ModelProfile -Name $ProfileDisplayName -Repository $ModelRepository -FileName $ModelFileName -ResolvedModelPath $Paths.ModelPath -CtxSize $DefaultCtxSize -GpuLayers $DefaultGpuLayers -Threads $DefaultThreads
    Write-Success "Model profile saved: $savedProfilePath"

    if ($HfRepo -and $HfFile) {
        $agentPath = New-ModelAgentFile -ProfileName $ProfileDisplayName -ModelFileName $ModelFileName
        Write-Success "Model-specific agent generated: $agentPath"
    }
}

function Main {
    [CmdletBinding()]
    param()

    Initialize-Deployment
    $downloadUrls = Get-DeploymentDownloadUrls
    if (-not $ModelOnly) {
        Install-LlamaCppBinaries -DownloadUrl $downloadUrls.Llama
    } else {
        Write-Info 'Skipping llama.cpp binary download (-ModelOnly flag set).'
    }
    Install-ModelFile -DownloadUrl $downloadUrls.Model
    Resolve-RuntimeDefaults
    New-DeploymentLauncher
    Finalize-GeneralizedArtifacts
    Write-Success 'SUCCESS! Your local AI environment is fully deployed.'
    Write-Success "Desktop launcher created at: $($Paths.LauncherPath)"
}

Main
