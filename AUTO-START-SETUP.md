# Llama Server Auto-Start/Stop Setup Guide

## Overview

This guide configures the llama-cpp server stack to automatically start when VS Code launches and stop when all VS Code instances close. This eliminates the need for manual server management and enables seamless inline chat features with local `llama-local` and `llama-vscode` models.

## Features

- ✓ **Auto-Start**: Servers launch when VS Code opens
- ✓ **Auto-Bootstrap**: VS Code settings auto-configure on each check
- ✓ **Health Monitoring**: Periodic endpoint health verification
- ✓ **Graceful Restart**: Failed endpoints automatically restart
- ✓ **Agent Discovery**: Enables llama-local and llama-vscode in agent picker
- ✓ **Inline Chat**: Model/agent selection works in inline chat
- ✓ **Zero Configuration**: Just run and forget

## Quick Start

### Option 1: Manual Watcher (Recommended for Testing)

1. Open PowerShell
2. Navigate to the LLAMA-VSCODE folder:
   ```powershell
   cd c:\Users\lordx\Desktop\LLAMA-VSCODE
   ```
3. Start the auto-watcher:
   ```batch
   .\Start-AI-Server-AutoWatcher.bat
   ```
4. Keep the window open - it monitors VS Code instances
5. Launch VS Code - servers should auto-start
6. Check the watcher log:
   ```powershell
   Get-Content $env:TEMP\llama-server-watcher.log -Wait
   ```

### Option 2: Windows Task Scheduler (Production)

For automatic startup with Windows login:

1. Open PowerShell as Administrator
2. Navigate to the scripts folder:
   ```powershell
   cd c:\Users\lordx\Desktop\LLAMA-VSCODE\scripts
   ```
3. Register the scheduled task:
   ```powershell
   .\Register-LlamaServerTask.ps1
   ```
4. Task will:
   - Auto-start when you log in
   - Run in background continuously
   - Start servers when VS Code launches
   - Monitor endpoint health

5. To uninstall the task:
   ```powershell
   .\Register-LlamaServerTask.ps1 -Uninstall
   ```

## Validation & Testing

### Test 1: Validate Inline Chat Features

Run the validation script to check all components:

```powershell
cd c:\Users\lordx\Desktop\LLAMA-VSCODE\scripts
.\Validate-InlineChatFeatures.ps1 -Verbose
```

This checks:
- ✓ Endpoint configuration (tools, chat, completion)
- ✓ Endpoint health (HTTP connectivity)
- ✓ Model registration in VS Code
- ✓ Agent discovery (llama-local, llama-vscode)
- ✓ Settings bootstrap state

### Test 2: Manual Server Startup

Start the server stack manually to verify endpoints:

```powershell
cd c:\Users\lordx\Desktop\LLAMA-VSCODE
.\Start-AI-Server.bat
```

Wait for health checks to complete, then verify:
```powershell
# In another terminal
Invoke-RestMethod http://localhost:8009/v1/models
Invoke-RestMethod http://localhost:8011/v1/models
Invoke-RestMethod http://localhost:8012/v1/models
```

### Test 3: Auto-Start Verification

1. Start the watcher:
   ```batch
   .\Start-AI-Server-AutoWatcher.bat
   ```
2. Open VS Code
3. Wait 10 seconds
4. Check if servers are running:
   ```powershell
   Get-Process | grep llama-server
   ```
5. Verify endpoints are healthy (see Test 1)

### Test 4: Inline Chat Feature Test

1. Ensure servers are running (see Test 3)
2. Open VS Code
3. Open a file or create a new chat
4. In inline chat:
   - Click the model dropdown (shows registered models)
   - Look for "qwen2.5-coder-3b-instruct" or other local models
   - If visible, local models are properly registered
5. Try agent selection:
   - Type `@` in chat to see agent suggestions
   - Look for `@llama-local` or `@llama-vscode`
   - If visible, agents are properly discovered

### Test 5: Agent Picker Visibility

In the agent selector dropdown:
1. Click the agent dropdown next to chat input
2. Scroll through available agents
3. Look for entries with "llama" in the name
4. If visible, agents are registered correctly

## Architecture

### Component Diagram

```
VS Code Instance
    ↓
Watcher Process (monitoring)
    ↓
┌─────────────────────────────────────────┐
│ Auto-Start Decision                     │
│ • Check: Is VS Code running?            │
│ • If YES: Ensure servers running        │
│ • If NO: Servers stay running           │
└─────────────────────────────────────────┘
    ↓
Llama Server Stack
    ├── Port 8009: Tools endpoint
    ├── Port 8011: Chat endpoint
    └── Port 8012: Completion endpoint
    ↓
llama-vscode Extension
    ├── Model registration
    ├── Agent discovery
    └── Inline chat support
```

### Flow Diagram

