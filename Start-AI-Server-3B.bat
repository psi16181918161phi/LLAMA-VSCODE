@echo off
setlocal
title Local AI Server - 3B Small Model
if not defined LLAMA_CTX_SIZE set "LLAMA_CTX_SIZE=3072"
if not defined LLAMA_GPU_LAYERS set "LLAMA_GPU_LAYERS=16"
if not defined LLAMA_THREADS set "LLAMA_THREADS=6"
if not defined LLAMA_MODEL set "LLAMA_MODEL=C:\AI_Models\qwen2.5-coder-3b-instruct-q4_k_m.gguf"
if not exist "%LLAMA_MODEL%" (
	echo Model file was not found: "%LLAMA_MODEL%"
	pause
	exit /b 1
)
call "%~dp0Start-AI-Server.bat" -Profile qwen2.5-3b
