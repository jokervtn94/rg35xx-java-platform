@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0RESTORE-R2C-AUDIO-R1-AB.ps1" %*
if errorlevel 1 pause
