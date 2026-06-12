@echo off
setlocal
cd /d "C:\llama_cpp"
title Local AI Server
if not defined LLAMA_PORT set "LLAMA_PORT=8009"
if not defined LLAMA_CTX_SIZE set "LLAMA_CTX_SIZE=3072"
if not defined LLAMA_GPU_LAYERS set "LLAMA_GPU_LAYERS=16"
if not defined LLAMA_THREADS set "LLAMA_THREADS=6"
if not defined LLAMA_MODEL set "LLAMA_MODEL=C:\AI_Models\qwen2.5-coder-3b-instruct-q4_k_m.gguf"
if not exist "llama-server.exe" (
	echo llama-server.exe was not found in "C:\llama_cpp".
	pause
	exit /b 1
)
if not exist "%LLAMA_MODEL%" (
	echo Model file was not found: "%LLAMA_MODEL%"
	echo Available stable launchers in this folder:
	echo   - Start-AI-Server.bat ^(3B default^)
	echo   - Start-AI-Server-0.5B.bat ^(0.5B fallback^)
	pause
	exit /b 1
)
echo Starting llama.cpp with port %LLAMA_PORT%, context %LLAMA_CTX_SIZE%, GPU layers %LLAMA_GPU_LAYERS%, threads %LLAMA_THREADS%.
llama-server.exe --model "%LLAMA_MODEL%" --port %LLAMA_PORT% --ctx-size %LLAMA_CTX_SIZE% -ngl %LLAMA_GPU_LAYERS% --threads %LLAMA_THREADS%
pause
