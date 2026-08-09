# TC IT TOOL v1.0

Windows IT Management Suite — a console-based PowerShell toolkit built for IT professionals to diagnose, repair, and manage Windows PCs quickly, without hunting through a dozen different utilities.

## Quick Start

Run in an **Administrator PowerShell** window:

```powershell
irm https://raw.githubusercontent.com/tejas-chandivakar/tc-it-tool/main/launch.ps1 | iex
```

This downloads the latest version fresh from GitHub and launches it — no installation required.

> **Note:** Always review scripts before running them, especially with elevated privileges. The full source is open in this repository.

## Features

- **System Information** — computer name, model, BIOS, Windows version/build, uptime, and more
- **Hardware Information** — CPU, RAM, disks, GPU, battery, monitors, USB/audio devices
- **Network Tools** — 14 utilities: IP/MAC info, ping, traceroute, DNS flush, speed test, adapter reset, and more
- **Windows Repair** — SFC, DISM, CHKDSK, Windows Update reset, cache/temp cleanup, service restarts
- **Software Management** — install, uninstall, search, and update software via Winget
- **Printer Tools** — list, add, remove printers, clear queue, restart spooler, print test page
- **User Management** — local users, password info, lock/log off/restart/shutdown
- **Security** — BitLocker, Windows Defender, Firewall, Secure Boot, and TPM status
- **Office Tools** — Outlook, Microsoft Teams, and OneDrive management
- **Reports** — generate full HTML, CSV, Excel, PDF, or laptop Battery reports, saved to a `TC IT TOOL Reports` folder on your Desktop
- **Automation** — bulk software install, PC auto-configuration, domain join, user creation, drive mapping

## Navigation

- **Arrow keys (Up/Down)** + **Enter** to select, **Esc** to go back
- Number keys also work as a fallback

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 or later
- Administrator privileges (the tool self-elevates if needed)
- Internet connection (for the online launcher and Winget-based features)

## Installation

### Online (recommended)

```powershell
irm https://raw.githubusercontent.com/tejas-chandivakar/tc-it-tool/main/launch.ps1 | iex
```

### Offline

1. Download or clone this repository
2. Open an Administrator PowerShell window in the project folder
3. Run:
   ```powershell
   .\TCITTool.ps1
   ```

If you see a "running scripts is disabled on this system" error, your machine's execution policy is blocking local scripts. Run this once in the same window, then try again:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```
This only affects the current PowerShell window — it does not change your system-wide security settings.

## Logging & Reports

- Every action is logged automatically with timestamp, command, status, and duration — useful for troubleshooting and audit trails (viewable from the Reports menu).
- Generated reports (HTML, CSV, Excel, PDF, Battery) are saved to a `TC IT TOOL Reports` folder on your Desktop, created automatically the first time you generate one.

## License

Free to use and modify.

## Author

Developed by **Tejas Chandivakar**
