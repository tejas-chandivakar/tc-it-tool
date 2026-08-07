# ============================================================
#  TC IT TOOL - UI Engine (Professional)
# ============================================================

# ── Colors ──────────────────────────────────────────────────
$C = @{
    Header  = "Cyan"
    Border  = "DarkCyan"
    Menu    = "White"
    Number  = "Yellow"
    Success = "Green"
    Error   = "Red"
    Warning = "Yellow"
    Info    = "Cyan"
    Dim     = "DarkGray"
    Input   = "White"
    Footer  = "DarkCyan"
}

# ── Console Setup ─────────────────────────────────────────────
function Set-ConsoleSetup {
    $Host.UI.RawUI.WindowTitle = "TC IT TOOL v$($Global:Config.Version)"
    try {
        $w = $Host.UI.RawUI.WindowSize
        $w.Width  = 80
        $w.Height = 45
        $Host.UI.RawUI.WindowSize = $w

        $b = $Host.UI.RawUI.BufferSize
        $b.Width = 80
        $Host.UI.RawUI.BufferSize = $b
    } catch {}
}

# ── Center Text ───────────────────────────────────────────────
function Get-Centered {
    param([string]$Text, [int]$Width = 76)
    $pad = [math]::Max(0, [math]::Floor(($Width - $Text.Length) / 2))
    return (" " * $pad) + $Text
}

# ── Box Line ──────────────────────────────────────────────────
function Write-BoxTop    { Write-Host "  ╔$("═" * 74)╗" -ForegroundColor $C.Border }
function Write-BoxBottom { Write-Host "  ╚$("═" * 74)╝" -ForegroundColor $C.Border }
function Write-BoxMid    { Write-Host "  ╠$("═" * 74)╣" -ForegroundColor $C.Border }
function Write-BoxLine   {
    param([string]$Text = "", [string]$Color = "White")
    $padded = $Text.PadRight(74)
    Write-Host "  ║" -NoNewline -ForegroundColor $C.Border
    Write-Host $padded -NoNewline -ForegroundColor $Color
    Write-Host "║" -ForegroundColor $C.Border
}
function Write-BoxEmpty  { Write-BoxLine "" }

# ── Header ────────────────────────────────────────────────────
function Show-Header {
    Clear-Host
    $ver   = $Global:Config.Version
    $pc    = $env:COMPUTERNAME
    $user  = $env:USERNAME
    $date  = Get-Date -Format "dd-MM-yyyy  HH:mm"

    Write-Host ""
    Write-BoxTop
    Write-BoxLine (Get-Centered "TC IT TOOL  v$ver") $C.Header
    Write-BoxLine (Get-Centered "Computer: $pc   |   User: $user") $C.Dim
    Write-BoxLine (Get-Centered $date) $C.Dim
    Write-BoxBottom
    Write-Host ""
}

# ── Section Title ────────────────────────────────────────────
function Show-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "  ╔$("═" * 74)╗" -ForegroundColor $C.Border
    Write-Host "  ║" -NoNewline -ForegroundColor $C.Border
    Write-Host (" " + $Title.ToUpper().PadRight(73)) -NoNewline -ForegroundColor $C.Header
    Write-Host "║" -ForegroundColor $C.Border
    Write-Host "  ╚$("═" * 74)╝" -ForegroundColor $C.Border
    Write-Host ""
}

# ── Main Menu Box ─────────────────────────────────────────────
function Show-Menu {
    param(
        [string]$Title,
        [string[]]$Options
    )
    Show-Header

    # Title bar
    Write-Host "  ╔$("═" * 74)╗" -ForegroundColor $C.Border
    Write-Host "  ║" -NoNewline -ForegroundColor $C.Border
    Write-Host (Get-Centered $Title 74).PadRight(74) -NoNewline -ForegroundColor $C.Header
    Write-Host "║" -ForegroundColor $C.Border
    Write-Host "  ╠$("═" * 74)╣" -ForegroundColor $C.Border

    Write-BoxEmpty

    # Menu items
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $num  = "{0,2}" -f ($i + 1)
        $line = "   [$num]  $($Options[$i])"
        Write-Host "  ║" -NoNewline -ForegroundColor $C.Border
        Write-Host "   [" -NoNewline -ForegroundColor $C.Dim
        Write-Host ("{0,2}" -f ($i+1)) -NoNewline -ForegroundColor $C.Number
        Write-Host "]  " -NoNewline -ForegroundColor $C.Dim
        Write-Host $Options[$i].PadRight(66) -NoNewline -ForegroundColor $C.Menu
        Write-Host "║" -ForegroundColor $C.Border
    }

    Write-BoxEmpty
    Write-Host "  ╠$("═" * 74)╣" -ForegroundColor $C.Border

    # Exit row
    Write-Host "  ║" -NoNewline -ForegroundColor $C.Border
    Write-Host "   [" -NoNewline -ForegroundColor $C.Dim
    Write-Host " 0" -NoNewline -ForegroundColor $C.Error
    Write-Host "]  " -NoNewline -ForegroundColor $C.Dim
    Write-Host "Back / Exit".PadRight(66) -NoNewline -ForegroundColor $C.Dim
    Write-Host "║" -ForegroundColor $C.Border

    Write-BoxEmpty
    Write-Host "  ╚$("═" * 74)╝" -ForegroundColor $C.Border

    # Footer
    Show-Footer
    Write-Host ""
}

# ── Footer ────────────────────────────────────────────────────
function Show-Footer {
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " CTRL+L: Logs " -NoNewline -ForegroundColor $C.Dim
    Write-Host "│" -NoNewline -ForegroundColor $C.Border
    Write-Host " CTRL+R: Report " -NoNewline -ForegroundColor $C.Dim
    Write-Host "│" -NoNewline -ForegroundColor $C.Border
    Write-Host " 0: Exit " -ForegroundColor $C.Dim
}

# ── Info Row ─────────────────────────────────────────────────
function Write-Info {
    param([string]$Label, [string]$Value)
    Write-Host "    " -NoNewline
    Write-Host ("{0,-24}" -f $Label) -NoNewline -ForegroundColor $C.Dim
    Write-Host " : " -NoNewline -ForegroundColor $C.Border
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
    $frames = @("⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏")
    $end    = (Get-Date).AddSeconds($Seconds)
    $i      = 0
    while ((Get-Date) -lt $end) {
        Write-Host "`r    $($frames[$i % $frames.Count])  $Label   " -NoNewline -ForegroundColor $C.Info
        Start-Sleep -Milliseconds 100
        $i++
    }
    Write-Host "`r  [+] $Label — Done.          " -ForegroundColor $C.Success
}

# ── Confirmation Dialog ───────────────────────────────────────
function Confirm-Action {
    param([string]$Message)
    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────┐" -ForegroundColor $C.Warning
    Write-Host "  │  [?] $($Message.PadRight(37))│" -ForegroundColor $C.Warning
    Write-Host "  │      [Y] Yes        [N] No              │" -ForegroundColor $C.Dim
    Write-Host "  └─────────────────────────────────────────┘" -ForegroundColor $C.Warning
    Write-Host ""
    $key = Read-Host "      Choice"
    return ($key -match "^[Yy]$")
}

# ── Pause ─────────────────────────────────────────────────────
function Pause-Screen {
    Write-Host ""
    Write-Host "  $("─" * 50)" -ForegroundColor $C.Border
    Write-Host "  Press any key to return to menu..." -ForegroundColor $C.Dim
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ── Divider ───────────────────────────────────────────────────
function Write-Divider {
    Write-Host "    $("─" * 60)" -ForegroundColor $C.Border
}
