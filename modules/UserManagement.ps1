# ============================================================
#  TC IT TOOL - User Management
# ============================================================

function Show-UserManagement {
    $opts = @(
        "Current User Info",
        "Local Users List",
        "Password Last Set",
        "Password Expiry",
        "Lock PC",
        "Log Off",
        "Restart PC",
        "Shutdown PC"
    )

    while ($true) {
        $sel = Show-Menu -Title "USER MANAGEMENT" -Options $opts

        switch ($sel) {
            1 { User-CurrentInfo }
            2 { User-LocalList }
            3 { User-PasswordLastSet }
            4 { User-PasswordExpiry }
            5 { User-LockPC }
            6 { User-LogOff }
            7 { User-Restart }
            8 { User-Shutdown }
            0 { return }
        }
        Pause-Screen
    }
}

function User-CurrentInfo {
    Show-Section "CURRENT USER INFO"
    $user   = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $groups = $user.Groups | ForEach-Object { $_.Translate([System.Security.Principal.NTAccount]).Value }

    Write-Info "Username"    $env:USERNAME
    Write-Info "Domain"      $env:USERDOMAIN
    Write-Info "Computer"    $env:COMPUTERNAME
    Write-Info "Profile Path" $env:USERPROFILE
    Write-Info "SID"         $user.User.Value
    Write-Divider
    Write-Host "    Groups:" -ForegroundColor $C.Dim
    $groups | ForEach-Object { Write-Host "      - $_" -ForegroundColor White }
    Write-Log -Command "Current User Info" -Status "SUCCESS"
}

function User-LocalList {
    Show-Section "LOCAL USERS"
    $users = Get-LocalUser -ErrorAction SilentlyContinue
    if ($users) {
        Write-Host ("    {0,-25} {1,-10} {2}" -f "Username", "Enabled", "Last Login") -ForegroundColor $C.Dim
        Write-Divider
        $users | ForEach-Object {
            $enabled = if ($_.Enabled) { "Yes" } else { "No" }
            $last    = if ($_.LastLogon) { $_.LastLogon.ToString("yyyy-MM-dd HH:mm") } else { "Never" }
            $color   = if ($_.Enabled) { "White" } else { "DarkGray" }
            Write-Host ("    {0,-25} {1,-10} {2}" -f $_.Name, $enabled, $last) -ForegroundColor $color
        }
    } else {
        Write-Warn "Could not retrieve local users."
    }
    Write-Log -Command "Local Users List" -Status "SUCCESS"
}

function User-PasswordLastSet {
    Show-Section "PASSWORD LAST SET"
    $users = Get-LocalUser -ErrorAction SilentlyContinue | Where-Object { $_.Enabled }
    $users | ForEach-Object {
        $lastSet = if ($_.PasswordLastSet) { $_.PasswordLastSet.ToString("yyyy-MM-dd HH:mm") } else { "Never / Not set" }
        Write-Info $_.Name $lastSet
    }
    Write-Log -Command "Password Last Set" -Status "SUCCESS"
}

function User-PasswordExpiry {
    Show-Section "PASSWORD EXPIRY"
    try {
        $users = Get-LocalUser -ErrorAction SilentlyContinue | Where-Object { $_.Enabled }
        $users | ForEach-Object {
            $expires = if ($_.PasswordExpires) { $_.PasswordExpires.ToString("yyyy-MM-dd") } else { "Never expires" }
            Write-Info $_.Name $expires
        }
        Write-Log -Command "Password Expiry" -Status "SUCCESS"
    } catch {
        Write-Fail "Could not retrieve expiry info."
        Write-Log -Command "Password Expiry" -Status "FAILED"
    }
}

function User-LockPC {
    Show-Section "LOCK PC"
    if (Confirm-Action "Lock this PC?") {
        Write-Step "Locking PC..."
        Write-Log -Command "Lock PC" -Status "SUCCESS"
        Start-Sleep -Seconds 1
        rundll32.exe user32.dll,LockWorkStation
    }
}

function User-LogOff {
    Show-Section "LOG OFF"
    if (Confirm-Action "Log off current user '$env:USERNAME'?") {
        Write-Step "Logging off..."
        Write-Log -Command "Log Off $env:USERNAME" -Status "SUCCESS"
        Start-Sleep -Seconds 1
        logoff
    }
}

function User-Restart {
    Show-Section "RESTART PC"
    Write-Host "    Delay in seconds (default 0): " -NoNewline -ForegroundColor $C.Warning
    $delay = Read-Host
    if (-not $delay -or $delay -notmatch "^\d+$") { $delay = 0 }

    if (Confirm-Action "Restart this PC in $delay seconds?") {
        Write-Step "Restarting in $delay seconds..."
        Write-Log -Command "Restart PC" -Status "SUCCESS"
        shutdown /r /t $delay /c "TC IT TOOL - Scheduled Restart"
    }
}

function User-Shutdown {
    Show-Section "SHUTDOWN PC"
    Write-Host "    Delay in seconds (default 0): " -NoNewline -ForegroundColor $C.Warning
    $delay = Read-Host
    if (-not $delay -or $delay -notmatch "^\d+$") { $delay = 0 }

    if (Confirm-Action "Shutdown this PC in $delay seconds?") {
        Write-Step "Shutting down in $delay seconds..."
        Write-Log -Command "Shutdown PC" -Status "SUCCESS"
        shutdown /s /t $delay /c "TC IT TOOL - Scheduled Shutdown"
    }
}
