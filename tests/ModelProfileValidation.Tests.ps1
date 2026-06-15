Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    . "$PSScriptRoot\..\scripts\Validate-ModelProfile.ps1"
}

Describe 'Model Profile Validation' {
    It 'accepts a valid profile file' {
        $profilePath = Join-Path $TestDrive 'valid-profile.json'
        @'
{
  "name": "Qwen2.5-Coder-3B",
  "hf_repo": "Qwen/Qwen2.5-Coder-3B-Instruct-GGUF",
  "hf_file": "qwen2.5-coder-3b-instruct-q4_k_m.gguf",
  "model_path": "C:\\AI_Models\\qwen2.5-coder-3b-instruct-q4_k_m.gguf",
  "ctx_size": 3072,
  "gpu_layers": 16,
  "threads": 6,
  "notes": "valid test profile"
}
'@ | Set-Content -Path $profilePath -Encoding ASCII

        $result = Test-ModelProfileFile -ProfilePath $profilePath -SchemaPath (Join-Path $PSScriptRoot '..\models\model-profile.schema.json')

        $result.name | Should -Be 'Qwen2.5-Coder-3B'
        $result.threads | Should -Be 6
    }

    It 'rejects missing required property' {
        $profilePath = Join-Path $TestDrive 'missing-field.json'
        @'
{
  "name": "BadProfile",
  "hf_repo": "Qwen/Qwen2.5-Coder-3B-Instruct-GGUF",
  "model_path": "C:\\AI_Models\\bad.gguf",
  "ctx_size": 3072,
  "gpu_layers": 16,
  "threads": 6,
  "notes": "missing hf_file"
}
'@ | Set-Content -Path $profilePath -Encoding ASCII

        { Test-ModelProfileFile -ProfilePath $profilePath -SchemaPath (Join-Path $PSScriptRoot '..\models\model-profile.schema.json') } | Should -Throw
    }

    It 'rejects invalid numeric ranges' {
        $profilePath = Join-Path $TestDrive 'invalid-ranges.json'
        @'
{
  "name": "BadRange",
  "hf_repo": "Qwen/Qwen2.5-Coder-3B-Instruct-GGUF",
  "hf_file": "bad-range.gguf",
  "model_path": "C:\\AI_Models\\bad-range.gguf",
  "ctx_size": 128,
  "gpu_layers": 16,
  "threads": 0,
  "notes": "invalid ctx/thread"
}
'@ | Set-Content -Path $profilePath -Encoding ASCII

        { Test-ModelProfileFile -ProfilePath $profilePath -SchemaPath (Join-Path $PSScriptRoot '..\models\model-profile.schema.json') } | Should -Throw
    }
}
