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
        # Buffer must be set >= window size, so widen buffer first
        $b = $Host.UI.RawUI.BufferSize
        $b.Width  = 120
        $b.Height = 3000
        $Host.UI.RawUI.BufferSize = $b

        $w = $Host.UI.RawUI.WindowSize
        $w.Width  = 120
        $w.Height = 40
        $Host.UI.RawUI.WindowSize = $w
    } catch {}
}

function Get-Centered {
    param([string]$Text, [int]$Width = 84)
    $pad = [math]::Max(0, [math]::Floor(($Width - $Text.Length) / 2))
    return (" " * $pad) + $Text
}

function Write-HeaderBlock {
    $ver   = $Global:Config.Version
    $pc    = $env:COMPUTERNAME
    $user  = $env:USERNAME
    $date  = Get-Date -Format "dd-MM-yyyy  HH:mm"

    Write-Host ""
    Write-Host "  ==========================================================================" -ForegroundColor $C.Border
    Write-Host (Get-Centered "TC IT TOOL  v$ver").PadRight(78) -ForegroundColor $C.Header
    Write-Host (Get-Centered "Computer: $pc    User: $user").PadRight(78) -ForegroundColor $C.Dim
    Write-Host (Get-Centered $date).PadRight(78) -ForegroundColor $C.Dim
    Write-Host "  ==========================================================================" -ForegroundColor $C.Border
    Write-Host ""
}

function Show-Header {
    Clear-Host
    Write-HeaderBlock
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

    $exitIndex = $Options.Count
    $selected  = 0
    $useArrows = $true
    $homePos   = $null

    try { [Console]::CursorVisible = $false } catch {}

    try {
    while ($true) {
        if ($null -eq $homePos) {
            Clear-Host
            $homePos = $Host.UI.RawUI.CursorPosition
        } else {
            try { $Host.UI.RawUI.CursorPosition = $homePos } catch { Clear-Host; $homePos = $Host.UI.RawUI.CursorPosition }
        }

        Write-HeaderBlock

        Write-Host "  +------------------------------------------------------------------------+" -ForegroundColor $C.Border
        Write-Host "  |" -NoNewline -ForegroundColor $C.Border
        Write-Host (Get-Centered $Title 72).PadRight(72) -NoNewline -ForegroundColor $C.Header
        Write-Host "|" -ForegroundColor $C.Border
        Write-Host "  +------------------------------------------------------------------------+" -ForegroundColor $C.Border
        Write-Host "  |                                                                        |" -ForegroundColor $C.Border

        for ($i = 0; $i -lt $Options.Count; $i++) {
            $num    = "{0,2}" -f ($i + 1)
            $isSel  = ($i -eq $selected)
            $marker = if ($isSel) { ">" } else { " " }
            $body   = " $marker [$num]  $($Options[$i])"
            $body   = $body.PadRight(72)
            if ($body.Length -gt 72) { $body = $body.Substring(0, 72) }

            Write-Host "  |" -NoNewline -ForegroundColor $C.Border
            if ($isSel) {
                Write-Host $body -NoNewline -ForegroundColor Black -BackgroundColor Cyan
            } else {
                Write-Host $body -NoNewline -ForegroundColor $C.Menu
            }
            Write-Host "|" -ForegroundColor $C.Border
        }

        Write-Host "  |                                                                        |" -ForegroundColor $C.Border
        Write-Host "  +------------------------------------------------------------------------+" -ForegroundColor $C.Border

        $exitSel  = ($selected -eq $exitIndex)
        $marker   = if ($exitSel) { ">" } else { " " }
        $exitBody = " $marker [ 0]  Exit / Back"
        $exitBody = $exitBody.PadRight(72)
        Write-Host "  |" -NoNewline -ForegroundColor $C.Border
        if ($exitSel) {
            Write-Host $exitBody -NoNewline -ForegroundColor Black -BackgroundColor Cyan
        } else {
            Write-Host $exitBody -NoNewline -ForegroundColor $C.Dim
        }
        Write-Host "|" -ForegroundColor $C.Border
        Write-Host "  +------------------------------------------------------------------------+" -ForegroundColor $C.Border

        Write-Host ""
        if ($useArrows) {
            Write-Host "     Up/Down: Move    Enter: Select    Esc: Back    (numbers also work)".PadRight(78) -ForegroundColor $C.Dim
        } else {
            Write-Host "     Enter option number, then press Enter:".PadRight(78) -ForegroundColor $C.Dim
        }

        if ($useArrows) {
            try {
                $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            } catch {
                $useArrows = $false
                try { [Console]::CursorVisible = $true } catch {}
                continue
            }

            switch ($key.VirtualKeyCode) {
                38 { $selected--; if ($selected -lt 0) { $selected = $exitIndex } }
                40 { $selected++; if ($selected -gt $exitIndex) { $selected = 0 } }
                13 { if ($selected -eq $exitIndex) { return 0 } else { return $selected + 1 } }
                27 { return 0 }
                8  { return 0 }
                default {
                    if ($key.Character -match '^[0-9]$') {
                        $n = [int]"$($key.Character)"
                        if ($n -eq 0) { return 0 }
                        elseif ($n -ge 1 -and $n -le $Options.Count) { return $n }
                    }
                }
            }
        } else {
            Write-Host "    Enter Option: " -NoNewline -ForegroundColor $C.Number
            $manual = Read-Host
            if ($manual -match "^\d+$") {
                $n = [int]$manual
                if ($n -eq 0) { return 0 }
                elseif ($n -ge 1 -and $n -le $Options.Count) { return $n }
            }
            Write-Warn "Invalid option."
            Start-Sleep -Milliseconds 800
        }
    }
    } finally {
        try { [Console]::CursorVisible = $true } catch {}
    }
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
