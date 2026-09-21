@echo off
setlocal EnableExtensions
set "LOG=%~dp0INSTALL-B4-DRAGON-MEDIA-TRACE-R1.log"
if "%~1"=="" (
  set /p "SD=Nhap ky tu o SD RG35XX ^(vi du H^): "
) else (
  set "SD=%~1"
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALL-B4-DRAGON-MEDIA-TRACE-R1.ps1" "%SD%" > "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"
type "%LOG%"
if not "%RC%"=="0" (
 echo INSTALL FAILED
 pause
 exit /b %RC%
)
echo INSTALL COMPLETE
pause
