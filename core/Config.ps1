# ============================================================
#  TC IT TOOL - Config
# ============================================================

$Global:Config = @{
    Version     = "1.0.0"
    ToolName    = "TC IT TOOL"
    Language    = "EN"
    Theme       = "Dark"
    LogDir      = "$PSScriptRoot\..\logs"
    ReportDir   = "$PSScriptRoot\..\reports"
    LogEnabled  = $true
}

# Ensure directories exist
if (-not (Test-Path $Global:Config.LogDir)) {
    New-Item -ItemType Directory -Force -Path $Global:Config.LogDir | Out-Null
}
if (-not (Test-Path $Global:Config.ReportDir)) {
    New-Item -ItemType Directory -Force -Path $Global:Config.ReportDir | Out-Null
}
