@echo off
setlocal
title Local AI Server Stack

set "ROOT=%~dp0"
set "PROFILE_NAME="
set "PROFILE_PATH="
if /I "%~1"=="-Profile" (
	set "PROFILE_NAME=%~2"
	set "PROFILE_PATH=%ROOT%models\%~2.json"
)
set "LLAMA_DIR=C:\llama_cpp"
set "LLAMA_EXE=%LLAMA_DIR%\llama-server.exe"
if not defined LLAMA_MODEL set "LLAMA_MODEL=C:\AI_Models\qwen2.5-coder-3b-instruct-q4_k_m.gguf"
if not defined LLAMA_CTX_SIZE set "LLAMA_CTX_SIZE=3072"
if not defined LLAMA_GPU_LAYERS set "LLAMA_GPU_LAYERS=16"
if not defined LLAMA_THREADS set "LLAMA_THREADS=6"
if not defined LLAMA_PORT_TOOLS set "LLAMA_PORT_TOOLS=8009"
if not defined LLAMA_PORT_CHAT set "LLAMA_PORT_CHAT=8011"
if not defined LLAMA_PORT_COMPLETION set "LLAMA_PORT_COMPLETION=8012"

if defined PROFILE_NAME (
	if not exist "%PROFILE_PATH%" (
		echo Profile file was not found: "%PROFILE_PATH%"
		pause
		exit /b 1
	)
	echo Loading profile "%PROFILE_NAME%"...
	powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Get-Content -Path '%PROFILE_PATH%' -Raw | ConvertFrom-Json; @('set ""LLAMA_MODEL='+$p.model_path+'""','set ""LLAMA_CTX_SIZE='+$p.ctx_size+'""','set ""LLAMA_GPU_LAYERS='+$p.gpu_layers+'""','set ""LLAMA_THREADS='+$p.threads+'""') | Set-Content -Path '%TEMP%\llama_profile_env.cmd' -Encoding ASCII"
	call "%TEMP%\llama_profile_env.cmd"
	del "%TEMP%\llama_profile_env.cmd" >nul 2>&1
)

if not exist "%LLAMA_EXE%" (
	echo llama-server.exe was not found in "%LLAMA_DIR%".
	pause
	exit /b 1
)
if not exist "%LLAMA_MODEL%" (
	echo Model file was not found: "%LLAMA_MODEL%"
	echo Available stable launchers in this folder:
	echo   - Start-AI-Server.bat ^(3B default stack^)
	echo   - Start-AI-Server-0.5B.bat ^(0.5B fallback stack^)
	pause
	exit /b 1
)

echo Applying llama-vscode user settings bootstrap...
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%scripts\Configure-LlamaVscode.ps1" -ModelPath "%LLAMA_MODEL%" -ContextSize %LLAMA_CTX_SIZE% -GpuLayers %LLAMA_GPU_LAYERS% -Threads %LLAMA_THREADS% -ToolsPort %LLAMA_PORT_TOOLS% -ChatPort %LLAMA_PORT_CHAT% -CompletionPort %LLAMA_PORT_COMPLETION%
if errorlevel 1 (
	echo Warning: settings bootstrap failed. Continuing with server startup.
)

echo Starting llama.cpp endpoint stack with model "%LLAMA_MODEL%"
echo   tools:      http://localhost:%LLAMA_PORT_TOOLS%
echo   chat:       http://localhost:%LLAMA_PORT_CHAT%
echo   completion: http://localhost:%LLAMA_PORT_COMPLETION%

start "llama-tools" /min "%LLAMA_EXE%" --model "%LLAMA_MODEL%" --port %LLAMA_PORT_TOOLS% --ctx-size %LLAMA_CTX_SIZE% -ngl %LLAMA_GPU_LAYERS% --threads %LLAMA_THREADS%
start "llama-chat" /min "%LLAMA_EXE%" --model "%LLAMA_MODEL%" --port %LLAMA_PORT_CHAT% --ctx-size %LLAMA_CTX_SIZE% -ngl %LLAMA_GPU_LAYERS% --threads %LLAMA_THREADS%
start "llama-completion" /min "%LLAMA_EXE%" --model "%LLAMA_MODEL%" --port %LLAMA_PORT_COMPLETION% --ctx-size %LLAMA_CTX_SIZE% -ngl %LLAMA_GPU_LAYERS% --threads %LLAMA_THREADS%

echo Verifying endpoint health...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ports=@(%LLAMA_PORT_TOOLS%,%LLAMA_PORT_CHAT%,%LLAMA_PORT_COMPLETION%); $ok=$true; foreach($p in $ports){ $healthy=$false; foreach($i in 1..60){ try { Invoke-RestMethod -Uri ('http://127.0.0.1:' + $p + '/health') -TimeoutSec 2 | Out-Null; $healthy=$true; break } catch { try { Invoke-RestMethod -Uri ('http://127.0.0.1:' + $p + '/v1/models') -TimeoutSec 2 | Out-Null; $healthy=$true; break } catch {} }; Start-Sleep -Milliseconds 500 }; if($healthy){ Write-Host ('  OK  : ' + $p) } else { Write-Host ('  FAIL: ' + $p); $ok=$false } }; if(-not $ok){ exit 1 }"
if errorlevel 1 (
	echo One or more endpoints failed health checks. Review the opened llama-server terminals.
	pause
	exit /b 1
)

echo All local endpoints are healthy. You can now select agent+model without manual setup.
pause
