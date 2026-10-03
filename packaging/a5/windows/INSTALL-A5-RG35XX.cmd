@echo off
setlocal EnableExtensions
title RG35XX AWEIGIT R1 - A5 CORE INSTALLER
echo ===============================================
echo  RG35XX-AWEIGIT-R1 - A5 CORE INTEGRATION
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
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALL-RG35XX-AWEIGIT-R1-A5.ps1" -SdRoot "%DRIVE%"
if errorlevel 1 goto :fail
echo.
echo [PASS] Cai dat A5 hoan tat.
echo Gan SD vao RG35XX va chay RG35XX-AWEIGIT-R1-A5-CORE
pause
exit /b 0
:bad
echo [FAIL] Chi nhap MOT ky tu o dia, vi du H.
:fail
pause
exit /b 1
