# ============================================================
#  TC IT TOOL - System Information
# ============================================================

function Show-SystemInfo {
    Show-Header
    Show-Section "SYSTEM INFORMATION"

    $start = Get-Date

    try {
        $os      = Get-CimInstance Win32_OperatingSystem
        $cs      = Get-CimInstance Win32_ComputerSystem
        $bios    = Get-CimInstance Win32_BIOS
        $tz      = (Get-TimeZone).DisplayName
        $install = $os.InstallDate.ToString("yyyy-MM-dd")
        $uptime  = (Get-Date) - $os.LastBootUpTime
        $uptimeStr = "{0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes

        $asset = ""
        try { $asset = (Get-CimInstance Win32_SystemEnclosure).SMBIOSAssetTag } catch {}

        # Registry থেকে proper version info
        $reg         = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        $displayVer  = $reg.DisplayVersion          # e.g. 25H2
        $buildNum    = $reg.CurrentBuildNumber       # e.g. 26200
        $ubr         = $reg.UBR                      # e.g. 8973
        $fullBuild   = "$buildNum.$ubr"              # e.g. 26200.8973

        Write-Info "Computer Name"   $env:COMPUTERNAME
        Write-Info "Username"        $env:USERNAME
        Write-Info "Manufacturer"    $cs.Manufacturer
        Write-Info "Model"           $cs.Model
        Write-Info "BIOS Version"    $bios.SMBIOSBIOSVersion
        Write-Info "Serial Number"   $bios.SerialNumber
        Write-Info "Asset Tag"       $(if ($asset) { $asset } else { "N/A" })
        Write-Divider
        Write-Info "Windows Version" $os.Caption
        Write-Info "Version"         $displayVer
        Write-Info "Build Number"    $fullBuild
        Write-Info "Install Date"    $install
        Write-Info "Uptime"          $uptimeStr
        Write-Info "Time Zone"       $tz

        $dur = [int]((Get-Date) - $start).TotalMilliseconds
        Write-Log -Command "System Information" -Status "SUCCESS" -Duration $dur
    } catch {
        Write-Fail "Failed to retrieve system information: $_"
        Write-Log -Command "System Information" -Status "FAILED" -Error $_.Exception.Message
    }

    Write-Host ""
}
