# ============================================================
#  TC IT TOOL v1.0 - Main Launcher
#  Run: .\TCITTool.ps1
# ============================================================

#Requires -Version 5.1
$ErrorActionPreference = "SilentlyContinue"

# ── Load Core ────────────────────────────────────────────────
$CorePath = Join-Path $PSScriptRoot "core"
. "$CorePath\Config.ps1"
. "$CorePath\AdminCheck.ps1"
. "$CorePath\Logger.ps1"
. "$CorePath\UI.ps1"

# ── Admin Elevation ──────────────────────────────────────────
Invoke-AdminElevation

# ── Load Modules ─────────────────────────────────────────────
$ModulesPath = Join-Path $PSScriptRoot "modules"
$moduleFiles = @(
    "SystemInfo.ps1",
    "HardwareInfo.ps1",
    "NetworkTools.ps1",
    "WindowsRepair.ps1",
    "SoftwareManagement.ps1",
    "PrinterTools.ps1",
    "UserManagement.ps1",
    "Security.ps1",
    "OfficeTools.ps1",
    "Reports.ps1",
    "Automation.ps1"
)

foreach ($mod in $moduleFiles) {
    $modPath = Join-Path $ModulesPath $mod
    if (Test-Path $modPath) {
        . $modPath
    }
}

# ── Main Menu ────────────────────────────────────────────────
$MainMenu = @(
    "System Information",
    "Hardware Information",
    "Network Tools",
    "Windows Repair",
    "Software Management",
    "Printer Tools",
    "User Management",
    "Security",
    "Office Tools",
    "Reports",
    "Automation"
)

# ── Menu Dispatch ─────────────────────────────────────────────
function Invoke-MenuOption {
    param([int]$Choice)
    switch ($Choice) {
        1  { if (Get-Command Show-SystemInfo      -EA SilentlyContinue) { Show-SystemInfo }      else { Write-Warn "Module not loaded yet." } }
        2  { if (Get-Command Show-HardwareInfo    -EA SilentlyContinue) { Show-HardwareInfo }    else { Write-Warn "Module not loaded yet." } }
        3  { if (Get-Command Show-NetworkTools    -EA SilentlyContinue) { Show-NetworkTools }    else { Write-Warn "Module not loaded yet." } }
        4  { if (Get-Command Show-WindowsRepair   -EA SilentlyContinue) { Show-WindowsRepair }   else { Write-Warn "Module not loaded yet." } }
        5  { if (Get-Command Show-SoftwareMgmt    -EA SilentlyContinue) { Show-SoftwareMgmt }    else { Write-Warn "Module not loaded yet." } }
        6  { if (Get-Command Show-PrinterTools    -EA SilentlyContinue) { Show-PrinterTools }    else { Write-Warn "Module not loaded yet." } }
        7  { if (Get-Command Show-UserManagement  -EA SilentlyContinue) { Show-UserManagement }  else { Write-Warn "Module not loaded yet." } }
        8  { if (Get-Command Show-Security        -EA SilentlyContinue) { Show-Security }        else { Write-Warn "Module not loaded yet." } }
        9  { if (Get-Command Show-OfficeTools     -EA SilentlyContinue) { Show-OfficeTools }     else { Write-Warn "Module not loaded yet." } }
        10 { if (Get-Command Show-Reports         -EA SilentlyContinue) { Show-Reports }         else { Write-Warn "Module not loaded yet." } }
        11 { if (Get-Command Show-Automation      -EA SilentlyContinue) { Show-Automation }      else { Write-Warn "Module not loaded yet." } }
    }
}

# ── Main Loop ────────────────────────────────────────────────
Write-Log -Command "Tool Launched" -Status "SUCCESS"

while ($true) {
    Show-Menu -Title "MAIN MENU" -Options $MainMenu

    Write-Host "    Enter Option: " -NoNewline -ForegroundColor $C.Warning
    $input = Read-Host

    if ($input -match "^\d+$") {
        $choice = [int]$input

        if ($choice -eq 0 -or $choice -eq 12) {
            Write-Host ""
            Write-Success "Exiting TC IT TOOL. Goodbye!"
            Write-Log -Command "Tool Exited" -Status "SUCCESS"
            Start-Sleep -Seconds 1
            exit
        }

        if ($choice -ge 1 -and $choice -le 11) {
            $start = Get-Date
            Invoke-MenuOption -Choice $choice
            $dur = [int]((Get-Date) - $start).TotalMilliseconds
            Write-Log -Command $MainMenu[$choice - 1] -Status "SUCCESS" -Duration $dur
            Pause-Screen
        } else {
            Write-Warn "Invalid option. Please enter 1-11 or 0 to exit."
            Start-Sleep -Seconds 1
        }
    } else {
        Write-Warn "Invalid input. Numbers only."
        Start-Sleep -Seconds 1
    }
}
