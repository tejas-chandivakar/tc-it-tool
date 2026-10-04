# ============================================================
#  TC IT TOOL - Software Management
# ============================================================

function Show-SoftwareMgmt {
    $opts = @(
        "Installed Software List",
        "Install Software (Winget)",
        "Multi-Select Install (Checklist)",
        "Uninstall Software",
        "Winget Search",
        "Winget Upgrade (Single)",
        "Update All Software",
        "Export Installed Software"
    )

    while ($true) {
        $sel = Show-Menu -Title "SOFTWARE MANAGEMENT" -Options $opts

        switch ($sel) {
            1 { SW-ListInstalled }
            2 { SW-Install }
            3 { SW-MultiInstall }
            4 { SW-Uninstall }
            5 { SW-Search }
            6 { SW-Upgrade }
            7 { SW-UpdateAll }
            8 { SW-Export }
            0 { return }
        }
        Pause-Screen
    }
}

function SW-ListInstalled {
    Show-Section "INSTALLED SOFTWARE"
    Write-Step "Fetching installed software..."
    $apps = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
                             "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName } |
            Select-Object DisplayName, DisplayVersion, Publisher |
            Sort-Object DisplayName

    $i = 1
    $apps | ForEach-Object {
        Write-Host ("    {0,-3}. {1,-45} {2}" -f $i, $_.DisplayName, $_.DisplayVersion) -ForegroundColor White
        $i++
    }
    Write-Host ""
    Write-Info "Total" "$($apps.Count) applications installed"
    Write-Log -Command "List Installed Software" -Status "SUCCESS"
}

