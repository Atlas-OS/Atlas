# Export only packages used by this PC's physical Ethernet and Wi-Fi adapters.
# PnPUtil reads the driver store; this never installs or changes host drivers.
function Get-AtlasNetworkPackages {
    $devices = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($adapter in @(Get-NetAdapter -Physical -IncludeHidden -ErrorAction Stop)) {
        if ($adapter.InterfaceType -in @(6, 71) -and $adapter.PnPDeviceID) {
            [void]$devices.Add([string]$adapter.PnPDeviceID)
        }
    }
    $packages = @{}
    foreach ($driver in @(Get-CimInstance -ClassName Win32_PnPSignedDriver -Filter "DeviceClass = 'NET'" -ErrorAction Stop)) {
        if (-not $devices.Contains([string]$driver.DeviceID)) { continue }
        # Inbox drivers are provided by Windows and cannot be exported by PnPUtil.
        if ([string]$driver.InfName -notmatch '^oem[0-9]+\.inf$') { continue }
        if (-not $driver.IsSigned) { throw 'An installed network driver is unsigned. Turn off network driver copying and obtain a signed driver from the device manufacturer.' }
        $packages[[string]$driver.InfName] = [pscustomobject]@{
            inf = [string]$driver.InfName
            name = [string]$driver.DeviceName
            provider = [string]$driver.DriverProviderName
            version = [string]$driver.DriverVersion
        }
    }
    return @($packages.Values | Sort-Object inf)
}

function Get-AtlasNetworkHardwareIds {
    $devices = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($adapter in @(Get-NetAdapter -Physical -IncludeHidden -ErrorAction Stop)) {
        if ($adapter.InterfaceType -in @(6,71) -and $adapter.PnPDeviceID) { [void]$devices.Add([string]$adapter.PnPDeviceID) }
    }
    $ids = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($device in @(Get-CimInstance -ClassName Win32_PnPEntity -Filter "PNPClass = 'Net'" -ErrorAction Stop)) {
        if (-not $devices.Contains([string]$device.DeviceID)) { continue }
        foreach ($id in @($device.HardwareID) + @($device.CompatibleID)) {
            if ($id) { [void]$ids.Add([string]$id) }
        }
    }
    return ,$ids
}

function Test-AtlasNetworkUpdate($Update, $HardwareIds) {
    return ([int]$Update.Type -eq 2 -and [string]$Update.DriverClass -ieq 'Net' -and $HardwareIds.Contains([string]$Update.DriverHardwareID))
}

function Assert-AtlasNetworkDownloadConnection {
    $null = [Windows.Networking.Connectivity.NetworkInformation, Windows.Networking.Connectivity, ContentType=WindowsRuntime]
    $connectionProfile = [Windows.Networking.Connectivity.NetworkInformation]::GetInternetConnectionProfile()
    if ($null -eq $connectionProfile -or [string]$connectionProfile.GetNetworkConnectivityLevel() -ne 'InternetAccess') { throw 'Connect to the internet to check for newer network drivers, or choose installed drivers only.' }
    $cost = $connectionProfile.GetConnectionCost()
    if ([string]$cost.NetworkCostType -ne 'Unrestricted' -or $cost.Roaming -or $cost.OverDataLimit -or $cost.BackgroundDataUsageRestricted) {
        throw 'Use an unmetered connection to download network drivers, or choose installed drivers only.'
    }
}

