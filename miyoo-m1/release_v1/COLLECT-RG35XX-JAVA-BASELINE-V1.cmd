@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0COLLECT-RG35XX-JAVA-BASELINE-V1.ps1" %*
if errorlevel 1 (
  echo.
  echo COLLECT FAILED.
  pause
  exit /b 1
)
echo.
echo EVIDENCE COLLECTION COMPLETE.
pause
