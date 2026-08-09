# ============================================================
#  TC IT TOOL - Office Tools
# ============================================================

function Show-OfficeTools {
    $opts = @(
        "Outlook",
        "Microsoft Teams",
        "OneDrive"
    )

    while ($true) {
        $sel = Show-Menu -Title "OFFICE TOOLS" -Options $opts

        switch ($sel) {
            1 { Office-Outlook }
            2 { Office-Teams }
            3 { Office-OneDrive }
            0 { return }
        }
        Pause-Screen
    }
}

function Office-Outlook {
    Show-Section "OUTLOOK"

    # Check if installed
    $outlookPaths = @(
        "$env:ProgramFiles\Microsoft Office\root\Office16\OUTLOOK.EXE",
        "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16\OUTLOOK.EXE",
        "$env:ProgramFiles\Microsoft Office\Office16\OUTLOOK.EXE",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OUTLOOK.EXE"
    )
    $outlookExe = $outlookPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($outlookExe) {
        $ver = (Get-Item $outlookExe).VersionInfo.FileVersion
        Write-Info "Outlook Path"    $outlookExe
        Write-Info "Version"         $ver
        Write-Host ""

        Write-Host "    [1] Open Outlook" -ForegroundColor White
        Write-Host "    [2] Check Outlook Processes" -ForegroundColor White
        Write-Host "    [3] Restart Outlook" -ForegroundColor White
        Write-Host ""
        Write-Host "    Choice: " -NoNewline -ForegroundColor $C.Warning
        $choice = Read-Host

        switch ($choice) {
            "1" {
                Write-Step "Launching Outlook..."
                Start-Process $outlookExe
                Write-Success "Outlook launched."
                Write-Log -Command "Open Outlook" -Status "SUCCESS"
            }
            "2" {
                $proc = Get-Process -Name OUTLOOK -ErrorAction SilentlyContinue
                if ($proc) {
                    Write-Info "Process ID" $proc.Id
                    Write-Info "Memory"     "$([math]::Round($proc.WorkingSet64 / 1MB, 0)) MB"
                    Write-Info "Status"     "Running"
                } else {
                    Write-Warn "Outlook is not currently running."
                }
                Write-Log -Command "Check Outlook Process" -Status "SUCCESS"
            }
            "3" {
                Stop-Process -Name OUTLOOK -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                Start-Process $outlookExe
                Write-Success "Outlook restarted."
                Write-Log -Command "Restart Outlook" -Status "SUCCESS"
            }
        }
    } else {
        Write-Warn "Outlook not found on this PC."
        Write-Host ""
        Write-Host "    [1] Open Outlook (Microsoft Store / New)" -ForegroundColor White
        Write-Host "    Choice: " -NoNewline -ForegroundColor $C.Warning
        $choice = Read-Host
        if ($choice -eq "1") {
            Start-Process "ms-outlook:"
            Write-Log -Command "Open Outlook (Store)" -Status "SUCCESS"
        }
    }
}

