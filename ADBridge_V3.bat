@echo off
title Wireless ADB - Local Wi-Fi Controller  by Nani0p
color 0A
setlocal enabledelayedexpansion

:: =========================================================================
::
::   Wireless ADB Controller
::   Author  : Nani0p
::   GitHub  : https://github.com/Navdeep0p
::   License : MIT — free to use, modify, and distribute with attribution.
::
:: =========================================================================
::                        CONFIGURATION BLOCK
::   Edit here if auto-detection fails (rare — leave blank otherwise).
:: =========================================================================

:: Leave empty to auto-detect. Set only if auto-detect fails:
:: set "ADB_PATH=C:\Users\YourName\AppData\Local\Android\Sdk\platform-tools"
set "ADB_PATH="

:: Set DEBUG_MODE=1 to print diagnostic messages, 0 to hide them.
set "DEBUG_MODE=1"

:: =========================================================================
::   DO NOT EDIT BELOW THIS LINE
:: =========================================================================

:: ---- AUTO-DETECT ADB PATH ----
:: Priority: 1) manually set above  2) already on PATH  3) common locations  4) prompt
if not "!ADB_PATH!"=="" (
    if exist "!ADB_PATH!\adb.exe" goto ADB_FOUND
    echo  [!] Configured ADB_PATH not valid: !ADB_PATH!
    set "ADB_PATH="
)

where adb >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=*" %%a in ('where adb') do (
        if "!ADB_PATH!"=="" set "ADB_PATH=%%~dpa"
    )
    :: strip trailing backslash
    if "!ADB_PATH:~-1!"=="\" set "ADB_PATH=!ADB_PATH:~0,-1!"
    echo  [i] ADB found on PATH: !ADB_PATH!
    goto ADB_FOUND
)

:: Search common install locations
for %%D in (
    "%LOCALAPPDATA%\Android\Sdk\platform-tools"
    "%APPDATA%\..\Local\Android\Sdk\platform-tools"
    "C:\platform-tools"
    "C:\Android\platform-tools"
    "%ProgramFiles%\Android\platform-tools"
    "%ProgramFiles(x86)%\Android\platform-tools"
) do (
    if "!ADB_PATH!"=="" (
        if exist "%%~D\adb.exe" set "ADB_PATH=%%~D"
    )
)

if not "!ADB_PATH!"=="" (
    echo  [i] ADB auto-detected at: !ADB_PATH!
    goto ADB_FOUND
)

:: Not found anywhere — ask user
echo.
echo  [!] ADB not found automatically.
echo  [i] Enter the full path to your platform-tools folder.
echo  [i] Example: C:\Users\You\AppData\Local\Android\Sdk\platform-tools
echo.
set /p ADB_PATH="  platform-tools path: "
if not exist "!ADB_PATH!\adb.exe" (
    echo.
    echo  [!] adb.exe not found at that path. Exiting.
    pause
    exit /b 1
)

:ADB_FOUND
cd /d "!ADB_PATH!"

if "%~1"=="--watcher" goto WATCHER_MODE
if "%~1"=="--auto" (
    set "DEVICE_ID=%~2"
    echo !DEVICE_ID! ^| findstr ":" >nul
    if errorlevel 1 (
        set "USB_SERIAL=!DEVICE_ID!"
        goto CONVERT_USB_TO_WIRELESS
    )
    call :UPDATE_CACHE "!DEVICE_ID!"
    goto MENU_START
)



:: -------------------------------------------------------------------------
::  AUTO_DETECT OR WAIT FOR DEVICE
:: -------------------------------------------------------------------------
:INITIALIZE
cls
echo =======================================================
echo      LOCAL WI-FI ADB CONTROLLER  ^|  by Nani0p
echo      github.com/Navdeep0p
echo =======================================================
echo.
if not exist "cache" mkdir cache
if not exist "cache\devices.txt" type nul > "cache\devices.txt"

echo  [*] Checking for previously cached devices...
for /f "tokens=1,2,3 delims=|" %%A in (cache\devices.txt) do (
    echo  [-] Attempting auto-reconnect to %%C...
    adb connect %%C >nul 2>&1
)

:: Count currently connected devices
set "NUM_DEVICES=0"
set "ONLY_DEV="
for /f "tokens=1" %%a in ('adb devices ^| findstr /v "List" ^| findstr "device"') do (
    set /a NUM_DEVICES+=1
    set "ONLY_DEV=%%a"
)

if "!NUM_DEVICES!"=="0" goto NO_DEVICES_MENU

if "!NUM_DEVICES!"=="1" (
    :: FIX: echo|findstr does not set errorlevel reliably inside an if block.
    :: Use string substitution to detect colon — if removing ":" changes the string,
    :: then it contains a colon (wireless IP:port). If unchanged, it is a USB serial.
    set "DEV_CHECK=!ONLY_DEV!"
    if "!DEV_CHECK!"=="!DEV_CHECK::=!" (
        :: No colon found — USB serial, convert to wireless
        set "USB_SERIAL=!ONLY_DEV!"
        goto CONVERT_USB_TO_WIRELESS
    ) else (
        :: Colon found — wireless IP:port, use directly
        set "FRIENDLY_NAME="
        for /f "tokens=*" %%x in ('adb -s !ONLY_DEV! shell getprop ro.product.model 2^>nul') do set "FRIENDLY_NAME=%%x"
        if "!FRIENDLY_NAME!"=="" set "FRIENDLY_NAME=Device"
        echo  [+] Auto-connected to cached device:
        echo      !FRIENDLY_NAME! ^(!ONLY_DEV!^)
        set "DEVICE_ID=!ONLY_DEV!"
        call :UPDATE_CACHE "!DEVICE_ID!"
        timeout /t 2 >nul
        goto MENU_START
    )
)

:: If multiple connected
goto SELECT_DEVICE

:: -------------------------------------------------------------------------
::  NO DEVICES MENU (CACHE FALLBACK)
:: -------------------------------------------------------------------------
:NO_DEVICES_MENU
cls
echo =======================================================
echo               DEVICE SELECTION MENU
echo =======================================================
echo.
echo  [!] No connected devices found.
echo.
echo   KNOWN CACHED DEVICES:
set "IDX=0"
if exist "cache\devices.txt" (
    for /f "tokens=1,2,3 delims=|" %%a in (cache\devices.txt) do (
        set /a IDX+=1
        set "CACHE_EP_!IDX!=%%c"
        echo   [!IDX!] %%b ^(%%a^) - %%c
    )
)
if "!IDX!"=="0" echo   (No devices in cache)

echo.
echo   [r] Refresh Connected Devices
echo   [n] Connect New Device (USB)
echo   [0] Exit
echo.
set /p SEL_CHOICE="Select option: "
if /i "!SEL_CHOICE!"=="r" goto INITIALIZE
if /i "!SEL_CHOICE!"=="n" goto CONNECT_NEW_DEVICE
if /i "!SEL_CHOICE!"=="0" goto EXIT_SCRIPT

set "TARGET_EP=!CACHE_EP_%SEL_CHOICE%!"
if not "!TARGET_EP!"=="" (
    echo  [*] Attempting to connect to !TARGET_EP!...
    echo  [DEBUG] adb connect Output:
    adb connect !TARGET_EP!
    timeout /t 2 >nul
    adb devices ^| findstr "!TARGET_EP!" ^| findstr "device" >nul
    if errorlevel 1 (
        echo  [!] Device not currently connected.
        pause
        goto NO_DEVICES_MENU
    ) else (
        set "DEVICE_ID=!TARGET_EP!"
        call :UPDATE_CACHE "!DEVICE_ID!"
        goto MENU_START
    )
)

echo  [!] Invalid selection.
timeout /t 2 >nul
goto NO_DEVICES_MENU

:: -------------------------------------------------------------------------
::  WAIT FOR NEW USB DEVICE
:: -------------------------------------------------------------------------
:CONNECT_NEW_DEVICE
cls
echo  [*] Waiting for a new device to be connected via USB...
adb wait-for-device
goto INITIALIZE

:: -------------------------------------------------------------------------
::  CONVERT USB TO WIRELESS
::  FIX: DEVICE_ID is ALWAYS set to IP:5555 — never to the USB serial
:: -------------------------------------------------------------------------
:CONVERT_USB_TO_WIRELESS
echo.
echo  [+] USB device detected: !USB_SERIAL!
echo  [DEBUG] Device Serial: !USB_SERIAL!

