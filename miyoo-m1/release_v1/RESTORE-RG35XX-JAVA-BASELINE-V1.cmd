@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0RESTORE-RG35XX-JAVA-BASELINE-V1.ps1" %*
if errorlevel 1 (
  echo.
  echo RESTORE FAILED.
  pause
  exit /b 1
)
echo.
echo RESTORE COMPLETE.
pause
