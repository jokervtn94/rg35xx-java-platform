@echo off
setlocal EnableExtensions
title RG35XX AWEIGIT R1 - A5 EVIDENCE
echo ===============================================
echo  RG35XX-AWEIGIT-R1 - A5 EVIDENCE COLLECTOR
echo ===============================================
echo.
set /p DRIVE=Nhap ky tu o SD RG35XX (vi du H): 
if "%DRIVE%"=="" goto :bad
set "DRIVE=%DRIVE: =%"
set "DRIVE=%DRIVE::=%"
set "DRIVE=%DRIVE:\=%"
if not "%DRIVE:~1,1%"=="" goto :bad
echo(%DRIVE%| findstr /R /I "^[A-Z]$" >nul || goto :bad
if not exist "%DRIVE%:\" (echo [FAIL] Khong tim thay %DRIVE%:\&goto :fail)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0COLLECT-RG35XX-AWEIGIT-R1-A5.ps1" -SdRoot "%DRIVE%"
if errorlevel 1 goto :fail
echo.
echo [PASS] Da tao A5 evidence ZIP trong thu muc nay.
echo Upload RG35XX-AWEIGIT-R1-A5-EVIDENCE-*.zip vao ChatGPT.
pause
exit /b 0
:bad
echo [FAIL] Chi nhap MOT ky tu o dia, vi du H.
:fail
pause
exit /b 1