:: Retrieve Friendly Name BEFORE switching to tcpip
set "FRIENDLY_NAME="
for /f "tokens=*" %%x in ('adb -s !USB_SERIAL! shell getprop ro.product.model 2^>nul') do set "FRIENDLY_NAME=%%x"
if "!FRIENDLY_NAME!"=="" set "FRIENDLY_NAME=Device"
echo  [DEBUG] Device Model: !FRIENDLY_NAME!

echo  [*] Retrieving IP address...
set "RAW_IP="
set "CLEAN_IP="
set "DEVICE_IP="

:: Method 1: DHCP properties (most Android versions)
for /f "tokens=*" %%a in ('adb -s !USB_SERIAL! shell "getprop dhcp.wlan0.ipaddress" 2^>nul') do set "RAW_IP=%%a"

:: Method 2: Live interface state (Android 10+ fallback)
if "!RAW_IP!"=="" (
    for /f "tokens=2" %%a in ('adb -s !USB_SERIAL! shell "ip -4 addr show wlan0" ^| findstr "inet " 2^>nul') do set "RAW_IP=%%a"
)

:: Strip subnet mask and carriage return
for /f "tokens=1 delims=/" %%a in ("!RAW_IP!") do set "CLEAN_IP=%%a"
for /f "tokens=1" %%a in ("!CLEAN_IP!") do set "DEVICE_IP=%%a"

echo  [DEBUG] Device IP: !DEVICE_IP!

if "!DEVICE_IP!"=="" (
    echo  [!] Could not parse IP automatically.
    echo.
    set /p DEVICE_IP="     Manually enter the device Wi-Fi IP address: "
)

if "!DEVICE_IP!"=="" (
    echo  [!] Wi-Fi IP is required. Aborting.
    pause
    goto NO_DEVICES_MENU
)

:: ---- ALWAYS use port 5555 for tcpip ----
:: Android (especially MIUI/HyperOS) ignores the port argument and restarts adbd
:: on 5555 regardless. After connecting wirelessly, if a port collision exists
:: (another device already on IP:5555), we disconnect and skip this device.
set "PORT_TARGET=5555"

echo  [*] Switching device to TCP/IP mode (Port 5555)...
echo  [DEBUG] adb tcpip Result:
adb -s !USB_SERIAL! tcpip 5555

:: ---- WAIT LOOP: goto-based so errorlevel propagates correctly ----
:: for /l loops break errorlevel from child commands -- use goto instead.
:: CORRECT logic: loop while device IS responsive (errorlevel 0 = still on old USB adbd).
:: Exit the loop when it STOPS responding (errorlevel 1 = adbd restarted in TCP mode).
:: Cap at 15s in case some devices never drop the USB serial (they transition silently).
echo  [*] Waiting for device to switch to TCP/IP mode...
set "WAIT_COUNT=0"
:TCPIP_WAIT_LOOP
timeout /t 1 >nul
set /a WAIT_COUNT+=1
if !WAIT_COUNT! GEQ 15 (
    echo  [*] Timeout reached - TCP/IP mode should be active. Continuing...
    goto TCPIP_WAIT_DONE
)
adb -s !USB_SERIAL! shell "echo checking" >nul 2>&1
if not errorlevel 1 goto TCPIP_WAIT_LOOP
:TCPIP_WAIT_DONE

echo  [*] TCP/IP mode active.
echo.
echo  [!] IMPORTANT: Unplug the USB cable from the device now!
echo  [i] (HyperOS/MIUI devices block wireless connections while USB is attached)
echo.
pause

echo  [DEBUG] Current ADB Devices List:
adb devices

:: ---- Check if another device is already occupying this IP:port ----
adb devices > "%TEMP%\adb_dev_check.tmp" 2>nul
findstr "!DEVICE_IP!:5555" "%TEMP%\adb_dev_check.tmp" >nul
set "ALREADY_EL=!errorlevel!"
del "%TEMP%\adb_dev_check.tmp" >nul 2>&1
if "!ALREADY_EL!"=="0" (
    echo  [*] !DEVICE_IP!:5555 already connected ^(same IP, different session^). Using existing connection.
    set "DEVICE_ID=!DEVICE_IP!:5555"
    goto CONN_SUCCESS
)

echo  [*] Attempting to connect to !DEVICE_IP!:5555...
set "CONN_ATTEMPT=0"
:CONN_RETRY
set /a CONN_ATTEMPT+=1
echo  [-] Connection Attempt !CONN_ATTEMPT! of 5...
echo  [DEBUG] adb connect Result:
adb connect !DEVICE_IP!:5555
timeout /t 2 >nul

adb devices > "%TEMP%\adb_dev_check.tmp" 2>nul
findstr "!DEVICE_IP!:5555" "%TEMP%\adb_dev_check.tmp" | findstr "device" >nul
set "CONN_EL=!errorlevel!"
del "%TEMP%\adb_dev_check.tmp" >nul 2>&1
if "!CONN_EL!"=="0" goto CONN_SUCCESS

if !CONN_ATTEMPT! LSS 5 (
    echo  [!] Attempt !CONN_ATTEMPT! failed. Waiting 4 seconds before retry...
    timeout /t 4 >nul
    goto CONN_RETRY
)

echo.
echo  [!] Critical Failure: Could not establish wireless ADB connection after 5 attempts.
echo  [!] Ensure the device is on the same Wi-Fi network and AP isolation is off.
pause
goto NO_DEVICES_MENU

:CONN_SUCCESS
echo  [+] Successfully connected wirelessly!

:: DEVICE_ID is always IP:5555 -- Android enforces this regardless of tcpip argument
set "DEVICE_ID=!DEVICE_IP!:5555"

echo  [DEBUG] Active Transport: !DEVICE_ID!
echo  [INFO] Auto-connected: !FRIENDLY_NAME! (!USB_SERIAL!)

echo  [DEBUG] Cache Entry: !USB_SERIAL!^|!FRIENDLY_NAME!^|!DEVICE_ID!
call :UPDATE_CACHE "!DEVICE_ID!" "!USB_SERIAL!"
timeout /t 4 >nul
goto MENU_START

:: -------------------------------------------------------------------------
::  WATCHER MODE (Runs in background)
:: -------------------------------------------------------------------------
:WATCHER_MODE
set "SEEN_DEVICES="
:WATCHER_LOOP
set "CURR_DEVICES="
for /f "tokens=1" %%a in ('adb devices ^| findstr /v "List" ^| findstr "device"') do (
    set "CURR_DEVICES=!CURR_DEVICES! %%a"
)
:: Compare
:: FIX: echo|findstr does not set errorlevel reliably in for loops.
:: Use string substitution for colon detection, and substring search for seen-list.
for %%D in (!CURR_DEVICES!) do (
    set "WD_CHECK=%%D"
    if "!WD_CHECK!"=="!WD_CHECK::=!" (
        :: No colon = USB serial (not yet wireless) — check if already seen
        set "WD_SEEN=!SEEN_DEVICES!"
        if "!WD_SEEN:%%D=!"=="!WD_SEEN!" (
            :: Not in seen list — new device, launch handler
            set "SEEN_DEVICES=!SEEN_DEVICES! %%D"
            start "Wireless ADB - Connected: %%D" cmd /c ""%~f0" --auto %%D"
        )
    )
)
timeout /t 2 >nul
goto WATCHER_LOOP

:: -------------------------------------------------------------------------
::  DEVICE SELECTION (When selecting another device)
:: -------------------------------------------------------------------------
:SELECT_DEVICE
cls
echo =======================================================
echo            SELECT CONNECTED DEVICE
echo =======================================================
echo.
echo   CONNECTED DEVICES:
set "idx=0"
for /f "tokens=1" %%a in ('adb devices ^| findstr /v "List" ^| findstr "device"') do (
    set /a idx+=1
    set "DEV_!idx!=%%a"
    echo   [!idx!] %%a
)

echo.
echo   KNOWN CACHED DEVICES (Not currently connected):
set "c_idx=!idx!"
if exist "cache\devices.txt" (
    for /f "tokens=1,2,3 delims=|" %%a in (cache\devices.txt) do (
        :: Ensure it's not already listed
        set "ALREADY_LISTED=0"
        for /l %%i in (1,1,!idx!) do (
            if "!DEV_%%i!"=="%%c" set "ALREADY_LISTED=1"
        )
        if "!ALREADY_LISTED!"=="0" (
            set /a c_idx+=1
            set "DEV_!c_idx!=%%c"
            set "DEV_NEEDS_CONNECT_!c_idx!=1"
            echo   [!c_idx!] %%b ^(%%a^) - %%c
        )
    )
)

