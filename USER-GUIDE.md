# User Guide: Profile-Driven GGUF Setup

## 1. Install Requirements

- Windows + PowerShell 5.1 or newer
- NVIDIA GPU recommended
- Internet access for first install

## 2. Install a Model

### Option A: Use a built-in profile

```powershell
cd c:\Users\lordx\Desktop\LLAMA-VSCODE
.\installing_ggufs_hf.ps1 -Profile qwen2.5-3b
```

### Option B: Install any GGUF from Hugging Face

```powershell
cd c:\Users\lordx\Desktop\LLAMA-VSCODE
.\installing_ggufs_hf.ps1 -HfRepo "TheBloke/Mistral-7B-Instruct-v0.2-GGUF" -HfFile "mistral-7b-instruct-v0.2.Q4_K_M.gguf" -ProfileName "mistral-7b"
```

## 3. Start the Server Stack

```batch
Start-AI-Server.bat -Profile qwen2.5-3b
```

Expected endpoints:
- tools: http://localhost:8009
- chat: http://localhost:8011
- completion: http://localhost:8012

## 4. Use Auto-Watcher

```batch
Start-AI-Server-AutoWatcher.bat -Profile qwen2.5-3b
```

For startup at Windows login:

```powershell
cd .\scripts
.\Register-LlamaServerTask.ps1 -Profile qwen2.5-3b
```

## 5. Validate Profile Schema and Runtime

```powershell
cd .\scripts
. .\Validate-ModelProfile.ps1
Test-ModelProfileFile -ProfilePath ..\models\qwen2.5-3b.json -SchemaPath ..\models\model-profile.schema.json
.\Validate-InlineChatFeatures.ps1 -Verbose
```

## 6. Search Hugging Face GGUF Models

```powershell
cd .\scripts
.\Find-HuggingFaceGGUF.ps1 -Query "phi 3 mini instruct" -Author "microsoft"
.\Find-HuggingFaceGGUF.ps1 -Query "mistral" -Repository "TheBloke/Mistral-7B-Instruct-v0.2-GGUF"
```

## 7. Run Local Quality Checks

```powershell
Invoke-Pester -Path .\tests
```

## 8. Troubleshooting

- Profile validation fails:
  - Ensure required keys exist and follow `models/model-profile.schema.json`.
- Endpoints do not come up:
  - Check `C:\llama_cpp\llama-server.exe` exists.
  - Check model path exists in selected profile.
  - Check `%TEMP%\llama-server-watcher.log`.
- Model/agent missing in VS Code picker:
  - Run `scripts/Validate-InlineChatFeatures.ps1 -Verbose`.
