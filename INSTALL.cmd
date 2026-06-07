@echo off
REM Double-click this to set up the bar display on a new PC.
echo Running bar-display installer...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALL.ps1"
echo.
pause