echo.
echo   [r] Refresh
echo   [n] Connect New Device (USB)
echo   [b] Back to Main Menu
echo   [0] Exit
echo.
set /p SEL_CHOICE="Select option: "
if /i "!SEL_CHOICE!"=="b" goto MENU_START
if /i "!SEL_CHOICE!"=="r" goto INITIALIZE
if /i "!SEL_CHOICE!"=="n" goto CONNECT_NEW_DEVICE
if /i "!SEL_CHOICE!"=="0" goto EXIT_SCRIPT

set "TARGET_DEV=!DEV_%SEL_CHOICE%!"
if "!TARGET_DEV!"=="" (
    echo  [!] Invalid selection.
    timeout /t 2 >nul
    goto SELECT_DEVICE
)

if "!DEV_NEEDS_CONNECT_%SEL_CHOICE%!"=="1" (
    echo  [*] Attempting to connect to !TARGET_DEV!...
    adb connect !TARGET_DEV! >nul 2>&1
    timeout /t 2 >nul
    adb devices ^| findstr "!TARGET_DEV!" ^| findstr "device" >nul
    if errorlevel 1 (
        echo  [!] Device not currently connected.
        pause
        goto SELECT_DEVICE
    )
)

:: Check if it's USB (no colon = USB serial)
:: FIX: echo|findstr unreliable — use string substitution instead
set "DEV_CHECK=!TARGET_DEV!"
if "!DEV_CHECK!"=="!DEV_CHECK::=!" (
    set "USB_SERIAL=!TARGET_DEV!"
    goto CONVERT_USB_TO_WIRELESS
)

:: FIX: Only accept IP:port style as DEVICE_ID
set "DEVICE_ID=!TARGET_DEV!"
call :UPDATE_CACHE "!DEVICE_ID!"
echo  [+] Switched to device: !DEVICE_ID!
timeout /t 2 >nul
goto MENU_START

:: =========================================================================
::  VERIFY CONNECTION HELPER — reconnects wirelessly if device dropped
::  FIX: Called before every major ADB command block
:: =========================================================================
:VERIFY_CONNECTION
:: Check if DEVICE_ID looks like a USB serial (no colon) — refuse to use it
echo !DEVICE_ID! | findstr ":" >nul
if errorlevel 1 (
    echo  [!] DEVICE_ID is a USB serial ^(!DEVICE_ID!^), not a wireless address.
    echo  [!] Please reconnect via USB to re-pair wirelessly.
    pause
    goto INITIALIZE
)
:: Ping the device to confirm it's still reachable
adb -s !DEVICE_ID! shell echo ping >nul 2>&1
if errorlevel 1 (
    echo  [*] Device dropped. Attempting reconnect to !DEVICE_ID!...
    adb connect !DEVICE_ID! >nul 2>&1
    timeout /t 2 >nul
    adb -s !DEVICE_ID! shell echo ping >nul 2>&1
    if errorlevel 1 (
        echo  [!] Could not reconnect to !DEVICE_ID!.
        echo  [i] Make sure phone Wi-Fi is on and both devices are on the same network.
        pause
        goto NO_DEVICES_MENU
    )
    echo  [+] Reconnected to !DEVICE_ID!.
)
exit /b 0

:: =========================================================================
::  MAIN MENU
:: =========================================================================
:MENU_START
:: FIX: Guard — refuse to proceed if DEVICE_ID is a USB serial
echo !DEVICE_ID! | findstr ":" >nul
if errorlevel 1 (
    echo  [!] No wireless device active. Returning to device selection...
    timeout /t 2 >nul
    goto INITIALIZE
)
cls
echo =======================================================
echo   ACTIVE NODE: %DEVICE_ID% ^| DASHBOARD
echo   by Nani0p ^| github.com/Navdeep0p
echo =======================================================
echo.
echo   SELECT MODULE:
echo.
echo   [1]  Keystroke Injection ^& Remote Control
echo   [2]  Wireless Screen Mirror (scrcpy)
echo   [3]  Sideload / Install APK (Ghost Mode)
echo   [4]  Data Pulling
echo   [5]  Automated Screenshot Engine
echo   [6]  Install Shizuku Framework
echo   [7]  Phone Actions (GPS / Maps / Call / Record / Photo)
echo   [8]  Connect Another Device
echo   [9]  Disconnect and Exit
echo.
set /p CHOICE="Select module (1-9): "

if "%CHOICE%"=="1" goto PROJECT_1
if "%CHOICE%"=="2" goto PROJECT_2
if "%CHOICE%"=="3" goto INSTALL_APK
if "%CHOICE%"=="4" goto DATA_PULLING
if "%CHOICE%"=="5" goto SS_ENGINE_STANDALONE
if "%CHOICE%"=="6" goto INJECT_SHIZUKU
if "%CHOICE%"=="7" goto MODULE_PHONE_ACTIONS
if "%CHOICE%"=="8" goto SELECT_DEVICE
if "%CHOICE%"=="9" goto EXIT_SCRIPT

echo  [!] Invalid selection.
timeout /t 2 >nul
goto MENU_START

:: =========================================================================
::  MODULE 1: KEYSTROKE INJECTION / REMOTE CONTROL
:: =========================================================================
:PROJECT_1
call :VERIFY_CONNECTION
cls
echo =======================================================
echo      PROJECT 1: WIRELESS CONTROL TERMINAL
echo      Controlling: %DEVICE_ID%
echo =======================================================
echo.
echo   [1]  Wake Up Screen               [6]  Press BACK Button
echo   [2]  Toggle Power / Screen        [7]  Open a URL in Browser
echo   [3]  Press ENTER Key              [8]  Launch App Directly
echo   [4]  Type a Text Message          [9]  Return to Main Menu
echo   [5]  Press HOME Button
echo.
set /p P1_CHOICE="Select option (1-9): "

if "%P1_CHOICE%"=="1" (
    adb -s %DEVICE_ID% shell input keyevent 224
    echo  [*] Wake Up signal sent.
    timeout /t 2 >nul
    goto PROJECT_1
)
if "%P1_CHOICE%"=="2" (
    adb -s %DEVICE_ID% shell input keyevent 26
    echo  [*] Power/Screen toggle sent.
    timeout /t 2 >nul
    goto PROJECT_1
)
if "%P1_CHOICE%"=="3" (
    adb -s %DEVICE_ID% shell input keyevent 66
    echo  [*] ENTER key sent.
    timeout /t 2 >nul
    goto PROJECT_1
)
if "%P1_CHOICE%"=="4" (
    echo.
    set /p TEXT_INPUT="  Enter text to inject: "
    adb -s %DEVICE_ID% shell input text "!TEXT_INPUT!"
    echo  [*] Text injected successfully.
    timeout /t 3 >nul
    goto PROJECT_1
)
if "%P1_CHOICE%"=="5" (
    adb -s %DEVICE_ID% shell input keyevent 3
    echo  [*] HOME button sent.
    timeout /t 2 >nul
    goto PROJECT_1
)
if "%P1_CHOICE%"=="6" (
    adb -s %DEVICE_ID% shell input keyevent 4
    echo  [*] BACK button sent.
    timeout /t 2 >nul
    goto PROJECT_1
)
if "%P1_CHOICE%"=="7" (
    echo.
    set /p TARGET_URL="  Enter URL (e.g., https://google.com): "
    adb -s %DEVICE_ID% shell am start -a android.intent.action.VIEW -d "!TARGET_URL!"
    echo  [*] Browser intent sent.
    timeout /t 3 >nul
    goto PROJECT_1
)
if "%P1_CHOICE%"=="8" goto APP_LAUNCHER
if "%P1_CHOICE%"=="9" goto MENU_START

echo  [!] Invalid selection.
timeout /t 2 >nul
goto PROJECT_1

:: =========================================================================
::  MODULE 2: WIRELESS SCREEN MIRROR (SCRCPY)
:: =========================================================================
:PROJECT_2
call :VERIFY_CONNECTION
cls
echo =======================================================
echo          PROJECT 2: WIRELESS SCRCPY ENGINE
echo          Streaming: %DEVICE_ID%
echo =======================================================
echo.
echo   [1]  Standard Mirror
echo   [2]  High-Performance (H.264, 8Mbps, 60fps)
echo   [3]  Screen Only (audio plays on phone)
echo   [4]  Return to Main Menu
echo.
set /p P2_CHOICE="Select profile (1-4): "

