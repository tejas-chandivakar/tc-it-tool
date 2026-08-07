# ============================================================
#  TC IT TOOL - Logger
# ============================================================

function Write-Log {
    param(
        [string]$Command,
        [string]$Status   = "SUCCESS",
        [string]$Error    = "-",
        [int]   $Duration = 0
    )

    if (-not $Global:Config.LogEnabled) { return }

    $logDir = $Global:Config.LogDir
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    }

    $logFile  = Join-Path $logDir "$(Get-Date -Format 'yyyy-MM-dd').log"
    $date     = Get-Date -Format "yyyy-MM-dd"
    $time     = Get-Date -Format "HH:mm:ss"
    $computer = $env:COMPUTERNAME
    $user     = $env:USERNAME
    $line     = "$date | $time | $computer | $user | $Command | $Status | ${Duration}ms | $Error"

    Add-Content -Path $logFile -Value $line
}

function Show-Logs {
    $logDir = $Global:Config.LogDir
    $logFile = Join-Path $logDir "$(Get-Date -Format 'yyyy-MM-dd').log"

    Write-Host ""
    if (Test-Path $logFile) {
        Write-Host "  Log File: $logFile" -ForegroundColor Cyan
        Write-Host ""
        Get-Content $logFile | ForEach-Object {
            $parts = $_ -split " \| "
            if ($parts[5] -eq "SUCCESS") {
                Write-Host "  $_" -ForegroundColor Green
            } elseif ($parts[5] -eq "FAILED") {
                Write-Host "  $_" -ForegroundColor Red
            } else {
                Write-Host "  $_" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "  No logs found for today." -ForegroundColor Yellow
    }
    Write-Host ""
}