function Office-Teams {
    Show-Section "MICROSOFT TEAMS"

    $teamsPaths = @(
        "$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe",
        "$env:ProgramFiles\Microsoft\Teams\current\Teams.exe",
        "$env:ProgramFiles (x86)\Microsoft\Teams\current\Teams.exe"
    )
    $teamsExe = $teamsPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($teamsExe) {
        $ver = (Get-Item $teamsExe).VersionInfo.FileVersion
        Write-Info "Teams Path"    $teamsExe
        Write-Info "Version"       $ver
        Write-Host ""
    } else {
        Write-Warn "Classic Teams not found. Checking for new Teams..."
    }

    Write-Host "    [1] Open Teams" -ForegroundColor White
    Write-Host "    [2] Check Teams Processes" -ForegroundColor White
    Write-Host "    [3] Restart Teams" -ForegroundColor White
    Write-Host "    [4] Clear Teams Cache" -ForegroundColor White
    Write-Host ""
    Write-Host "    Choice: " -NoNewline -ForegroundColor $C.Warning
    $choice = Read-Host

    switch ($choice) {
        "1" {
            Write-Step "Launching Teams..."
            if ($teamsExe) { Start-Process $teamsExe }
            else { Start-Process "msteams:" }
            Write-Success "Teams launched."
            Write-Log -Command "Open Teams" -Status "SUCCESS"
        }
        "2" {
            $procs = Get-Process -Name "Teams*" -ErrorAction SilentlyContinue
            if ($procs) {
                $procs | ForEach-Object {
                    Write-Info $_.Name "$([math]::Round($_.WorkingSet64 / 1MB, 0)) MB RAM"
                }
            } else {
                Write-Warn "Teams is not running."
            }
            Write-Log -Command "Check Teams Process" -Status "SUCCESS"
        }
        "3" {
            Stop-Process -Name "Teams*" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            if ($teamsExe) { Start-Process $teamsExe } else { Start-Process "msteams:" }
            Write-Success "Teams restarted."
            Write-Log -Command "Restart Teams" -Status "SUCCESS"
        }
        "4" {
            if (Confirm-Action "Clear Teams cache? Teams will close.") {
                Stop-Process -Name "Teams*" -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                $cacheDir = "$env:APPDATA\Microsoft\Teams"
                $folders  = @("Cache","blob_storage","databases","GPUCache","IndexedDB","Local Storage","tmp")
                foreach ($f in $folders) {
                    $path = Join-Path $cacheDir $f
                    if (Test-Path $path) {
                        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Step "Cleared: $f"
                    }
                }
                Write-Success "Teams cache cleared."
                Write-Log -Command "Clear Teams Cache" -Status "SUCCESS"
            }
        }
    }
}

function Office-OneDrive {
    Show-Section "ONEDRIVE"

    $oneDrivePath = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
    $syncStatus   = "Unknown"

    if (Test-Path $oneDrivePath) {
        $ver = (Get-Item $oneDrivePath).VersionInfo.FileVersion
        Write-Info "OneDrive Path"   $oneDrivePath
        Write-Info "Version"         $ver
    } else {
        Write-Warn "OneDrive executable not found."
    }

    # Sync status via process
    $proc = Get-Process -Name OneDrive -ErrorAction SilentlyContinue
    $syncStatus = if ($proc) { "Running" } else { "Not Running" }
    $syncColor  = if ($proc) { $C.Success } else { $C.Warning }
    Write-Host "    Sync Status : " -NoNewline -ForegroundColor $C.Dim
    Write-Host $syncStatus -ForegroundColor $syncColor

    # OneDrive folder
    $odFolder = "$env:USERPROFILE\OneDrive"
    if (Test-Path $odFolder) {
        $size = (Get-ChildItem $odFolder -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        Write-Info "OneDrive Folder" $odFolder
        Write-Info "Folder Size"     "$([math]::Round($size / 1GB, 2)) GB"
    }

    Write-Host ""
    Write-Host "    [1] Open OneDrive" -ForegroundColor White
    Write-Host "    [2] Restart OneDrive" -ForegroundColor White
    Write-Host "    [3] Open OneDrive Folder" -ForegroundColor White
    Write-Host ""
    Write-Host "    Choice: " -NoNewline -ForegroundColor $C.Warning
    $choice = Read-Host

    switch ($choice) {
        "1" {
            Write-Step "Launching OneDrive..."
            if (Test-Path $oneDrivePath) { Start-Process $oneDrivePath }
            Write-Success "OneDrive launched."
            Write-Log -Command "Open OneDrive" -Status "SUCCESS"
        }
        "2" {
            Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            if (Test-Path $oneDrivePath) { Start-Process $oneDrivePath }
            Write-Success "OneDrive restarted."
            Write-Log -Command "Restart OneDrive" -Status "SUCCESS"
        }
        "3" {
            if (Test-Path $odFolder) {
                Start-Process explorer $odFolder
                Write-Success "OneDrive folder opened."
                Write-Log -Command "Open OneDrive Folder" -Status "SUCCESS"
            } else {
                Write-Fail "OneDrive folder not found."
            }
        }
    }
}
