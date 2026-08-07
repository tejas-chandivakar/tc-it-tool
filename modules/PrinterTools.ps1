# ============================================================
#  TC IT TOOL - Printer Tools
# ============================================================

function Show-PrinterTools {
    $opts = @(
        "Installed Printers",
        "Default Printer",
        "Restart Print Spooler",
        "Clear Print Queue",
        "Add Printer (IP)",
        "Remove Printer",
        "Print Test Page"
    )

    while ($true) {
        Show-Menu -Title "PRINTER TOOLS" -Options $opts
        Write-Host "    Enter Option: " -NoNewline -ForegroundColor $C.Warning
        $sel = Read-Host

        switch ($sel) {
            "1" { Print-List }
            "2" { Print-Default }
            "3" { Print-RestartSpooler }
            "4" { Print-ClearQueue }
            "5" { Print-AddPrinter }
            "6" { Print-Remove }
            "7" { Print-TestPage }
            "0" { return }
            default { Write-Warn "Invalid option." ; Start-Sleep 1 }
        }
        Pause-Screen
    }
}

function Print-List {
    Show-Section "INSTALLED PRINTERS"
    $printers = Get-Printer -ErrorAction SilentlyContinue
    if ($printers) {
        $i = 1
        $printers | ForEach-Object {
            $default = if ($_.Default) { " [DEFAULT]" } else { "" }
            Write-Host ("    {0}. {1}{2}  — {3}" -f $i, $_.Name, $default, $_.PrinterStatus) -ForegroundColor White
            $i++
        }
    } else {
        Write-Warn "No printers found."
    }
    Write-Log -Command "List Printers" -Status "SUCCESS"
}

function Print-Default {
    Show-Section "DEFAULT PRINTER"
    $default = Get-Printer | Where-Object { $_.Default }
    if ($default) {
        Write-Info "Default Printer" $default.Name
        Write-Info "Status"          $default.PrinterStatus
        Write-Info "Port"            $default.PortName
    } else {
        Write-Warn "No default printer set."
    }
    Write-Log -Command "Default Printer" -Status "SUCCESS"
}

function Print-RestartSpooler {
    Show-Section "RESTART PRINT SPOOLER"
    Write-Step "Restarting Print Spooler service..."
    Restart-Service -Name Spooler -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    $status = (Get-Service -Name Spooler).Status
    if ($status -eq "Running") {
        Write-Success "Print Spooler restarted. Status: $status"
        Write-Log -Command "Restart Spooler" -Status "SUCCESS"
    } else {
        Write-Fail "Spooler status: $status"
        Write-Log -Command "Restart Spooler" -Status "FAILED"
    }
}

function Print-ClearQueue {
    Show-Section "CLEAR PRINT QUEUE"
    if (Confirm-Action "Clear all pending print jobs?") {
        Stop-Service -Name Spooler -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:SystemRoot\System32\spool\PRINTERS\*" -Force -Recurse -ErrorAction SilentlyContinue
        Start-Service -Name Spooler -ErrorAction SilentlyContinue
        Write-Success "Print queue cleared."
        Write-Log -Command "Clear Print Queue" -Status "SUCCESS"
    }
}

function Print-AddPrinter {
    Show-Section "ADD PRINTER (IP)"
    Write-Host "    Printer IP Address: " -NoNewline -ForegroundColor $C.Warning
    $ip = Read-Host
    Write-Host "    Printer Name: " -NoNewline -ForegroundColor $C.Warning
    $name = Read-Host

    if (-not $ip -or -not $name) { Write-Warn "IP and Name required."; return }

    Write-Step "Adding printer port..."
    Add-PrinterPort -Name "IP_$ip" -PrinterHostAddress $ip -ErrorAction SilentlyContinue

    Write-Step "Adding printer..."
    Add-Printer -Name $name -DriverName "Generic / Text Only" -PortName "IP_$ip" -ErrorAction SilentlyContinue

    $check = Get-Printer -Name $name -ErrorAction SilentlyContinue
    if ($check) {
        Write-Success "Printer '$name' added at $ip"
        Write-Log -Command "Add Printer $name $ip" -Status "SUCCESS"
    } else {
        Write-Fail "Failed to add printer. Check driver name."
        Write-Log -Command "Add Printer $name $ip" -Status "FAILED"
    }
}

function Print-Remove {
    Show-Section "REMOVE PRINTER"
    $printers = Get-Printer -ErrorAction SilentlyContinue
    if (-not $printers) { Write-Warn "No printers found."; return }

    $i = 1
    $printers | ForEach-Object { Write-Host "    [$i] $($_.Name)" -ForegroundColor White ; $i++ }
    Write-Host ""
    Write-Host "    Select printer: " -NoNewline -ForegroundColor $C.Warning
    $pick = Read-Host
    $printer = $printers | Select-Object -Index ([int]$pick - 1)

    if ($printer -and (Confirm-Action "Remove '$($printer.Name)'?")) {
        Remove-Printer -Name $printer.Name -ErrorAction SilentlyContinue
        Write-Success "Printer '$($printer.Name)' removed."
        Write-Log -Command "Remove Printer $($printer.Name)" -Status "SUCCESS"
    }
}

function Print-TestPage {
    Show-Section "PRINT TEST PAGE"
    $printers = Get-Printer -ErrorAction SilentlyContinue
    if (-not $printers) { Write-Warn "No printers found."; return }

    $i = 1
    $printers | ForEach-Object { Write-Host "    [$i] $($_.Name)" -ForegroundColor White ; $i++ }
    Write-Host ""
    Write-Host "    Select printer: " -NoNewline -ForegroundColor $C.Warning
    $pick = Read-Host
    $printer = $printers | Select-Object -Index ([int]$pick - 1)

    if ($printer) {
        Write-Step "Sending test page to '$($printer.Name)'..."
        $wmi = Get-WmiObject -Query "SELECT * FROM Win32_Printer WHERE Name='$($printer.Name)'" -ErrorAction SilentlyContinue
        if ($wmi) {
            $wmi.PrintTestPage() | Out-Null
            Write-Success "Test page sent."
            Write-Log -Command "Print Test Page $($printer.Name)" -Status "SUCCESS"
        } else {
            Write-Fail "Could not send test page."
            Write-Log -Command "Print Test Page" -Status "FAILED"
        }
    }
}
