@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0COLLECT-B4-DRAGON-SERVICE-REPAINT-SERIALIZE-R1.ps1" %*
if errorlevel 1 pause
