@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALL-RG35XX-GARLICOS-JAVA-BASELINE-V1.ps1" %*
if errorlevel 1 exit /b 1
echo INSTALL COMPLETE
pause
