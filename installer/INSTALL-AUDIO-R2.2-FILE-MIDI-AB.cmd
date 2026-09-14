@echo off
setlocal
set SD=%~1
if "%SD%"=="" set /p SD=Nhap ky tu o SD (vi du H): 
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALL-AUDIO-R2.2-FILE-MIDI-AB.ps1" "%SD%"
pause