function SW-MultiInstall {
    # App catalog: IsHeader = category row (not selectable)
    $catalog = @(
        [PSCustomObject]@{ IsHeader=$true;  Label="-- BROWSERS --";          Id="" }
        [PSCustomObject]@{ IsHeader=$false; Label="Google Chrome";            Id="Google.Chrome" }
        [PSCustomObject]@{ IsHeader=$false; Label="Mozilla Firefox";          Id="Mozilla.Firefox" }
        [PSCustomObject]@{ IsHeader=$true;  Label="-- COMMUNICATION --";      Id="" }
        [PSCustomObject]@{ IsHeader=$false; Label="Microsoft Teams";          Id="Microsoft.Teams" }
        [PSCustomObject]@{ IsHeader=$false; Label="Zoom";                     Id="Zoom.Zoom" }
        [PSCustomObject]@{ IsHeader=$false; Label="WhatsApp";                 Id="WhatsApp.WhatsApp" }
        [PSCustomObject]@{ IsHeader=$true;  Label="-- PRODUCTIVITY --";       Id="" }
        [PSCustomObject]@{ IsHeader=$false; Label="7-Zip";                    Id="7zip.7zip" }
        [PSCustomObject]@{ IsHeader=$false; Label="Adobe Acrobat Reader";     Id="Adobe.Acrobat.Reader.64-bit" }
        [PSCustomObject]@{ IsHeader=$false; Label="Notepad++";                Id="Notepad++.Notepad++" }
        [PSCustomObject]@{ IsHeader=$false; Label="WinRAR";                   Id="RARLab.WinRAR" }
        [PSCustomObject]@{ IsHeader=$true;  Label="-- DEVELOPMENT --";        Id="" }
        [PSCustomObject]@{ IsHeader=$false; Label="VS Code";                  Id="Microsoft.VisualStudioCode" }
        [PSCustomObject]@{ IsHeader=$false; Label="Git";                      Id="Git.Git" }
        [PSCustomObject]@{ IsHeader=$false; Label="Node.js LTS";              Id="OpenJS.NodeJS.LTS" }
        [PSCustomObject]@{ IsHeader=$false; Label="Python";                   Id="Python.Python.3" }
        [PSCustomObject]@{ IsHeader=$true;  Label="-- REMOTE / IT TOOLS --";  Id="" }
        [PSCustomObject]@{ IsHeader=$false; Label="AnyDesk";                  Id="AnyDesk.AnyDesk" }
        [PSCustomObject]@{ IsHeader=$false; Label="Remote Desktop Client";    Id="Microsoft.RemoteDesktopClient" }
        [PSCustomObject]@{ IsHeader=$false; Label="Microsoft PowerToys";      Id="Microsoft.PowerToys" }
        [PSCustomObject]@{ IsHeader=$true;  Label="-- MEDIA / CLOUD --";      Id="" }
        [PSCustomObject]@{ IsHeader=$false; Label="VLC Media Player";         Id="VideoLAN.VLC" }
        [PSCustomObject]@{ IsHeader=$false; Label="Google Drive";             Id="Google.GoogleDrive" }
    )

    # checked state array (parallel to $catalog)
    $checked = @($false) * $catalog.Count

    # selectable indices only
    $selectableIdx = @()
    for ($i = 0; $i -lt $catalog.Count; $i++) {
        if (-not $catalog[$i].IsHeader) { $selectableIdx += $i }
    }

    $cursor = $selectableIdx[0]  # current highlighted row (catalog index)

    try { [Console]::CursorVisible = $false } catch {}
    $homePos = $null

    $done = $false
    while (-not $done) {
        # --- draw (no Write-HeaderBlock here - keeps line count under 40) ---
        if ($null -eq $homePos) {
            Clear-Host
            $homePos = $Host.UI.RawUI.CursorPosition
        } else {
            try { $Host.UI.RawUI.CursorPosition = $homePos }
            catch { Clear-Host; $homePos = $Host.UI.RawUI.CursorPosition }
        }

        # Compact title row (1 line only)
        Write-Host ("  TC IT TOOL  |  MULTI-SELECT INSTALL  |  Space: Toggle  Enter: Install  Esc: Back").PadRight(120) -ForegroundColor Cyan
        Write-Host ("  " + ("-" * 68)).PadRight(120) -ForegroundColor DarkGray

        for ($i = 0; $i -lt $catalog.Count; $i++) {
            $item = $catalog[$i]
            if ($item.IsHeader) {
                Write-Host ("  {0,-70}" -f "") -ForegroundColor DarkGray
                Write-Host ("    {0,-66}" -f $item.Label) -ForegroundColor DarkYellow
            } else {
                $box = if ($checked[$i]) { "[x]" } else { "[ ]" }
                $line = "    $box  $($item.Label)"
                if ($i -eq $cursor) {
                    Write-Host ("{0,-72}" -f $line) -ForegroundColor Black -BackgroundColor Cyan
                } else {
                    $fg = if ($checked[$i]) { "Green" } else { "White" }
                    Write-Host ("{0,-72}" -f $line) -ForegroundColor $fg
                }
            }
        }

        $selCount = ($checked | Where-Object { $_ }).Count
        Write-Host ("  " + ("-" * 68)).PadRight(120) -ForegroundColor DarkGray
        $statusLine = "  Selected: $selCount app(s)"
        Write-Host ("{0,-72}" -f $statusLine) -ForegroundColor $(if ($selCount -gt 0) { "Green" } else { "Gray" })

        # --- input ---
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        $vk  = $key.VirtualKeyCode
        $ch  = $key.Character

        if ($vk -eq 38) {
            # Up
            $pos = [Array]::IndexOf($selectableIdx, $cursor)
            if ($pos -gt 0) { $cursor = $selectableIdx[$pos - 1] }
        } elseif ($vk -eq 40) {
            # Down
            $pos = [Array]::IndexOf($selectableIdx, $cursor)
            if ($pos -lt ($selectableIdx.Count - 1)) { $cursor = $selectableIdx[$pos + 1] }
        } elseif ($ch -eq ' ') {
            # Space - toggle
            $checked[$cursor] = -not $checked[$cursor]
        } elseif ($vk -eq 13) {
            # Enter - install
            $done = $true
        } elseif ($vk -eq 27 -or $vk -eq 8) {
            # Esc / Backspace - back
            try { [Console]::CursorVisible = $true } catch {}
            return
        }
    }

    try { [Console]::CursorVisible = $true } catch {}

    # Collect selected
    $toInstall = @()
    for ($i = 0; $i -lt $catalog.Count; $i++) {
        if ($checked[$i] -and -not $catalog[$i].IsHeader) {
            $toInstall += $catalog[$i]
        }
    }

    if ($toInstall.Count -eq 0) {
        Clear-Host
        Write-HeaderBlock
        Show-Section "MULTI-SELECT INSTALL"
        Write-Warn "No apps selected. Returning to menu."
        return
    }

    Clear-Host
    Write-HeaderBlock
    Show-Section "MULTI-SELECT INSTALL"

    Write-Host "    Apps to install:" -ForegroundColor $C.Dim
    $toInstall | ForEach-Object { Write-Host "      - $($_.Label)" -ForegroundColor White }
    Write-Host ""

    if (Confirm-Action "Install $($toInstall.Count) selected app(s) via Winget?") {
        $idx     = 1
        $passed  = 0
        $failed  = 0
        foreach ($app in $toInstall) {
            Write-Step "[$idx/$($toInstall.Count)] Installing $($app.Label)..."
            $start  = Get-Date
            $output = winget install --id $app.Id --accept-source-agreements --accept-package-agreements -e --silent 2>&1
            $exitC  = $LASTEXITCODE
            $dur    = [int]((Get-Date) - $start).TotalMilliseconds
            if ($exitC -eq 0 -or ($output -join "") -match "Successfully installed") {
                Write-Success "$($app.Label) installed  (${dur}ms)"
                Write-Log -Command "Multi-Install $($app.Id)" -Status "SUCCESS" -Duration $dur
                $passed++
            } else {
                $errMsg = ($output | Where-Object { $_ -match "0x|error|fail|Forbidden" } | Select-Object -First 1)
                Write-Fail "$($app.Label) FAILED — $errMsg"
                Write-Log -Command "Multi-Install $($app.Id)" -Status "FAILED" -Error "$errMsg"
                $failed++
            }
            $idx++
        }
        Write-Host ""
        if ($failed -eq 0) {
            Write-Success "All $passed installation(s) complete."
        } else {
            Write-Warn "$passed installed, $failed failed. Check logs for details."
        }
    }
}

