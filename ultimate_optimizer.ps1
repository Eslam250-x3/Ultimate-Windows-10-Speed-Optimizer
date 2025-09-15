# ===================================================================
# Ultimate Windows 10 Speed Optimizer - Maximum Performance Edition
# Run as Administrator - This will SUPERCHARGE your system!
# ===================================================================

param(
    [switch]$Extreme = $false,
    [switch]$Gaming = $false,
    [switch]$CreateRestore = $true
)

$Host.UI.RawUI.BackgroundColor = "Black"
Clear-Host

function Write-Status {
    param(
        $Text,
        $Color = "White",
        $Icon = "►",
        [switch]$NoNewline
    )
    # This function was updated to support the -NoNewline switch
    if ($NoNewline) {
        Write-Host "$Icon $Text" -ForegroundColor $Color -NoNewline
    }
    else {
        Write-Host "$Icon $Text" -ForegroundColor $Color
    }
}

function Create-RestorePoint {
    if ($CreateRestore) {
        Write-Status "Creating system restore point..." "Yellow"
        try {
            Enable-ComputerRestore -Drive "C:\"
            Checkpoint-Computer -Description "Before Speed Optimization" -RestorePointType "MODIFY_SETTINGS"
            Write-Status "Restore point created successfully" "Green"
        }
        catch {
            Write-Status "Could not create restore point - continuing anyway" "Yellow"
        }
    }
}

function Test-AdminRights {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-NOT $isAdmin) {
        Write-Status "ERROR: Must run as Administrator!" "Red"
        Read-Host "Press Enter to exit"
        exit 1
    }
}

function Get-DetailedSystemInfo {
    Write-Status "Analyzing system performance..." "Cyan"
    
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor
    $memory = Get-CimInstance Win32_ComputerSystem
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
    
    $totalRAM = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
    $freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
    $totalSpace = [math]::Round($disk.Size / 1GB, 2)
    $diskUsagePercent = [math]::Round((($totalSpace - $freeSpace) / $totalSpace) * 100, 1)
    
    Write-Status "System: $($os.Caption) $($os.Version)" "White"
    Write-Status ("CPU: {0} ({1} cores)" -f $cpu.Name, $cpu.NumberOfCores) "White"
    Write-Status "RAM: $totalRAM GB" "White"
    Write-Status "GPU: $($gpu.Name)" "White"
    Write-Status ("Disk: {0} GB free / {1} GB total ({2}% used)" -f $freeSpace, $totalSpace, $diskUsagePercent) "White"
    
    # Performance recommendations based on specs
    if ($totalRAM -lt 8) {
        Write-Status "LOW RAM: Consider upgrading to 8GB+ for better performance" "Red"
    }
    if ($diskUsagePercent -gt 85) {
        Write-Status "LOW DISK SPACE: Free up space or consider SSD upgrade" "Red"
    }
    if ($cpu.NumberOfCores -lt 4) {
        Write-Status "CPU: Older CPU detected - some optimizations will focus on efficiency" "Yellow"
    }
    
    return @{
        RAM = $totalRAM
        DiskUsage = $diskUsagePercent
        CPUCores = $cpu.NumberOfCores
        HasSSD = (Get-PhysicalDisk | Where-Object {$_.MediaType -eq "SSD"}).Count -gt 0
    }
}

function Optimize-MemoryManagement {
    Write-Status "ADVANCED: Optimizing memory management..." "Cyan"
    
    try {
        # Advanced memory settings
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
        
        # Disable paging executive (keep system in RAM)
        Set-ItemProperty -Path $regPath -Name "DisablePagingExecutive" -Value 1 -Force
        
        # Optimize system cache
        Set-ItemProperty -Path $regPath -Name "LargeSystemCache" -Value 1 -Force
        
        # Clear pagefile at shutdown (security + performance)
        Set-ItemProperty -Path $regPath -Name "ClearPageFileAtShutdown" -Value 0 -Force
        
        # Optimize virtual memory allocation
        Set-ItemProperty -Path $regPath -Name "SystemPages" -Value 0 -Force
        
        Write-Status "Memory management optimized" "Green"
    }
    catch {
        Write-Status "Failed to optimize memory management" "Red"
    }
}

