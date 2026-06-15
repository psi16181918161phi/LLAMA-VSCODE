Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ModelProfileSchemaPath {
    [CmdletBinding()]
    param(
        [string]$RootPath = (Split-Path -Parent $PSScriptRoot)
    )

    return Join-Path $RootPath 'models\model-profile.schema.json'
}

function Test-ModelProfileObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$ProfileObject
    )

    $requiredProperties = @('name', 'hf_repo', 'hf_file', 'model_path', 'ctx_size', 'gpu_layers', 'threads', 'notes')
    foreach ($property in $requiredProperties) {
        if (-not ($ProfileObject.PSObject.Properties.Name -contains $property)) {
            throw "Profile is missing required property '$property'."
        }
    }

    if ([string]::IsNullOrWhiteSpace([string]$ProfileObject.name)) {
        throw "Profile field 'name' must be a non-empty string."
    }

    if ([string]::IsNullOrWhiteSpace([string]$ProfileObject.hf_repo) -or ([string]$ProfileObject.hf_repo -notmatch '^[^/]+/[^/]+$')) {
        throw "Profile field 'hf_repo' must be in 'owner/repo' format."
    }

    if ([string]::IsNullOrWhiteSpace([string]$ProfileObject.hf_file) -or ([string]$ProfileObject.hf_file -notmatch '(?i)\.gguf$')) {
        throw "Profile field 'hf_file' must be a .gguf filename."
    }

    if ([string]::IsNullOrWhiteSpace([string]$ProfileObject.model_path)) {
        throw "Profile field 'model_path' must be a non-empty path."
    }

    $ctxSize = [int]$ProfileObject.ctx_size
    if ($ctxSize -lt 256 -or $ctxSize -gt 32768) {
        throw "Profile field 'ctx_size' must be between 256 and 32768."
    }

    $gpuLayers = [int]$ProfileObject.gpu_layers
    if ($gpuLayers -lt 0 -or $gpuLayers -gt 200) {
        throw "Profile field 'gpu_layers' must be between 0 and 200."
    }

    $threads = [int]$ProfileObject.threads
    if ($threads -lt 1 -or $threads -gt 128) {
        throw "Profile field 'threads' must be between 1 and 128."
    }

    return $true
}

function Test-ModelProfileFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ProfilePath,

        [string]$SchemaPath = (Get-ModelProfileSchemaPath)
    )

    if (-not (Test-Path -Path $ProfilePath -PathType Leaf)) {
        throw "Profile file not found: $ProfilePath"
    }

    $raw = Get-Content -Path $ProfilePath -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        throw "Profile file is empty: $ProfilePath"
    }

    $profileObject = $raw | ConvertFrom-Json

    $testJsonCommand = Get-Command -Name Test-Json -ErrorAction SilentlyContinue
    $canUseSchemaValidation = $false
    if ($testJsonCommand) {
        $canUseSchemaValidation = ($testJsonCommand.Parameters.Keys -contains 'SchemaFile') -and (Test-Path -Path $SchemaPath -PathType Leaf)
    }

    if ($canUseSchemaValidation) {
        $schemaValid = $raw | Test-Json -SchemaFile $SchemaPath
        if (-not $schemaValid) {
            throw "Profile schema validation failed for file: $ProfilePath"
        }
    }

    Test-ModelProfileObject -ProfileObject $profileObject | Out-Null
    return $profileObject
}
