@echo off
setlocal EnableExtensions
title RG35XX AWEIGIT R1 - A4 INSTALLER

echo ===============================================
echo  RG35XX-AWEIGIT-R1 - A4 SMOKE INSTALLER
echo ===============================================
echo.
echo Hay giai nen ZIP hoan toan truoc khi chay file nay.
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
if not exist "%~dp0INSTALL-RG35XX-AWEIGIT-R1-A4.ps1" (
  echo.
  echo [FAIL] Khong tim thay INSTALL-RG35XX-AWEIGIT-R1-A4.ps1
  echo Ban phai giai nen TOAN BO file ZIP vao mot thu muc.
  goto :fail
)

echo.
echo Dang kiem tra JamVM/glibj va cai A4 vao %DRIVE%:\ ...
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALL-RG35XX-AWEIGIT-R1-A4.ps1" -SdRoot "%DRIVE%"
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" (
  echo [FAIL] Installer tra ve ma loi %RC%.
  echo Hay chup NGUYEN cua so nay gui ChatGPT.
  goto :fail
)

echo [PASS] Cai dat A4 hoan tat.
echo Thao SD an toan, gan vao RG35XX va chay:
echo RG35XX-AWEIGIT-R1-A4-SMOKE
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
