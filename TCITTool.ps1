# ============================================================
#  TC IT TOOL v1.0 - Main Launcher
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

# UTF-8 Encoding
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding           = [System.Text.Encoding]::UTF8
    chcp 65001 | Out-Null
} catch {}

# Load Core
$CorePath = Join-Path $PSScriptRoot "core"
. "$CorePath\Config.ps1"
. "$CorePath\AdminCheck.ps1"
. "$CorePath\Logger.ps1"
. "$CorePath\UI.ps1"

# Admin Elevation
Invoke-AdminElevation -ScriptPath $MyInvocation.MyCommand.Path

# Console Setup
Set-ConsoleSetup

# Load Modules
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
    if (Test-Path $modPath) { . $modPath }
}

# Main Menu Items
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

function Invoke-MenuOption {
    param([int]$Choice)
    switch ($Choice) {
        1  { if (Get-Command Show-SystemInfo     -EA SilentlyContinue) { Show-SystemInfo }     else { Write-Warn "Module not loaded." } }
        2  { if (Get-Command Show-HardwareInfo   -EA SilentlyContinue) { Show-HardwareInfo }   else { Write-Warn "Module not loaded." } }
        3  { if (Get-Command Show-NetworkTools   -EA SilentlyContinue) { Show-NetworkTools }   else { Write-Warn "Module not loaded." } }
        4  { if (Get-Command Show-WindowsRepair  -EA SilentlyContinue) { Show-WindowsRepair }  else { Write-Warn "Module not loaded." } }
        5  { if (Get-Command Show-SoftwareMgmt   -EA SilentlyContinue) { Show-SoftwareMgmt }   else { Write-Warn "Module not loaded." } }
        6  { if (Get-Command Show-PrinterTools   -EA SilentlyContinue) { Show-PrinterTools }   else { Write-Warn "Module not loaded." } }
        7  { if (Get-Command Show-UserManagement -EA SilentlyContinue) { Show-UserManagement } else { Write-Warn "Module not loaded." } }
        8  { if (Get-Command Show-Security       -EA SilentlyContinue) { Show-Security }       else { Write-Warn "Module not loaded." } }
        9  { if (Get-Command Show-OfficeTools    -EA SilentlyContinue) { Show-OfficeTools }    else { Write-Warn "Module not loaded." } }
        10 { if (Get-Command Show-Reports        -EA SilentlyContinue) { Show-Reports }        else { Write-Warn "Module not loaded." } }
        11 { if (Get-Command Show-Automation     -EA SilentlyContinue) { Show-Automation }     else { Write-Warn "Module not loaded." } }
    }
}

function Show-Splash {
    Clear-Host
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "                    T C   I T   T O O L" -ForegroundColor Cyan
    Write-Host "                    ---------------------" -ForegroundColor DarkCyan
    Write-Host "                Windows IT Management Suite" -ForegroundColor Gray
    Write-Host "                     v$($Global:Config.Version) by Tejas" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "                    " -NoNewline
    Show-Spinner -Label "Loading modules..." -Seconds 2
    Write-Host ""
}

function Show-ExitScreen {
    Show-Header
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "              Thank you for using TC IT TOOL" -ForegroundColor Cyan
    Write-Host "                     Have a great day!" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-Host ""
}

# Main Execution
Write-Log -Command "Tool Launched" -Status "SUCCESS"
Show-Splash

$running = $true
while ($running) {
    Show-Menu -Title "MAIN MENU" -Options $MainMenu

    Write-Host ""
    Write-Host "    Enter Option: " -NoNewline -ForegroundColor Yellow
    $userInput = Read-Host

    $isNumber = $userInput -match "^\d+$"

    if ($isNumber) {
        $choice = [int]$userInput

        if ($choice -eq 0) {
            Show-ExitScreen
            Write-Log -Command "Tool Exited" -Status "SUCCESS"
            Start-Sleep -Seconds 1
            $running = $false
        }
        else {
            $valid = ($choice -ge 1) -and ($choice -le 11)
            if ($valid) {
                $start = Get-Date
                Invoke-MenuOption -Choice $choice
                $dur = [int]((Get-Date) - $start).TotalMilliseconds
                Write-Log -Command $MainMenu[$choice - 1] -Status "SUCCESS" -Duration $dur
                Pause-Screen
            }
            else {
                Write-Warn "Invalid option. Enter 1-11 or 0 to exit."
                Start-Sleep -Seconds 1
            }
        }
    }
    else {
        Write-Warn "Numbers only. Enter 1-11 or 0."
        Start-Sleep -Seconds 1
    }
}
