@echo off
setlocal
set "SD=%~1"
if "%SD%"=="" set /p "SD=Nhap ky tu o SD (vi du H): "
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALL-AUDIO-R2.3-HANG-LOCALIZATION-AB.ps1" "%SD%"
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" echo INSTALL FAILED - exit code %RC%
if "%RC%"=="0" echo INSTALL PASSED - DEVICE TEST REQUIRED
pause
exit /b %RC%
