param(
    [switch]$RunOnce = $false,
    [int]$CheckIntervalSeconds = 5,
    [string]$LogPath = (Join-Path $env:TEMP 'llama-server-watcher.log'),
    [string]$ProfilePath = '',
    [string]$ModelPath = 'C:\AI_Models\qwen2.5-coder-3b-instruct-q4_k_m.gguf',
    [int]$ContextSize = 3072,
    [int]$GpuLayers = 16,
    [int]$Threads = 6
)

$ErrorActionPreference = 'SilentlyContinue'

# Configuration
$LLAMA_DIR = "C:\llama_cpp"
$LLAMA_EXE = Join-Path $LLAMA_DIR "llama-server.exe"
$MODEL_PATH = $ModelPath
$CTX_SIZE = $ContextSize
$GPU_LAYERS = $GpuLayers
$THREADS = $Threads
$PORT_TOOLS = 8009
$PORT_CHAT = 8011
$PORT_COMPLETION = 8012

if ($ProfilePath -and (Test-Path -Path $ProfilePath -PathType Leaf)) {
    try {
        $profile = Get-Content -Path $ProfilePath -Raw | ConvertFrom-Json
        if ($profile.model_path) { $MODEL_PATH = [string]$profile.model_path }
        if ($profile.ctx_size) { $CTX_SIZE = [int]$profile.ctx_size }
        if ($profile.gpu_layers) { $GPU_LAYERS = [int]$profile.gpu_layers }
        if ($profile.threads) { $THREADS = [int]$profile.threads }
    } catch {
        Write-Host "[WARN] Could not parse profile at '$ProfilePath'. Using direct parameters."
    }
}

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp | $Message" | Add-Content -Path $LogPath
    Write-Host $Message
}

