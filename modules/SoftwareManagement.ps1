# ============================================================
#  TC IT TOOL - Software Management
# ============================================================

function Show-SoftwareMgmt {
    $opts = @(
        "Installed Software List",
        "Install Software (Winget)",
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
            3 { SW-Uninstall }
            4 { SW-Search }
            5 { SW-Upgrade }
            6 { SW-UpdateAll }
            7 { SW-Export }
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
