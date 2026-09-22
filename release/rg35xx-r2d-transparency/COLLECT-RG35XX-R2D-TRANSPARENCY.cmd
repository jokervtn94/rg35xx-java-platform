@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0COLLECT-RG35XX-R2D-TRANSPARENCY.ps1" %*
if errorlevel 1 (echo FAILED&pause&exit /b 1)
pause
