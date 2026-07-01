@echo off
REM Immediately kills all running llama-server.exe processes and the
REM background auto-watcher. Use this to stop CPU/fan load right now.
REM
REM This does NOT remove the auto-start scheduled task. To permanently
REM disable auto-start (so it doesn't relaunch at your next login), run:
REM   scripts\Register-LlamaServerTask.ps1 -Uninstall
REM
REM To turn it back on later:
REM   scripts\Register-LlamaServerTask.ps1 -Profile qwen2.5-3b

set "ROOT=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%scripts\Stop-LlamaServers.ps1"
pause
