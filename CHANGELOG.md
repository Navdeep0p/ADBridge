# Changelog

All notable changes to this project are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).  
This project uses [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

### Planned
- Module 6: Voice recording — auto-save to laptop
- Module 6: Rear camera photo capture — timestamp-based pull
- Module 6: Front camera (selfie) capture
- Multi-device session management (connect several devices simultaneously)

---

## [1.1.0] — 2025

### Added
- **ADB auto-detection** (4-tier cascade): checks manually configured path → `PATH` environment variable → six common install locations → interactive prompt. Removes the hardcoded path that broke the script for all users except the original author.
- **Port collision resolution loop**: scans ports 5555–5570 in order and assigns the first one not in use. Replaces the previous 3-line chain that silently re-used 5557 if all three initial ports were occupied.
- **Credits and attribution** embedded in all section headers, exit screen, and file header block.
- **Module 6 under-development guard**: options 5 (Voice Record), 6 (Rear Photo), and 7 (Selfie) now display a clear `[UNDER DEVELOPMENT]` label and a redirect message instead of jumping to incomplete code.
- **ADB_PATH override in config block**: power users can set a custom path in one place at the top of the file; auto-detection skips if a valid manual path is provided.

### Fixed
- **Module 6, Option 1 (GPS Toggle) crash**: `GPS_MODE` and `GPS_RAW` were uninitialized before the `for /f` loop. An empty result from `adb shell` left the variables undefined, causing the subsequent `if` comparison to fail unpredictably. Added `set "GPS_MODE=0"` and `set "GPS_RAW="` initializers as safe defaults.
- **Module 6, Option 1 redirect style**: `adb shell settings put` calls used bare `2>nul` (stderr only) instead of `>nul 2>&1` (both streams), allowing stdout to print during silent operations. Corrected across all six GPS toggle commands.
- **Module 6, Option 2 (Location Settings) crash**: missing `errorlevel 1` guard after the `am start` call. If the intent failed (device disconnected, ADB daemon restarted), the script fell through silently. Added a guard that prints an error message and pauses before returning to the menu.
- **Title bar `^` character**: `title` does not interpret `^` as an escape character — it was appearing literally as `^|` in the window title bar. Removed the escape character from the `title` line only (all `echo` lines correctly retain `^|`, `^&`, `^>` as required).
- **Output path display**: `%ADB_PATH%\Screenshots`, `%ADB_PATH%\Photos`, and `%ADB_PATH%\Recordings` in all output confirmation messages replaced with `%CD%`, which correctly reflects the working directory after `cd /d` and works regardless of how ADB was detected.

### Changed
- Configuration block updated: hardcoded `ADB_PATH` removed and replaced with a commented-out template line.
- `DO NOT EDIT BELOW THIS LINE` section now contains the full auto-detection block.

---

## [1.0.0] — 2025

### Initial release

- **Two-stage connection**: USB-based TCP/IP pairing (Stage 1) and cached wireless reconnection (Stage 2)
- **Auto port assignment**: 5555 → 5556 → 5557 (3-port chain, replaced in v1.1.0)
- **Device IP extraction**: dual-method (DHCP properties and live interface state) with subnet mask and carriage-return stripping, regex sanity check, and manual fallback
- **Module 1 — Keystroke Injection**: wake, power, HOME, BACK, ENTER, text inject, URL open, app launcher sub-menu (YouTube, Chrome, Settings, WhatsApp, Instagram, Snapchat, front/rear camera, custom package)
- **Module 2 — scrcpy Screen Mirror**: standard, high-performance (H.264 · 8 Mbps · 60 fps), screen-only profiles
- **Module 3 — Ghost APK Sideloader**: Play Protect bypass window, reinstall flag, optional God Mode (`SYSTEM_ALERT_WINDOW`, `RUN_IN_BACKGROUND`, `RUN_ANY_IN_BACKGROUND`, device idle whitelist)
- **Module 4 — Screenshot Engine**: configurable count and interval, sequential PNG saves; in-app continuous mode tied to scrcpy process lifecycle
- **Module 5 — Shizuku Installer**: PowerShell GitHub API fetch for latest release APK, install, daemon start
- **Module 6 — Phone Actions**: GPS toggle (location_mode + providers_allowed), Location Settings launch, Google Maps navigation (text and URL), direct phone call with dialler fallback
- **Companion Agent** (`Remote.apk`): React Native / Expo SDK 56, Hermes engine, `com.navdeepreddy.RemoteAgent`, background engine with boot receiver, Vercel command endpoint sync, Shizuku integration
