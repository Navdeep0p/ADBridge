# Contributing

Thank you for taking the time to contribute. This document covers how to report bugs, request features, and submit code changes.

---

## Before You Start

- Check the [existing issues](https://github.com/Navdeep0p/wireless-adb-controller/issues) to avoid duplicates
- For significant changes, open an issue first to discuss the approach before investing time in a pull request
- Keep changes focused: one fix or feature per pull request

---

## Reporting Bugs

Use the [Bug Report](.github/ISSUE_TEMPLATE/bug_report.md) template when opening an issue. Please include:

- **Windows version** (run `winver`)
- **ADB version** (`adb version`)
- **Android version and device model**
- **Exact steps to reproduce** — be specific about menu selections and inputs
- **What you expected to happen**
- **What actually happened** — include any error messages printed to the terminal
- **scrcpy version** if the issue is in Module 2

The more detail you provide, the faster the issue can be diagnosed.

---

## Requesting Features

Use the [Feature Request](.github/ISSUE_TEMPLATE/feature_request.md) template. Describe:

- The problem you are trying to solve (not just the solution)
- Any workarounds you currently use
- Whether you would be willing to implement it yourself

---

## Development Setup

### Controller (`adbridge.bat`)

No build step required. Open in any plain-text editor. Recommended: [VS Code](https://code.visualstudio.com/) with the [Batch Runner](https://marketplace.visualstudio.com/items?itemName=NilsSoderman.batch-runner) extension for syntax highlighting.

Testing requires a real Android device with USB Debugging enabled. There is no test harness for Batch scripts; manual testing against each affected module is expected.

### Agent (`Remote.apk`)

The agent is an Expo SDK 56 / React Native project.

```bash
# Install dependencies
npm install

# Start Metro bundler
npx expo start

# Build a local APK
npx expo run:android
# or
eas build --platform android --profile preview
```

Requires Node.js 18+, JDK 17, and Android SDK with API level 35 build tools.

---

## Code Style

### Batch script (`adbridge.bat`)

- Use `>nul 2>&1` for suppressing both stdout and stderr — never bare `2>nul`
- Use `!VARIABLE!` (delayed expansion) consistently inside code blocks; use `%VARIABLE%` at the top level where safe
- All `goto` labels are in `SCREAMING_SNAKE_CASE`
- Add a brief inline comment (`:: ...`) for any non-obvious logic
- Error paths must either show a message and `pause` or `timeout /t 2` before returning to a menu — never silently drop to an unexpected label

### Agent (React Native / TypeScript)

- TypeScript strict mode is expected
- Functional components and hooks only — no class components
- Keep platform-specific code in `.android.ts` / `.ios.ts` files where possible
- No inline styles — use `StyleSheet.create`

---

## Pull Request Process

1. Fork the repository and create a branch from `main`:
   ```bash
   git checkout -b fix/gps-toggle-crash
   ```
2. Make your changes. Keep commits small and descriptive:
   ```
   fix: initialise GPS_MODE before for/f loop to prevent empty-variable crash
   ```
3. Test manually on at least one Android device
4. Update `CHANGELOG.md` under the `[Unreleased]` section
5. Open a pull request against `main` with a clear title and description
6. Reference any related issues with `Closes #N` or `Fixes #N`

### Commit message format

```
<type>: <short description>

[optional body]
[optional footer]
```

Types: `fix`, `feat`, `docs`, `refactor`, `test`, `chore`

---

## What Not to Submit

- Hardcoded credentials, IP addresses, or personal paths
- Changes that break backward compatibility without strong justification
- Features that bypass device security in ways that exceed the stated scope of this tool
- Code that targets devices the submitter does not own or have authorisation for

---

## Questions

Open a [discussion](https://github.com/Navdeep0p/wireless-adb-controller/discussions) for general questions rather than issues. Issues are tracked for bugs and concrete feature requests only.
