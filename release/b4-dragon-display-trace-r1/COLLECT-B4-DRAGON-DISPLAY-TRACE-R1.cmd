@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0COLLECT-B4-DRAGON-DISPLAY-TRACE-R1.ps1" %*
if errorlevel 1 (
 echo COLLECT FAILED
 pause
 exit /b 1
)
pause
