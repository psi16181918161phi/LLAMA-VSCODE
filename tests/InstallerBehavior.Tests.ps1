Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:LLamaInstallerSkipMain = $true
    . "$PSScriptRoot\..\installing_ggufs_hf.ps1"
}

Describe 'Installer Behavior Helpers' {
    It 'normalizes profile names to stable slugs' {
        (Convert-ToSlug -Text 'Qwen 2.5 Coder 3B') | Should -Be 'qwen-2-5-coder-3b'
        (Convert-ToSlug -Text 'Meta-Llama 3 8B Instruct') | Should -Be 'meta-llama-3-8b-instruct'
    }

    It 'returns conservative defaults for sub-0.8GB models' {
        Mock Get-Item { [pscustomobject]@{ Length = [int64](0.5 * 1GB) } } -ParameterFilter { $Path -eq 'C:\mock\tiny.gguf' }

        $result = Get-SafeRuntimeDefaults -ModelPath 'C:\mock\tiny.gguf'

        $result.Ctx | Should -Be 2048
        $result.Ngl | Should -Be 8
        $result.Threads | Should -Be 4
    }

    It 'returns conservative defaults for 2-4GB models' {
        Mock Get-Item { [pscustomobject]@{ Length = [int64](3.0 * 1GB) } } -ParameterFilter { $Path -eq 'C:\mock\mid.gguf' }

        $result = Get-SafeRuntimeDefaults -ModelPath 'C:\mock\mid.gguf'

        $result.Ctx | Should -Be 3072
        $result.Ngl | Should -Be 16
        $result.Threads | Should -Be 6
    }

    It 'creates launcher content with supplied defaults' {
        $launcherPath = Join-Path $TestDrive 'Start-AI-Server-test.bat'

        New-LauncherScript -Path $launcherPath -WorkingDirectory 'C:\llama_cpp' -ModelFile 'C:\AI_Models\sample.gguf' -DefaultCtxSize 3072 -DefaultGpuLayers 16 -DefaultThreads 6

        $content = Get-Content -Path $launcherPath -Raw

        $content | Should -Match 'LLAMA_CTX_SIZE=3072'
        $content | Should -Match 'LLAMA_GPU_LAYERS=16'
        $content | Should -Match 'LLAMA_THREADS=6'
        $content | Should -Match '--model "C:\\AI_Models\\sample.gguf"'
    }
}