if "%P2_CHOICE%"=="1" (
    echo  [*] Starting standard mirror...
    scrcpy.exe -s %DEVICE_ID%
    goto PROJECT_2
)
if "%P2_CHOICE%"=="2" (
    echo  [*] Starting high-performance mirror...
    scrcpy.exe -s %DEVICE_ID% -b 8M -m 1920 --max-fps 60 --video-codec=h264
    goto PROJECT_2
)
if "%P2_CHOICE%"=="3" (
    echo  [*] Starting screen-only mirror...
    scrcpy.exe -s %DEVICE_ID% --no-audio
    goto PROJECT_2
)
if "%P2_CHOICE%"=="4" goto MENU_START

echo  [!] Invalid selection.
timeout /t 2 >nul
goto PROJECT_2

:: =========================================================================
::  MODULE 3: GHOST APK SIDELOADER
:: =========================================================================
:INSTALL_APK
call :VERIFY_CONNECTION
cls
echo =======================================================
echo            GHOST APK DEPLOYMENT INJECTOR
echo =======================================================
echo.
echo  [*] Drag-and-drop your .apk file into this window,
echo      then press ENTER.
echo.
set /p APK_PATH="  APK Path: "
echo.

echo  [*] Temporarily disabling Play Protect scanner...
adb -s %DEVICE_ID% shell settings put global package_verifier_enable 0 >nul 2>&1
adb -s %DEVICE_ID% shell settings put secure miui_package_verifier_enable 0 >nul 2>&1
timeout /t 3 >nul

echo  [*] Installing APK...
adb -s %DEVICE_ID% install -r %APK_PATH%
if errorlevel 1 (
    echo.
    echo  [!] Installation FAILED. Check the path and try again.
    echo  [*] Restoring Play Protect...
    adb -s %DEVICE_ID% shell settings put global package_verifier_enable 1 >nul 2>&1
    adb -s %DEVICE_ID% shell settings put secure miui_package_verifier_enable 1 >nul 2>&1
    pause
    goto MENU_START
)

echo  [*] Restoring Play Protect scanner...
adb -s %DEVICE_ID% shell settings put global package_verifier_enable 1 >nul 2>&1
adb -s %DEVICE_ID% shell settings put secure miui_package_verifier_enable 1 >nul 2>&1

echo.
echo  [+] APK installed successfully!
echo.
set /p GOD_MODE="  Apply elevated permissions (God Mode)? (y/n): "
if /I not "%GOD_MODE%"=="y" goto SKIP_PERMS

echo.
set /p INJECT_PKG="  Enter exact package name (e.g., com.nani0p.RemoteAgent): "
echo  [*] Injecting system-level permissions for %INJECT_PKG%...
adb -s %DEVICE_ID% shell dumpsys deviceidle whitelist +%INJECT_PKG% >nul 2>&1
adb -s %DEVICE_ID% shell appops set %INJECT_PKG% SYSTEM_ALERT_WINDOW allow >nul 2>&1
adb -s %DEVICE_ID% shell appops set %INJECT_PKG% RUN_IN_BACKGROUND allow >nul 2>&1
adb -s %DEVICE_ID% shell appops set %INJECT_PKG% RUN_ANY_IN_BACKGROUND allow >nul 2>&1

echo  [*] Waking app from stopped state...
adb -s %DEVICE_ID% shell monkey -p %INJECT_PKG% 1 >nul 2>&1
timeout /t 4 >nul

echo  [*] Minimizing app to background...
adb -s %DEVICE_ID% shell input keyevent 3
echo.
echo  [+] COMPLETE: Agent is armed, authorized, and hidden.

:SKIP_PERMS
echo.
pause
goto MENU_START

:: =========================================================================
::  MODULE 4: DATA PULLING
:: =========================================================================
:DATA_PULLING
call :VERIFY_CONNECTION
cls
echo =======================================================
echo               DATA PULLING ENGINE
echo               Device: %DEVICE_ID%
echo =======================================================
echo.
echo   [1]  Pull Images
echo   [2]  Pull Videos
echo   [3]  Pull Documents
echo   [4]  Pull Downloads
echo   [5]  Pull WhatsApp Media
echo   [6]  Pull Screenshots
echo   [7]  Pull Everything
echo   [0]  Back
echo.
set /p DP_CHOICE="Select module (0-7): "

if "%DP_CHOICE%"=="1" set "PULL_TARGET=Images" & goto PERFORM_PULL
if "%DP_CHOICE%"=="2" set "PULL_TARGET=Videos" & goto PERFORM_PULL
if "%DP_CHOICE%"=="3" set "PULL_TARGET=Documents" & goto PERFORM_PULL
if "%DP_CHOICE%"=="4" set "PULL_TARGET=Downloads" & goto PERFORM_PULL
if "%DP_CHOICE%"=="5" set "PULL_TARGET=WhatsApp" & goto PERFORM_PULL
if "%DP_CHOICE%"=="6" set "PULL_TARGET=Screenshots" & goto PERFORM_PULL
if "%DP_CHOICE%"=="7" set "PULL_TARGET=Everything" & goto PERFORM_PULL
if "%DP_CHOICE%"=="0" goto MENU_START

echo  [!] Invalid selection.
timeout /t 2 >nul
goto DATA_PULLING

:PERFORM_PULL
echo.
echo  [*] Pull started...
set "SUCCESS_COUNT=0"
set "SKIPPED_COUNT=0"

:: Create local directories
if not exist "PulledData" mkdir "PulledData"
if not exist "PulledData\Images" mkdir "PulledData\Images"
if not exist "PulledData\Videos" mkdir "PulledData\Videos"
if not exist "PulledData\Documents" mkdir "PulledData\Documents"
if not exist "PulledData\Downloads" mkdir "PulledData\Downloads"
if not exist "PulledData\WhatsApp" mkdir "PulledData\WhatsApp"
if not exist "PulledData\Screenshots" mkdir "PulledData\Screenshots"

if "%PULL_TARGET%"=="Images" goto PULL_IMAGES
if "%PULL_TARGET%"=="Videos" goto PULL_VIDEOS
if "%PULL_TARGET%"=="Documents" goto PULL_DOCUMENTS
if "%PULL_TARGET%"=="Downloads" goto PULL_DOWNLOADS
if "%PULL_TARGET%"=="WhatsApp" goto PULL_WHATSAPP
if "%PULL_TARGET%"=="Screenshots" goto PULL_SCREENSHOTS
if "%PULL_TARGET%"=="Everything" goto PULL_EVERYTHING
goto DATA_PULLING

:PULL_IMAGES
if "%DEBUG_MODE%"=="1" echo [DEBUG] Entered PULL_IMAGES
call :DO_PULL "/sdcard/DCIM" "PulledData\Images"
call :DO_PULL "/sdcard/Pictures" "PulledData\Images"
goto PULL_DONE

:PULL_VIDEOS
if "%DEBUG_MODE%"=="1" echo [DEBUG] Entered PULL_VIDEOS
call :DO_PULL "/sdcard/DCIM/Camera" "PulledData\Videos"
call :DO_PULL "/sdcard/Movies" "PulledData\Videos"
goto PULL_DONE

:PULL_DOCUMENTS
if "%DEBUG_MODE%"=="1" echo [DEBUG] Entered PULL_DOCUMENTS
call :DO_PULL "/sdcard/Documents" "PulledData\Documents"
goto PULL_DONE

:PULL_DOWNLOADS
if "%DEBUG_MODE%"=="1" echo [DEBUG] Entered PULL_DOWNLOADS
call :DO_PULL "/sdcard/Download" "PulledData\Downloads"
goto PULL_DONE

:PULL_WHATSAPP
if "%DEBUG_MODE%"=="1" echo [DEBUG] Entered PULL_WHATSAPP
call :DO_PULL "/sdcard/Android/media/com.whatsapp/WhatsApp/Media" "PulledData\WhatsApp"
goto PULL_DONE

:PULL_SCREENSHOTS
if "%DEBUG_MODE%"=="1" echo [DEBUG] Entered PULL_SCREENSHOTS
call :DO_PULL "/sdcard/DCIM/Screenshots" "PulledData\Screenshots"
call :DO_PULL "/sdcard/Pictures/Screenshots" "PulledData\Screenshots"
call :DO_PULL "/sdcard/Screenshots" "PulledData\Screenshots"
goto PULL_DONE

