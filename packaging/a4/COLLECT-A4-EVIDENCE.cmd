@echo off
setlocal EnableExtensions
title RG35XX AWEIGIT R1 - A4 EVIDENCE COLLECTOR

echo ===============================================
echo  RG35XX-AWEIGIT-R1 - A4 EVIDENCE COLLECTOR
echo ===============================================
echo.
set /p DRIVE=Nhap ky tu o SD RG35XX (vi du H): 
if "%DRIVE%"=="" goto :badinput
set "DRIVE=%DRIVE: =%"
set "DRIVE=%DRIVE::=%"
set "DRIVE=%DRIVE:\=%"
if not "%DRIVE:~1,1%"=="" goto :badinput
echo(%DRIVE%| findstr /R /I "^[A-Z]$" >nul || goto :badinput

if not exist "%DRIVE%:\" (
  echo.
  echo [FAIL] Khong tim thay o dia: %DRIVE%:\
  goto :fail
)
if not exist "%~dp0COLLECT-RG35XX-AWEIGIT-R1-A4.ps1" (
  echo.
  echo [FAIL] Khong tim thay COLLECT-RG35XX-AWEIGIT-R1-A4.ps1
  echo Ban phai giai nen TOAN BO file ZIP vao mot thu muc.
  goto :fail
)

echo.
echo Dang thu evidence tu %DRIVE%:\ ...
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0COLLECT-RG35XX-AWEIGIT-R1-A4.ps1" -SdRoot "%DRIVE%"
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" (
  echo [FAIL] Collector tra ve ma loi %RC%.
  goto :fail
)

echo [PASS] Da tao file evidence ZIP trong cung thu muc nay.
echo Hay upload file RG35XX-AWEIGIT-R1-A4-EVIDENCE-*.zip vao ChatGPT.
echo.
pause
exit /b 0

:badinput
echo.
echo [FAIL] Ky tu o dia khong hop le.
echo Chi nhap MOT chu cai, vi du: H
:fail
echo.
pause
exit /b 1
