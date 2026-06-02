# Security Policy

## Scope

This document covers the Wireless ADB Controller (`adbridge.bat`) and the companion Android agent (`Remote.apk`, package `com.nani0p.RemoteAgent`).

---

## Intended Use

This tool is designed for use on Android devices that you **own or have explicit written authorisation to manage**. It relies on Android Debug Bridge (ADB) in TCP/IP mode, which is a built-in Android developer feature that requires:

- Physical access to the device for initial setup
- USB Debugging to be manually enabled by the device owner
- Both devices to be on the same local network

**Using this tool against devices you do not own or have permission to control is illegal** under computer fraud and unauthorised access laws in most jurisdictions, including but not limited to the Computer Fraud and Abuse Act (US), the Computer Misuse Act (UK), and the Information Technology Act (India).

---

## Known Security Considerations

### ADB TCP/IP has no authentication

Once a device is in TCP/IP mode, **any device on the same local network can connect to it** via `adb connect`. ADB does not encrypt traffic and does not authenticate connections beyond the RSA key pairing done over USB.

**Mitigation:**
- Disable USB Debugging on your Android device when not actively using this tool (Developer Options → USB Debugging → off)
- Use this tool only on trusted, private networks (your home or personal hotspot)
- Never use this tool on public Wi-Fi

### Play Protect is temporarily disabled during APK installation

Module 3 sets `package_verifier_enable 0` immediately before installing an APK and restores it to `1` immediately after (including on error paths). This window is intentionally brief but exists.

**Mitigation:**
- Only sideload APKs from sources you trust and have verified
- Do not leave the installer prompt unattended during this window

### God Mode grants broad background permissions

Selecting God Mode in Module 3 grants `SYSTEM_ALERT_WINDOW`, `RUN_IN_BACKGROUND`, and `RUN_ANY_IN_BACKGROUND` to the installed package, and adds it to the device idle whitelist.

**Mitigation:**
- Only apply God Mode to your own applications
- Review the package name carefully before confirming

### Agent cloud communication

`Remote.apk` synchronises with a Vercel-hosted endpoint (`remote-backend-zeta.vercel.app`). All commands received from this endpoint are executed on the device. This endpoint is under the control of the repository owner.

**Mitigation:**
- If you are deploying this in a production or sensitive environment, host your own backend and rebuild the agent with your own endpoint
- Review the agent source before deploying

---

## Supported Versions

| Component | Supported |
|-----------|-----------|
| `adbridge.bat` (latest `main`) | Yes |
| `Remote.apk` v1.0.0 | Yes |
| Older releases | No — please update |

---

## Reporting a Vulnerability

If you discover a security vulnerability in this project, **please do not open a public GitHub issue.**

Report it privately by emailing:

**`security@[your-domain]`** *(replace with your actual contact before publishing)*

Or use [GitHub's private vulnerability reporting](https://github.com/Navdeep0p/wireless-adb-controller/security/advisories/new) if enabled on the repository.

### What to include

- A clear description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested remediation (optional but appreciated)

### Response commitment

- **Acknowledgement** within 72 hours
- **Status update** (confirmed, investigating, or not applicable) within 7 days
- **Fix or public disclosure** timeline communicated once the issue is confirmed

Responsible disclosures are credited in the release notes unless you prefer to remain anonymous.

---

## Out of Scope

The following are not considered security vulnerabilities for this project:

- ADB TCP/IP having no built-in authentication (this is an Android platform design decision)
- Theoretical attacks requiring physical device access beyond the initial USB pairing
- Vulnerabilities in ADB itself, scrcpy, Shizuku, or the Android operating system — please report those to their respective maintainers