:PULL_EVERYTHING
if "%DEBUG_MODE%"=="1" echo [DEBUG] Entered PULL_EVERYTHING
call :DO_PULL "/sdcard/DCIM" "PulledData\Images"
call :DO_PULL "/sdcard/Pictures" "PulledData\Images"
call :DO_PULL "/sdcard/DCIM/Camera" "PulledData\Videos"
call :DO_PULL "/sdcard/Movies" "PulledData\Videos"
call :DO_PULL "/sdcard/Documents" "PulledData\Documents"
call :DO_PULL "/sdcard/Download" "PulledData\Downloads"
call :DO_PULL "/sdcard/Android/media/com.whatsapp/WhatsApp/Media" "PulledData\WhatsApp"
call :DO_PULL "/sdcard/DCIM/Screenshots" "PulledData\Screenshots"
call :DO_PULL "/sdcard/Pictures/Screenshots" "PulledData\Screenshots"
call :DO_PULL "/sdcard/Screenshots" "PulledData\Screenshots"
goto PULL_DONE

:PULL_DONE
echo.
echo  [*] Pull completed.
echo  [*] Folders copied successfully: %SUCCESS_COUNT%
if !SKIPPED_COUNT! gtr 0 (
    echo  [*] Folders skipped ^(not found^): %SKIPPED_COUNT%
)
echo.
if "%DEBUG_MODE%"=="1" echo [DEBUG] Returning to DATA_PULLING menu
pause
goto DATA_PULLING

:: =========================================================================
::  MODULE 5: STANDALONE SCREENSHOT ENGINE
:: =========================================================================
:SS_ENGINE_STANDALONE
call :VERIFY_CONNECTION
cls
echo =======================================================
echo         AUTOMATED SCREENSHOT INTERVAL ENGINE
echo =======================================================
echo.
set /p SS_COUNT="  How many screenshots? (e.g., 5): "
set /p SS_INTERVAL="  Interval between shots in seconds? (e.g., 3): "
echo.

if not exist "Screenshots" mkdir "Screenshots"
echo  [*] Starting screenshot sequence...
echo.

for /L %%I in (1, 1, %SS_COUNT%) do (
    echo  [Shot %%I of %SS_COUNT%] Capturing...
    adb -s %DEVICE_ID% shell screencap -p /sdcard/tmp_shot_%%I.png
    adb -s %DEVICE_ID% pull /sdcard/tmp_shot_%%I.png "Screenshots\Capture_%%I.png" >nul
    adb -s %DEVICE_ID% shell rm /sdcard/tmp_shot_%%I.png
    timeout /t %SS_INTERVAL% >nul
)
echo.
echo  [+] Done! Images saved to: %CD%\Screenshots
pause
goto MENU_START

:: =========================================================================
::  MODULE 6: SHIZUKU FRAMEWORK INSTALLER
:: =========================================================================
:INJECT_SHIZUKU
call :VERIFY_CONNECTION
cls
echo =======================================================
echo          SHIZUKU FRAMEWORK INSTALLER
echo =======================================================
echo.
echo  [*] Fetching latest Shizuku release from GitHub...
powershell -Command "$release = Invoke-RestMethod -Uri 'https://api.github.com/repos/RikkaApps/Shizuku/releases/latest'; $url = ($release.assets | Where-Object { $_.name -like '*release.apk' }).browser_download_url; Invoke-WebRequest -Uri $url -OutFile 'shizuku_latest.apk'"
if errorlevel 1 (
    echo  [!] Download failed. Check your internet connection.
    pause
    goto MENU_START
)

echo  [*] Installing Shizuku on device...
adb -s %DEVICE_ID% install -r shizuku_latest.apk
if errorlevel 1 (
    echo  [!] Shizuku installation failed.
    del shizuku_latest.apk >nul 2>&1
    pause
    goto MENU_START
)

echo  [*] Starting Shizuku background daemon...
adb -s %DEVICE_ID% shell sh /sdcard/Android/data/moe.shizuku.privileged.api/start.sh

echo.
echo  [+] Shizuku installed and running!
del shizuku_latest.apk >nul 2>&1
pause
goto MENU_START

:: =========================================================================
::  SUB-MENU: APP LAUNCHER (with auto scrcpy mirror)
:: =========================================================================
:APP_LAUNCHER
call :VERIFY_CONNECTION
cls
echo =======================================================
echo           WIRELESS APPLICATION LAUNCHER
echo =======================================================
echo.
echo  App launches on device AND opens a live mirror here.
echo.
echo   [1] YouTube           [5] Instagram
echo   [2] Google Chrome     [6] Snapchat
echo   [3] Device Settings   [7] Camera (Rear)
echo   [4] WhatsApp          [8] Camera (Front / Selfie)
echo.
echo   [c] Custom App (enter package name manually)
echo   [r] Return to Control Panel
echo.
set /p APP_CHOICE="Select app: "

if "%APP_CHOICE%"=="r" goto PROJECT_1
if "%APP_CHOICE%"=="1" set "APP_PKG=com.google.android.youtube"    & set "APP_NAME=YouTube"        & goto LAUNCH_ROUTINE
if "%APP_CHOICE%"=="2" set "APP_PKG=com.android.chrome"            & set "APP_NAME=Chrome"          & goto LAUNCH_ROUTINE
if "%APP_CHOICE%"=="3" set "APP_PKG=SETTINGS"                      & set "APP_NAME=Settings"        & goto LAUNCH_ROUTINE
if "%APP_CHOICE%"=="4" set "APP_PKG=com.whatsapp"                  & set "APP_NAME=WhatsApp"        & goto LAUNCH_ROUTINE
if "%APP_CHOICE%"=="5" set "APP_PKG=com.instagram.android"         & set "APP_NAME=Instagram"       & goto LAUNCH_ROUTINE
if "%APP_CHOICE%"=="6" set "APP_PKG=com.snapchat.android"          & set "APP_NAME=Snapchat"        & goto LAUNCH_ROUTINE
if "%APP_CHOICE%"=="7" set "APP_PKG=CAMERA_REAR"                   & set "APP_NAME=Rear Camera"     & goto LAUNCH_ROUTINE
if "%APP_CHOICE%"=="8" set "APP_PKG=CAMERA_FRONT"                  & set "APP_NAME=Front Camera"    & goto LAUNCH_ROUTINE
if /I "%APP_CHOICE%"=="c" (
    echo.
    set /p APP_PKG="  Enter package name (e.g., com.twitter.android): "
    set "APP_NAME=Custom App"
    goto LAUNCH_ROUTINE
)

echo  [!] Invalid selection.
timeout /t 2 >nul
goto APP_LAUNCHER

:LAUNCH_ROUTINE
echo.
echo  [*] Launching %APP_NAME% on device...

:: -- For camera launches: grant permission + wake screen safely --
if "%APP_PKG%"=="CAMERA_REAR" goto DO_CAM_PREP
if "%APP_PKG%"=="CAMERA_FRONT" goto DO_CAM_PREP
goto SKIP_CAM_PREP

:DO_CAM_PREP
echo  [*] Granting camera permissions...
for %%P in (com.android.camera com.android.camera2 com.miui.camera com.sec.android.app.camera org.codeaurora.snapcam com.oneplus.camera) do (
    adb -s %DEVICE_ID% shell pm grant %%P android.permission.CAMERA >nul 2>&1
    adb -s %DEVICE_ID% shell appops set %%P CAMERA allow >nul 2>&1
)
set "SCREEN_WAS_OFF_L=0"
for /f "tokens=*" %%a in ('adb -s %DEVICE_ID% shell "dumpsys power | grep mWakefulness=" 2^>nul') do set "WAKE_RAW_L=%%a"
echo !WAKE_RAW_L! | findstr /i "Asleep Dozing" >nul 2>&1
if not errorlevel 1 (
    set "SCREEN_WAS_OFF_L=1"
    echo  [*] Waking screen...
    adb -s %DEVICE_ID% shell input keyevent 26
    timeout /t 2 >nul
    :: FIX: reconnect after wake to ensure wireless link is still up
    adb connect %DEVICE_ID% >nul 2>&1
    timeout /t 2 >nul
    adb -s %DEVICE_ID% shell input swipe 540 1600 540 800 300 >nul 2>&1
    timeout /t 1 >nul
)
:SKIP_CAM_PREP

