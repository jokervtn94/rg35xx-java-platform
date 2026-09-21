@echo off
setlocal EnableExtensions
set "LOG=%~dp0VERIFY-B4-SCREENSHOT-R1-ROLLBACK.log"
if "%~1"=="" (
  set /p "SD=Nhap ky tu o SD RG35XX ^(vi du G^): "
) else (
  set "SD=%~1"
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0VERIFY-B4-SCREENSHOT-R1-ROLLBACK.ps1" "%SD%" > "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"
type "%LOG%"
if not "%RC%"=="0" (
 echo VERIFY FAILED
 pause
 exit /b %RC%
)
echo VERIFY PASS
pause
