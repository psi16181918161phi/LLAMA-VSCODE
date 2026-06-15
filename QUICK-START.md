# Quick Start: Profile-Based Local Llama Servers

## What You Can Do

- Install built-in profiles or any GGUF from Hugging Face
- Start server stack manually or with auto-watcher
- Validate profile schema and runtime integration
- Run local tests before opening pull requests

- Servers auto-start when VS Code opens
- Health monitoring every 5 seconds
- Settings auto-bootstrap every 5 minutes
- Profile-driven model/runtime configuration

## Install Models

### Built-in profile

```powershell
cd c:\Users\lordx\Desktop\LLAMA-VSCODE
.\installing_ggufs_hf.ps1 -Profile qwen2.5-3b
```

### Any Hugging Face GGUF

```powershell
cd c:\Users\lordx\Desktop\LLAMA-VSCODE
.\installing_ggufs_hf.ps1 -HfRepo "TheBloke/Mistral-7B-Instruct-v0.2-GGUF" -HfFile "mistral-7b-instruct-v0.2.Q4_K_M.gguf" -ProfileName "mistral-7b"
```

### Discover GGUF repos/files

```powershell
cd c:\Users\lordx\Desktop\LLAMA-VSCODE\scripts
.\Find-HuggingFaceGGUF.ps1 -Query "mistral instruct gguf" -Author "TheBloke"
.\Find-HuggingFaceGGUF.ps1 -Query "mistral" -Repository "TheBloke/Mistral-7B-Instruct-v0.2-GGUF"
```

## Start Servers

### Option 1: Manual Start

```batch
cd c:\Users\lordx\Desktop\LLAMA-VSCODE
Start-AI-Server.bat -Profile qwen2.5-3b
```

### Option 2: Auto-Watcher

```batch
cd c:\Users\lordx\Desktop\LLAMA-VSCODE
Start-AI-Server-AutoWatcher.bat -Profile qwen2.5-3b
```

Then open VS Code. The watcher keeps endpoints healthy and settings bootstrapped.

### Option 3: Auto-Start at Windows Login (Production)

Run as Administrator:

```powershell
cd c:\Users\lordx\Desktop\LLAMA-VSCODE\scripts
.\Register-LlamaServerTask.ps1
```

or with profile:

```powershell
.\Register-LlamaServerTask.ps1 -Profile qwen2.5-3b
```

Restart Windows - watcher will auto-start and manage servers.

## Validate Everything Works

```powershell
cd c:\Users\lordx\Desktop\LLAMA-VSCODE\scripts
.\Validate-InlineChatFeatures.ps1
```

Validate profile schema:

```powershell
. .\Validate-ModelProfile.ps1
Test-ModelProfileFile -ProfilePath ..\models\qwen2.5-3b.json -SchemaPath ..\models\model-profile.schema.json
```

Run tests:

```powershell
Invoke-Pester -Path ..\tests
```

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
- **Profile Schema:** models/model-profile.schema.json
- **Validation Script:** scripts/Validate-ModelProfile.ps1
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
