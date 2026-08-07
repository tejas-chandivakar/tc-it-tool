# ============================================================
#  TC IT TOOL v1.0 - Online Launcher
#  Usage: irm https://raw.githubusercontent.com/tejas-chandivakar/tc-it-tool/main/launch.ps1 | iex
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

# UTF-8 Encoding
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 | Out-Null
} catch {}

# Config
$TOOL_NAME    = "TC IT TOOL"
$TOOL_VERSION = "1.0.0"
$GITHUB_USER  = "tejas-chandivakar"
$GITHUB_REPO  = "tc-it-tool"
$GITHUB_BRANCH= "main"
$INSTALL_DIR  = "$env:TEMP\TCITTool"

$RAW_BASE = "https://cdn.jsdelivr.net/gh/$GITHUB_USER/$GITHUB_REPO@$GITHUB_BRANCH"

$FILES = @(
    "TCITTool.ps1",
    "core/Config.ps1",
    "core/AdminCheck.ps1",
    "core/Logger.ps1",
    "core/UI.ps1",
    "modules/SystemInfo.ps1",
    "modules/HardwareInfo.ps1",
    "modules/NetworkTools.ps1",
    "modules/WindowsRepair.ps1",
    "modules/SoftwareManagement.ps1",
    "modules/PrinterTools.ps1",
    "modules/UserManagement.ps1",
    "modules/Security.ps1",
    "modules/OfficeTools.ps1",
    "modules/Reports.ps1",
    "modules/Automation.ps1"
)

function cWrite {
    param([string]$Text, [string]$Color = "White", [switch]$NoNewline)
    if ($NoNewline) { Write-Host $Text -ForegroundColor $Color -NoNewline }
    else            { Write-Host $Text -ForegroundColor $Color }
}

function Show-Banner {
    Clear-Host
    cWrite ""
    cWrite "  ================================================================" "DarkCyan"
    cWrite ""
    cWrite "                     T C   I T   T O O L" "Cyan"
    cWrite "                     ---------------------" "DarkCyan"
    cWrite "                 Windows IT Management Suite" "Gray"
    cWrite "                        v$TOOL_VERSION by Tejas" "DarkGray"
    cWrite ""
    cWrite "  ================================================================" "DarkCyan"
    cWrite ""
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Elevate {
    if (-not (Test-Admin)) {
        cWrite "  [!] Requires Administrator. Relaunching..." "Yellow"
        Start-Sleep -Seconds 1
        $cmd = "irm $RAW_BASE/launch.ps1 | iex"
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`"" -Verb RunAs
        exit
    }
}

function Test-Internet {
    try {
        $r = Invoke-WebRequest -Uri "https://raw.githubusercontent.com" -UseBasicParsing -TimeoutSec 5
        return $r.StatusCode -eq 200
    } catch {
        return $false
    }
}

function Get-LatestVersion {
    try {
        $url = "$RAW_BASE/version.txt"
        $ver = (Invoke-RestMethod -Uri $url -TimeoutSec 5).Trim()
        return $ver
    } catch {
        return $null
    }
}

function Get-ToolFile {
    param([string]$RelativePath)
    $bust     = Get-Random
    $url      = "$RAW_BASE/$($RelativePath -replace '\\', '/')?nocache=$bust"
    $destPath = Join-Path $INSTALL_DIR $RelativePath
    $destDir  = Split-Path $destPath -Parent

    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    }

    try {
        $headers = @{ "Cache-Control" = "no-cache"; "Pragma" = "no-cache" }
        Invoke-WebRequest -Uri $url -OutFile $destPath -UseBasicParsing -TimeoutSec 15 -Headers $headers
        return $true
    } catch {
        return $false
    }
}

function Show-DownloadProgress {
    param([int]$Current, [int]$Total, [string]$FileName)
    $pct    = [math]::Floor(($Current / $Total) * 100)
    $filled = [math]::Floor($pct / 5)
    $empty  = 20 - $filled
    $bar    = ("#" * $filled) + ("-" * $empty)
    $short  = $FileName
    if ($short.Length -gt 35) { $short = $short.Substring(0,35) }
    Write-Host "`r  [$bar] $pct%  $($short.PadRight(35))" -NoNewline -ForegroundColor Cyan
}

# ==============================================================
#  MAIN
# ==============================================================

Show-Banner

# Step 1 - Admin
cWrite "  [1/4] Checking privileges..." "DarkGray"
Invoke-Elevate
cWrite "  [OK] Running as Administrator" "Green"

# Step 2 - Internet
cWrite "  [2/4] Checking internet connection..." "DarkGray"
if (-not (Test-Internet)) {
    cWrite ""
    cWrite "  [X] No internet connection detected." "Red"
    cWrite ""
    Read-Host "  Press Enter to exit"
    exit 1
}
cWrite "  [OK] Internet connection OK" "Green"

# Step 3 - Version Check
cWrite "  [3/4] Checking for latest version..." "DarkGray"
$latest = Get-LatestVersion
if ($latest) {
    if ($latest -eq $TOOL_VERSION) {
        cWrite "  [OK] You have the latest version (v$TOOL_VERSION)" "Green"
    } else {
        cWrite "  [!] New version available: v$latest  (current: v$TOOL_VERSION)" "Yellow"
    }
} else {
    cWrite "  [~] Version check skipped" "DarkGray"
}

# Step 4 - Download (fresh)
cWrite "  [4/4] Downloading TC IT TOOL files (fresh)..." "DarkGray"
if (Test-Path $INSTALL_DIR) {
    Remove-Item $INSTALL_DIR -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null
cWrite ""

$total   = $FILES.Count
$current = 0
$failed  = @()

foreach ($file in $FILES) {
    $current++
    Show-DownloadProgress -Current $current -Total $total -FileName $file
    $ok = Get-ToolFile -RelativePath $file
    if (-not $ok) { $failed += $file }
}

Write-Host ""
cWrite ""

if ($failed.Count -gt 0) {
    cWrite "  [X] Failed to download:" "Red"
    $failed | ForEach-Object { cWrite "      - $_" "Red" }
    cWrite ""
    Read-Host "  Press Enter to exit"
    exit 1
}

cWrite "  [OK] All files downloaded successfully" "Green"
cWrite ""

# Launch
cWrite "  ================================================================" "DarkCyan"
cWrite "   Launching $TOOL_NAME..." "Cyan"
cWrite "  ================================================================" "DarkCyan"
cWrite ""
Start-Sleep -Milliseconds 800

$mainScript = Join-Path $INSTALL_DIR "TCITTool.ps1"

if (Test-Path $mainScript) {
    try {
        & $mainScript
    } catch {
        cWrite ""
        cWrite "  [X] ERROR: $($_.Exception.Message)" "Red"
        cWrite "  Line: $($_.InvocationInfo.ScriptLineNumber)" "Yellow"
        cWrite ""
        Read-Host "  Press Enter to close"
    }
} else {
    cWrite "  [X] TCITTool.ps1 not found at $mainScript" "Red"
    Read-Host "  Press Enter to exit"
    exit 1
}
