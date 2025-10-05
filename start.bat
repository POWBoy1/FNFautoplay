@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

set "arch=%PROCESSOR_ARCHITECTURE%"
set "ahkExe="

if /i "%arch%"=="AMD64" (
    if exist "scripts\AutoHotkey64.exe" set "ahkExe=scripts\AutoHotkey64.exe"
    if not defined ahkExe if exist "scripts\AutoHotkey32.exe" set "ahkExe=scripts\AutoHotkey32.exe"
) else (
    if exist "scripts\AutoHotkey32.exe" set "ahkExe=scripts\AutoHotkey32.exe"
)

if defined ahkExe (
    start "" "%ahkExe%" "scripts\GUI_Launcher.ahk"
) else (
    echo No compatible AutoHotkey executable found in scripts folder.
    pause
)
