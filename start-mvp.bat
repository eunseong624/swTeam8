@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve.ps1"
if errorlevel 1 (
  echo.
  echo Server could not start. Opening index.html directly. Camera will be off.
  start "" "%~dp0index.html"
)
pause
