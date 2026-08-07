# ============================================================
#  TC IT TOOL - UI Engine (Professional, ASCII-safe)
# ============================================================

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

function Set-ConsoleSetup {
    try {
        $Host.UI.RawUI.WindowTitle = "TC IT TOOL v$($Global:Config.Version)"
    } catch {}
    try {
        $w = $Host.UI.RawUI.WindowSize
        $w.Width  = 90
        $w.Height = 45
        $Host.UI.RawUI.WindowSize = $w

        $b = $Host.UI.RawUI.BufferSize
        $b.Width  = 90
        $b.Height = 3000
        $Host.UI.RawUI.BufferSize = $b
    } catch {}
}

function Get-Centered {
    param([string]$Text, [int]$Width = 84)
    $pad = [math]::Max(0, [math]::Floor(($Width - $Text.Length) / 2))
    return (" " * $pad) + $Text
}

function Show-Header {
    Clear-Host
    $ver   = $Global:Config.Version
    $pc    = $env:COMPUTERNAME
    $user  = $env:USERNAME
    $date  = Get-Date -Format "dd-MM-yyyy  HH:mm"

    Write-Host ""
    Write-Host "  ==========================================================================" -ForegroundColor $C.Border
    Write-Host (Get-Centered "TC IT TOOL  v$ver") -ForegroundColor $C.Header
    Write-Host (Get-Centered "Computer: $pc    User: $user") -ForegroundColor $C.Dim
    Write-Host (Get-Centered $date) -ForegroundColor $C.Dim
    Write-Host "  ==========================================================================" -ForegroundColor $C.Border
    Write-Host ""
}

function Show-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "  --------------------------------------------------------------------------" -ForegroundColor $C.Border
    Write-Host "    $($Title.ToUpper())" -ForegroundColor $C.Header
    Write-Host "  --------------------------------------------------------------------------" -ForegroundColor $C.Border
    Write-Host ""
}

function Show-Menu {
    param(
        [string]$Title,
        [string[]]$Options
    )
    Show-Header

    Write-Host "  +------------------------------------------------------------------------+" -ForegroundColor $C.Border
    Write-Host "  |" -NoNewline -ForegroundColor $C.Border
    Write-Host (Get-Centered $Title 72) -NoNewline -ForegroundColor $C.Header
    Write-Host "|" -ForegroundColor $C.Border
    Write-Host "  +------------------------------------------------------------------------+" -ForegroundColor $C.Border
    Write-Host "  |                                                                        |" -ForegroundColor $C.Border

    for ($i = 0; $i -lt $Options.Count; $i++) {
        $num = "{0,2}" -f ($i + 1)
        Write-Host "  |   [" -NoNewline -ForegroundColor $C.Border
        Write-Host $num -NoNewline -ForegroundColor $C.Number
        Write-Host "]  " -NoNewline -ForegroundColor $C.Border
        $text = $Options[$i]
        $pad  = 63 - $text.Length
        if ($pad -lt 0) { $pad = 0 }
        Write-Host $text -NoNewline -ForegroundColor $C.Menu
        Write-Host (" " * $pad) -NoNewline
        Write-Host "|" -ForegroundColor $C.Border
    }

    Write-Host "  |                                                                        |" -ForegroundColor $C.Border
    Write-Host "  +------------------------------------------------------------------------+" -ForegroundColor $C.Border
    Write-Host "  |   [ 0]  " -NoNewline -ForegroundColor $C.Border
    Write-Host "Exit / Back                                                    " -NoNewline -ForegroundColor $C.Dim
    Write-Host "|" -ForegroundColor $C.Border
    Write-Host "  +------------------------------------------------------------------------+" -ForegroundColor $C.Border

    Write-Host ""
    Write-Host "     Logs: view via [10] Reports > View Today's Logs" -ForegroundColor $C.Dim
}

function Write-Info {
    param([string]$Label, [string]$Value)
    Write-Host "    " -NoNewline
    Write-Host ("{0,-24}" -f $Label) -NoNewline -ForegroundColor $C.Dim
    Write-Host " : " -NoNewline -ForegroundColor $C.Border
    Write-Host $Value -ForegroundColor $C.Menu
}

function Write-Success { param([string]$Msg) Write-Host "  [+] $Msg" -ForegroundColor $C.Success }
function Write-Fail    { param([string]$Msg) Write-Host "  [X] $Msg" -ForegroundColor $C.Error }
function Write-Warn    { param([string]$Msg) Write-Host "  [!] $Msg" -ForegroundColor $C.Warning }
function Write-Step    { param([string]$Msg) Write-Host "  [*] $Msg" -ForegroundColor $C.Info }

function Show-Progress {
    param([string]$Label, [int]$Percent)
    $filled = [math]::Floor($Percent / 5)
    $empty  = 20 - $filled
    $bar    = ("#" * $filled) + ("-" * $empty)
    Write-Host "`r    $Label  [$bar] $Percent%" -NoNewline -ForegroundColor $C.Info
}

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
    Write-Host "`r  [+] $Label - Done.               " -ForegroundColor $C.Success
}

function Confirm-Action {
    param([string]$Message)
    Write-Host ""
    Write-Host "  +----------------------------------------------------+" -ForegroundColor $C.Warning
    Write-Host "  |  [?] $Message" -ForegroundColor $C.Warning
    Write-Host "  |      [Y] Yes     [N] No" -ForegroundColor $C.Dim
    Write-Host "  +----------------------------------------------------+" -ForegroundColor $C.Warning
    Write-Host ""
    $key = Read-Host "      Choice"
    return ($key -match "^[Yy]$")
}

function Pause-Screen {
    Write-Host ""
    Write-Host "  --------------------------------------------------------------------------" -ForegroundColor $C.Border
    Write-Host "  Press any key to return to menu..." -ForegroundColor $C.Dim
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Write-Divider {
    Write-Host "    ------------------------------------------------------------" -ForegroundColor $C.Border
}
