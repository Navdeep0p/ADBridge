# Wireless ADB Controller

**A Windows-based ADB control suite with a companion Android agent, enabling wireless device management over a local Wi-Fi network.**

Built by [Navdeep Reddy](https://github.com/Navdeep0p) · MIT License

---

## Overview

Wireless ADB Controller is a two-component system: a Windows batch script (`adbridge.bat`) that drives Android Debug Bridge (ADB) over Wi-Fi, and a companion Android application (`Remote.apk`) that runs as a persistent background agent on the target device. Together they provide a menu-driven interface for remote control, screen mirroring, APK deployment, automated screenshots, GPS management, navigation, and phone call initiation — all without physical USB access after initial pairing.

The controller auto-detects your ADB installation, handles port collisions across up to 16 simultaneous connections, and stores output (screenshots, recordings, photos) in organised subdirectories next to the script.

---

## Architecture

```
┌─────────────────────────────┐        Wi-Fi LAN        ┌──────────────────────────┐
│     Windows Host             │◄───────────────────────►│   Android Device          │
│                              │                          │                           │
│  adbridge.bat                  │   ADB over TCP/IP        │  ADB Daemon (adbd)        │
│  ├─ ADB auto-detection       │   ports 5555–5570        │                           │
│  ├─ Module 1: Keystroke      │                          │  Remote.apk               │
│  ├─ Module 2: scrcpy mirror  │◄── Vercel API sync ─────►│  └─ Background agent      │
│  ├─ Module 3: APK sideload   │                          │     (headless, boot-aware)│
│  ├─ Module 4: Screenshots    │                          │                           │
│  ├─ Module 5: Shizuku        │                          │                           │
│  └─ Module 6: Phone actions  │                          │                           │
└─────────────────────────────┘                          └──────────────────────────┘
```

**Controller** (`adbridge.bat`) — pure Windows Batch, no external dependencies beyond ADB and optionally scrcpy.

**Agent** (`Remote.apk`) — React Native / Expo SDK 56, Hermes engine, `com.navdeepreddy.RemoteAgent`. Runs as a headless background service, survives reboots via `RECEIVE_BOOT_COMPLETED`, and synchronises with the Vercel-hosted command endpoint.

---

## Features

### Controller (`adbridge.bat`)

| Module | Description |
|--------|-------------|
| **1 — Keystroke Injection** | Wake screen, power toggle, HOME/BACK/ENTER keys, text injection, URL launch, app launcher sub-menu |
| **2 — Screen Mirror** | Standard, high-performance (H.264, 8 Mbps, 60 fps), and audio-off profiles via scrcpy |
| **3 — Ghost APK Sideload** | Drag-and-drop install, temporary Play Protect bypass, optional elevated permissions (God Mode) |
| **4 — Screenshot Engine** | Configurable count and interval, sequential captures saved locally as `Screenshots\Capture_N.png` |
| **5 — Shizuku Installer** | Fetches latest release from GitHub, installs, and starts the Shizuku daemon over ADB |
| **6 — Phone Actions** | GPS toggle (reads current mode, inverts it), Location Settings launch, Google Maps navigation (text or URL), direct/dialler phone call |

Additional features under active development in Module 6: voice recording, rear camera capture, front camera (selfie) capture.

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
| [scrcpy](https://github.com/Genymobile/scrcpy) | Required for Module 2 (Screen Mirror) only |
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
:: 1. Download and place adbridge.bat anywhere on your PC
:: 2. Double-click adbridge.bat — ADB is auto-detected
:: 3. Connect your Android device via USB and enable USB Debugging
:: 4. Select [2] to discover the device, then unplug USB
:: 5. All future sessions use [1] (cached wireless connection)
```

---

## Usage

### First-time connection (USB required)

1. Run `adbridge.bat`
2. Select `[2] Connect a new device via USB cable`
3. Confirm the serial number shown matches your device
4. The script switches the device to TCP/IP mode, extracts its Wi-Fi IP, and connects wirelessly
5. Unplug the USB cable when prompted — you will not need it again on the same network

### Subsequent connections (wireless only)

1. Run `adbridge.bat`
2. Select `[1] Use a cached connection listed above`
3. Enter the `IP:PORT` shown (e.g., `192.168.1.42:5555`)

### Module quick-reference

```
[1] Keystroke Injection / Remote Control
    ├─ Wake screen, power, HOME, BACK, ENTER
    ├─ Text injection
    ├─ Open URL in browser
    └─ App Launcher (YouTube, Chrome, WhatsApp, Instagram, Snapchat, Camera, custom)

[2] Wireless Screen Mirror (scrcpy)
    ├─ Standard
    ├─ High-performance (H.264 · 8 Mbps · 60 fps)
    └─ Screen only (audio on phone)

[3] Sideload / Install APK
    └─ Drag-and-drop APK → optional God Mode permissions

[4] Automated Screenshot Engine
    └─ Count + interval → Screenshots\Capture_N.png

[5] Install Shizuku Framework
    └─ Downloads latest APK from GitHub, installs, starts daemon

[6] Phone Actions
    ├─ Toggle GPS (reads current state, inverts)
    ├─ Open Location Settings on device
    ├─ Google Maps navigation (text query or URL)
    ├─ Direct phone call (falls back to dialler)
    ├─ [UNDER DEVELOPMENT] Voice recording
    ├─ [UNDER DEVELOPMENT] Rear camera photo
    └─ [UNDER DEVELOPMENT] Front camera selfie
```

### Output locations

All output is saved relative to the `platform-tools` directory (where `adbridge.bat` runs):

| Type | Path |
|------|------|
| Screenshots | `Screenshots\Capture_N.png` |
| In-app screenshots | `Screenshots\<AppName>_N.png` |
| Recordings | `Recordings\` |
| Photos / Selfies | `Photos\` |

---

## ADB Path Detection

The script resolves `adb.exe` in four steps, stopping at the first success:

1. Manual override — uncomment and set `ADB_PATH` in the configuration block at the top of `adbridge.bat`
2. `where adb` — picks it up if platform-tools is already on `PATH`
3. Common install locations scan:
   - `%LOCALAPPDATA%\Android\Sdk\platform-tools`
   - `C:\platform-tools`
   - `C:\Android\platform-tools`
   - `%ProgramFiles%\Android\platform-tools`
   - `%ProgramFiles(x86)%\Android\platform-tools`
4. Interactive prompt — asks for the path and validates it before continuing

---

## Port Management

ADB wireless connections use TCP ports starting at 5555. The script scans ports 5555–5570 in order and assigns the first one not already listed in `adb devices`. If all 16 ports are occupied, stale sessions are disconnected with `adb disconnect` and the scan restarts from 5555.

---

## Known Limitations

- **Windows only.** The controller is a `.bat` file and requires `cmd.exe`.
- **Same-network only.** ADB TCP/IP does not traverse NAT by default; both devices must be on the same LAN subnet.
- **scrcpy not bundled.** You must install scrcpy separately for Module 2.
- **Android 10+ GPS toggle.** On Android 10 and above, `settings put secure location_mode` may require manual confirmation in the Location Settings UI due to system-level restrictions. Use option `[2]` to verify.
- **OEM camera variance.** Module 6 camera features (under development) probe for known camera packages across major OEMs (Xiaomi/MIUI, Samsung, OnePlus, AOSP, Qualcomm Snapdragon Camera). Unusual OEM camera packages may require manual intervention.

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
