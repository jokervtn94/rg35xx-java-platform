@echo off
setlocal EnableExtensions
set "LOG=%~dp0INSTALL-RG35XX-CLEAN-R1.log"
if "%~1"=="" (
  echo.
  echo RG35XX Clean Consolidated R1
  set /p "SD=Nhap ky tu o SD RG35XX ^(vi du G^): "
) else (
  set "SD=%~1"
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALL-RG35XX-CLEAN-R1.ps1" "%SD%" > "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"
type "%LOG%"
echo.
if not "%RC%"=="0" (
  echo INSTALL FAILED - exit code %RC%
  echo Gui file: %LOG%
  pause
  exit /b %RC%
)
echo INSTALL COMPLETE
pause
exit /b 0
