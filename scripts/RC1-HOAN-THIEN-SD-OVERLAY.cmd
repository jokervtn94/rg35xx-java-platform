@echo off
setlocal
cd /d "%~dp0.."
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0rc1_complete_sd_overlay.ps1" "%CD%\RG35XX_Java_RC1_SD_Overlay"
set RC=%ERRORLEVEL%
echo.
if not "%RC%"=="0" (
  echo RC1 COMPLETE: FAILED with exit code %RC%
) else (
  echo RC1 COMPLETE: DONE. Copy/merge the completed overlay into the root of the RG35XX SD card.
)
echo.
pause
exit /b %RC%
