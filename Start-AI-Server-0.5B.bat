@echo off
setlocal
title Local AI Server - 0.5B Fallback Model
if not defined LLAMA_CTX_SIZE set "LLAMA_CTX_SIZE=2048"
if not defined LLAMA_GPU_LAYERS set "LLAMA_GPU_LAYERS=8"
if not defined LLAMA_THREADS set "LLAMA_THREADS=4"
if not defined LLAMA_MODEL set "LLAMA_MODEL=C:\AI_Models\qwen2.5-coder-0.5b-instruct-q2_k.gguf"
if not exist "%LLAMA_MODEL%" (
	echo Model file was not found: "%LLAMA_MODEL%"
	echo Run: .\installing_ggufs_hf.ps1 -Tiny -ModelOnly
	pause
	exit /b 1
)
call "%~dp0Start-AI-Server.bat"
