@echo off
setlocal
cd /d "C:\llama_cpp"
title Local AI Server
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
llama-server.exe --model "C:\AI_Models\Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf" --port 8009 --ctx-size 8192 -ngl 99
pause
