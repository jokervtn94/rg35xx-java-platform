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

rem R4: do not pass %%~dp0 as -OutputDir. Its trailing backslash can produce
rem an illegal quoted Windows path. PowerShell resolves output to $PSScriptRoot.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0COLLECT-A8-COMPAT-EVIDENCE.ps1" -SdRoot "%SDROOT%"
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
