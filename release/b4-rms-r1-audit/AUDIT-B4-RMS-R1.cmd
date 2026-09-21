@echo off
setlocal EnableExtensions
set "LOG=%~dp0AUDIT-B4-RMS-R1.log"
if "%~1"=="" (
  set /p "SD=Nhap ky tu o SD RG35XX ^(vi du H^): "
) else (
  set "SD=%~1"
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0AUDIT-B4-RMS-R1.ps1" "%SD%" > "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"
type "%LOG%"
echo.
if not "%RC%"=="0" (
 echo RMS AUDIT FAILED
 echo Gui file: %LOG%
 pause
 exit /b %RC%
)
echo RMS AUDIT COMPLETE
pause
