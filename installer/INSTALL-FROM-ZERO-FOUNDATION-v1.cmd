@echo off
setlocal
set "SCRIPT=%~dp0INSTALL-FROM-ZERO-FOUNDATION-v1.ps1"
if not exist "%SCRIPT%" (
  echo INSTALL FAIL: missing %SCRIPT%
  exit /b 1
)
if "%~1"=="" (
  powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
) else (
  powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" "%~1"
)
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" echo Installer failed with exit code %RC%.
pause
exit /b %RC%
