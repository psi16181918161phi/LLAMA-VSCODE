# Inline Chat Feature Validation for llama-local and llama-vscode
# This script validates:
# 1. Inline chat model/agent picker visibility
# 2. Local model registration in chatLanguageModels.json
# 3. Agent discovery and frontmatter compliance
# 4. Settings bootstrap state

param(
    [switch]$Verbose = $false
)

$ErrorActionPreference = 'SilentlyContinue'

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "═" * 70 -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "═" * 70 -ForegroundColor Cyan
}

function Write-Result {
    param([string]$Check, [bool]$Pass, [string]$Details = "")
    $icon = if ($Pass) { "[OK]" } else { "[FAIL]" }
    $color = if ($Pass) { "Green" } else { "Red" }
    Write-Host "  $icon $Check" -ForegroundColor $color
    if ($Details) {
        Write-Host "       $Details" -ForegroundColor Gray
    }
}

function Get-Setting {
    param([string]$Key)
    $settingsPath = Join-Path $env:APPDATA 'Code\User\settings.json'
    if (-not (Test-Path $settingsPath)) { return $null }
    
    try {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        return $settings.$Key
    } catch {
        return $null
    }
}

function Test-EndpointHealth {
    param([int]$Port)
    try {
        Invoke-RestMethod -Uri "http://127.0.0.1:$Port/health" -TimeoutSec 2 -ErrorAction Stop | Out-Null
        return $true
    } catch {
        try {
            Invoke-RestMethod -Uri "http://127.0.0.1:$Port/v1/models" -TimeoutSec 2 -ErrorAction Stop | Out-Null
            return $true
        } catch {
            return $false
        }
    }
}

# ============================================================================

Write-Section "Inline Chat Feature Validation"
Write-Host "Testing llama-local and llama-vscode integration with VS Code"

# 1. Check endpoint configuration
Write-Section "1. Endpoint Configuration"

$endpoints = @{
    "Tools (8009)"      = Get-Setting 'llama-vscode.endpoint_tools'
    "Chat (8011)"       = Get-Setting 'llama-vscode.endpoint_chat'
    "Completion (8012)" = Get-Setting 'llama-vscode.endpoint'
}

$allEndpointsConfigured = $true
foreach ($name in $endpoints.Keys) {
    $configured = $null -ne $endpoints[$name]
    Write-Result "Endpoint configured: $name" $configured $endpoints[$name]
    if (-not $configured) { $allEndpointsConfigured = $false }
}

# 2. Check endpoint health
Write-Section "2. Endpoint Health"

$ports = @(8009, 8011, 8012)
$allHealthy = $true
foreach ($port in $ports) {
    $healthy = Test-EndpointHealth -Port $port
    $portNames = @{ 8009 = "Tools"; 8011 = "Chat"; 8012 = "Completion" }
    Write-Result "Endpoint healthy: $($portNames[$port]) (port $port)" $healthy
    if (-not $healthy) { $allHealthy = $false }
}

# 3. Check model registration
Write-Section "3. Model Registration"

$modelPath = Join-Path $env:APPDATA 'Code\User\chatLanguageModels.json'
$modelPathExists = Test-Path $modelPath
Write-Result "chatLanguageModels.json exists" $modelPathExists $modelPath

if ($modelPathExists) {
    try {
        $models = Get-Content $modelPath -Raw | ConvertFrom-Json
        $hasLlama = @($models | Where-Object {
                ($_.name -like 'llama*') -or
                ($_.vendor -eq 'llama-vscode') -or
                ($_.provider -eq 'llama-vscode')
            })
        Write-Result "Llama provider registered" ($hasLlama.Count -gt 0) "$($hasLlama.Count) provider entry(s)"
        
        if ($Verbose -and $hasLlama) {
            Write-Host "    Registered models:" -ForegroundColor Gray
            $hasLlama | ForEach-Object { Write-Host "      - $($_.label) (ID: $($_.id))" -ForegroundColor Gray }
        }
    } catch {
        Write-Result "chatLanguageModels.json is valid JSON" $false "Parse error"
    }
}

# 4. Check agent discovery
Write-Section "4. Agent Discovery"

$agentPaths = @(
    (Join-Path $env:USERPROFILE '.copilot\agents'),
    (Join-Path $env:APPDATA 'Code\User\prompts\agents'),
    '.github\agents'
)