```
1. Watcher starts
   ↓
2. Get VS Code process count
   ├── COUNT > 0: Ensure servers running
   │             └→ Check endpoint health
   │                ├─ OK: Continue monitoring
   │                └─ FAIL: Restart server
   │
   └── COUNT = 0: Servers stay running
                  (available for background tasks)
   ↓
3. Bootstrap settings every 5 minutes
   └→ Ensure llama-vscode.tool_create_agent_enabled = true
   ↓
4. Wait 5 seconds, go to step 2
```

## File Structure

```
LLAMA-VSCODE/
├── Start-AI-Server-AutoWatcher.bat          ← Start watcher manually
├── scripts/
│   ├── Start-LlamaServerWatcher.ps1         ← Core watcher logic
│   ├── Register-LlamaServerTask.ps1         ← Register Windows task
│   ├── Validate-InlineChatFeatures.ps1      ← Validation script
│   └── Configure-LlamaVscode.ps1            ← Settings bootstrap
```

## Environment Variables (Optional)

Override defaults in the watcher by setting before launch:

```powershell
$env:LLAMA_MODEL = "C:\AI_Models\qwen2.5-coder-0.5b-instruct-q2_k.gguf"
$env:LLAMA_CTX_SIZE = "2048"
$env:LLAMA_GPU_LAYERS = "8"
$env:LLAMA_THREADS = "4"
$env:LLAMA_PORT_TOOLS = "8009"
$env:LLAMA_PORT_CHAT = "8011"
$env:LLAMA_PORT_COMPLETION = "8012"

# Then start watcher
.\Start-AI-Server-AutoWatcher.bat
```

## Monitoring & Logs

### Watcher Log Location

```
%TEMP%\llama-server-watcher.log
```

View in real-time:
```powershell
Get-Content $env:TEMP\llama-server-watcher.log -Wait
```

### Log Format

```
2026-06-12 14:30:45 | === Llama Server Watcher Started ===
2026-06-12 14:30:45 | [14:30:45] VS Code running (1 instances)
2026-06-12 14:30:46 | ↻ Starting llama-tools (port 8009)...
2026-06-12 14:30:51 | ✓ llama-tools (port 8009) started successfully
2026-06-12 14:31:00 | Bootstrap: Enabled llama-vscode agent creation
```

## Troubleshooting

### Issue: Servers don't start automatically

**Check:**
1. Is watcher running?
   ```powershell
   Get-Process | grep powershell
   ```
2. Are VS Code processes detected?
   ```powershell
   Get-Process -Name "Code"
   ```
3. Check watcher log for errors
   ```powershell
   Get-Content $env:TEMP\llama-server-watcher.log | tail -50
   ```

### Issue: Endpoints report as unhealthy

**Check:**
1. Is llama-server.exe available?
   ```powershell
   Test-Path C:\llama_cpp\llama-server.exe
   ```
2. Is the model file present?
   ```powershell
   Test-Path C:\AI_Models\qwen2.5-coder-3b-instruct-q4_k_m.gguf
   ```
3. Are ports available?
   ```powershell
   Get-NetTCPConnection -State Listen | Where-Object {$_.LocalPort -in 8009,8011,8012}
   ```

### Issue: Inline chat models/agents not visible

**Check:**
1. Run validation:
   ```powershell
   .\Validate-InlineChatFeatures.ps1 -Verbose
   ```
2. Verify chatLanguageModels.json exists:
   ```powershell
   Test-Path "$env:APPDATA\Code\User\chatLanguageModels.json"
   ```
3. Check agent files exist:
   ```powershell
   Get-ChildItem "$env:USERPROFILE\.copilot\agents" -Filter "llama*.agent.md"
   ```
4. Verify settings:
   ```powershell
   $s = Get-Content "$env:APPDATA\Code\User\settings.json" -Raw | ConvertFrom-Json
   $s.'llama-vscode.tool_create_agent_enabled'  # Should be true
   ```

### Issue: Task scheduler not starting

**Fix:**
1. Verify admin permissions:
   ```powershell
   [Security.Principal.WindowsPrincipal]::New([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrator')
   ```
2. Check task exists:
   ```powershell
   Get-ScheduledTask -TaskName "Llama-Server-Auto-Watcher"
   ```
3. Manually trigger task:
   ```powershell
   Start-ScheduledTask -TaskName "Llama-Server-Auto-Watcher"
   ```

## Next Steps

1. **Test the setup:**
   - Run `Validate-InlineChatFeatures.ps1` to verify all components
   - Launch VS Code and check if servers auto-start
   - Test inline chat with model/agent selection

2. **Deploy to production:**
   - Run `Register-LlamaServerTask.ps1` for auto-startup
   - Restart Windows to verify it persists
   - Monitor `$env:TEMP\llama-server-watcher.log`

3. **Customize:**
   - Edit `Start-LlamaServerWatcher.ps1` to change ports, models, or intervals
   - Adjust GPU layers (-ngl) or context size based on your hardware
   - Modify health check frequency for different monitoring needs

## Support

For detailed debugging, enable verbose logging by modifying the watcher script:
- Change `CheckIntervalSeconds` to 2 for faster monitoring
- Add additional logging calls for specific events
- Review copilot-instructions.md for model/agent policies
