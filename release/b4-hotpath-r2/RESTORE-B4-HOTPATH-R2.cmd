@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0RESTORE-B4-HOTPATH-R2.ps1" %*
if errorlevel 1 (
 echo RESTORE FAILED
 pause
 exit /b 1
)
echo RESTORE COMPLETE
pause