function SW-Install {
    Show-Section "INSTALL SOFTWARE"
    Write-Host "    Winget App ID (e.g. Google.Chrome): " -NoNewline -ForegroundColor $C.Warning
    $appId = Read-Host
    if (-not $appId) { Write-Warn "No app ID entered."; return }

    if (Confirm-Action "Install '$appId' via Winget?") {
        Write-Step "Installing $appId..."
        $start = Get-Date
        winget install --id $appId --accept-source-agreements --accept-package-agreements -e 2>&1 |
            ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
        $dur = [int]((Get-Date) - $start).TotalMilliseconds
        Write-Success "Install command completed."
        Write-Log -Command "Install $appId" -Status "SUCCESS" -Duration $dur
    }
}

function SW-Uninstall {
    Show-Section "UNINSTALL SOFTWARE"
    Write-Host "    App name to uninstall: " -NoNewline -ForegroundColor $C.Warning
    $name = Read-Host
    if (-not $name) { Write-Warn "No name entered."; return }

    if (Confirm-Action "Uninstall '$name' via Winget?") {
        Write-Step "Uninstalling $name..."
        winget uninstall --name $name --accept-source-agreements -e 2>&1 |
            ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
        Write-Success "Uninstall command completed."
        Write-Log -Command "Uninstall $name" -Status "SUCCESS"
    }
}

function SW-Search {
    Show-Section "WINGET SEARCH"
    Write-Host "    Search: " -NoNewline -ForegroundColor $C.Warning
    $query = Read-Host
    if (-not $query) { Write-Warn "No query entered."; return }

    Write-Step "Searching for '$query'..."
    winget search $query 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor White }
    Write-Log -Command "Winget Search $query" -Status "SUCCESS"
}

function SW-Upgrade {
    Show-Section "WINGET UPGRADE (SINGLE)"
    Write-Host "    App ID to upgrade: " -NoNewline -ForegroundColor $C.Warning
    $appId = Read-Host
    if (-not $appId) { Write-Warn "No app ID entered."; return }

    Write-Step "Upgrading $appId..."
    winget upgrade --id $appId --accept-source-agreements --accept-package-agreements -e 2>&1 |
        ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    Write-Success "Upgrade complete."
    Write-Log -Command "Upgrade $appId" -Status "SUCCESS"
}

function SW-UpdateAll {
    Show-Section "UPDATE ALL SOFTWARE"
    if (Confirm-Action "Update ALL installed software via Winget?") {
        Write-Step "Updating all packages..."
        $start = Get-Date
        winget upgrade --all --accept-source-agreements --accept-package-agreements 2>&1 |
            ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
        $dur = [int]((Get-Date) - $start).TotalMilliseconds
        Write-Success "All updates complete."
        Write-Log -Command "Update All Software" -Status "SUCCESS" -Duration $dur
    }
}

function SW-Export {
    Show-Section "EXPORT INSTALLED SOFTWARE"
    $outPath = "$($Global:Config.ReportDir)\InstalledSoftware_$env:COMPUTERNAME_$(Get-Date -Format 'yyyyMMdd').csv"

    Write-Step "Exporting software list..."
    $apps = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
                             "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName } |
            Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
            Sort-Object DisplayName

    $apps | Export-Csv -Path $outPath -NoTypeInformation -Encoding UTF8
    Write-Success "Exported to: $outPath"
    Write-Log -Command "Export Software List" -Status "SUCCESS"
}
