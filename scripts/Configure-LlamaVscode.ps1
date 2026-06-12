param(
    [string]$ModelPath = 'C:\AI_Models\qwen2.5-coder-3b-instruct-q4_k_m.gguf',
    [int]$ContextSize = 3072,
    [int]$GpuLayers = 16,
    [int]$Threads = 6,
    [int]$ToolsPort = 8009,
    [int]$ChatPort = 8011,
    [int]$CompletionPort = 8012
)

$ErrorActionPreference = 'Stop'

$settingsPath = Join-Path $env:APPDATA 'Code\User\settings.json'
$userModelsPath = Join-Path $env:APPDATA 'Code\User\chatLanguageModels.json'
$workspaceModelsPath = Join-Path $PSScriptRoot '..\.vscode\chatLanguageModels.json'
$llamaExe = 'C:\llama_cpp\llama-server.exe'

if (-not (Test-Path $settingsPath)) {
    '{}' | Set-Content -Path $settingsPath -Encoding UTF8
}

$settingsRaw = Get-Content -Path $settingsPath -Raw
if ([string]::IsNullOrWhiteSpace($settingsRaw)) {
    $settingsRaw = '{}'
}

try {
    $settings = $settingsRaw | ConvertFrom-Json
} catch {
    throw "Unable to parse $settingsPath as JSON. Remove trailing comments and try again."
}

function Set-SettingValue {
    param(
        [object]$Target,
        [string]$Name,
        [object]$Value
    )

    if ($Target.PSObject.Properties.Name -contains $Name) {
        $Target.$Name = $Value
    } else {
        $Target | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

$modelName = [System.IO.Path]::GetFileNameWithoutExtension($ModelPath)
$launchTools = "`"$llamaExe`" --model `"$ModelPath`" --port $ToolsPort --ctx-size $ContextSize -ngl $GpuLayers --threads $Threads"
$launchChat = "`"$llamaExe`" --model `"$ModelPath`" --port $ChatPort --ctx-size $ContextSize -ngl $GpuLayers --threads $Threads"
$launchCompletion = "`"$llamaExe`" --model `"$ModelPath`" --port $CompletionPort --ctx-size $ContextSize -ngl $GpuLayers --threads $Threads"

Set-SettingValue -Target $settings -Name 'llama-vscode.tool_create_agent_enabled' -Value $true
Set-SettingValue -Target $settings -Name 'llama-vscode.tool_edit_file_enabled' -Value $true
Set-SettingValue -Target $settings -Name 'llama-vscode.tool_permit_file_changes' -Value $true
Set-SettingValue -Target $settings -Name 'llama-vscode.tool_read_file_enabled' -Value $true
Set-SettingValue -Target $settings -Name 'llama-vscode.tool_get_diff_enabled' -Value $true
Set-SettingValue -Target $settings -Name 'llama-vscode.tool_list_directory_enabled' -Value $true
Set-SettingValue -Target $settings -Name 'llama-vscode.tools_max_iterations' -Value 20
Set-SettingValue -Target $settings -Name 'llama-vscode.ai_model' -Value $modelName
Set-SettingValue -Target $settings -Name 'llama-vscode.endpoint' -Value "http://localhost:$CompletionPort"
Set-SettingValue -Target $settings -Name 'llama-vscode.endpoint_tools' -Value "http://localhost:$ToolsPort"
Set-SettingValue -Target $settings -Name 'llama-vscode.endpoint_chat' -Value "http://localhost:$ChatPort"
Set-SettingValue -Target $settings -Name 'llama-vscode.launch_tools' -Value $launchTools
Set-SettingValue -Target $settings -Name 'llama-vscode.launch_chat' -Value $launchChat
Set-SettingValue -Target $settings -Name 'llama-vscode.launch_completion' -Value $launchCompletion

$settings | ConvertTo-Json -Depth 20 | Set-Content -Path $settingsPath -Encoding UTF8

if (Test-Path $workspaceModelsPath) {
    Copy-Item -Path $workspaceModelsPath -Destination $userModelsPath -Force
}

Write-Host "Updated llama-vscode user settings and model provider registrations."
Write-Host "tool_edit_file enabled : true"
Write-Host "tools endpoint      : http://localhost:$ToolsPort"
Write-Host "chat endpoint       : http://localhost:$ChatPort"
Write-Host "completion endpoint : http://localhost:$CompletionPort"