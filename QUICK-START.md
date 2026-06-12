# Quick Start: Auto-Start Llama Servers

## What's New?

✅ **No more manual server startup!**

- Servers auto-start when VS Code opens
- Servers auto-stop logic available (currently keeps running for background tasks)
- Health monitoring every 5 seconds
- Settings auto-bootstrap every 5 minutes

## How to Use

### Option 1: Immediate Testing (Manual)

```batch
cd c:\Users\lordx\Desktop\LLAMA-VSCODE
Start-AI-Server-AutoWatcher.bat
```

Then open VS Code - servers will auto-start.

### Option 2: Auto-Start at Windows Login (Production)

Run as Administrator:

```powershell
cd c:\Users\lordx\Desktop\LLAMA-VSCODE\scripts
.\Register-LlamaServerTask.ps1
```

Restart Windows - watcher will auto-start and manage servers.

## Validate Everything Works

```powershell
cd c:\Users\lordx\Desktop\LLAMA-VSCODE\scripts
.\Validate-InlineChatFeatures.ps1
```

Expected output: **✅ All checks passed!**

## Using Inline Chat

### Model Selection
1. Open VS Code
2. Click model dropdown in chat input
3. Select "Local Qwen2.5-Coder X (llama-vscode)" or similar
4. Start coding!

### Agent Selection
1. Type `@` in chat
2. Select `@llama-local` or `@llama-vscode`
3. Ask your question

## Monitor Status

View live watcher logs:

```powershell
Get-Content $env:TEMP\llama-server-watcher.log -Wait
```

## Troubleshooting

**Servers not starting?**
- Check: `Get-Process -Name "Code"` (should see VS Code instances)
- Check: `Invoke-RestMethod http://localhost:8009/health` (should return 200)
- Check: `$env:TEMP\llama-server-watcher.log` for errors

**Models/agents not showing in picker?**
- Run validation: `.\Validate-InlineChatFeatures.ps1 -Verbose`
- Check: `Test-Path "$env:APPDATA\Code\User\chatLanguageModels.json"`
- Check: `Test-Path "$env:USERPROFILE\.copilot\agents\llama-local.agent.md"`

## Documentation

- **Full Setup Guide:** AUTO-START-SETUP.md
- **Test Results:** IMPLEMENTATION_REPORT.md
- **This Quick Start:** QUICK-START.md

## System Status

All components validated and working:
- ✅ 3 endpoints (tools, chat, completion)
- ✅ 4 models registered (llama-vscode + llama-local)
- ✅ 2 agents discoverable (@llama-local, @llama-vscode)
- ✅ Auto-start infrastructure ready
- ✅ Health monitoring active
- ✅ Settings bootstrap enabled

**Status: 🟢 Production Ready**
