<#
.SYNOPSIS
    Immediately stops all running llama-server.exe processes and the background
    auto-watcher, without touching the scheduled task registration.

.DESCRIPTION
    Use this for an instant "turn it off now" kill switch when the CPU/fans are
    running hot. It does NOT disable auto-start at next login - for that, run:
        scripts\Register-LlamaServerTask.ps1 -Uninstall

.EXAMPLE
    .\scripts\Stop-LlamaServers.ps1
#>

$ErrorActionPreference = 'SilentlyContinue'

$stopped = 0

Get-Process -Name "llama-server" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "Stopping llama-server.exe (PID $($_.Id))..."
    Stop-Process -Id $_.Id -Force
    $stopped++
}

Get-CimInstance Win32_Process -Filter "Name='powershell.exe' OR Name='pwsh.exe'" |
Where-Object { $_.CommandLine -match 'Start-LlamaServerWatcher' } |
ForEach-Object {
    Write-Host "Stopping watcher process (PID $($_.ProcessId))..."
    Stop-Process -Id $_.ProcessId -Force
    $stopped++
}

if ($stopped -eq 0) {
    Write-Host "Nothing was running. llama-server and watcher are already stopped."
} else {
    Write-Host "Stopped $stopped process(es)."
}

Write-Host ""
Write-Host "Note: if the 'Llama-Server-Auto-Watcher' scheduled task is still registered,"
Write-Host "it will start the servers again at your next login. To disable that permanently, run:"
Write-Host "  scripts\Register-LlamaServerTask.ps1 -Uninstall"
Write-Host "To re-enable auto-start later, run:"
Write-Host "  scripts\Register-LlamaServerTask.ps1 -Profile qwen2.5-3b"
