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

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALL-A8-COMPAT-HARNESS.ps1" -SdRoot "%SDROOT%"
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
  echo.
  echo INSTALL FAIL - exit code %RC%
  echo Neu R3 tao A8-COMPAT-SD-DIAGNOSTIC.txt o goc SD, gui file do de phan tich.
) else (
  echo.
  echo INSTALL PASS
)
pause
exit /b %RC%
