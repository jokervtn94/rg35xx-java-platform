@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0COLLECT-RG35XX-CLEAN-R2A.ps1" %*
if errorlevel 1 (
 echo COLLECT FAILED
 pause
 exit /b 1
)
pause
