@echo off
setlocal EnableExtensions
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0RESTORE-RG35XX-SD-PRECLEAN-R1.ps1" %*
if errorlevel 1 (
 echo RESTORE FAILED
 pause
 exit /b 1
)
echo RESTORE COMPLETE
pause