if "%APP_PKG%"=="SETTINGS" (
    adb -s %DEVICE_ID% shell am start -a android.settings.SETTINGS >nul 2>&1
) else if "%APP_PKG%"=="CAMERA_REAR" (
    adb -s %DEVICE_ID% shell am start -a android.media.action.STILL_IMAGE_CAMERA >nul 2>&1
) else if "%APP_PKG%"=="CAMERA_FRONT" (
    adb -s %DEVICE_ID% shell am start -a android.media.action.STILL_IMAGE_CAMERA --ei android.intent.extras.CAMERA_FACING 1 >nul 2>&1
) else if "%APP_PKG%"=="com.whatsapp" (
    adb -s %DEVICE_ID% shell am start -n com.whatsapp/com.whatsapp.Main >nul 2>&1
) else if "%APP_PKG%"=="com.instagram.android" (
    adb -s %DEVICE_ID% shell am start -n com.instagram.android/com.instagram.mainactivity.MainActivity >nul 2>&1
) else if "%APP_PKG%"=="com.snapchat.android" (
    adb -s %DEVICE_ID% shell am start -n com.snapchat.android/com.snap.mushroom.MainActivity >nul 2>&1
) else (
    adb -s %DEVICE_ID% shell monkey -p %APP_PKG% 1 >nul 2>&1
)

echo  [*] Opening live scrcpy mirror in background...
start "" scrcpy.exe -s %DEVICE_ID% -b 8M -m 1920 --max-fps 60 --video-codec=h264
echo.
set /p IN_APP_SS="  Start continuous background screenshots? (y/n): "
if /I "%IN_APP_SS%"=="y" goto SS_ENGINE_IN_APP
goto APP_LAUNCHER

:SS_ENGINE_IN_APP
echo.
if not exist "Screenshots" mkdir "Screenshots"
echo  [*] Continuous screenshot mode active. Close scrcpy to stop.
echo.
set /a SS_NUM=1

:SS_LOOP
tasklist | findstr /i "scrcpy.exe" >nul
if errorlevel 1 (
    echo.
    echo  [*] Mirror closed. Stopping screenshot engine.
    echo  [+] Images saved to: %CD%\Screenshots
    pause
    goto APP_LAUNCHER
)
echo  [Shot %SS_NUM% - %APP_NAME%] Capturing...
adb -s %DEVICE_ID% shell screencap -p /sdcard/tmp_shot.png
adb -s %DEVICE_ID% pull /sdcard/tmp_shot.png "Screenshots\%APP_NAME%_%SS_NUM%.png" >nul
adb -s %DEVICE_ID% shell rm /sdcard/tmp_shot.png
set /a SS_NUM+=1
timeout /t 2 >nul
goto SS_LOOP

:: =========================================================================
::  MODULE 7: PHONE ACTIONS — GPS / MAPS / CALL / RECORD / PHOTO
:: =========================================================================
:MODULE_PHONE_ACTIONS
call :VERIFY_CONNECTION
cls
echo =======================================================
echo      MODULE 7: PHONE ACTIONS ^& SENSORS
echo      Device: %DEVICE_ID%
echo      by Nani0p ^| github.com/Navdeep0p
echo =======================================================
echo.
echo   [1]  Toggle GPS / Location (On ^| Off)
echo   [2]  Open Location Settings on Device
echo   [3]  Google Maps Navigation
echo   [4]  Make a Direct Phone Call
echo   [5]  Record Voice          [UNDER DEVELOPMENT]
echo   [6]  Click Photo           [UNDER DEVELOPMENT]
echo   [7]  Click Selfie          [UNDER DEVELOPMENT]
echo   [8]  Return to Main Menu
echo.
set /p PA_CHOICE="Select option (1-8): "

if "%PA_CHOICE%"=="1" goto PA_GPS_TOGGLE
if "%PA_CHOICE%"=="2" goto PA_GPS_SETTINGS
if "%PA_CHOICE%"=="3" goto PA_MAPS_NAV
if "%PA_CHOICE%"=="4" goto PA_PHONE_CALL
if "%PA_CHOICE%"=="5" (
    echo.
    echo  [!] This feature is currently UNDER DEVELOPMENT.
    echo  [i] Stay tuned: github.com/Navdeep0p
    timeout /t 3 >nul
    goto MODULE_PHONE_ACTIONS
)
if "%PA_CHOICE%"=="6" (
    echo.
    echo  [!] This feature is currently UNDER DEVELOPMENT.
    echo  [i] Stay tuned: github.com/Navdeep0p
    timeout /t 3 >nul
    goto MODULE_PHONE_ACTIONS
)
if "%PA_CHOICE%"=="7" (
    echo.
    echo  [!] This feature is currently UNDER DEVELOPMENT.
    echo  [i] Stay tuned: github.com/Navdeep0p
    timeout /t 3 >nul
    goto MODULE_PHONE_ACTIONS
)
if "%PA_CHOICE%"=="8" goto MENU_START
echo  [!] Invalid selection.
timeout /t 2 >nul
goto MODULE_PHONE_ACTIONS

:: ---- [1] TOGGLE GPS ----
:PA_GPS_TOGGLE
echo.
echo  [*] Reading current Location mode...
set "GPS_MODE=0"
set "GPS_RAW="
for /f "tokens=*" %%a in ('adb -s %DEVICE_ID% shell settings get secure location_mode 2^>nul') do set "GPS_RAW=%%a"
for /f "tokens=1" %%a in ("!GPS_RAW!") do set "GPS_MODE=%%a"
echo  [*] Current mode value: !GPS_MODE!
if "!GPS_MODE!"=="0" (
    echo  [*] GPS is OFF -^> Turning ON (High Accuracy)...
    adb -s %DEVICE_ID% shell settings put secure location_mode 3 >nul 2>&1
    adb -s %DEVICE_ID% shell settings put secure location_providers_allowed +gps >nul 2>&1
    adb -s %DEVICE_ID% shell settings put secure location_providers_allowed +network >nul 2>&1
    echo  [+] GPS turned ON successfully.
) else (
    echo  [*] GPS is ON (Mode: !GPS_MODE!) -^> Turning OFF...
    adb -s %DEVICE_ID% shell settings put secure location_mode 0 >nul 2>&1
    adb -s %DEVICE_ID% shell settings put secure location_providers_allowed -gps >nul 2>&1
    adb -s %DEVICE_ID% shell settings put secure location_providers_allowed -network >nul 2>&1
    echo  [+] GPS turned OFF successfully.
)
echo.
echo  [i] NOTE: Android 10+ may require manual confirmation in Location Settings.
echo  [i] Use option [2] to verify the toggle on-screen.
timeout /t 4 >nul
goto MODULE_PHONE_ACTIONS

:: ---- [2] OPEN LOCATION SETTINGS ----
:PA_GPS_SETTINGS
echo.
echo  [*] Opening Location Settings on device...
adb -s %DEVICE_ID% shell am start -a android.settings.LOCATION_SOURCE_SETTINGS >nul 2>&1
if errorlevel 1 (
    echo  [!] Could not launch Location Settings. Check device connection.
    pause
    goto MODULE_PHONE_ACTIONS
)
echo  [+] Location Settings launched. You can toggle GPS from there.
timeout /t 3 >nul
goto MODULE_PHONE_ACTIONS

:: ---- [3] GOOGLE MAPS NAVIGATION ----
:PA_MAPS_NAV
echo.
echo  Enter a destination as plain text OR paste a Google Maps URL.
echo  Examples:
echo    Eiffel Tower Paris
echo    https://goo.gl/maps/xxxx
echo.
set "NAV_DEST="
set /p NAV_DEST="  Destination: "
if "!NAV_DEST!"=="" (
    echo  [!] Destination cannot be empty.
    timeout /t 2 >nul
    goto MODULE_PHONE_ACTIONS
)
echo !NAV_DEST! | findstr /i "http" >nul
if not errorlevel 1 (
    echo  [*] Detected URL -^> launching directly in Maps...
    adb -s %DEVICE_ID% shell am start -a android.intent.action.VIEW -d "!NAV_DEST!" >nul 2>&1
) else (
    set "NAV_ENCODED=!NAV_DEST: =+!"
    echo  [*] Launching navigation to: !NAV_DEST!
    adb -s %DEVICE_ID% shell am start -a android.intent.action.VIEW -d "google.navigation:q=!NAV_ENCODED!" >nul 2>&1
)
echo  [+] Google Maps Navigation launched on device.
timeout /t 3 >nul
goto MODULE_PHONE_ACTIONS

