@echo off
set "SCRIPT_DIR=%~dp0"
set "VBS_PATH=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\ADBridgeWatcher.vbs"

echo Set WshShell = CreateObject("WScript.Shell") > "%VBS_PATH%"
echo WshShell.Run "cmd /c """%SCRIPT_DIR%ADBridge_V2.bat""" --watcher", 0, False >> "%VBS_PATH%"

echo [+] Auto-start watcher installed.

:: Stop existing watcher processes (optional, requires checking for wscript.exe running the specific script or just killing cmd instances running ADBridge_V2.bat --watcher but that's complex, so we'll just start it)
:: Let's start the script right now instead of waiting for a restart
echo [*] Starting watcher now...
cscript //nologo "%VBS_PATH%"

echo [+] Done! You can now plug in a device.
pause