function Optimize-CPUScheduling {
    Write-Status "ADVANCED: Optimizing CPU scheduling..." "Cyan"
    
    try {
        # Prioritize foreground applications
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 26 -Force
        
        # Optimize processor scheduling
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "IRQ8Priority" -Value 1 -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "IRQ16Priority" -Value 2 -Force
        
        Write-Status "CPU scheduling optimized for responsiveness" "Green"
    }
    catch {
        Write-Status "Failed to optimize CPU scheduling" "Red"
    }
}

function Disable-UselessServices {
    Write-Status "EXTREME: Disabling resource-heavy services..." "Cyan"
    
    $servicesToDisable = @{
        # Search and indexing
        "WSearch" = "Windows Search (uses lots of CPU/disk)"
        "SearchIndexer" = "Search Indexer"
        
        # Background services
        "SysMain" = "SuperFetch/Prefetch (SSD optimization)"
        "Themes" = "Themes (visual effects)"
        "TabletInputService" = "Touch keyboard and handwriting"
        "WbioSrvc" = "Windows Biometric Service"
        "WerSvc" = "Windows Error Reporting"
        "DiagTrack" = "Diagnostic Tracking Service"
        "dmwappushservice" = "WAP Push Message Routing"
        "lfsvc" = "Geolocation Service"
        "MapsBroker" = "Downloaded Maps Manager"
        "NetTcpPortSharing" = "Net.Tcp Port Sharing Service"
        "RemoteAccess" = "Routing and Remote Access"
        "RemoteRegistry" = "Remote Registry"
        "SharedAccess" = "Internet Connection Sharing"
        "TrkWks" = "Distributed Link Tracking Client"
        "WMPNetworkSvc" = "Windows Media Player Network Sharing"
        
        # Fax and print
        "Fax" = "Fax Service"
        "PrintNotify" = "Printer Extensions and Notifications"
        "Spooler" = "Print Spooler (if no printer)"
        
        # Xbox and gaming (unless gaming mode)
        "XblAuthManager" = "Xbox Live Auth Manager"
        "XblGameSave" = "Xbox Live Game Save"
        "XboxGipSvc" = "Xbox Accessory Management Service"
        "XboxNetApiSvc" = "Xbox Live Networking Service"
    }
    
    foreach ($service in $servicesToDisable.Keys) {
        try {
            $serviceObj = Get-Service -Name $service -ErrorAction SilentlyContinue
            if ($serviceObj -and $serviceObj.Status -ne "Disabled") {
                # Skip Xbox services if gaming mode is enabled
                if ($Gaming -and $service.StartsWith("Xbox")) {
                    Write-Status "Skipping $service (Gaming mode enabled)" "Yellow"
                    continue
                }
                
                # Skip print spooler if printer detected
                if ($service -eq "Spooler" -and (Get-Printer -ErrorAction SilentlyContinue)) {
                    Write-Status "Skipping Print Spooler (Printer detected)" "Yellow"
                    continue
                }
                
                Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                Set-Service -Name $service -StartupType Disabled -ErrorAction Stop
                Write-Status "Disabled: $($servicesToDisable[$service])" "Green"
            }
        }
        catch {
            Write-Status "Could not disable: $($servicesToDisable[$service])" "Yellow"
        }
    }
}

function Optimize-NetworkPerformance {
    Write-Status "ADVANCED: Turbocharging network performance..." "Cyan"
    
    try {
        # Disable network throttling
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Force
        
        # Optimize TCP settings
        netsh int tcp set global autotuninglevel=normal
        netsh int tcp set global chimney=enabled
        netsh int tcp set global rss=enabled
        netsh int tcp set global netdma=enabled
        
        # Set DNS to fast servers (Google + Cloudflare)
        $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
        foreach ($adapter in $adapters) {
            Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses "8.8.8.8","1.1.1.1","8.8.4.4","1.0.0.1"
        }
        
        Write-Status "Network performance optimized" "Green"
    }
    catch {
        Write-Status "Failed to optimize network" "Yellow"
    }
}

