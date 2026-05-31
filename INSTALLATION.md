# Installation Guide

Complete setup instructions for the Wireless ADB Controller.

---

## Prerequisites

### 1. Android Platform Tools (ADB)

The controller auto-detects ADB at launch. You only need to install it once.

**Option A — Android Studio (recommended if you develop Android apps)**

Install [Android Studio](https://developer.android.com/studio). Platform tools are included at:
```
%LOCALAPPDATA%\Android\Sdk\platform-tools\
```

**Option B — Standalone platform-tools**

1. Download from [developer.android.com/tools/releases/platform-tools](https://developer.android.com/tools/releases/platform-tools)
2. Extract the ZIP to a folder, e.g. `C:\platform-tools\`
3. Optionally add it to your system `PATH`:
   - Search "Environment Variables" → Edit system environment variables → Path → New → paste the folder path
   - After adding to PATH, open a new `cmd` window and run `adb version` to verify

If you skip adding to PATH, the auto-detection scan will find it in `C:\platform-tools\` or other common locations automatically.

### 2. scrcpy (for screen mirroring — Module 2 only)

1. Download the latest Windows release from [github.com/Genymobile/scrcpy/releases](https://github.com/Genymobile/scrcpy/releases)
2. Extract the ZIP into the same folder as `adbridge.bat`, or any folder on your `PATH`
3. Verify: `scrcpy --version`

If you do not plan to use screen mirroring, you can skip this step.

---

## Controller Setup

1. Download `adbridge.bat` from the [Releases](https://github.com/Navdeep0p/wireless-adb-controller/releases) page
2. Place it anywhere convenient — a dedicated folder is recommended (e.g. `C:\ADB-Controller\`)
3. Run it by double-clicking or from a command prompt:
   ```bat
   cd C:\ADB-Controller
   adbridge.bat
   ```

No installation, registry entries, or administrator rights required.

---

## Android Device Setup

### Enable Developer Options

1. Open **Settings** → **About Phone**
2. Tap **Build Number** seven times
3. You will see "You are now a developer!"

### Enable USB Debugging

1. Open **Settings** → **System** → **Developer Options**
2. Toggle **USB Debugging** on
3. Confirm the prompt that appears

### Verify ADB recognises your device

Connect via USB. Run `adb devices` in a command prompt — you should see your device serial number with the status `device`. If it shows `unauthorized`, unlock your phone and tap **Always allow from this computer** on the dialog that appears.

---

## First Connection (USB required — one time only)

1. Connect the Android device to your PC via USB
2. Run `adbridge.bat`
3. Select `[2] Connect a new device via USB cable`
4. The script lists USB-attached devices. Confirm the serial number matches your device and type or paste it
5. The script:
   - Scans for a free port (5555–5570) and calls `adb tcpip <port>`
   - Waits up to 15 seconds for the device to re-stabilise on TCP/IP
   - Extracts the device's Wi-Fi IP via DHCP properties (`getprop dhcp.wlan0.ipaddress`) or live interface state (`ip -4 addr show wlan0`)
   - Connects wirelessly and confirms the connection
6. When prompted, unplug the USB cable

> **Note:** If IP extraction fails automatically, the script will ask you to enter it manually. You can find your device's IP at Settings → About Phone → Status → IP Address.

---

## Subsequent Connections (wireless only)

1. Ensure the Android device is connected to the same Wi-Fi network as your PC
2. Run `adbridge.bat`
3. Select `[1] Use a cached connection listed above`
4. Enter the `IP:PORT` shown in the cached list (e.g. `192.168.1.42:5555`)

The script verifies the connection is alive before proceeding to the main menu.

---

## Agent Installation (`Remote.apk`)

The companion agent is optional but required for cloud-synced command execution.

1. Download `Remote.apk` from the [Releases](https://github.com/Navdeep0p/wireless-adb-controller/releases) page
2. Install via Module 3 (Ghost APK Sideloader) or manually:
   ```bat
   adb install Remote.apk
   ```
3. Launch **Android Agent** on the device once to grant necessary permissions
4. The agent starts automatically on reboot via the `RECEIVE_BOOT_COMPLETED` receiver

### Permissions requested at runtime

| Permission | Purpose |
|------------|---------|
| `POST_NOTIFICATIONS` | Status notifications (Android 13+) |
| `READ/WRITE_EXTERNAL_STORAGE` | File access for media operations |
| `ACCESS_FINE_LOCATION` | GPS coordinate access |
| `CAMERA` | Camera capture features |
| `RECORD_AUDIO` | Voice recording |
| `READ_PHONE_STATE` | Device state queries |
| `SYSTEM_ALERT_WINDOW` | Overlay for background operations |

---

## ADB Path — Manual Override

If auto-detection fails (unusual installation paths, corporate environments with restricted `where`), open `adbridge.bat` in a text editor and uncomment the override line in the configuration block at the top:

```bat
:: Leave empty to auto-detect. Set only if auto-detect fails:
set "ADB_PATH=C:\your\custom\path\to\platform-tools"
```

Save the file and run again. The script validates the path before proceeding.

---

## Troubleshooting

### "ADB not found automatically"
- Install platform-tools and add to PATH, or use the manual override (see above)
- Verify `adb.exe` exists in the folder you specified

### "Could not reach IP:PORT"
- Confirm both PC and Android device are on the same Wi-Fi network
- Check that USB Debugging is still enabled on the device
- Try reconnecting via USB (select `[2]`) to re-establish TCP/IP mode

### Device shows `unauthorized` in `adb devices`
- Unlock the device screen and accept the RSA fingerprint dialog
- If the dialog does not appear, revoke all ADB authorisations at Developer Options → Revoke USB Debugging Authorisations, then reconnect

### scrcpy fails to start
- Ensure `scrcpy.exe` is in the same folder as `adbridge.bat` or on your `PATH`
- Run `scrcpy --version` in a terminal to verify it is installed correctly

### GPS toggle shows "Mode 0" but GPS is visually on
- Android 10+ restricts `settings put secure location_mode`. Use Module 6 → `[2]` to open Location Settings on the device and toggle manually

### All ports 5555–5570 occupied
- The script automatically calls `adb disconnect` to clear stale sessions and retries from 5555
- If this persists, run `adb disconnect` manually in a terminal, then restart the script