:: ---- [4] DIRECT PHONE CALL ----
:PA_PHONE_CALL
echo.
echo  Enter the phone number to call.
echo  Include country code for international (e.g., +911234567890)
echo.
set "CALL_NUM="
set /p CALL_NUM="  Phone Number: "
if "!CALL_NUM!"=="" (
    echo  [!] Number cannot be empty.
    timeout /t 2 >nul
    goto MODULE_PHONE_ACTIONS
)
echo  [*] Initiating call to !CALL_NUM!...
adb -s %DEVICE_ID% shell am start -a android.intent.action.CALL -d "tel:!CALL_NUM!"
if errorlevel 1 (
    echo  [!] Direct CALL intent failed. Opening Dialer instead...
    adb -s %DEVICE_ID% shell am start -a android.intent.action.DIAL -d "tel:!CALL_NUM!" >nul 2>&1
    echo  [i] Dialer opened with number pre-filled. Press call on device.
) else (
    echo  [+] Call initiated successfully on device.
)
timeout /t 3 >nul
goto MODULE_PHONE_ACTIONS

:: ---- [5] RECORD VOICE ----
:PA_VOICE_REC
echo.
set "REC_SECS="
set /p REC_SECS="  Recording duration in seconds (e.g., 10): "
if "!REC_SECS!"=="" set "REC_SECS=10"
if not exist "Recordings" mkdir "Recordings"
echo.
echo  [*] Opening Voice Recorder on device...
adb -s %DEVICE_ID% shell am start -a android.provider.MediaStore.RECORD_SOUND >nul 2>&1
timeout /t 2 >nul
echo  [*] Recording for !REC_SECS! seconds...
timeout /t !REC_SECS! >nul
echo  [*] Stopping recording (sending Back key)...
adb -s %DEVICE_ID% shell input keyevent 4
timeout /t 3 >nul
echo  [*] Searching for newest audio file on device...
set "REC_FILE="
for /f "tokens=*" %%a in ('adb -s %DEVICE_ID% shell "find /sdcard -maxdepth 4 \( -name '*.m4a' -o -name '*.3gp' -o -name '*.aac' -o -name '*.mp3' -o -name '*.wav' \) 2^>/dev/null ^| xargs ls -t 2^>/dev/null ^| head -1"') do set "REC_FILE=%%a"
for /f "tokens=1" %%a in ("!REC_FILE!") do set "REC_FILE=%%a"
if not "!REC_FILE!"=="" (
    echo  [*] Found: !REC_FILE!
    adb -s %DEVICE_ID% pull "!REC_FILE!" "Recordings\"
    echo  [+] Recording saved to: %CD%\Recordings\
) else (
    echo  [!] Could not locate audio file automatically.
    echo  [i] Check /sdcard/Music, /sdcard/Recordings, or /sdcard/MIUI/sound_recorder on device.
)
pause
goto MODULE_PHONE_ACTIONS

:: ---- [6] CLICK PHOTO — REAR CAMERA ----
:PA_PHOTO_REAR
echo.
if not exist "Photos" mkdir "Photos"

:: -- Check if screen is currently off --
set "SCREEN_WAS_OFF=0"
for /f "tokens=*" %%a in ('adb -s %DEVICE_ID% shell "dumpsys power | grep mWakefulness=" 2^>nul') do set "WAKE_RAW=%%a"
echo !WAKE_RAW! | findstr /i "Asleep Dozing" >nul 2>&1
if not errorlevel 1 set "SCREEN_WAS_OFF=1"

if "!SCREEN_WAS_OFF!"=="1" (
    echo  [*] Screen is off — waking...
    adb -s %DEVICE_ID% shell input keyevent 26
    timeout /t 2 >nul
    :: FIX: reconnect using DEVICE_ID (IP:port), not the USB serial
    adb connect %DEVICE_ID% >nul 2>&1
    timeout /t 2 >nul
    adb -s %DEVICE_ID% shell input swipe 540 1600 540 800 300 >nul 2>&1
    timeout /t 1 >nul
)

:: -- Detect installed camera package (Windows-side findstr, NOT inside shell) --
echo  [*] Detecting camera package...
set "CAM_PKG="
for %%P in (com.miui.camera com.sec.android.app.camera com.oneplus.camera com.android.camera2 com.android.camera org.codeaurora.snapcam) do (
    if "!CAM_PKG!"=="" (
        adb -s %DEVICE_ID% shell pm list packages | findstr /i "%%P" >nul 2>&1
        if not errorlevel 1 set "CAM_PKG=%%P"
    )
)
if "!CAM_PKG!"=="" set "CAM_PKG=com.android.camera2"
echo  [*] Using: !CAM_PKG!

:: -- Grant camera permission to that package only --
adb -s %DEVICE_ID% shell pm grant !CAM_PKG! android.permission.CAMERA >nul 2>&1
adb -s %DEVICE_ID% shell appops set !CAM_PKG! CAMERA allow >nul 2>&1

:: -- Place timestamp marker BEFORE opening camera --
adb -s %DEVICE_ID% shell "touch /sdcard/.snap_marker" >nul 2>&1

:: -- Launch rear camera: monkey is most reliable cross-OEM launcher --
echo  [*] Opening Rear Camera...
adb -s %DEVICE_ID% shell "am force-stop !CAM_PKG!" >nul 2>&1
timeout /t 1 >nul
adb -s %DEVICE_ID% shell "am start -a android.media.action.STILL_IMAGE_CAMERA -p !CAM_PKG!" >nul 2>&1

:: -- Verify camera is actually in foreground before shuttering --
echo  [*] Waiting for camera to open...
set "CAM_OPEN=0"
for /l %%W in (1,1,10) do (
    if "!CAM_OPEN!"=="0" (
        timeout /t 1 >nul
        adb -s %DEVICE_ID% shell "dumpsys window windows | grep mCurrentFocus" 2^>nul | findstr /i "!CAM_PKG!" >nul 2>&1
        if not errorlevel 1 set "CAM_OPEN=1"
    )
)
if "!CAM_OPEN!"=="0" (
    echo  [!] Camera did not open — aborting to avoid wrong photo.
    adb -s %DEVICE_ID% shell "rm /sdcard/.snap_marker" >nul 2>&1
    if "!SCREEN_WAS_OFF!"=="1" adb -s %DEVICE_ID% shell input keyevent 26 >nul 2>&1
    pause
    goto MODULE_PHONE_ACTIONS
)
echo  [+] Camera confirmed open. Stabilizing (3 sec)...
timeout /t 3 >nul

:: -- Fire shutter --
echo  [*] Sending shutter...
adb -s %DEVICE_ID% shell input keyevent 27 >nul 2>&1
timeout /t 1 >nul
adb -s %DEVICE_ID% shell input keyevent 24 >nul 2>&1
timeout /t 4 >nul

:: -- Close camera app --
adb -s %DEVICE_ID% shell input keyevent 3 >nul 2>&1

:: -- Locate new photo (timestamp-based, parentheses fix the -o precedence bug) --
echo  [*] Locating captured photo...
set "PHO_FILE="
for /f "tokens=*" %%a in ('adb -s %DEVICE_ID% shell "find /sdcard/DCIM -newer /sdcard/.snap_marker \( -name '*.jpg' -o -name '*.jpeg' \) 2^>/dev/null ^| head -1"') do set "PHO_FILE=%%a"
for /f "tokens=1" %%a in ("!PHO_FILE!") do set "PHO_FILE=%%a"
adb -s %DEVICE_ID% shell "rm /sdcard/.snap_marker" >nul 2>&1

if not "!PHO_FILE!"=="" (
    echo  [*] Pulling: !PHO_FILE!
    echo  -----------------------------------------------
    adb -s %DEVICE_ID% pull "!PHO_FILE!" Photos
    if not errorlevel 1 (
        adb -s %DEVICE_ID% shell rm "!PHO_FILE!" >nul 2>&1
        echo  -----------------------------------------------
        echo  [+] Photo saved to: %CD%\Photos\ and deleted from device.
        start "" explorer "%CD%\Photos"
    ) else (
        echo  [!] Pull failed. File still on device: !PHO_FILE!
    )
) else (
    echo  [!] No new photo found after marker. Shutter may have failed.
)
if "!SCREEN_WAS_OFF!"=="1" (
    echo  [*] Restoring screen to off...
    adb -s %DEVICE_ID% shell input keyevent 26 >nul 2>&1
)
pause
goto MODULE_PHONE_ACTIONS

