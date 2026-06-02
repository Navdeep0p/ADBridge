@echo off
set "SCRIPT_DIR=%~dp0"
set "VBS_PATH=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\ADBridgeWatcher.vbs"

echo Set WshShell = CreateObject("WScript.Shell") > "%VBS_PATH%"
echo WshShell.Run "cmd /c """%SCRIPT_DIR%ADBridge.bat""" --watcher", 0, False >> "%VBS_PATH%"

echo [+] Auto-start watcher installed.
pause
