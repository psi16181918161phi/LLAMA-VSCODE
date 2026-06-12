@echo off
setlocal
cd /d "C:\llama_cpp"
title Local AI Server - 0.5B Fallback Model
if not defined LLAMA_PORT set "LLAMA_PORT=8009"
if not defined LLAMA_CTX_SIZE set "LLAMA_CTX_SIZE=2048"
if not defined LLAMA_GPU_LAYERS set "LLAMA_GPU_LAYERS=8"
if not defined LLAMA_THREADS set "LLAMA_THREADS=4"
if not exist "llama-server.exe" (
	echo llama-server.exe was not found in "C:\llama_cpp".
	pause
	exit /b 1
)
if not exist "C:\AI_Models\qwen2.5-coder-0.5b-instruct-q2_k.gguf" (
	echo Model file was not found: "C:\AI_Models\qwen2.5-coder-0.5b-instruct-q2_k.gguf"
	echo Run: .\installing_ggufs_hf.ps1 -Tiny -ModelOnly
	pause
	exit /b 1
)
echo Starting llama.cpp (0.5B fallback model) with port %LLAMA_PORT%, context %LLAMA_CTX_SIZE%, GPU layers %LLAMA_GPU_LAYERS%, threads %LLAMA_THREADS%.
llama-server.exe --model "C:\AI_Models\qwen2.5-coder-0.5b-instruct-q2_k.gguf" --port %LLAMA_PORT% --ctx-size %LLAMA_CTX_SIZE% -ngl %LLAMA_GPU_LAYERS% --threads %LLAMA_THREADS%
pause
