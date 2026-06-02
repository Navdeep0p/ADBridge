# Wireless ADB Controller

**A Windows-based ADB control suite with a companion Android agent, enabling wireless device management over a local Wi-Fi network.**

Built by [Navdeep Reddy](https://github.com/Navdeep0p) · MIT License

---

## Overview

Wireless ADB Controller is a two-component system: a Windows batch script (`ADBridge_V2.bat`) that drives Android Debug Bridge (ADB) over Wi-Fi, and a companion Android application (`Remote.apk`) that runs as a persistent background agent on the target device. Together they provide a menu-driven interface for remote control, screen mirroring, APK deployment, data pulling, automated screenshots, GPS management, navigation, phone call initiation, voice recording, and camera capture — all without physical USB access after initial pairing.

The controller auto-detects your ADB installation, maintains a local device cache for instant reconnection, and includes a background watcher mode that auto-converts newly plugged USB devices to wireless automatically.

---

## Architecture

```
┌─────────────────────────────┐        Wi-Fi LAN        ┌──────────────────────────┐
│     Windows Host             │◄───────────────────────►│   Android Device          │
│                              │                          │                           │
│  ADBridge_V2.bat             │   ADB over TCP/IP        │  ADB Daemon (adbd)        │
│  ├─ ADB auto-detection       │   port 5555              │                           │
│  ├─ Device cache system      │                          │  Remote.apk               │
│  ├─ Watcher mode (autostart) │◄── Vercel API sync ─────►│  └─ Background agent      │
│  ├─ Module 1: Keystroke      │                          │     (headless, boot-aware)│
│  ├─ Module 2: scrcpy mirror  │                          │                           │
│  ├─ Module 3: APK sideload   │                          │                           │
│  ├─ Module 4: Data Pulling   │                          │                           │
│  ├─ Module 5: Screenshots    │                          │                           │
│  ├─ Module 6: Shizuku        │                          │                           │
│  └─ Module 7: Phone actions  │                          │                           │
└─────────────────────────────┘                          └──────────────────────────┘
```

**Controller** (`ADBridge_V2.bat`) — pure Windows Batch, no external dependencies beyond ADB and optionally scrcpy.

**Agent** (`Remote.apk`) — React Native / Expo SDK 56, Hermes engine, `com.nani0p.RemoteAgent`. Runs as a headless background service, survives reboots via `RECEIVE_BOOT_COMPLETED`, and synchronises with the Vercel-hosted command endpoint.

---

## Features

### Controller (`ADBridge_V2.bat`)

| Module | Description |
|--------|-------------|
| **1 — Keystroke Injection** | Wake screen, power toggle, HOME/BACK/ENTER keys, text injection, URL launch, app launcher sub-menu |
| **2 — Screen Mirror** | Standard, high-performance (H.264, 8 Mbps, 60 fps), and audio-off profiles via scrcpy |
| **3 — Ghost APK Sideload** | Drag-and-drop install, temporary Play Protect bypass, optional elevated permissions (God Mode) |
| **4 — Data Pulling** | Pull images, videos, documents, downloads, WhatsApp media, or screenshots into organised `PulledData\` subdirectories |
| **5 — Screenshot Engine** | Configurable count and interval, sequential captures saved locally as `Screenshots\Capture_N.png` |
| **6 — Shizuku Installer** | Fetches latest release from GitHub, installs, and starts the Shizuku daemon over ADB |
| **7 — Phone Actions** | GPS toggle, Location Settings launch, Google Maps navigation (text or URL), direct/dialler phone call, voice recording, rear camera photo, front camera selfie |

Additional features available via command-line flags:

| Flag | Description |
|------|-------------|
| `--watcher` | Background daemon mode — polls for newly connected USB devices and auto-converts them to wireless |
| `--auto <ID>` | Headless auto-pairing; pass a USB serial or `IP:PORT` to connect without interactive prompts |

### Agent (`Remote.apk`)

- Persistent background engine, starts on device boot
- Polls command endpoint, executes hardware actions remotely
- Shizuku-aware for elevated privilege operations
- Requests: `INTERNET`, `WAKE_LOCK`, `RECEIVE_BOOT_COMPLETED`, `SYSTEM_ALERT_WINDOW`, `READ/WRITE_EXTERNAL_STORAGE`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `CAMERA`, `RECORD_AUDIO`, `READ_PHONE_STATE`, `VIBRATE`, `POST_NOTIFICATIONS`

---

## Requirements

### Windows Host

| Requirement | Notes |
|-------------|-------|
| Windows 10 / 11 | Batch scripting (`cmd.exe`) |
| [Android Platform Tools](https://developer.android.com/tools/releases/platform-tools) | Provides `adb.exe`. Auto-detected from PATH or common install locations |
| [scrcpy](https://github.com/Genymobile/scrcpy) | Required for Module 2 (Screen Mirror) and App Launcher live mirror only |
| USB cable | Required only for the initial pairing step; can be disconnected immediately after |

### Android Device

| Requirement | Notes |
|-------------|-------|
| Android 6.0+ (API 23) | Minimum supported |
| USB Debugging enabled | Settings → Developer Options → USB Debugging |
| Same Wi-Fi network | Both devices must be on the same LAN subnet |
| `Remote.apk` installed | Optional; required only for cloud-synced agent features |

---

## Installation

See [INSTALLATION.md](INSTALLATION.md) for a complete step-by-step guide.

**Quick start:**

```bat
:: 1. Download and place ADBridge_V2.bat anywhere on your PC
:: 2. Double-click ADBridge_V2.bat — ADB is auto-detected
:: 3. Connect your Android device via USB and enable USB Debugging
:: 4. The script auto-detects the USB device and converts it to wireless
:: 5. Unplug the USB cable when prompted — you will not need it again on the same network
```

### Auto-start Watcher (optional)

Run `install_autostart.bat` once to install a background watcher that starts with Windows and automatically pairs any USB device you plug in — no manual steps needed for future connections.

```bat
:: Run once to install
install_autostart.bat
```

This creates a VBScript entry in your Startup folder that silently launches `ADBridge_V2.bat --watcher` on login.

---

## Usage

### First-time connection (USB required)

1. Run `ADBridge_V2.bat`
2. Plug in your Android device via USB with USB Debugging enabled
3. The script automatically detects the device, reads its Wi-Fi IP, switches it to TCP/IP mode, and connects wirelessly — with up to 3 retry attempts
4. For HyperOS / MIUI devices: unplug the USB cable **before** the wireless connection attempt (the script will prompt you)
5. The device is saved to `cache\devices.txt` for instant reconnection in future sessions

### Subsequent connections (wireless only)

1. Run `ADBridge_V2.bat`
2. Cached devices are reconnected automatically on startup
3. If a single wireless device is found, it connects immediately and goes straight to the main menu
4. If multiple devices are detected, a selection menu is shown

### Device Cache

The script stores paired devices in `cache\devices.txt` (format: `USB_serial|model_name|IP:PORT|timestamp`). On every launch, all cached entries are attempted automatically — no manual input required for known devices.

### Module quick-reference

```
[1] Keystroke Injection / Remote Control
    ├─ Wake screen, power, HOME, BACK, ENTER
    ├─ Text injection
    ├─ Open URL in browser
    └─ App Launcher (YouTube, Chrome, Settings, WhatsApp, Instagram, Snapchat,
                     Rear Camera, Front Camera, custom package)
        └─ Each launch opens a live scrcpy mirror + optional continuous screenshots

[2] Wireless Screen Mirror (scrcpy)
    ├─ Standard
    ├─ High-performance (H.264 · 8 Mbps · 60 fps)
    └─ Screen only (audio on phone)

[3] Sideload / Install APK
    └─ Drag-and-drop APK → optional God Mode permissions

[4] Data Pulling
    ├─ Images      (/sdcard/DCIM, /sdcard/Pictures)
    ├─ Videos      (/sdcard/DCIM/Camera, /sdcard/Movies)
    ├─ Documents   (/sdcard/Documents)
    ├─ Downloads   (/sdcard/Download)
    ├─ WhatsApp    (/sdcard/Android/media/com.whatsapp/WhatsApp/Media)
    ├─ Screenshots (/sdcard/DCIM/Screenshots, /sdcard/Pictures/Screenshots)
    └─ Everything  (all of the above in one pass)

[5] Automated Screenshot Engine
    └─ Count + interval → Screenshots\Capture_N.png

[6] Install Shizuku Framework
    └─ Downloads latest APK from GitHub, installs, starts daemon

[7] Phone Actions
    ├─ Toggle GPS (reads current state, inverts)
    ├─ Open Location Settings on device
    ├─ Google Maps navigation (text query or URL)
    ├─ Direct phone call (falls back to dialler)
    ├─ Voice recording (opens recorder, captures audio, pulls to Recordings\)
    ├─ Rear camera photo (OEM-aware, timestamp-based pull to Photos\)
    └─ Front camera selfie (OEM-aware, timestamp-based pull to Photos\)
```

### Output locations

All output is saved relative to the `platform-tools` directory (where `ADBridge_V2.bat` runs):

| Type | Path |
|------|------|
| Screenshots | `Screenshots\Capture_N.png` |
| In-app screenshots | `Screenshots\<AppName>_N.png` |
| Pulled images | `PulledData\Images\` |
| Pulled videos | `PulledData\Videos\` |
| Pulled documents | `PulledData\Documents\` |
| Pulled downloads | `PulledData\Downloads\` |
| Pulled WhatsApp media | `PulledData\WhatsApp\` |
| Pulled screenshots | `PulledData\Screenshots\` |
| Recordings | `Recordings\` |
| Photos / Selfies | `Photos\` |

---

## ADB Path Detection

The script resolves `adb.exe` in four steps, stopping at the first success:

1. Manual override — uncomment and set `ADB_PATH` in the configuration block at the top of `ADBridge_V2.bat`
2. `where adb` — picks it up if platform-tools is already on `PATH`
3. Common install locations scan:
   - `%LOCALAPPDATA%\Android\Sdk\platform-tools`
   - `C:\platform-tools`
   - `C:\Android\platform-tools`
   - `%ProgramFiles%\Android\platform-tools`
   - `%ProgramFiles(x86)%\Android\platform-tools`
4. Interactive prompt — asks for the path and validates it before continuing

---

## Debug Mode

Set `DEBUG_MODE=1` in the configuration block at the top of `ADBridge_V2.bat` (enabled by default) to print diagnostic messages including device serial, IP resolution method, ADB connect output, and cache entries. Set to `0` to suppress all debug output for a clean interface.

---

## Known Limitations

- **Windows only.** The controller is a `.bat` file and requires `cmd.exe`.
- **Same-network only.** ADB TCP/IP does not traverse NAT by default; both devices must be on the same LAN subnet.
- **scrcpy not bundled.** You must install scrcpy separately for Module 2 and the App Launcher live mirror.
- **Android 10+ GPS toggle.** On Android 10 and above, `settings put secure location_mode` may require manual confirmation in the Location Settings UI due to system-level restrictions. Use option `[2]` in Module 7 to verify on-screen.
- **HyperOS / MIUI wireless pairing.** These devices block wireless ADB connections while USB is still attached. The script prompts you to unplug before attempting the wireless connection.
- **OEM camera variance.** Module 7 camera features probe for known camera packages across major OEMs (Xiaomi/MIUI, Samsung, OnePlus, AOSP, Qualcomm Snapdragon Camera). Unusual OEM camera packages may require manual intervention.

---

## Security Considerations

See [SECURITY.md](SECURITY.md) for the full security policy.

- **Use on your own devices only.** This tool requires USB Debugging and physical access for initial pairing. Using it on devices you do not own or have explicit authorisation for is illegal in most jurisdictions.
- **ADB TCP/IP has no authentication.** Any device on the same Wi-Fi network can connect to an open ADB port. Disable USB Debugging when not in use.
- **Play Protect is temporarily disabled** during APK installation (Module 3) and re-enabled immediately after. This is standard practice for sideloading; do not sideload APKs from untrusted sources.
- **God Mode permissions** (`SYSTEM_ALERT_WINDOW`, `RUN_IN_BACKGROUND`) are granted only on explicit confirmation.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on bug reports, feature requests, and pull requests.

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

---

## License

MIT License — see [LICENSE](LICENSE) for details.

```
Copyright (c) 2025 Navdeep Reddy
```

Free to use, modify, and distribute with attribution.
