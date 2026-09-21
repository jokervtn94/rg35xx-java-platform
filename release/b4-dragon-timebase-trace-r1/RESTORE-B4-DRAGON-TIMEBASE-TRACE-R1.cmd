@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0RESTORE-B4-DRAGON-TIMEBASE-TRACE-R1.ps1" %*
if errorlevel 1 pause
