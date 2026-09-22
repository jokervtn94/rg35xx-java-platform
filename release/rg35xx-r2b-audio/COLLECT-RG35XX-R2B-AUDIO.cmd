@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0COLLECT-RG35XX-R2B-AUDIO.ps1" %*
pause