function Test-Endpoint {
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

function Test-ServerRunning {
    param([int]$Port)
    try {
        $result = Test-NetConnection -ComputerName 127.0.0.1 -Port $Port -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        return $result.TcpTestSucceeded
    } catch {
        return $false
    }
}

function Start-LlamaServer {
    param(
        [string]$Name,
        [int]$Port
    )
    
    # Check if process is already running on this port
    if (Test-ServerRunning -Port $Port) {
        Write-Log "  [OK] $Name (port $Port) already running"
        return $true
    }
    
    Write-Log "  [>>] Starting $Name (port $Port)..."
    
    try {
        # Start hidden, detached from current process
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = $LLAMA_EXE
        $pinfo.Arguments = "--model `"$MODEL_PATH`" --port $Port --ctx-size $CTX_SIZE -ngl $GPU_LAYERS --threads $THREADS"
        $pinfo.UseShellExecute = $false
        $pinfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $pinfo.CreateNoWindow = $true
        
        [System.Diagnostics.Process]::Start($pinfo) | Out-Null
        
        # Wait for endpoint to become ready
        $maxAttempts = 60
        $attempt = 0
        while ($attempt -lt $maxAttempts) {
            if (Test-Endpoint -Port $Port) {
                Write-Log "  [OK] $Name (port $Port) started successfully"
                return $true
            }
            Start-Sleep -Milliseconds 500
            $attempt++
        }
        
        Write-Log "  [FAIL] $Name (port $Port) timeout waiting for health check"
        return $false
    } catch {
        Write-Log "  [FAIL] $Name (port $Port) failed to start: $_"
        return $false
    }
}

function Get-VSCodeInstanceCount {
    try {
        $count = @(Get-Process -Name "Code" -ErrorAction SilentlyContinue).Count
        return $count
    } catch {
        return 0
    }
}

function Update-LlamaBootstrapSettings {
    $settingsPath = Join-Path $env:APPDATA 'Code\User\settings.json'
    
    try {
        if (-not (Test-Path $settingsPath)) {
            '{}' | Set-Content -Path $settingsPath -Encoding UTF8
        }
        
        $settingsRaw = Get-Content -Path $settingsPath -Raw
        if ([string]::IsNullOrWhiteSpace($settingsRaw)) {
            $settingsRaw = '{}'
        }
        
        $settings = $settingsRaw | ConvertFrom-Json

        function Set-SettingValue {
            param(
                [object]$Target,
                [string]$Name,
                [object]$Value
            )

            if ($Target.PSObject.Properties.Name -contains $Name) {
                $changed = $Target.$Name -ne $Value
                $Target.$Name = $Value
                return $changed
            }

            $Target | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
            return $true
        }

        $changedAny = $false
        $changedAny = (Set-SettingValue -Target $settings -Name 'llama-vscode.tool_create_agent_enabled' -Value $true) -or $changedAny
        $changedAny = (Set-SettingValue -Target $settings -Name 'llama-vscode.tool_edit_file_enabled' -Value $true) -or $changedAny
        $changedAny = (Set-SettingValue -Target $settings -Name 'llama-vscode.tool_permit_file_changes' -Value $true) -or $changedAny
        $changedAny = (Set-SettingValue -Target $settings -Name 'llama-vscode.tool_read_file_enabled' -Value $true) -or $changedAny
        $changedAny = (Set-SettingValue -Target $settings -Name 'llama-vscode.tool_get_diff_enabled' -Value $true) -or $changedAny
        $changedAny = (Set-SettingValue -Target $settings -Name 'llama-vscode.tool_list_directory_enabled' -Value $true) -or $changedAny
        $changedAny = (Set-SettingValue -Target $settings -Name 'llama-vscode.tools_max_iterations' -Value 20) -or $changedAny

        if ($changedAny) {
            $settings | ConvertTo-Json -Depth 20 | Set-Content -Path $settingsPath -Encoding UTF8
            Write-Log "  [OK] Bootstrap: Enforced llama-vscode inline edit tool settings"
            return $true
        }

        return $false
    } catch {
        Write-Log "  [WARN] Bootstrap warning: $_"
        return $false
    }
}

# Main watcher loop
Write-Log "=== Llama Server Watcher Started ==="
Write-Log "Model: $MODEL_PATH"
Write-Log "Endpoints: tools=$PORT_TOOLS, chat=$PORT_CHAT, completion=$PORT_COMPLETION"

$previousVSCodeCount = 0
$lastBootstrap = (Get-Date).AddHours(-1)

do {
    $vscodeCount = Get-VSCodeInstanceCount
    
    if ($vscodeCount -gt 0) {
        # VS Code is running - ensure servers are up
        $nowTime = Get-Date -Format "HH:mm:ss"
        $statusMsg = "[$nowTime] VS Code running ($vscodeCount instances)"
        
        if ($vscodeCount -ne $previousVSCodeCount) {
            Write-Log $statusMsg
            $previousVSCodeCount = $vscodeCount
        }
        
        # Bootstrap settings periodically (every 5 minutes)
        if ((Get-Date) - $lastBootstrap -gt (New-TimeSpan -Minutes 5)) {
            Update-LlamaBootstrapSettings | Out-Null
            $lastBootstrap = Get-Date
        }
        
        # Check if all endpoints are healthy
        $allHealthy = $true
        $ports = @($PORT_TOOLS, $PORT_CHAT, $PORT_COMPLETION)
        
        foreach ($port in $ports) {
            if (-not (Test-Endpoint -Port $port)) {
                $allHealthy = $false
                Write-Log "  [WARN] Endpoint on port $port is not responding"
            }
        }
        
        # If any endpoint is down, try to restart the whole stack
        if (-not $allHealthy) {
            Write-Log "Restarting llama server stack..."
            Start-LlamaServer -Name "llama-tools" -Port $PORT_TOOLS | Out-Null
            Start-Sleep -Milliseconds 1000
            Start-LlamaServer -Name "llama-chat" -Port $PORT_CHAT | Out-Null
            Start-Sleep -Milliseconds 1000
            Start-LlamaServer -Name "llama-completion" -Port $PORT_COMPLETION | Out-Null
        }
    } else {
        # No VS Code running
        if ($previousVSCodeCount -gt 0) {
            Write-Log "VS Code closed, all instances stopped"
            Write-Log "Servers remain running (for background tasks or manual access)"
            $previousVSCodeCount = 0
        }
    }
    
    if ($RunOnce) {
        break
    }
    
    Start-Sleep -Seconds $CheckIntervalSeconds
} while ($true)

Write-Log "=== Llama Server Watcher Stopped ==="
