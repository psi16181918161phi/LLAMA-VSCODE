@echo off
setlocal enabledelayedexpansion

REM Start Llama Server Auto-Watcher
REM This script launches the background watcher that automatically starts/stops
REM llama-cpp servers based on VS Code instances running

set "ROOT=%~dp0"
set "WATCHER_SCRIPT=%ROOT%scripts\Start-LlamaServerWatcher.ps1"

if not exist "%WATCHER_SCRIPT%" (
	echo Error: Watcher script not found at %WATCHER_SCRIPT%
	pause
	exit /b 1
)

echo Starting Llama Server Auto-Watcher...
echo.
echo This watcher will:
echo   - Monitor VS Code running instances
echo   - Auto-start llama-server stack when VS Code launches
echo   - Auto-bootstrap settings for proper agent/model discovery
echo   - Check endpoint health every 5 seconds
echo.
echo Watcher log: %TEMP%\llama-server-watcher.log
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%WATCHER_SCRIPT%"

if errorlevel 1 (
	echo Watcher exited with error. Check logs for details.
	pause
	exit /b 1
)