:: ---- [7] CLICK SELFIE — FRONT CAMERA ----
:PA_PHOTO_FRONT
echo.
if not exist "Photos" mkdir "Photos"

:: -- Check if screen is currently off --
set "SCREEN_WAS_OFF=0"
for /f "tokens=*" %%a in ('adb -s %DEVICE_ID% shell "dumpsys power | grep mWakefulness=" 2^>nul') do set "WAKE_RAW=%%a"
echo !WAKE_RAW! | findstr /i "Asleep Dozing" >nul 2>&1
if not errorlevel 1 set "SCREEN_WAS_OFF=1"

if "!SCREEN_WAS_OFF!"=="1" (
    echo  [*] Screen is off — waking...
    adb -s %DEVICE_ID% shell input keyevent 26
    timeout /t 2 >nul
    :: FIX: reconnect using DEVICE_ID (IP:port), not the USB serial
    adb connect %DEVICE_ID% >nul 2>&1
    timeout /t 2 >nul
    adb -s %DEVICE_ID% shell input swipe 540 1600 540 800 300 >nul 2>&1
    timeout /t 1 >nul
)

:: -- Detect installed camera package (Windows-side findstr, NOT inside shell) --
echo  [*] Detecting camera package...
set "CAM_PKG="
for %%P in (com.miui.camera com.sec.android.app.camera com.oneplus.camera com.android.camera2 com.android.camera org.codeaurora.snapcam) do (
    if "!CAM_PKG!"=="" (
        adb -s %DEVICE_ID% shell pm list packages | findstr /i "%%P" >nul 2>&1
        if not errorlevel 1 set "CAM_PKG=%%P"
    )
)
if "!CAM_PKG!"=="" set "CAM_PKG=com.android.camera2"
echo  [*] Using: !CAM_PKG!

:: -- Grant camera permission to that package only --
adb -s %DEVICE_ID% shell pm grant !CAM_PKG! android.permission.CAMERA >nul 2>&1
adb -s %DEVICE_ID% shell appops set !CAM_PKG! CAMERA allow >nul 2>&1

:: -- Place timestamp marker BEFORE opening camera --
adb -s %DEVICE_ID% shell "touch /sdcard/.snap_marker" >nul 2>&1

:: -- Launch FRONT camera: force-stop first, then SELFIE intent to package --
echo  [*] Opening Front Camera (Selfie)...
adb -s %DEVICE_ID% shell "am force-stop !CAM_PKG!" >nul 2>&1
timeout /t 1 >nul
adb -s %DEVICE_ID% shell "am start -a android.media.action.SELFIE_STILL_IMAGE_CAMERA -p !CAM_PKG!" >nul 2>&1

:: -- Verify camera is in foreground before shuttering --
echo  [*] Waiting for camera to open...
set "CAM_OPEN=0"
for /l %%W in (1,1,10) do (
    if "!CAM_OPEN!"=="0" (
        timeout /t 1 >nul
        adb -s %DEVICE_ID% shell "dumpsys window windows | grep mCurrentFocus" 2^>nul | findstr /i "!CAM_PKG!" >nul 2>&1
        if not errorlevel 1 set "CAM_OPEN=1"
    )
)
if "!CAM_OPEN!"=="0" (
    echo  [!] Camera did not open — aborting to avoid wrong photo.
    adb -s %DEVICE_ID% shell "rm /sdcard/.snap_marker" >nul 2>&1
    if "!SCREEN_WAS_OFF!"=="1" adb -s %DEVICE_ID% shell input keyevent 26 >nul 2>&1
    pause
    goto MODULE_PHONE_ACTIONS
)
echo  [+] Camera confirmed open. Stabilizing (3 sec)...
timeout /t 3 >nul

:: -- Fire shutter --
echo  [*] Sending shutter...
adb -s %DEVICE_ID% shell input keyevent 27 >nul 2>&1
timeout /t 1 >nul
adb -s %DEVICE_ID% shell input keyevent 24 >nul 2>&1
timeout /t 4 >nul

:: -- Close camera --
adb -s %DEVICE_ID% shell input keyevent 3 >nul 2>&1

:: -- Locate new photo (parentheses fix -o precedence bug) --
echo  [*] Locating captured selfie...
set "PHO_FILE="
for /f "tokens=*" %%a in ('adb -s %DEVICE_ID% shell "find /sdcard/DCIM -newer /sdcard/.snap_marker \( -name '*.jpg' -o -name '*.jpeg' \) 2^>/dev/null ^| head -1"') do set "PHO_FILE=%%a"
for /f "tokens=1" %%a in ("!PHO_FILE!") do set "PHO_FILE=%%a"
adb -s %DEVICE_ID% shell "rm /sdcard/.snap_marker" >nul 2>&1

if not "!PHO_FILE!"=="" (
    echo  [*] Pulling: !PHO_FILE!
    echo  -----------------------------------------------
    adb -s %DEVICE_ID% pull "!PHO_FILE!" Photos
    if not errorlevel 1 (
        adb -s %DEVICE_ID% shell rm "!PHO_FILE!" >nul 2>&1
        echo  -----------------------------------------------
        echo  [+] Selfie saved to: %CD%\Photos\ and deleted from device.
        start "" explorer "%CD%\Photos"
    ) else (
        echo  [!] Pull failed. File still on device: !PHO_FILE!
    )
) else (
    echo  [!] No new photo found after marker. Shutter may have failed.
)
if "!SCREEN_WAS_OFF!"=="1" (
    echo  [*] Restoring screen to off...
    adb -s %DEVICE_ID% shell input keyevent 26 >nul 2>&1
)
pause
goto MODULE_PHONE_ACTIONS

:: =========================================================================
::  HELPER: DO_PULL
:: =========================================================================
:DO_PULL
set "REMOTE_PATH=%~1"
set "LOCAL_PATH=%~2"
if "%DEBUG_MODE%"=="1" echo [DEBUG] DO_PULL executing for: %REMOTE_PATH%
echo  [-] Checking: %REMOTE_PATH%
adb -s %DEVICE_ID% shell ls "%REMOTE_PATH%" >nul 2>&1
if errorlevel 1 (
    echo      [!] Not found. Skipping...
    set /a SKIPPED_COUNT+=1
) else (
    echo      [+] Found. Pulling...
    adb -s %DEVICE_ID% pull "%REMOTE_PATH%" "%LOCAL_PATH%" >nul 2>&1
    set /a SUCCESS_COUNT+=1
)
exit /b

:: =========================================================================
::  HELPER: UPDATE_CACHE
::  FIX: Duplicate-check now matches on the WIRELESS endpoint (column 3),
::       not on the USB serial, so re-pairing correctly updates the record.
:: =========================================================================
:UPDATE_CACHE
set "CACHE_IP=%~1"
set "CACHE_USB=%~2"
if "!CACHE_USB!"=="" set "CACHE_USB=!CACHE_IP!"

:: FIX: Check for duplicate on the wireless IP:port (3rd field), not USB serial
:: This prevents stale USB-serial entries from blocking the wireless entry
set "CACHE_DUPLICATE=0"
for /f "tokens=1,2,3 delims=|" %%a in (cache\devices.txt) do (
    if "%%c"=="!CACHE_IP!" set "CACHE_DUPLICATE=1"
)
if "!CACHE_DUPLICATE!"=="1" goto :EOF

set "FRIENDLY_NAME="
for /f "tokens=*" %%x in ('adb -s !CACHE_IP! shell getprop ro.product.model 2^>nul') do set "FRIENDLY_NAME=%%x"
if "!FRIENDLY_NAME!"=="" set "FRIENDLY_NAME=Device"

for /f "tokens=*" %%x in ('date /t') do set "CUR_DATE=%%x"
for /f "tokens=*" %%x in ('time /t') do set "CUR_TIME=%%x"

echo !CACHE_USB!^|!FRIENDLY_NAME!^|!CACHE_IP!^|!CUR_DATE! !CUR_TIME!>> "cache\devices.txt"
exit /b

:: =========================================================================
::  EXIT
:: =========================================================================
:EXIT_SCRIPT
echo.
echo  [*] Disconnecting all wireless ADB nodes...
adb disconnect
echo.
echo  -------------------------------------------------------
echo   Wireless ADB Controller  ^|  by Nani0p
echo   github.com/Navdeep0p
echo  -------------------------------------------------------
echo  [*] Goodbye.
timeout /t 2 >nul
goto :EOF
