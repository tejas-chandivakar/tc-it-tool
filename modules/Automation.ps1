# ============================================================
#  TC IT TOOL - Automation
# ============================================================

function Show-Automation {
    $opts = @(
        "Auto Install Software",
        "Auto Configure PC",
        "Join Domain",
        "Create Local User",
        "Map Network Drive",
        "Add Shared Printer",
        "Copy Company Files"
    )

    while ($true) {
        $sel = Show-Menu -Title "AUTOMATION" -Options $opts

        switch ($sel) {
            1 { Auto-InstallSoftware }
            2 { Auto-ConfigurePC }
            3 { Auto-JoinDomain }
            4 { Auto-CreateUser }
            5 { Auto-MapDrive }
            6 { Auto-AddSharedPrinter }
            7 { Auto-CopyFiles }
            0 { return }
        }
        Pause-Screen
    }
}

function Auto-InstallSoftware {
    Show-Section "AUTO INSTALL SOFTWARE"

    # Default software list
    $defaultList = @(
        "Google.Chrome",
        "7zip.7zip",
        "Adobe.Acrobat.Reader.64-bit",
        "Microsoft.Teams",
        "Zoom.Zoom"
    )

    Write-Host "    Default install list:" -ForegroundColor $C.Dim
    $i = 1
    $defaultList | ForEach-Object { Write-Host "      $i. $_" -ForegroundColor White ; $i++ }
    Write-Host ""
    Write-Host "    [1] Install default list" -ForegroundColor White
    Write-Host "    [2] Enter custom Winget IDs" -ForegroundColor White
    Write-Host ""
    Write-Host "    Choice: " -NoNewline -ForegroundColor $C.Warning
    $c = Read-Host

    $toInstall = @()
    if ($c -eq "1") {
        $toInstall = $defaultList
    } elseif ($c -eq "2") {
        Write-Host "    Enter Winget IDs (comma-separated): " -NoNewline -ForegroundColor $C.Warning
        $input = Read-Host
        $toInstall = $input -split "," | ForEach-Object { $_.Trim() }
    }

    if ($toInstall.Count -gt 0 -and (Confirm-Action "Install $($toInstall.Count) application(s)?")) {
        $i = 1
        foreach ($app in $toInstall) {
            Write-Step "[$i/$($toInstall.Count)] Installing $app..."
            winget install --id $app --accept-source-agreements --accept-package-agreements -e --silent 2>&1 | Out-Null
            Write-Success "$app - Done"
            Write-Log -Command "Auto Install $app" -Status "SUCCESS"
            $i++
        }
        Write-Success "All installations complete."
    }
}

function Auto-ConfigurePC {
    Show-Section "AUTO CONFIGURE PC"

    Write-Host "    Select configurations to apply:" -ForegroundColor $C.Dim
    Write-Host "    [1] Set Timezone to IST" -ForegroundColor White
    Write-Host "    [2] Enable Remote Desktop" -ForegroundColor White
    Write-Host "    [3] Disable Sleep (AC Power)" -ForegroundColor White
    Write-Host "    [4] Set Power Plan to High Performance" -ForegroundColor White
    Write-Host "    [5] Apply All" -ForegroundColor $C.Warning
    Write-Host ""
    Write-Host "    Choice: " -NoNewline -ForegroundColor $C.Warning
    $c = Read-Host

    $applyAll = $c -eq "5"

    if ($c -eq "1" -or $applyAll) {
        tzutil /s "India Standard Time"
        Write-Success "Timezone set to IST."
        Write-Log -Command "Set Timezone IST" -Status "SUCCESS"
    }
    if ($c -eq "2" -or $applyAll) {
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
        Write-Success "Remote Desktop enabled."
        Write-Log -Command "Enable Remote Desktop" -Status "SUCCESS"
    }
    if ($c -eq "3" -or $applyAll) {
        powercfg /change standby-timeout-ac 0
        Write-Success "Sleep disabled on AC power."
        Write-Log -Command "Disable Sleep" -Status "SUCCESS"
    }
    if ($c -eq "4" -or $applyAll) {
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        Write-Success "Power plan set to High Performance."
        Write-Log -Command "High Performance Power Plan" -Status "SUCCESS"
    }
}

function Auto-JoinDomain {
    Show-Section "JOIN DOMAIN"

    $currentDomain = (Get-WmiObject Win32_ComputerSystem).Domain
    Write-Info "Current Domain/Workgroup" $currentDomain
    Write-Host ""

    Write-Host "    Domain Name: " -NoNewline -ForegroundColor $C.Warning
    $domain = Read-Host
    Write-Host "    Admin Username: " -NoNewline -ForegroundColor $C.Warning
    $adminUser = Read-Host
    Write-Host "    Admin Password: " -NoNewline -ForegroundColor $C.Warning
    $adminPass = Read-Host -AsSecureString

    if (-not $domain -or -not $adminUser) { Write-Warn "Domain and username required."; return }

    if (Confirm-Action "Join domain '$domain'? PC will restart.") {
        try {
            $cred = New-Object System.Management.Automation.PSCredential("$domain\$adminUser", $adminPass)
            Add-Computer -DomainName $domain -Credential $cred -Restart -Force -ErrorAction Stop
            Write-Log -Command "Join Domain $domain" -Status "SUCCESS"
        } catch {
            Write-Fail "Failed to join domain: $($_.Exception.Message)"
            Write-Log -Command "Join Domain $domain" -Status "FAILED" -Error $_.Exception.Message
        }
    }
}

