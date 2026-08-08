# ============================================================
#  TC IT TOOL - Windows Repair
# ============================================================

function Show-WindowsRepair {
    $opts = @(
        "SFC (System File Checker)",
        "DISM (Windows Image Repair)",
        "CHKDSK (Disk Check)",
        "Windows Update Reset",
        "Clear Temp Files",
        "Clear Prefetch",
        "Clear System Cache",
        "Restart Explorer",
        "Restart Print Spooler",
        "Reset Network Stack",
        "Clear Windows Store Cache"
    )

    while ($true) {
        $sel = Show-Menu -Title "WINDOWS REPAIR" -Options $opts

        switch ($sel) {
            1  { Repair-SFC }
            2  { Repair-DISM }
            3  { Repair-CHKDSK }
            4  { Repair-WindowsUpdate }
            5  { Repair-ClearTemp }
            6  { Repair-ClearPrefetch }
            7  { Repair-ClearCache }
            8  { Repair-RestartExplorer }
            9  { Repair-RestartSpooler }
            10 { Repair-ResetNetwork }
            11 { Repair-StoreCache }
            0  { return }
        }
        Pause-Screen
    }
}

function Repair-SFC {
    Show-Section "SFC - SYSTEM FILE CHECKER"
    Write-Warn "This may take 10-20 minutes. Do not close the window."
    if (Confirm-Action "Run SFC /scannow?") {
        Write-Step "Running SFC scan..."
        $start = Get-Date
        $result = sfc /scannow 2>&1
        $dur  = [int]((Get-Date) - $start).TotalMilliseconds
        $result | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
        Write-Success "SFC scan complete."
        Write-Log -Command "SFC Scan" -Status "SUCCESS" -Duration $dur
    }
}

function Repair-DISM {
    Show-Section "DISM - WINDOWS IMAGE REPAIR"
    Write-Warn "This requires internet and may take 15-30 minutes."
    if (Confirm-Action "Run DISM RestoreHealth?") {
        Write-Step "Running DISM..."
        $start = Get-Date
        DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
        $dur = [int]((Get-Date) - $start).TotalMilliseconds
        Write-Success "DISM complete."
        Write-Log -Command "DISM RestoreHealth" -Status "SUCCESS" -Duration $dur
    }
}

function Repair-CHKDSK {
    Show-Section "CHKDSK - DISK CHECK"
    Write-Host "    Drive letter (e.g. C:): " -NoNewline -ForegroundColor $C.Warning
    $drive = Read-Host
    if (-not $drive) { $drive = "C:" }
    Write-Step "Running CHKDSK on $drive (read-only check)..."
    chkdsk $drive 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    Write-Success "CHKDSK complete."
    Write-Log -Command "CHKDSK $drive" -Status "SUCCESS"
}

function Repair-WindowsUpdate {
    Show-Section "WINDOWS UPDATE RESET"
    if (Confirm-Action "Reset Windows Update components?") {
        $cmds = @(
            { net stop wuauserv 2>&1 | Out-Null },
            { net stop cryptSvc 2>&1 | Out-Null },
            { net stop bits    2>&1 | Out-Null },
            { net stop msiserver 2>&1 | Out-Null },
            { Remove-Item "$env:SystemRoot\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue },
            { Remove-Item "$env:SystemRoot\System32\catroot2"    -Recurse -Force -ErrorAction SilentlyContinue },
            { net start wuauserv   2>&1 | Out-Null },
            { net start cryptSvc   2>&1 | Out-Null },
            { net start bits       2>&1 | Out-Null },
            { net start msiserver  2>&1 | Out-Null }
        )
        $labels = @("Stop wuauserv","Stop cryptSvc","Stop bits","Stop msiserver",
                    "Clear SoftwareDistribution","Clear catroot2",
                    "Start wuauserv","Start cryptSvc","Start bits","Start msiserver")
        for ($i = 0; $i -lt $cmds.Count; $i++) {
            Write-Step "$($labels[$i])..."
            & $cmds[$i]
        }
        Write-Success "Windows Update reset complete."
        Write-Log -Command "Windows Update Reset" -Status "SUCCESS"
    }
}

function Repair-ClearTemp {
    Show-Section "CLEAR TEMP FILES"
    Write-Step "Clearing temp files..."
    $before = (Get-ChildItem $env:TEMP -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    $freed = [math]::Round($before / 1MB, 1)
    Write-Success "Temp files cleared. ~${freed}MB freed."
    Write-Log -Command "Clear Temp" -Status "SUCCESS"
}

function Repair-ClearPrefetch {
    Show-Section "CLEAR PREFETCH"
    if (Confirm-Action "Clear Prefetch files?") {
        Remove-Item "C:\Windows\Prefetch\*" -Force -ErrorAction SilentlyContinue
        Write-Success "Prefetch cleared."
        Write-Log -Command "Clear Prefetch" -Status "SUCCESS"
    }
}

function Repair-ClearCache {
    Show-Section "CLEAR SYSTEM CACHE"
    Write-Step "Clearing DNS cache..."
    ipconfig /flushdns | Out-Null
    Write-Step "Clearing thumbnail cache..."
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
    Write-Step "Clearing icon cache..."
    ie4uinit.exe -show 2>&1 | Out-Null
    Write-Success "System cache cleared."
    Write-Log -Command "Clear System Cache" -Status "SUCCESS"
}

function Repair-RestartExplorer {
    Show-Section "RESTART EXPLORER"
    Write-Step "Restarting Windows Explorer..."
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process explorer
    Write-Success "Explorer restarted."
    Write-Log -Command "Restart Explorer" -Status "SUCCESS"
}

function Repair-RestartSpooler {
    Show-Section "RESTART PRINT SPOOLER"
    Write-Step "Restarting Print Spooler..."
    Restart-Service -Name Spooler -Force -ErrorAction SilentlyContinue
    $svc = Get-Service -Name Spooler
    if ($svc.Status -eq "Running") {
        Write-Success "Print Spooler restarted successfully."
        Write-Log -Command "Restart Spooler" -Status "SUCCESS"
    } else {
        Write-Fail "Failed to restart Spooler."
        Write-Log -Command "Restart Spooler" -Status "FAILED"
    }
}

function Repair-ResetNetwork {
    Show-Section "RESET NETWORK STACK"
    if (Confirm-Action "Reset Winsock and TCP/IP stack? (requires restart)") {
        Write-Step "Resetting Winsock..."
        netsh winsock reset 2>&1 | Out-Null
        Write-Step "Resetting TCP/IP..."
        netsh int ip reset 2>&1 | Out-Null
        Write-Step "Flushing DNS..."
        ipconfig /flushdns | Out-Null
        Write-Success "Network stack reset. Please restart your PC."
        Write-Log -Command "Reset Network Stack" -Status "SUCCESS"
    }
}

function Repair-StoreCache {
    Show-Section "CLEAR WINDOWS STORE CACHE"
    Write-Step "Clearing Windows Store cache..."
    wsreset.exe
    Write-Success "Store cache cleared."
    Write-Log -Command "Clear Store Cache" -Status "SUCCESS"
}
