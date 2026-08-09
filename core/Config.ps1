# ============================================================
#  TC IT TOOL - Config
# ============================================================

$Global:Config = @{
    Version     = "1.0.0"
    ToolName    = "TC IT TOOL"
    Language    = "EN"
    Theme       = "Dark"
    LogDir      = "$PSScriptRoot\..\logs"
    ReportDir   = Join-Path ([Environment]::GetFolderPath('Desktop')) "TC IT TOOL Reports"
    LogEnabled  = $true
}

# Ensure log directory exists (reports folder is created on first report generation)
if (-not (Test-Path $Global:Config.LogDir)) {
    New-Item -ItemType Directory -Force -Path $Global:Config.LogDir | Out-Null
}
