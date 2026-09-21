@echo off
setlocal EnableExtensions
set "LOG=%~dp0ENSURE-B4-DRAGON-RMS-PRECONDITION.log"
if "%~1"=="" (
  set /p "SD=Nhap ky tu o SD RG35XX ^(vi du H^): "
) else (
  set "SD=%~1"
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ENSURE-B4-DRAGON-RMS-PRECONDITION.ps1" "%SD%" > "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"
type "%LOG%"
echo.
if not "%RC%"=="0" (
 echo ENSURE FAILED
 echo Gui file: %LOG%
 pause
 exit /b %RC%
)
echo ENSURE COMPLETE
pause
exit /b 0
