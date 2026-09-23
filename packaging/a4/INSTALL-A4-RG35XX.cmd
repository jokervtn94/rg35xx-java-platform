@echo off
setlocal EnableExtensions
title RG35XX AWEIGIT R1 - A4 INSTALLER

echo ===============================================
echo  RG35XX-AWEIGIT-R1 - A4 SMOKE INSTALLER
echo ===============================================
echo.
echo Hay giai nen ZIP hoan toan truoc khi chay file nay.
echo.
set /p DRIVE=Nhap ky tu o SD RG35XX (vi du G): 
if "%DRIVE%"=="" goto :badinput
set "DRIVE=%DRIVE::=%"
set "DRIVE=%DRIVE:\=%"
set "SDROOT=%DRIVE%:\"

if not exist "%SDROOT%" (
  echo.
  echo [FAIL] Khong tim thay o dia: %SDROOT%
  goto :fail
)
if not exist "%~dp0INSTALL-RG35XX-AWEIGIT-R1-A4.ps1" (
  echo.
  echo [FAIL] Khong tim thay INSTALL-RG35XX-AWEIGIT-R1-A4.ps1
  echo Ban phai giai nen TOAN BO file ZIP vao mot thu muc.
  goto :fail
)

echo.
echo Dang kiem tra JamVM/glibj va cai A4 vao %SDROOT% ...
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALL-RG35XX-AWEIGIT-R1-A4.ps1" -SdRoot "%SDROOT%"
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" (
  echo [FAIL] Installer tra ve ma loi %RC%.
  echo Hay chup man hinh nay hoac gui file RG35XX-AWEIGIT-R1-A4-INSTALL-RESULT.txt neu co.
  goto :fail
)

echo [PASS] Cai dat A4 hoan tat.
echo Thao SD an toan, gan vao RG35XX va chay:
echo RG35XX-AWEIGIT-R1-A4-SMOKE
echo.
pause
exit /b 0

:badinput
echo [FAIL] Chua nhap ky tu o dia SD.
:fail
echo.
pause
exit /b 1
