# ============================================================
#  TC IT TOOL - Reports Engine
# ============================================================

function Show-Reports {
    $opts = @(
        "Generate Full HTML Report",
        "Export CSV Report",
        "Export Excel Report",
        "Export PDF Report",
        "View Today's Logs",
        "Open Reports Folder"
    )

    while ($true) {
        Show-Menu -Title "REPORTS" -Options $opts
        Write-Host "    Enter Option: " -NoNewline -ForegroundColor $C.Warning
        $sel = Read-Host

        switch ($sel) {
            "1" { Report-HTML }
            "2" { Report-CSV }
            "3" { Report-Excel }
            "4" { Report-PDF }
            "5" { Show-Logs }
            "6" { Start-Process (Resolve-Path $Global:Config.ReportDir) }
            "0" { return }
            default { Write-Warn "Invalid option." ; Start-Sleep 1 }
        }
        Pause-Screen
    }
}

# ── Data Collector ────────────────────────────────────────────
function Get-ReportData {
    Show-Section "COLLECTING DATA"
    $data = @{}

    Write-Step "System Information..."
    try {
        $os   = Get-CimInstance Win32_OperatingSystem
        $cs   = Get-CimInstance Win32_ComputerSystem
        $bios = Get-CimInstance Win32_BIOS
        $uptime = (Get-Date) - $os.LastBootUpTime
        $reg        = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        $displayVer = $reg.DisplayVersion
        $fullBuild  = "$($reg.CurrentBuildNumber).$($reg.UBR)"

        $data.System = @{
            ComputerName  = $env:COMPUTERNAME
            Username      = $env:USERNAME
            Manufacturer  = $cs.Manufacturer
            Model         = $cs.Model
            BIOSVersion   = $bios.SMBIOSBIOSVersion
            SerialNumber  = $bios.SerialNumber
            WindowsVer    = $os.Caption
            Version       = $displayVer
            BuildNumber   = $fullBuild
            InstallDate   = $os.InstallDate.ToString("yyyy-MM-dd")
            Uptime        = "{0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes
            TimeZone      = (Get-TimeZone).DisplayName
            ReportDate    = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
    } catch { $data.System = @{ Error = "Failed to collect" } }
    Write-Success "System — Done"

    Write-Step "Hardware Information..."
    try {
        $cpu     = Get-CimInstance Win32_Processor | Select-Object -First 1
        $ramGB   = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        $freeRAM = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
        $gpu     = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name
        $disks   = Get-CimInstance Win32_DiskDrive | ForEach-Object {
            "$($_.Model) — $([math]::Round($_.Size/1GB,0))GB"
        }
        $data.Hardware = @{
            CPU      = "$($cpu.Name) ($($cpu.NumberOfCores) cores)"
            RAM      = "Total: ${ramGB}GB | Free: ${freeRAM}GB"
            GPU      = $gpu
            Disks    = $disks -join " | "
        }
    } catch { $data.Hardware = @{ Error = "Failed to collect" } }
    Write-Success "Hardware — Done"

    Write-Step "Network Information..."
    try {
        $ip  = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch "^127" } | Select-Object -First 1).IPAddress
        $mac = (Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1).MacAddress
        $dns = (Get-DnsClientServerAddress | Where-Object { $_.ServerAddresses } | Select-Object -First 1).ServerAddresses -join ", "
        $gw  = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object -First 1).NextHop
        $data.Network = @{
            IPAddress = $ip
            MACAddress = $mac
            DNS       = $dns
            Gateway   = $gw
        }
    } catch { $data.Network = @{ Error = "Failed to collect" } }
    Write-Success "Network — Done"

    Write-Step "Security Information..."
    try {
        $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
        $tpm      = Get-Tpm -ErrorAction SilentlyContinue
        $fw       = Get-NetFirewallProfile -ErrorAction SilentlyContinue
        try { $sb = Confirm-SecureBootUEFI } catch { $sb = "N/A" }
        $data.Security = @{
            DefenderRT   = if ($defender) { $defender.RealTimeProtectionEnabled } else { "N/A" }
            DefenderSigs = if ($defender) { $defender.AntivirusSignatureVersion } else { "N/A" }
            TPMPresent   = if ($tpm)      { $tpm.TpmPresent } else { "N/A" }
            SecureBoot   = $sb
            Firewall     = ($fw | ForEach-Object { "$($_.Name): $($_.Enabled)" }) -join " | "
        }
    } catch { $data.Security = @{ Error = "Failed to collect" } }
    Write-Success "Security — Done"

    Write-Step "Installed Software..."
    try {
        $data.Software = Get-ItemProperty `
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName } |
            Select-Object DisplayName, DisplayVersion, Publisher |
            Sort-Object DisplayName
    } catch { $data.Software = @() }
    Write-Success "Software — Done"

    return $data
}

# ── HTML Report ───────────────────────────────────────────────
function Report-HTML {
    Show-Section "GENERATE HTML REPORT"
    $data     = Get-ReportData
    $outFile  = "$($Global:Config.ReportDir)\Report_$($env:COMPUTERNAME)_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    $s        = $data.System
    $hw       = $data.Hardware
    $net      = $data.Network
    $sec      = $data.Security
    $sw       = $data.Software

    $swRows = ($sw | ForEach-Object {
        "<tr><td>$($_.DisplayName)</td><td>$($_.DisplayVersion)</td><td>$($_.Publisher)</td></tr>"
    }) -join ""

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>TC IT TOOL Report - $($s.ComputerName)</title>
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  body { font-family: Segoe UI, Arial, sans-serif; background:#0f0f1a; color:#e0e0e0; padding:20px; }
  h1 { color:#00d4ff; text-align:center; padding:20px; font-size:2rem; letter-spacing:2px; }
  h2 { color:#00b4d8; margin:20px 0 10px; border-bottom:1px solid #333; padding-bottom:6px; }
  .header-bar { background:linear-gradient(135deg,#1a1a2e,#16213e); border:1px solid #00d4ff44;
                border-radius:8px; padding:16px 24px; margin-bottom:24px; text-align:center; }
  .header-bar p { color:#90e0ef; font-size:0.9rem; margin-top:4px; }
  .grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(360px,1fr)); gap:16px; margin-bottom:24px; }
  .card { background:#1a1a2e; border:1px solid #2a2a4a; border-radius:8px; padding:20px; }
  .card h2 { margin-top:0; }
  table { width:100%; border-collapse:collapse; font-size:0.88rem; }
  th { background:#00d4ff22; color:#00d4ff; padding:8px; text-align:left; }
  td { padding:7px 8px; border-bottom:1px solid #2a2a4a; }
  tr:hover td { background:#ffffff08; }
  .label { color:#90e0ef; width:180px; font-weight:600; }
  .ok   { color:#06d6a0; font-weight:600; }
  .warn { color:#ffd166; font-weight:600; }
  .fail { color:#ef476f; font-weight:600; }
  .sw-section { margin-top:24px; }
  footer { text-align:center; color:#555; margin-top:32px; font-size:0.8rem; }
</style>
</head>
<body>

<div class="header-bar">
  <h1>TC IT TOOL &mdash; System Report</h1>
  <p>Generated: $($s.ReportDate) &nbsp;|&nbsp; Computer: $($s.ComputerName) &nbsp;|&nbsp; User: $($s.Username)</p>
</div>

<div class="grid">

<div class="card">
  <h2>&#128187; System Information</h2>
  <table>
    <tr><td class="label">Computer Name</td><td>$($s.ComputerName)</td></tr>
    <tr><td class="label">Username</td><td>$($s.Username)</td></tr>
    <tr><td class="label">Manufacturer</td><td>$($s.Manufacturer)</td></tr>
    <tr><td class="label">Model</td><td>$($s.Model)</td></tr>
    <tr><td class="label">BIOS Version</td><td>$($s.BIOSVersion)</td></tr>
    <tr><td class="label">Serial Number</td><td>$($s.SerialNumber)</td></tr>
    <tr><td class="label">Windows</td><td>$($s.WindowsVer)</td></tr>
    <tr><td class="label">Version</td><td>$($s.Version)</td></tr>
    <tr><td class="label">Build Number</td><td>$($s.BuildNumber)</td></tr>
    <tr><td class="label">Install Date</td><td>$($s.InstallDate)</td></tr>
    <tr><td class="label">Uptime</td><td>$($s.Uptime)</td></tr>
    <tr><td class="label">Time Zone</td><td>$($s.TimeZone)</td></tr>
  </table>
</div>

<div class="card">
  <h2>&#9881; Hardware Information</h2>
  <table>
    <tr><td class="label">CPU</td><td>$($hw.CPU)</td></tr>
    <tr><td class="label">RAM</td><td>$($hw.RAM)</td></tr>
    <tr><td class="label">GPU</td><td>$($hw.GPU)</td></tr>
    <tr><td class="label">Storage</td><td>$($hw.Disks)</td></tr>
  </table>
</div>

<div class="card">
  <h2>&#127760; Network Information</h2>
  <table>
    <tr><td class="label">IP Address</td><td>$($net.IPAddress)</td></tr>
    <tr><td class="label">MAC Address</td><td>$($net.MACAddress)</td></tr>
    <tr><td class="label">DNS</td><td>$($net.DNS)</td></tr>
    <tr><td class="label">Gateway</td><td>$($net.Gateway)</td></tr>
  </table>
</div>

<div class="card">
  <h2>&#128274; Security Status</h2>
  <table>
    <tr>
      <td class="label">Defender RT</td>
      <td class="$(if ($sec.DefenderRT -eq 'True') { 'ok' } else { 'fail' })">
        $(if ($sec.DefenderRT -eq 'True') { 'Enabled' } else { 'DISABLED' })
      </td>
    </tr>
    <tr><td class="label">AV Signatures</td><td>$($sec.DefenderSigs)</td></tr>
    <tr>
      <td class="label">TPM</td>
      <td class="$(if ($sec.TPMPresent -eq 'True') { 'ok' } else { 'warn' })">
        $(if ($sec.TPMPresent -eq 'True') { 'Present' } else { 'Not Detected' })
      </td>
    </tr>
    <tr>
      <td class="label">Secure Boot</td>
      <td class="$(if ($sec.SecureBoot -eq 'True') { 'ok' } else { 'warn' })">
        $(if ($sec.SecureBoot -eq 'True') { 'Enabled' } else { $sec.SecureBoot })
      </td>
    </tr>
    <tr><td class="label">Firewall</td><td>$($sec.Firewall)</td></tr>
  </table>
</div>

</div>

<div class="sw-section card">
  <h2>&#128230; Installed Software ($($sw.Count) applications)</h2>
  <table>
    <thead><tr><th>Application</th><th>Version</th><th>Publisher</th></tr></thead>
    <tbody>$swRows</tbody>
  </table>
</div>

<footer>TC IT TOOL v$($Global:Config.Version) &mdash; Generated on $($s.ReportDate)</footer>

</body>
</html>
"@

    $html | Out-File -FilePath $outFile -Encoding UTF8
    Write-Host ""
    Write-Success "HTML Report saved: $outFile"
    Write-Log -Command "Generate HTML Report" -Status "SUCCESS"

    Write-Host ""
    Write-Host "    Open report in browser? [Y/N]: " -NoNewline -ForegroundColor $C.Warning
    $open = Read-Host
    if ($open -match "^[Yy]$") { Start-Process $outFile }
}

# ── CSV Report ────────────────────────────────────────────────
function Report-CSV {
    Show-Section "EXPORT CSV REPORT"
    $data    = Get-ReportData
    $outFile = "$($Global:Config.ReportDir)\Report_$($env:COMPUTERNAME)_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $s       = $data.System
    $hw      = $data.Hardware
    $net     = $data.Network
    $sec     = $data.Security

    $rows = @(
        [PSCustomObject]@{ Category="System"; Key="Computer Name";  Value=$s.ComputerName },
        [PSCustomObject]@{ Category="System"; Key="Username";       Value=$s.Username },
        [PSCustomObject]@{ Category="System"; Key="Manufacturer";   Value=$s.Manufacturer },
        [PSCustomObject]@{ Category="System"; Key="Model";          Value=$s.Model },
        [PSCustomObject]@{ Category="System"; Key="Windows";        Value=$s.WindowsVer },
        [PSCustomObject]@{ Category="System"; Key="Build";          Value=$s.BuildNumber },
        [PSCustomObject]@{ Category="System"; Key="Serial";         Value=$s.SerialNumber },
        [PSCustomObject]@{ Category="System"; Key="Uptime";         Value=$s.Uptime },
        [PSCustomObject]@{ Category="Hardware"; Key="CPU";          Value=$hw.CPU },
        [PSCustomObject]@{ Category="Hardware"; Key="RAM";          Value=$hw.RAM },
        [PSCustomObject]@{ Category="Hardware"; Key="GPU";          Value=$hw.GPU },
        [PSCustomObject]@{ Category="Hardware"; Key="Storage";      Value=$hw.Disks },
        [PSCustomObject]@{ Category="Network"; Key="IP Address";    Value=$net.IPAddress },
        [PSCustomObject]@{ Category="Network"; Key="MAC Address";   Value=$net.MACAddress },
        [PSCustomObject]@{ Category="Network"; Key="DNS";           Value=$net.DNS },
        [PSCustomObject]@{ Category="Network"; Key="Gateway";       Value=$net.Gateway },
        [PSCustomObject]@{ Category="Security"; Key="Defender RT";  Value=$sec.DefenderRT },
        [PSCustomObject]@{ Category="Security"; Key="Secure Boot";  Value=$sec.SecureBoot },
        [PSCustomObject]@{ Category="Security"; Key="TPM";          Value=$sec.TPMPresent }
    )

    $rows | Export-Csv -Path $outFile -NoTypeInformation -Encoding UTF8
    Write-Success "CSV Report saved: $outFile"
    Write-Log -Command "Export CSV Report" -Status "SUCCESS"

    Write-Host "    Open file? [Y/N]: " -NoNewline -ForegroundColor $C.Warning
    $open = Read-Host
    if ($open -match "^[Yy]$") { Start-Process $outFile }
}

# ── Excel Report ──────────────────────────────────────────────
function Report-Excel {
    Show-Section "EXPORT EXCEL REPORT"

    # Check for ImportExcel module
    $hasModule = Get-Module -ListAvailable -Name ImportExcel
    if (-not $hasModule) {
        Write-Warn "ImportExcel module not installed."
        Write-Host "    Install it now? [Y/N]: " -NoNewline -ForegroundColor $C.Warning
        $install = Read-Host
        if ($install -match "^[Yy]$") {
            Write-Step "Installing ImportExcel..."
            Install-Module -Name ImportExcel -Force -Scope CurrentUser
        } else {
            Write-Warn "Falling back to CSV export..."
            Report-CSV
            return
        }
    }

    $data    = Get-ReportData
    $outFile = "$($Global:Config.ReportDir)\Report_$($env:COMPUTERNAME)_$(Get-Date -Format 'yyyyMMdd_HHmmss').xlsx"
    $s       = $data.System
    $hw      = $data.Hardware
    $net     = $data.Network
    $sec     = $data.Security

    # System sheet
    $sysData = [PSCustomObject]@{
        "Computer Name" = $s.ComputerName
        "Username"      = $s.Username
        "Manufacturer"  = $s.Manufacturer
        "Model"         = $s.Model
        "Windows"       = $s.WindowsVer
        "Build"         = $s.BuildNumber
        "Serial"        = $s.SerialNumber
        "Uptime"        = $s.Uptime
        "CPU"           = $hw.CPU
        "RAM"           = $hw.RAM
        "GPU"           = $hw.GPU
        "IP Address"    = $net.IPAddress
        "MAC"           = $net.MACAddress
        "Gateway"       = $net.Gateway
        "Defender"      = $sec.DefenderRT
        "Secure Boot"   = $sec.SecureBoot
        "Report Date"   = $s.ReportDate
    }

    try {
        $sysData  | Export-Excel -Path $outFile -WorksheetName "System Info"   -AutoSize -TableStyle Medium9
        $data.Software | Export-Excel -Path $outFile -WorksheetName "Software" -AutoSize -TableStyle Medium2 -Append
        Write-Success "Excel Report saved: $outFile"
        Write-Log -Command "Export Excel Report" -Status "SUCCESS"

        Write-Host "    Open file? [Y/N]: " -NoNewline -ForegroundColor $C.Warning
        $open = Read-Host
        if ($open -match "^[Yy]$") { Start-Process $outFile }
    } catch {
        Write-Fail "Excel export failed: $_"
        Write-Log -Command "Export Excel Report" -Status "FAILED" -Error $_.Exception.Message
    }
}

# ── PDF Report (HTML → PDF via browser print) ─────────────────
function Report-PDF {
    Show-Section "EXPORT PDF REPORT"

    Write-Step "Generating HTML first (PDF converts from HTML)..."
    $data    = Get-ReportData
    $htmlOut = "$env:TEMP\TCITTool_TempReport.html"
    $pdfOut  = "$($Global:Config.ReportDir)\Report_$($env:COMPUTERNAME)_$(Get-Date -Format 'yyyyMMdd_HHmmss').pdf"

    # Generate HTML to temp
    $Global:Config.ReportDir | Out-Null
    $oldDir  = $Global:Config.ReportDir
    $Global:Config.ReportDir = $env:TEMP

    # Try Chrome headless PDF
    $chrome = @(
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1

    $Global:Config.ReportDir = $oldDir

    if ($chrome) {
        Report-HTML 2>&1 | Out-Null
        $tempHtml = "$env:TEMP\Report_$($env:COMPUTERNAME)_*.html" |
                    Resolve-Path -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTime -Descending |
                    Select-Object -First 1

        if ($tempHtml) {
            Write-Step "Converting to PDF via Chrome..."
            $args = "--headless --disable-gpu --print-to-pdf=`"$pdfOut`" `"$tempHtml`""
            Start-Process -FilePath $chrome -ArgumentList $args -Wait -NoNewWindow
            Write-Success "PDF saved: $pdfOut"
            Write-Log -Command "Export PDF Report" -Status "SUCCESS"

            Write-Host "    Open PDF? [Y/N]: " -NoNewline -ForegroundColor $C.Warning
            $open = Read-Host
            if ($open -match "^[Yy]$") { Start-Process $pdfOut }
        }
    } else {
        Write-Warn "Google Chrome not found. Generating HTML Report instead."
        Write-Warn "Open the HTML in Chrome and use Ctrl+P → Save as PDF."
        Report-HTML
        Write-Log -Command "Export PDF Report" -Status "SUCCESS" -Error "Fallback to HTML"
    }
}
