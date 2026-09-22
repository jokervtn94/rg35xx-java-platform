@echo off
setlocal EnableExtensions
set "LOG=%~dp0SCAN-RG35XX-OLD-PLATFORM.log"
if "%~1"=="" (
  set /p "SD=Nhap ky tu o SD RG35XX ^(vi du G^): "
) else (
  set "SD=%~1"
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0RG35XX-SD-PRECLEAN-R1.ps1" "%SD%" -ScanOnly > "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"
type "%LOG%"
echo.
if not "%RC%"=="0" (
 echo SCAN FAILED - exit code %RC%
 pause
 exit /b %RC%
)
echo SCAN COMPLETE
pause