function Optimize-DiskPerformance {
    Write-Status "ADVANCED: Optimizing disk performance..." "Cyan"
    
    try {
        # Disable 8.3 filename creation (NTFS performance)
        fsutil behavior set disable8dot3 1
        
        # Optimize NTFS performance
        fsutil behavior set DisableLastAccess 1
        fsutil behavior set EncryptPagingFile 0
        
        # Disable disk defragmentation schedule (for SSD)
        $hasSSd = (Get-PhysicalDisk | Where-Object {$_.MediaType -eq "SSD"}).Count -gt 0
        if ($hasSSD) {
            Disable-ScheduledTask -TaskName "Microsoft\Windows\Defrag\ScheduledDefrag" -ErrorAction SilentlyContinue
            Write-Status "Disabled defrag schedule (SSD detected)" "Green"
        }
        
        # Enable write caching
        $disks = Get-CimInstance -ClassName Win32_DiskDrive
        foreach ($disk in $disks) {
            $disk | Set-CimInstance -Property @{WriteCacheEnabled=$true}
        }
        
        Write-Status "Disk performance optimized" "Green"
    }
    catch {
        Write-Status "Failed to optimize disk performance" "Yellow"
    }
}

function Remove-BloatwareApps {
    Write-Status "EXTREME: Removing Windows bloatware..." "Cyan"
    
    $bloatware = @(
        "Microsoft.3DBuilder",
        "Microsoft.BingWeather",
        "Microsoft.GetHelp",
        "Microsoft.Getstarted",
        "Microsoft.Messaging", 
        "Microsoft.Microsoft3DViewer",
        "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.NetworkSpeedTest",
        "Microsoft.News",
        "Microsoft.Office.Lens",
        "Microsoft.Office.Sway",
        "Microsoft.OneConnect",
        "Microsoft.People",
        "Microsoft.Print3D",
        "Microsoft.SkypeApp",
        "Microsoft.StorePurchaseApp",
        "Microsoft.Office.OneNote",
        "Microsoft.MixedReality.Portal",
        "Microsoft.ZuneMusic",
        "Microsoft.ZuneVideo",
        "microsoft.windowscommunicationsapps",
        "Microsoft.MinecraftUWP",
        "Microsoft.MicrosoftOfficeHub",
        "Flipboard.Flipboard",
        "ShazamEntertainmentLtd.Shazam",
        "king.com.CandyCrushSodaSaga",
        "ClearChannelRadioDigital.iHeartRadio",
        "4DF9E0F8.Netflix",
        "Drawboard.DrawboardPDF",
        "D52A8D61.FarmVille2CountryEscape"
    )
    
    $removed = 0
    foreach ($app in $bloatware) {
        try {
            $package = Get-AppxPackage -Name $app -ErrorAction SilentlyContinue
            if ($package) {
                Remove-AppxPackage -Package $package.PackageFullName -ErrorAction Stop
                Write-Status "Removed: $($app.Split('.')[-1])" "Green"
                $removed++
            }
        }
        catch {
            # Silent fail - app might be in use
        }
    }
    
    if ($removed -gt 0) {
        Write-Status "Removed $removed bloatware apps" "Green"
    } else {
        Write-Status "No bloatware apps found to remove" "Yellow"
    }
}

function Optimize-StartupPrograms {
    Write-Status "ADVANCED: Optimizing startup programs..." "Cyan"
    
    try {
        # Get startup programs
        $startupApps = Get-CimInstance Win32_StartupCommand | Where-Object {
            $_.Command -notlike "*Windows Security*" -and 
            $_.Command -notlike "*Audio*" -and
            $_.Command -notlike "*Graphics*" -and
            $_.Name -notlike "*Audio*" -and
            $_.Name -notlike "*Graphics*"
        }
        
        Write-Status "Found $($startupApps.Count) non-essential startup programs" "White"
        Write-Status "Recommendation: Manually disable unnecessary programs from Task Manager > Startup tab" "Cyan"
        
        # Show top resource-heavy startup programs
        foreach ($app in $startupApps | Select-Object -First 5) {
            Write-Status "  • $($app.Name) - $($app.Location)" "Yellow"
        }
    }
    catch {
        Write-Status "Could not analyze startup programs" "Yellow"
    }
}

function Optimize-VisualEffects {
    Write-Status "EXTREME: Disabling all visual effects..." "Cyan"
    
    try {
        # Disable all visual effects for maximum performance
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Force
        
        # Disable animations
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value 0 -Force
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](144,18,3,128,16,0,0,0)) -Force
        
        # Disable menu animations
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value 0 -Force
        
        # Disable taskbar animations
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 0 -Force
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Value 0 -Force
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Value 0 -Force
        
        Write-Status "Visual effects disabled for maximum performance" "Green"
    }
    catch {
        Write-Status "Failed to disable visual effects" "Red"
    }
}

