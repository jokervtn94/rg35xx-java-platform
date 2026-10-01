@echo off
setlocal
cd /d "%~dp0"

set "SDROOT=%~1"
if not defined SDROOT (
  set /p "SDROOT=Nhap ky tu o SD RG35XX (vi du H): "
)

if not defined SDROOT (
  echo ERROR: Chua nhap o SD.
  pause
  exit /b 2
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0COLLECT-A8-COMPAT-EVIDENCE.ps1" -SdRoot "%SDROOT%" -OutputDir "%~dp0"
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
  echo.
  echo COLLECT FAIL - exit code %RC%
) else (
  echo.
  echo COLLECT PASS - ZIP duoc tao trong thu muc nay.
)
pause
exit /b %RC%
