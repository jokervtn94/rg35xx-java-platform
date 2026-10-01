@echo off
setlocal
cd /d "%~dp0"

set "SDROOT=%~1"
if not defined SDROOT set /p "SDROOT=Nhap ky tu o SD RG35XX (vi du H): "
if not defined SDROOT (
  echo ERROR: Chua nhap o SD.
  pause
  exit /b 2
)

set "GAMEJAR=%~2"
if not defined GAMEJAR set /p "GAMEJAR=Nhap duong dan file JAR tren SD (vi du H:\Roms\JAVA\game.jar): "
if not defined GAMEJAR (
  echo ERROR: Chua nhap file JAR.
  pause
  exit /b 3
)

set "CID=%~3"
if not defined CID set /p "CID=Nhap Candidate ID (vi du A8-COMP-01): "
if not defined CID (
  echo ERROR: Chua nhap Candidate ID.
  pause
  exit /b 4
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0REGISTER-A8-COMPAT-GAME.ps1" -SdRoot "%SDROOT%" -GameJar "%GAMEJAR%" -CandidateId "%CID%"
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
  echo.
  echo REGISTER FAIL - exit code %RC%
) else (
  echo.
  echo REGISTER PASS - launcher da duoc tao trong Roms\APPS.
)
pause
exit /b %RC%
