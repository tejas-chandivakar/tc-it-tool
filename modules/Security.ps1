# ============================================================
#  TC IT TOOL - Security
# ============================================================

function Show-Security {
    Show-Header
    Show-Section "SECURITY STATUS"

    $start = Get-Date

    try {
        # BitLocker
        Write-Host "    [ BitLocker ]" -ForegroundColor $C.Header
        $bl = Get-BitLockerVolume -ErrorAction SilentlyContinue
        if ($bl) {
            $bl | ForEach-Object {
                $status = $_.ProtectionStatus
                $color  = if ($status -eq "On") { $C.Success } else { $C.Warning }
                Write-Host ("    {0,-6} Protection: " -f $_.MountPoint) -NoNewline -ForegroundColor $C.Dim
                Write-Host $status -ForegroundColor $color
                Write-Host ("           Volume Status : {0}" -f $_.VolumeStatus) -ForegroundColor White
                Write-Host ("           Encryption    : {0}%" -f $_.EncryptionPercentage) -ForegroundColor White
            }
        } else {
            Write-Host "    BitLocker    : Not available or not configured" -ForegroundColor $C.Warning
        }

        Write-Divider

        # Windows Defender
        Write-Host "    [ Windows Defender ]" -ForegroundColor $C.Header
        $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($defender) {
            $rtColor = if ($defender.RealTimeProtectionEnabled) { $C.Success } else { $C.Error }
            Write-Host "    Real-time Protection : " -NoNewline -ForegroundColor $C.Dim
            Write-Host $(if ($defender.RealTimeProtectionEnabled) { "Enabled" } else { "DISABLED" }) -ForegroundColor $rtColor
            Write-Info "    Antivirus Signatures" $defender.AntivirusSignatureVersion
            Write-Info "    Last Scan Time"       $defender.QuickScanStartTime
            Write-Info "    Definitions Updated"  $defender.AntivirusSignatureLastUpdated
        } else {
            Write-Warn "    Could not retrieve Defender status."
        }

        Write-Divider

        # Firewall
        Write-Host "    [ Firewall ]" -ForegroundColor $C.Header
        $fw = Get-NetFirewallProfile -ErrorAction SilentlyContinue
        $fw | ForEach-Object {
            $state = if ($_.Enabled) { "ON" } else { "OFF" }
            $color = if ($_.Enabled) { $C.Success } else { $C.Error }
            Write-Host ("    {0,-10} : " -f $_.Name) -NoNewline -ForegroundColor $C.Dim
            Write-Host $state -ForegroundColor $color
        }

        Write-Divider

        # Secure Boot
        Write-Host "    [ Secure Boot ]" -ForegroundColor $C.Header
        try {
            $sb    = Confirm-SecureBootUEFI -ErrorAction SilentlyContinue
            $sbStr = if ($sb) { "Enabled" } else { "Disabled" }
            $sbCol = if ($sb) { $C.Success } else { $C.Warning }
            Write-Host "    Secure Boot : " -NoNewline -ForegroundColor $C.Dim
            Write-Host $sbStr -ForegroundColor $sbCol
        } catch {
            Write-Host "    Secure Boot : Not supported (Legacy BIOS)" -ForegroundColor $C.Warning
        }

        Write-Divider

        # TPM
        Write-Host "    [ TPM ]" -ForegroundColor $C.Header
        $tpm = Get-Tpm -ErrorAction SilentlyContinue
        if ($tpm) {
            $tpmColor = if ($tpm.TpmPresent -and $tpm.TpmReady) { $C.Success } else { $C.Warning }
            Write-Host "    TPM Present  : " -NoNewline -ForegroundColor $C.Dim
            Write-Host $tpm.TpmPresent -ForegroundColor $tpmColor
            Write-Info "    TPM Ready"  $tpm.TpmReady
            Write-Info "    TPM Enabled" $tpm.TpmEnabled
        } else {
            Write-Host "    TPM          : Not detected" -ForegroundColor $C.Warning
        }

        Write-Divider

        # Antivirus (3rd party)
        Write-Host "    [ Antivirus (Installed) ]" -ForegroundColor $C.Header
        $av = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName AntiVirusProduct -ErrorAction SilentlyContinue
        if ($av) {
            $av | ForEach-Object {
                $state = if ($_.productState -band 0x1000) { "Active" } else { "Inactive" }
                $color = if ($state -eq "Active") { $C.Success } else { $C.Warning }
                Write-Host "    $($_.displayName) : " -NoNewline -ForegroundColor $C.Dim
                Write-Host $state -ForegroundColor $color
            }
        } else {
            Write-Warn "    No 3rd party antivirus detected."
        }

        $dur = [int]((Get-Date) - $start).TotalMilliseconds
        Write-Log -Command "Security Status" -Status "SUCCESS" -Duration $dur
    } catch {
        Write-Fail "Error retrieving security info: $_"
        Write-Log -Command "Security Status" -Status "FAILED" -Error $_.Exception.Message
    }

    Write-Host ""
}
