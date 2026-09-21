@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0RESTORE-B4-DRAGON-DISPLAY-TRACE-R1.ps1" %*
if errorlevel 1 (
 echo RESTORE FAILED
 pause
 exit /b 1
)
echo RESTORE COMPLETE
pause
