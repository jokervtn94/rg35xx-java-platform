@echo off
setlocal
set "SCRIPT=%~dp0INSTALL-FROM-ZERO-NOMASK-GOLDENFONT-AB.ps1"
if not exist "%SCRIPT%" (
  echo ERROR: Missing %SCRIPT%
  exit /b 1
)
if "%~1"=="" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" "%~1"
)
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" echo INSTALL FAILED with exit code %RC%
exit /b %RC%
