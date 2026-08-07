# ============================================================
#  TC IT TOOL - Network Tools
# ============================================================

function Show-NetworkTools {
    $opts = @(
        "IP Address",
        "MAC Address",
        "DNS Servers",
        "Gateway",
        "DHCP Info",
        "Wi-Fi Details",
        "Ping Test",
        "Traceroute",
        "NSLookup",
        "Flush DNS",
        "Renew IP",
        "Release IP",
        "Internet Speed Test",
        "Network Adapter Reset"
    )

    while ($true) {
        Show-Menu -Title "NETWORK TOOLS" -Options $opts
        Write-Host "    Enter Option: " -NoNewline -ForegroundColor $C.Warning
        $sel = Read-Host

        switch ($sel) {
            "1"  { Net-IPAddress }
            "2"  { Net-MACAddress }
            "3"  { Net-DNS }
            "4"  { Net-Gateway }
            "5"  { Net-DHCP }
            "6"  { Net-WiFi }
            "7"  { Net-Ping }
            "8"  { Net-Traceroute }
            "9"  { Net-NSLookup }
            "10" { Net-FlushDNS }
            "11" { Net-RenewIP }
            "12" { Net-ReleaseIP }
            "13" { Net-SpeedTest }
            "14" { Net-AdapterReset }
            "0"  { return }
            default { Write-Warn "Invalid option." ; Start-Sleep 1 }
        }
        Pause-Screen
    }
}

function Net-IPAddress {
    Show-Section "IP ADDRESS"
    $adapters = Get-NetIPAddress | Where-Object { $_.AddressFamily -in "IPv4","IPv6" -and $_.IPAddress -notmatch "^(127|::1|fe80)" }
    foreach ($a in $adapters) {
        Write-Info "$($a.InterfaceAlias) ($($a.AddressFamily))" $a.IPAddress
    }
    Write-Log -Command "IP Address" -Status "SUCCESS"
}

function Net-MACAddress {
    Show-Section "MAC ADDRESS"
    Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
        Write-Info $_.Name $_.MacAddress
    }
    Write-Log -Command "MAC Address" -Status "SUCCESS"
}

function Net-DNS {
    Show-Section "DNS SERVERS"
    Get-DnsClientServerAddress | Where-Object { $_.ServerAddresses } | ForEach-Object {
        Write-Info $_.InterfaceAlias ($_.ServerAddresses -join ", ")
    }
    Write-Log -Command "DNS Servers" -Status "SUCCESS"
}

function Net-Gateway {
    Show-Section "DEFAULT GATEWAY"
    Get-NetRoute -DestinationPrefix "0.0.0.0/0" | ForEach-Object {
        Write-Info $_.InterfaceAlias $_.NextHop
    }
    Write-Log -Command "Gateway" -Status "SUCCESS"
}

function Net-DHCP {
    Show-Section "DHCP INFO"
    Get-NetIPConfiguration | Where-Object { $_.NetIPv4Interface.Dhcp -eq "Enabled" } | ForEach-Object {
        Write-Info "Interface"   $_.InterfaceAlias
        Write-Info "DHCP Server" $_.NetIPv4Interface.DhcpServer
        Write-Info "IPv4"        $_.IPv4Address.IPAddress
    }
    Write-Log -Command "DHCP Info" -Status "SUCCESS"
}

function Net-WiFi {
    Show-Section "WI-FI DETAILS"
    try {
        $wifi = netsh wlan show interfaces
        $wifi | Where-Object { $_ -match "^\s+(SSID|Signal|Authentication|Channel|Receive rate)" } |
                ForEach-Object { Write-Host "    $_" -ForegroundColor White }
        Write-Log -Command "Wi-Fi Details" -Status "SUCCESS"
    } catch {
        Write-Fail "Could not retrieve Wi-Fi details."
        Write-Log -Command "Wi-Fi Details" -Status "FAILED" -Error $_.Exception.Message
    }
}