$agentCount = 0
foreach ($path in $agentPaths) {
    if (Test-Path $path) {
        $agents = Get-ChildItem $path -Filter "*.agent.md" -ErrorAction SilentlyContinue
        if ($agents) {
            $agentCount += @($agents).Count
            Write-Result "Agents found in: $path" $true "$(@($agents).Count) agents"
            
            if ($Verbose) {
                $agents | ForEach-Object {
                    Write-Host "      - $($_.Name)" -ForegroundColor Gray
                }
            }
        }
    }
}

Write-Result "Total agents discovered" ($agentCount -gt 0) "$agentCount total"

# 5. Check llama-specific agents
Write-Section "5. Llama-Specific Agents"

$llamaAgents = @("llama-local.agent.md", "llama-vscode.agent.md")
$llamaFound = 0

foreach ($agentPath in $agentPaths) {
    if (Test-Path $agentPath) {
        foreach ($agent in $llamaAgents) {
            $fullPath = Join-Path $agentPath $agent
            if (Test-Path $fullPath) {
                $llamaFound++
                Write-Result "Agent found: $agent" $true $agentPath
                
                if ($Verbose) {
                    $content = Get-Content $fullPath -TotalCount 20
                    Write-Host "    Frontmatter sample:" -ForegroundColor Gray
                    $content | ForEach-Object { Write-Host "      $_" -ForegroundColor Gray }
                }
            }
        }
    }
}

if ($llamaFound -eq 0) {
    Write-Result "Llama agents found" $false "Neither llama-local nor llama-vscode detected"
}

# 6. Check settings bootstrap
Write-Section "6. Settings Bootstrap"

$checks = @{
    "Agent creation enabled"      = "llama-vscode.tool_create_agent_enabled"
    "Edit file tool enabled"      = "llama-vscode.tool_edit_file_enabled"
    "Read file tool enabled"      = "llama-vscode.tool_read_file_enabled"
    "Get diff tool enabled"       = "llama-vscode.tool_get_diff_enabled"
    "List directory tool enabled" = "llama-vscode.tool_list_directory_enabled"
    "AI Model configured"         = "llama-vscode.ai_model"
    "Launch tools command"        = "llama-vscode.launch_tools"
    "Launch chat command"         = "llama-vscode.launch_chat"
    "Launch completion command"   = "llama-vscode.launch_completion"
}

foreach ($checkName in $checks.Keys) {
    $setting = Get-Setting $checks[$checkName]
    $isBoolCheck = $checkName -like "*enabled"
    if ($isBoolCheck) {
        Write-Result $checkName ($setting -eq $true) $checks[$checkName]
    } else {
        Write-Result $checkName ($null -ne $setting) $checks[$checkName]
    }
}

# 7. Summary
Write-Section "Summary & Recommendations"

$summaryScore = 0
$scoreChecks = @(
    [bool]$allEndpointsConfigured,
    [bool]$allHealthy,
    [bool]$modelPathExists,
    [bool]($agentCount -gt 0),
    [bool]($llamaFound -gt 0)
)
$maxScore = $scoreChecks.Count

$scoreChecks | ForEach-Object {
    if ($_) { $summaryScore++ }
}

Write-Host ""
Write-Host "  Score: $summaryScore / $maxScore checks passed" -ForegroundColor $(if ($summaryScore -eq $maxScore) { "Green" } else { "Yellow" })
Write-Host ""

if ($summaryScore -lt $maxScore) {
    Write-Host "  Recommended fixes:" -ForegroundColor Yellow
    if (-not $allEndpointsConfigured) {
        Write-Host "    - Run: Start-AI-Server.bat to ensure all endpoints are configured" -ForegroundColor Yellow
    }
    if (-not $allHealthy) {
        Write-Host "    - Verify llama-server is running or check ports availability" -ForegroundColor Yellow
    }
    if (-not $modelPathExists) {
        Write-Host "    - Run Configure-LlamaVscode.ps1 to register models" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [OK] All checks passed! Inline chat should work with llama models." -ForegroundColor Green
    Write-Host "  - Try using @llama-local or @llama-vscode in inline chat" -ForegroundColor Green
    Write-Host "  - Use the model picker (dropdown) when clicking in a chat input" -ForegroundColor Green
}

Write-Host ""
