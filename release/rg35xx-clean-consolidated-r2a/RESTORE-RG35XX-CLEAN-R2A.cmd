@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0RESTORE-RG35XX-CLEAN-R2A.ps1" %*
if errorlevel 1 (
 echo RESTORE FAILED
 pause
 exit /b 1
)
echo RESTORE COMPLETE
pause
