@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0VERIFY-RG35XX-GARLICOS-JAVA-BASELINE-V1.3.ps1" %*
if errorlevel 1 (
  echo.
  echo VERIFY FAILED
  pause
  exit /b 1
)
echo.
pause
