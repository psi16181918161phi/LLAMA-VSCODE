param(
    [switch]$Uninstall = $false
)

$ErrorActionPreference = 'Stop'

$taskName = "Llama-Server-Auto-Watcher"
$taskDescription = "Automatically manages llama-cpp server instances based on VS Code activity"
$scriptRoot = Split-Path -Parent $PSScriptRoot
$watcherScript = Join-Path $scriptRoot "scripts\Start-LlamaServerWatcher.ps1"

function Write-Status {
    param([string]$Message, [string]$Type = "Info")
    $color = "White"
    if ($Type -eq "Success") { $color = "Green" }
    if ($Type -eq "Error") { $color = "Red" }
    if ($Type -eq "Warning") { $color = "Yellow" }
    Write-Host "[$Type] $Message" -ForegroundColor $color
}

# Check for admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Status "This script requires Administrator privileges" "Error"
    Write-Status "Please run 'Run as Administrator' and try again" "Error"
    exit 1
}

if ($Uninstall) {
    Write-Status "Uninstalling scheduled task: $taskName" "Info"
    try {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        Write-Status "Task uninstalled successfully" "Success"
    } catch {
        Write-Status "Task not found or already removed" "Warning"
    }
    exit 0
}

# Verify watcher script exists
if (-not (Test-Path $watcherScript)) {
    Write-Status "Watcher script not found: $watcherScript" "Error"
    exit 1
}

Write-Status "Configuring scheduled task for auto-start" "Info"
Write-Status "Task name: $taskName" "Info"
Write-Status "Watcher script: $watcherScript" "Info"

try {
    # Check if task already exists
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Status "Task already exists, updating..." "Warning"
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    
    # Create the task trigger (at logon)
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    
    # Create the task action (WindowStyle Hidden so no console appears at logon)
    $action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$watcherScript`" -CheckIntervalSeconds 5"
    
    # Create task settings (compatible across ScheduledTasks module variants)
    try {
        $settings = New-ScheduledTaskSettingsSet `
            -AllowStartIfOnBatteries `
            -DontStopIfGoingOnBatteries `
            -StartWhenAvailable `
            -RunOnlyIfNetworkAvailable:$false `
            -MultipleInstances IgnoreNew
    } catch {
        $settings = New-ScheduledTaskSettingsSet `
            -AllowStartIfOnBatteries `
            -DontStopIfGoingOnBatteries `
            -StartWhenAvailable `
            -RunOnlyIfNetworkAvailable:$false
    }
    
    # Register the task
    $task = Register-ScheduledTask `
        -TaskName $taskName `
        -Trigger $trigger `
        -Action $action `
        -Settings $settings `
        -Description $taskDescription `
        -RunLevel Highest `
        -Force
    
    Write-Status "Task registered successfully!" "Success"
    
    # Try to start it immediately
    Write-Status "Starting task now..." "Info"
    Start-ScheduledTask -TaskName $taskName
    
    Start-Sleep -Seconds 2
    
    # Verify it's running
    $runningTask = Get-ScheduledTask -TaskName $taskName
    if ($runningTask.State -eq "Running") {
        Write-Status "Task is running successfully" "Success"
    } else {
        Write-Status "Task registered but not running yet. It will start at next logon." "Warning"
    }
    
    Write-Status "" "Info"
    Write-Status "Next steps:" "Info"
    Write-Status "  1. Monitor the watcher log: $env:TEMP\llama-server-watcher.log" "Info"
    Write-Status "  2. Open VS Code - servers should auto-start" "Info"
    Write-Status "  3. Close all VS Code windows - servers remain running" "Info"
    Write-Status "  4. To uninstall: Run this script with -Uninstall flag" "Info"
    
} catch {
    Write-Status "Failed to register task: $_" "Error"
    exit 1
}
