# ============================================================
#  TC IT TOOL - Hardware Information
# ============================================================

function Show-HardwareInfo {
    Show-Header
    Show-Section "HARDWARE INFORMATION"

    $start = Get-Date
    try {
        # CPU
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        $cpuLoad = (Get-CimInstance Win32_Processor).LoadPercentage
        Write-Info "CPU"         "$($cpu.Name) | Cores: $($cpu.NumberOfCores) | Usage: $cpuLoad%"

        # RAM
        $ram      = Get-CimInstance Win32_ComputerSystem
        $totalRAM = [math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
        $freeRAM  = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
        $usedRAM  = [math]::Round($totalRAM - $freeRAM, 2)
        Write-Info "RAM"         "Total: ${totalRAM}GB | Used: ${usedRAM}GB | Free: ${freeRAM}GB"

        # RAM Slots
        $ramSlots = Get-CimInstance Win32_PhysicalMemory
        foreach ($slot in $ramSlots) {
            $slotGB = [math]::Round($slot.Capacity / 1GB, 0)
            Write-Info "  RAM Slot" "$($slot.DeviceLocator) - ${slotGB}GB @ $($slot.Speed)MHz"
        }

        Write-Divider

        # Motherboard
        $mb = Get-CimInstance Win32_BaseBoard
        Write-Info "Motherboard" "$($mb.Manufacturer) $($mb.Product)"

        # Disk
        $disks = Get-CimInstance Win32_DiskDrive
        foreach ($disk in $disks) {
            $sizeGB = [math]::Round($disk.Size / 1GB, 0)
            $type   = if ($disk.MediaType -match "SSD|Solid") { "SSD" } else { "HDD" }
            Write-Info "Drive"   "$($disk.Model) | ${sizeGB}GB | $type"
        }

        # Logical Drives free space
        $logDrives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
        foreach ($d in $logDrives) {
            $freeGB  = [math]::Round($d.FreeSpace / 1GB, 1)
            $totalGB = [math]::Round($d.Size / 1GB, 1)
            Write-Info "  $($d.DeviceID) Free" "${freeGB}GB / ${totalGB}GB"
        }

        Write-Divider

        # GPU
        $gpus = Get-CimInstance Win32_VideoController
        foreach ($gpu in $gpus) {
            $vramMB = [math]::Round($gpu.AdapterRAM / 1MB, 0)
            Write-Info "GPU"    "$($gpu.Name) | VRAM: ${vramMB}MB | Driver: $($gpu.DriverVersion)"
        }

        Write-Divider

        # Battery
        $battery = Get-CimInstance Win32_Battery
        if ($battery) {
            Write-Info "Battery Health"  "$($battery.EstimatedChargeRemaining)%"
            Write-Info "Battery Status"  $battery.Status
        } else {
            Write-Info "Battery"         "No battery detected (Desktop)"
        }

        # Monitor
        $monitors = Get-CimInstance WmiMonitorID -Namespace root\wmi -ErrorAction SilentlyContinue
        if ($monitors) {
            foreach ($mon in $monitors) {
                $name = ($mon.UserFriendlyName | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ }) -join ""
                Write-Info "Monitor"     $name
            }
        }

        Write-Divider

        # USB Devices
        $usb = Get-PnpDevice -Class USB -Status OK -ErrorAction SilentlyContinue | Select-Object -First 8
        foreach ($u in $usb) {
            Write-Info "USB"     $u.FriendlyName
        }

        # Audio
        $audio = Get-CimInstance Win32_SoundDevice
        foreach ($a in $audio) {
            Write-Info "Audio"   $a.Name
        }

        # Webcam
        $cam = Get-PnpDevice -Class Camera -Status OK -ErrorAction SilentlyContinue |
               Select-Object -First 1
        if ($cam) {
            Write-Info "Webcam"  $cam.FriendlyName
        } else {
            Write-Info "Webcam"  "Not detected"
        }

        $dur = [int]((Get-Date) - $start).TotalMilliseconds
        Write-Log -Command "Hardware Information" -Status "SUCCESS" -Duration $dur
    } catch {
        Write-Fail "Failed to retrieve hardware info: $_"
        Write-Log -Command "Hardware Information" -Status "FAILED" -Error $_.Exception.Message
    }

    Write-Host ""
}
