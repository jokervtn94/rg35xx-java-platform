@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0COLLECT-RG35XX-CLEAN-R1.ps1" %*
if errorlevel 1 (
 echo COLLECT FAILED
 pause
 exit /b 1
)
pause
