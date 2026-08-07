# ============================================================
#  TC IT TOOL - UI Engine
# ============================================================

# ── Colors ──────────────────────────────────────────────────
$C = @{
    Header  = "Cyan"
    Border  = "DarkCyan"
    Menu    = "White"
    Success = "Green"
    Error   = "Red"
    Warning = "Yellow"
    Info    = "Cyan"
    Dim     = "DarkGray"
    Input   = "White"
}

# ── Clear + Header ───────────────────────────────────────────
function Show-Header {
    param([string]$Title = "TC IT TOOL")
    Clear-Host
    $ver  = $Global:Config.Version
    $pc   = $env:COMPUTERNAME
    $user = $env:USERNAME
    $line = "=" * 50

    Write-Host ""
    Write-Host "  $line" -ForegroundColor $C.Border
    Write-Host "       $($Global:Config.ToolName) v$ver" -ForegroundColor $C.Header
    Write-Host "       Computer: $pc  |  User: $user" -ForegroundColor $C.Dim
    Write-Host "  $line" -ForegroundColor $C.Border
    Write-Host ""
}

# ── Section Title ────────────────────────────────────────────
function Show-Section {
    param([string]$Title)
    $line = "-" * 50
    Write-Host ""
    Write-Host "  $line" -ForegroundColor $C.Border
    Write-Host "    $Title" -ForegroundColor $C.Header
    Write-Host "  $line" -ForegroundColor $C.Border
    Write-Host ""
}

# ── Menu Box ─────────────────────────────────────────────────
function Show-Menu {
    param(
        [string]$Title,
        [string[]]$Options
    )
    Show-Header
    Show-Section $Title

    for ($i = 0; $i -lt $Options.Count; $i++) {
        $num = $i + 1
        Write-Host "    [" -NoNewline -ForegroundColor $C.Border
        Write-Host "$num" -NoNewline -ForegroundColor $C.Warning
        Write-Host "]  $($Options[$i])" -ForegroundColor $C.Menu
    }

    Write-Host ""
    Write-Host "    [" -NoNewline -ForegroundColor $C.Border
    Write-Host "0" -NoNewline -ForegroundColor $C.Error
    Write-Host "]  Back / Exit" -ForegroundColor $C.Dim
    Write-Host ""
}

# ── Info Row ─────────────────────────────────────────────────
function Write-Info {
    param([string]$Label, [string]$Value)
    Write-Host "    " -NoNewline
    Write-Host ("{0,-22}" -f $Label) -NoNewline -ForegroundColor $C.Dim
    Write-Host ": " -NoNewline -ForegroundColor $C.Border
    Write-Host $Value -ForegroundColor $C.Menu
}

# ── Status Messages ──────────────────────────────────────────
function Write-Success { param([string]$Msg)
    Write-Host "  [+] $Msg" -ForegroundColor $C.Success }

function Write-Fail    { param([string]$Msg)
    Write-Host "  [X] $Msg" -ForegroundColor $C.Error }

function Write-Warn    { param([string]$Msg)
    Write-Host "  [!] $Msg" -ForegroundColor $C.Warning }

function Write-Step    { param([string]$Msg)
    Write-Host "  [*] $Msg" -ForegroundColor $C.Info }

# ── Progress Bar ─────────────────────────────────────────────
function Show-Progress {
    param([string]$Label, [int]$Percent)
    $filled = [math]::Floor($Percent / 5)
    $empty  = 20 - $filled
    $bar    = ("█" * $filled) + ("░" * $empty)
    Write-Host "`r    $Label  [$bar] $Percent%" -NoNewline -ForegroundColor $C.Info
}

# ── Spinner ──────────────────────────────────────────────────
function Show-Spinner {
    param([string]$Label, [int]$Seconds = 2)
    $frames = @("|", "/", "-", "\")
    $end    = (Get-Date).AddSeconds($Seconds)
    $i      = 0
    while ((Get-Date) -lt $end) {
        Write-Host "`r    $($frames[$i % 4])  $Label   " -NoNewline -ForegroundColor $C.Info
        Start-Sleep -Milliseconds 120
        $i++
    }
    Write-Host "`r    $Label  Done.          " -ForegroundColor $C.Success
}

# ── Confirmation Dialog ───────────────────────────────────────
function Confirm-Action {
    param([string]$Message)
    Write-Host ""
    Write-Host "  [?] $Message" -ForegroundColor $C.Warning
    Write-Host "      [Y] Yes   [N] No" -ForegroundColor $C.Dim
    Write-Host ""
    $key = Read-Host "      Choice"
    return ($key -match "^[Yy]$")
}

# ── Pause ─────────────────────────────────────────────────────
function Pause-Screen {
    Write-Host ""
    Write-Host "  Press any key to continue..." -ForegroundColor $C.Dim
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ── Divider ───────────────────────────────────────────────────
function Write-Divider {
    Write-Host "  $("-" * 50)" -ForegroundColor $C.Border
}