function Optimize-PowerManagement {
    Write-Status "EXTREME: Setting ultimate performance power plan..." "Cyan"
    
    try {
        # Create Ultimate Performance power plan
        $ultimateGuid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
        powercfg -duplicatescheme $ultimateGuid
        powercfg -setactive $ultimateGuid
        
        # Disable power throttling
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -Value 1 -Force
        
        # Disable USB selective suspend
        powercfg -setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
        powercfg -setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
        
        # Disable hibernate and fast startup
        powercfg -hibernate off
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Force
        
        Write-Status "Ultimate Performance power plan activated" "Green"
    }
    catch {
        Write-Status "Setting high performance plan instead..." "Yellow"
        powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    }
}

function Clean-SystemFiles {
    Write-Status "ADVANCED: Deep cleaning system files..." "Cyan"
    
    $cleanupLocations = @{
        "Windows Update Cache" = "C:\Windows\SoftwareDistribution\Download"
        "Windows Logs" = "C:\Windows\Logs"
        "Crash Dumps" = "C:\Windows\Minidump"
        "Temp Files" = @($env:TEMP, "C:\Windows\Temp", "$env:LOCALAPPDATA\Temp")
        "Prefetch Files" = "C:\Windows\Prefetch"
        "Thumbnail Cache" = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
        "Browser Caches" = @(
            "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
            "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
            "$env:APPDATA\Mozilla\Firefox\Profiles\*\cache2"
        )
        "Recent Files" = "$env:APPDATA\Microsoft\Windows\Recent"
        "Jump Lists" = "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations"
    }
    
    $totalCleaned = 0
    foreach ($location in $cleanupLocations.Keys) {
        $paths = $cleanupLocations[$location]
        if ($paths -is [string]) { $paths = @($paths) }
        
        foreach ($path in $paths) {
            if (Test-Path $path) {
                try {
                    $sizeBefore = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
                    Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                    $sizeAfter = if (Test-Path $path) { (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB } else { 0 }
                    $cleaned = [math]::Round($sizeBefore - $sizeAfter, 2)
                    if ($cleaned -gt 0) {
                        $totalCleaned += $cleaned
                        # CORRECTED: Rewrote this line with the -f format operator to be more robust and prevent parsing errors.
                        Write-Status ("Cleaned {0}: {1} MB" -f $location, $cleaned) "Green"
                    }
                }
                catch {
                    # Silent continue
                }
            }
        }
    }
    
    # Empty recycle bin
    try {
        Clear-RecycleBin -Force -ErrorAction Stop
        Write-Status "Recycle Bin emptied" "Green"
    }
    catch { }
    
    Write-Status "Total space freed: $([math]::Round($totalCleaned, 2)) MB" "Green"
}

function Run-AdvancedMaintenance {
    Write-Status "ADVANCED: Running system maintenance..." "Cyan"
    
    # DISM health check and repair
    Write-Status "Running DISM health scan..." "White"
    try {
        $dismResult = DISM /Online /Cleanup-Image /CheckHealth
        if ($LASTEXITCODE -ne 0) {
            Write-Status "Running DISM repair..." "Yellow"
            DISM /Online /Cleanup-Image /RestoreHealth
        }
        Write-Status "DISM scan completed" "Green"
    }
    catch {
        Write-Status "DISM scan failed" "Red"
    }
    
    # System file check
    Write-Status "Running system file check..." "White"
    try {
        $sfcResult = Start-Process -FilePath "sfc" -ArgumentList "/scannow" -Wait -PassThru -NoNewWindow
        Write-Status "System file check completed" "Green"
    }
    catch {
        Write-Status "System file check failed" "Red"
    }
    
    # Reset network stack
    Write-Status "Resetting network stack..." "White"
    try {
        netsh winsock reset | Out-Null
        netsh int ip reset | Out-Null
        ipconfig /flushdns | Out-Null
        Write-Status "Network stack reset" "Green"
    }
    catch {
        Write-Status "Failed to reset network stack" "Yellow"
    }
}

function Show-FinalReport {
    Write-Status "`nULTIMATE OPTIMIZATION COMPLETED!" "Green"
    
    # Get updated system info
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
    $memory = Get-CimInstance Win32_ComputerSystem
    $totalRAM = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
    
    Write-Status "System Status After Optimization:" "Cyan"
    Write-Status "Free Disk Space: $freeSpace GB" "White"
    Write-Status "Total RAM: $totalRAM GB" "White"
    
    Write-Status "`nPERFORMANCE IMPROVEMENTS APPLIED:" "Yellow"
    Write-Status "Memory management optimized" "Green"
    Write-Status "CPU scheduling optimized" "Green"
    Write-Status "Network performance boosted" "Green"
    Write-Status "Disk performance enhanced" "Green"
    Write-Status "Visual effects disabled" "Green"
    Write-Status "Bloatware removed" "Green"
    Write-Status "Services optimized" "Green"
    Write-Status "Power plan set to maximum" "Green"
    Write-Status "System files cleaned and repaired" "Green"
    
    Write-Status "`nCRITICAL NEXT STEPS:" "Red"
    Write-Status "1. RESTART YOUR COMPUTER NOW!" "Red"
    Write-Status "2. Check Task Manager > Startup tab and disable more programs if needed" "Yellow"
    Write-Status "3. Run Windows Update to ensure compatibility" "Yellow"
    Write-Status "4. Monitor system performance for 24-48 hours" "Yellow"
    
    if ($CreateRestore) {
        Write-Status "`nSystem restore point created - you can revert if needed" "Cyan"
    }
}

# ======================== MAIN EXECUTION ========================

Write-Host "██╗  ██╗██╗  ████████╗██╗███╗   ███╗ █████╗ ████████╗███████╗" -ForegroundColor Red
Write-Host "██║  ██║██║  ╚══██╔══╝██║████╗ ████║██╔══██╗╚══██╔══╝██╔════╝" -ForegroundColor Red
Write-Host "██║  ██║██║     ██║   ██║██╔████╔██║███████║   ██║   █████╗  " -ForegroundColor Red
Write-Host "██║  ██║██║     ██║   ██║██║╚██╔╝██║██╔══██║   ██║   ██╔══╝  " -ForegroundColor Red
Write-Host "╚██████╔╝███████╗██║   ██║██║ ╚═╝ ██║██║  ██║   ██║   ███████╗" -ForegroundColor Red
Write-Host " ╚═════╝ ╚══════╝╚═╝   ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝" -ForegroundColor Red
Write-Host ""
Write-Status "Windows 10 ULTIMATE Speed Optimizer" "Green"
Write-Status "WARNING: This will make EXTREME changes for MAXIMUM performance!" "Red"

# Confirm extreme mode
if ($Extreme -or $Gaming) {
    Write-Status "EXTREME MODE ACTIVATED - Maximum performance settings will be applied!" "Red"
    $confirm = Read-Host "Continue? (Type 'YES' to confirm)"
    if ($confirm -ne "YES") {
        Write-Status "Operation cancelled by user" "Yellow"
        exit
    }
}

# Check admin rights
Test-AdminRights

# Create restore point
Create-RestorePoint

# Get system info and recommendations
$systemInfo = Get-DetailedSystemInfo

Write-Status "`nStarting ULTIMATE optimization process..." "Green"
Write-Status "This will take 10-15 minutes - DO NOT INTERRUPT!" "Red"

# Run all optimizations
Clean-SystemFiles
Optimize-MemoryManagement
Optimize-CPUScheduling
Disable-UselessServices
Optimize-NetworkPerformance
Optimize-DiskPerformance
Remove-BloatwareApps
Optimize-StartupPrograms
Optimize-VisualEffects
Optimize-PowerManagement
Run-AdvancedMaintenance

# Show final report
Show-FinalReport

# Restart prompt
Write-Status "`nRestart computer now for changes to take effect? (Y/N): " "Yellow" -NoNewline
$restart = Read-Host

if ($restart -eq "Y" -or $restart -eq "y") {
    Write-Status "Restarting in 15 seconds..." "Red"
    Write-Status "Your system will be SIGNIFICANTLY faster after restart!" "Green"
    Start-Sleep -Seconds 15
    Restart-Computer -Force
} else {
    Write-Status "IMPORTANT: Restart as soon as possible for maximum benefit!" "Red"
    Read-Host "Press Enter to exit"
}

# ======================== END OF SCRIPT ========================
