@echo off
setlocal
cd /d "C:\llama_cpp"
title Local AI Server
if not defined LLAMA_PORT set "LLAMA_PORT=8009"
if not defined LLAMA_CTX_SIZE set "LLAMA_CTX_SIZE=4096"
if not defined LLAMA_GPU_LAYERS set "LLAMA_GPU_LAYERS=35"
if not defined LLAMA_THREADS set "LLAMA_THREADS=8"
if not exist "llama-server.exe" (
	echo llama-server.exe was not found in "C:\llama_cpp".
	pause
	exit /b 1
)
if not exist "C:\AI_Models\Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf" (
	echo Model file was not found: "C:\AI_Models\Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf"
	pause
	exit /b 1
)
echo Starting llama.cpp with port %LLAMA_PORT%, context %LLAMA_CTX_SIZE%, GPU layers %LLAMA_GPU_LAYERS%, threads %LLAMA_THREADS%.
llama-server.exe --model "C:\AI_Models\Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf" --port %LLAMA_PORT% --ctx-size %LLAMA_CTX_SIZE% -ngl %LLAMA_GPU_LAYERS% --threads %LLAMA_THREADS%
pause