function Auto-CreateUser {
    Show-Section "CREATE LOCAL USER"

    Write-Host "    Username: " -NoNewline -ForegroundColor $C.Warning
    $username = Read-Host
    Write-Host "    Full Name: " -NoNewline -ForegroundColor $C.Warning
    $fullName = Read-Host
    Write-Host "    Password: " -NoNewline -ForegroundColor $C.Warning
    $password = Read-Host -AsSecureString
    Write-Host "    Add to Administrators? [Y/N]: " -NoNewline -ForegroundColor $C.Warning
    $isAdmin = Read-Host

    if (-not $username) { Write-Warn "Username required."; return }

    if (Confirm-Action "Create user '$username'?") {
        try {
            New-LocalUser -Name $username -Password $password -FullName $fullName -PasswordNeverExpires -ErrorAction Stop
            if ($isAdmin -match "^[Yy]$") {
                Add-LocalGroupMember -Group "Administrators" -Member $username -ErrorAction SilentlyContinue
                Write-Success "User '$username' created and added to Administrators."
            } else {
                Write-Success "User '$username' created."
            }
            Write-Log -Command "Create User $username" -Status "SUCCESS"
        } catch {
            Write-Fail "Failed: $($_.Exception.Message)"
            Write-Log -Command "Create User $username" -Status "FAILED" -Error $_.Exception.Message
        }
    }
}

function Auto-MapDrive {
    Show-Section "MAP NETWORK DRIVE"

    Write-Host "    Drive Letter (e.g. Z:): " -NoNewline -ForegroundColor $C.Warning
    $letter = Read-Host
    Write-Host "    Network Path (e.g. \\\\server\\share): " -NoNewline -ForegroundColor $C.Warning
    $path = Read-Host

    if (-not $letter -or -not $path) { Write-Warn "Drive letter and path required."; return }

    if (Confirm-Action "Map $letter to '$path'?") {
        try {
            New-PSDrive -Name ($letter -replace ":","") -PSProvider FileSystem -Root $path -Persist -ErrorAction Stop | Out-Null
            Write-Success "Drive $letter mapped to $path"
            Write-Log -Command "Map Drive $letter $path" -Status "SUCCESS"
        } catch {
            Write-Fail "Failed: $($_.Exception.Message)"
            Write-Log -Command "Map Drive $letter $path" -Status "FAILED" -Error $_.Exception.Message
        }
    }
}

function Auto-AddSharedPrinter {
    Show-Section "ADD SHARED PRINTER"

    Write-Host "    Printer Path (e.g. \\\\server\\PrinterName): " -NoNewline -ForegroundColor $C.Warning
    $path = Read-Host

    if (-not $path) { Write-Warn "Printer path required."; return }

    if (Confirm-Action "Add shared printer '$path'?") {
        try {
            Add-Printer -ConnectionName $path -ErrorAction Stop
            Write-Success "Shared printer added: $path"
            Write-Log -Command "Add Shared Printer $path" -Status "SUCCESS"
        } catch {
            Write-Fail "Failed: $($_.Exception.Message)"
            Write-Log -Command "Add Shared Printer $path" -Status "FAILED" -Error $_.Exception.Message
        }
    }
}

function Auto-CopyFiles {
    Show-Section "COPY COMPANY FILES"

    Write-Host "    Source Path: " -NoNewline -ForegroundColor $C.Warning
    $src = Read-Host
    Write-Host "    Destination Path: " -NoNewline -ForegroundColor $C.Warning
    $dst = Read-Host

    if (-not $src -or -not $dst) { Write-Warn "Source and destination required."; return }
    if (-not (Test-Path $src))    { Write-Fail "Source path not found: $src"; return }

    if (Confirm-Action "Copy files from '$src' to '$dst'?") {
        try {
            if (-not (Test-Path $dst)) {
                New-Item -ItemType Directory -Force -Path $dst | Out-Null
            }
            Write-Step "Copying files..."
            $start = Get-Date
            Copy-Item -Path "$src\*" -Destination $dst -Recurse -Force -ErrorAction Stop
            $dur = [int]((Get-Date) - $start).TotalMilliseconds
            Write-Success "Files copied in ${dur}ms."
            Write-Log -Command "Copy Files $src -> $dst" -Status "SUCCESS" -Duration $dur
        } catch {
            Write-Fail "Copy failed: $($_.Exception.Message)"
            Write-Log -Command "Copy Files" -Status "FAILED" -Error $_.Exception.Message
        }
    }
}
