@echo off
setlocal EnableExtensions
set "LOG=%~dp0QUARANTINE-B4-RMS-R2.log"
if "%~1"=="" (
  set /p "SD=Nhap ky tu o SD RG35XX ^(vi du H^): "
) else (
  set "SD=%~1"
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0QUARANTINE-B4-RMS-R2.ps1" "%SD%" > "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"
type "%LOG%"
if not "%RC%"=="0" (
 echo QUARANTINE FAILED
 pause
 exit /b %RC%
)
echo QUARANTINE COMPLETE
pause