function Export-AtlasNetworkUpdates([string]$Destination, [string]$CancelFile, [string]$LogPath) {
    $ids = Get-AtlasNetworkHardwareIds
    if ($ids.Count -eq 0) { throw 'No physical Wi-Fi or Ethernet hardware could be matched to Windows Update.' }
    Assert-AtlasNetworkDownloadConnection
    if (Test-Path -LiteralPath $CancelFile) { throw (New-Object OperationCanceledException) }
    $session = New-Object -ComObject Microsoft.Update.Session
    $session.ClientApplicationID = 'Atlas ISO network drivers'
    $searcher = $session.CreateUpdateSearcher()
    $searcher.Online = $true
    # Query the public Windows Update service without changing the PC's driver
    # policy. No installer is created; the running OS is never updated here.
    $searcher.ServerSelection = 2
    $found = $searcher.Search("IsInstalled=0 and IsHidden=0 and Type='Driver'")
    if ([int]$found.ResultCode -ne 2) { throw 'Windows Update could not complete the network driver search.' }
    $updates = New-Object -ComObject Microsoft.Update.UpdateColl
    $downloadBytes = [decimal]0
    foreach ($update in $found.Updates) {
        if (Test-AtlasNetworkUpdate $update $ids) {
            if (-not $update.EulaAccepted) { $update.AcceptEula() }
            [void]$updates.Add($update)
            $downloadBytes += [decimal]$update.MaxDownloadSize
        }
    }
    if ($updates.Count -eq 0) { 'No newer matching network drivers offered; retaining installed packages.' | Add-Content -LiteralPath $LogPath -Encoding UTF8; return @() }
    if ($updates.Count -gt 32) { throw 'Windows Update returned too many network packages for this Beta.' }
    if ($downloadBytes -gt 2GB) { throw 'The offered network drivers exceed the 2 GB Beta download limit.' }
    if (Test-Path -LiteralPath $CancelFile) { throw (New-Object OperationCanceledException) }
    $downloader = $session.CreateUpdateDownloader()
    $downloader.Updates = $updates
    $download = $downloader.Download()
    if ([int]$download.ResultCode -ne 2) { throw 'Windows Update could not download every selected network driver.' }
    $report = @()
    for ($index = 0; $index -lt $updates.Count; $index++) {
        if (Test-Path -LiteralPath $CancelFile) { throw (New-Object OperationCanceledException) }
        $update = $updates.Item($index)
        $folder = Join-Path $Destination "windows-update-$index"
        [void][IO.Directory]::CreateDirectory($folder)
        # Use complete signed driver files, never restore the WUA cache into the
        # reinstalled OS. Some payloads are still cabinets after CopyFromCache.
        $update.CopyFromCache($folder, $true)
        foreach ($cab in @(Get-ChildItem -LiteralPath $folder -Filter '*.cab' -File -Recurse)) {
            & (Join-Path $env:WINDIR 'System32\expand.exe') '-F:*' $cab.FullName $folder | Add-Content -LiteralPath $LogPath -Encoding UTF8
            if ($LASTEXITCODE -ne 0) { throw 'A downloaded network driver could not be extracted.' }
        }
        $files = @(Get-ChildItem -LiteralPath $folder -File -Recurse)
        if (@($files | Where-Object Extension -eq '.inf').Count -eq 0 -or @($files | Where-Object Extension -eq '.cat').Count -eq 0) {
            throw 'Windows Update did not provide a complete driver package. Choose installed drivers only.'
        }
        $report += [pscustomobject]@{ source='windows-update'; name=[string]$update.Title; updateId=[string]$update.Identity.UpdateID }
    }
    return $report
}

function Export-AtlasNetworkDrivers([string]$Destination, [string]$CancelFile, [string]$LogPath, [switch]$CheckUpdates) {
    $packages = @(Get-AtlasNetworkPackages)
    if ($packages.Count -eq 0 -and -not $CheckUpdates) {
        throw 'No installed third-party Wi-Fi or Ethernet drivers could be exported. Windows may already include your drivers. Turn off network driver copying to continue, or install the network driver from your device manufacturer first.'
    }
    [void][IO.Directory]::CreateDirectory($Destination)
    foreach ($package in $packages) {
        if (Test-Path -LiteralPath $CancelFile) { throw (New-Object OperationCanceledException 'Network driver export cancelled.') }
        $folder = Join-Path $Destination ([IO.Path]::GetFileNameWithoutExtension($package.inf))
        [void][IO.Directory]::CreateDirectory($folder)
        & (Join-Path $env:WINDIR 'System32\pnputil.exe') /export-driver $package.inf $folder | Add-Content -LiteralPath $LogPath -Encoding UTF8
        if ($LASTEXITCODE -ne 0) { throw "Windows could not export network driver $($package.inf). See the network driver log." }
        $files = @(Get-ChildItem -LiteralPath $folder -File -Recurse -Force)
        if (@($files | Where-Object Extension -eq '.inf').Count -eq 0 -or @($files | Where-Object Extension -eq '.cat').Count -eq 0) {
            throw "Network driver export is incomplete: $($package.inf)."
        }
    }
    if ($CheckUpdates) { $packages += @(Export-AtlasNetworkUpdates -Destination $Destination -CancelFile $CancelFile -LogPath $LogPath) }
    if ($packages.Count -eq 0) { throw 'No network driver packages could be copied. Choose not to include network drivers if Windows already provides them.' }
    $bytes = [long](Get-ChildItem -LiteralPath $Destination -File -Recurse -Force | Measure-Object Length -Sum).Sum
    if ($bytes -gt 2GB) { throw 'The network driver packages exceed the 2 GB Beta limit.' }
    return $packages
}