function Net-Ping {
    Show-Section "PING TEST"
    Write-Host "    Target (IP/Domain): " -NoNewline -ForegroundColor $C.Warning
    $target = Read-Host
    if (-not $target) { $target = "8.8.8.8" }

    Write-Step "Pinging $target..."
    $result = Test-Connection -ComputerName $target -Count 4 -ErrorAction SilentlyContinue
    if ($result) {
        $avg = [math]::Round(($result | Measure-Object -Property ResponseTime -Average).Average, 0)
        Write-Success "Ping successful — Avg: ${avg}ms"
        $result | ForEach-Object { Write-Info "Reply from $($_.Address)" "$($_.ResponseTime)ms" }
        Write-Log -Command "Ping $target" -Status "SUCCESS"
    } else {
        Write-Fail "Ping failed — $target unreachable"
        Write-Log -Command "Ping $target" -Status "FAILED" -Error "No response"
    }
}

function Net-Traceroute {
    Show-Section "TRACEROUTE"
    Write-Host "    Target: " -NoNewline -ForegroundColor $C.Warning
    $target = Read-Host
    if (-not $target) { $target = "8.8.8.8" }
    Write-Step "Tracing route to $target..."
    tracert -d -h 20 $target | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    Write-Log -Command "Traceroute $target" -Status "SUCCESS"
}

function Net-NSLookup {
    Show-Section "NSLOOKUP"
    Write-Host "    Domain: " -NoNewline -ForegroundColor $C.Warning
    $domain = Read-Host
    if (-not $domain) { $domain = "google.com" }
    $result = Resolve-DnsName $domain -ErrorAction SilentlyContinue
    if ($result) {
        $result | ForEach-Object { Write-Info $_.Name $_.IPAddress }
        Write-Log -Command "NSLookup $domain" -Status "SUCCESS"
    } else {
        Write-Fail "Could not resolve $domain"
        Write-Log -Command "NSLookup $domain" -Status "FAILED" -Error "DNS resolution failed"
    }
}

function Net-FlushDNS {
    Show-Section "FLUSH DNS"
    Write-Step "Flushing DNS cache..."
    ipconfig /flushdns | Out-Null
    Write-Success "DNS cache flushed successfully."
    Write-Log -Command "Flush DNS" -Status "SUCCESS"
}

function Net-RenewIP {
    Show-Section "RENEW IP"
    Write-Step "Renewing IP address..."
    ipconfig /renew | Out-Null
    Write-Success "IP address renewed."
    Write-Log -Command "Renew IP" -Status "SUCCESS"
}

function Net-ReleaseIP {
    Show-Section "RELEASE IP"
    if (Confirm-Action "Release IP address? Network will disconnect temporarily.") {
        Write-Step "Releasing IP address..."
        ipconfig /release | Out-Null
        Write-Success "IP address released."
        Write-Log -Command "Release IP" -Status "SUCCESS"
    }
}

function Net-SpeedTest {
    Show-Section "INTERNET SPEED TEST"
    Write-Step "Testing download speed (downloading 10MB test file)..."
    try {
        $url   = "http://speed.hetzner.de/10MB.bin"
        $tmp   = "$env:TEMP\speedtest.bin"
        $start = Get-Date
        Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing | Out-Null
        $dur   = ((Get-Date) - $start).TotalSeconds
        $mbps  = [math]::Round((10 / $dur) * 8, 2)
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        Write-Success "Download Speed: ~${mbps} Mbps  (${dur}s for 10MB)"
        Write-Log -Command "Speed Test" -Status "SUCCESS"
    } catch {
        Write-Fail "Speed test failed: $_"
        Write-Log -Command "Speed Test" -Status "FAILED" -Error $_.Exception.Message
    }
}

function Net-AdapterReset {
    Show-Section "NETWORK ADAPTER RESET"
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    $i = 1
    $adapters | ForEach-Object { Write-Host "    [$i] $($_.Name)" -ForegroundColor White ; $i++ }
    Write-Host ""
    Write-Host "    Select adapter: " -NoNewline -ForegroundColor $C.Warning
    $pick = Read-Host
    $adapter = $adapters | Select-Object -Index ([int]$pick - 1)
    if ($adapter) {
        if (Confirm-Action "Reset adapter '$($adapter.Name)'?") {
            Disable-NetAdapter -Name $adapter.Name -Confirm:$false
            Start-Sleep -Seconds 2
            Enable-NetAdapter  -Name $adapter.Name -Confirm:$false
            Write-Success "Adapter '$($adapter.Name)' reset successfully."
            Write-Log -Command "Adapter Reset $($adapter.Name)" -Status "SUCCESS"
        }
    } else {
        Write-Fail "Invalid selection."
    }
}
