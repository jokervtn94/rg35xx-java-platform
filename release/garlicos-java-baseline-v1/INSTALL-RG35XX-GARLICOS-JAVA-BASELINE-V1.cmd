@echo off
setlocal EnableExtensions

set "LOG=%~dp0INSTALL-RG35XX-GARLICOS-JAVA-BASELINE-V1.log"

if "%~1"=="" (
  echo.
  echo RG35XX GarlicOS Java Baseline v1.1
  echo.
  set /p "SD=Nhap ky tu o SD RG35XX ^(vi du G^): "
) else (
  set "SD=%~1"
)

echo.
echo Dang cai vao SD: %SD%
echo Log: %LOG%
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALL-RG35XX-GARLICOS-JAVA-BASELINE-V1.ps1" "%SD%" > "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"

type "%LOG%"
echo.

if not "%RC%"=="0" (
  echo INSTALL FAILED - exit code %RC%
  echo Gui file log nay cho ChatGPT:
  echo %LOG%
  echo.
  pause
  exit /b %RC%
)

echo INSTALL COMPLETE
echo.
pause
exit /b 0
