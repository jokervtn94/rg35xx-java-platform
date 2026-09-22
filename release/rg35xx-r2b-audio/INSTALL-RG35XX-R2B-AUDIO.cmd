@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALL-RG35XX-R2B-AUDIO.ps1" %*
if errorlevel 1 pause
