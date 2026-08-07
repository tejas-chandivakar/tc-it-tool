# ============================================================
#  TC IT TOOL - Admin Check
# ============================================================

function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal   = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-AdminElevation {
    if (-not (Test-Admin)) {
        Write-Host ""
        Write-Host "  [!] Administrator privileges required." -ForegroundColor Yellow
        Write-Host "  [*] Relaunching as Administrator..." -ForegroundColor Cyan
        Start-Sleep -Seconds 1

        $scriptPath = $MyInvocation.ScriptName
        if (-not $scriptPath) {
            $scriptPath = $PSCommandPath
        }

        Start-Process -FilePath "powershell.exe" `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" `
            -Verb RunAs
        exit
    }
}
