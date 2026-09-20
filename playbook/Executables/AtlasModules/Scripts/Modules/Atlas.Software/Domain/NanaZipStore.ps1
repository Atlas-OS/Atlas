# Use the inbox Store API used by WinGet's MSStore.cpp. Unlike the WinGet
# PowerShell module, this works in the installer's SYSTEM/Windows PowerShell host.
function New-AtlasNanaZipStoreManager {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $null = [Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallManager, Windows.ApplicationModel.Store.Preview.InstallControl, ContentType=WindowsRuntime]
    $null = [Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallOptions, Windows.ApplicationModel.Store.Preview.InstallControl, ContentType=WindowsRuntime]
    $null = [Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallItem, Windows.ApplicationModel.Store.Preview.InstallControl, ContentType=WindowsRuntime]
    $null = [Windows.ApplicationModel.Store.Preview.InstallControl.GetEntitlementResult, Windows.ApplicationModel.Store.Preview.InstallControl, ContentType=WindowsRuntime]
    return New-Object Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallManager
}

function Wait-AtlasStoreResult {
    param($Operation, [type]$ResultType, [int]$TimeoutSeconds = 120)
    $method = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and $_.IsGenericMethod -and
        $_.GetGenericArguments().Count -eq 1 -and $_.GetParameters().Count -eq 1
    } | Select-Object -First 1
    $task = $method.MakeGenericMethod($ResultType).Invoke($null, @($Operation))
    if (-not $task.Wait($TimeoutSeconds * 1000)) {
        # Killing a client does not stop Store deployment. The pending marker
        # remains, preventing another installer from racing an unknown outcome.
        throw 'Microsoft Store did not respond in time. Restart Windows before retrying NanaZip installation.'
    }
    return $task.Result
}

function Get-AtlasNanaZipStoreJournal {
    $path = 'HKLM:\SOFTWARE\AtlasOS\NanaZipStore'
    $boot = (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime.ToUniversalTime().ToString('o')
    $pending = $null
    if (Test-Path -LiteralPath $path -ErrorAction Stop) {
        $key = Get-Item -LiteralPath $path -ErrorAction Stop
        try { $pending = $key.GetValue('PendingBoot') } finally { $key.Close() }
    }
    return [pscustomobject]@{ Path = $path; Boot = $boot; Pending = ($pending -ceq $boot) }
}

function Set-AtlasNanaZipStorePending {
    param($Journal, [bool]$Pending)
    if ($Pending) {
        New-Item -Path $Journal.Path -Force -ErrorAction Stop | Out-Null
        Set-ItemProperty -LiteralPath $Journal.Path -Name PendingBoot -Value $Journal.Boot -Type String -ErrorAction Stop
    }
    elseif (Test-Path -LiteralPath $Journal.Path -ErrorAction Stop) {
        Remove-ItemProperty -LiteralPath $Journal.Path -Name PendingBoot -ErrorAction Stop
    }
}

function Request-AtlasNanaZipStoreInstall {
    param($Manager)
    $options = New-Object Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallOptions
    $options.InstallForAllUsers = $true
    $options.AllowForcedAppRestart = $false
    $options.InstallInProgressToastNotificationMode = 2 # NoToast
    $options.CompletedInstallToastNotificationMode = 2
    return @(Wait-AtlasStoreResult -Operation ($Manager.StartProductInstallAsync('9N8G7TSCL18R', '', 'Atlas', '', $options)) `
        -ResultType ([System.Collections.Generic.IReadOnlyList[Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallItem]]))
}

function Get-AtlasNanaZipStoreEntitlement {
    param($Manager)
    $entitlement = Wait-AtlasStoreResult -Operation ($Manager.GetFreeDeviceEntitlementAsync('9N8G7TSCL18R', '', '')) `
        -ResultType ([Windows.ApplicationModel.Store.Preview.InstallControl.GetEntitlementResult])
    if ([string]$entitlement.Status -ne 'Succeeded') { throw "Store entitlement: $($entitlement.Status)" }
}

function Get-AtlasNanaZipStoreItems {
    param($Manager)
    return @($Manager.AppInstallItems | Where-Object { $_.ProductId -ceq '9N8G7TSCL18R' })
}

function Wait-AtlasNanaZipStoreItems {
    param($Manager, [object[]]$Items, [int]$TimeoutSeconds = 600)
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    $restarted = @{}
    $previous = ''
    do {
        $active = 0
        $failed = $false
        $descriptions = foreach ($item in $Items) {
            $status = $item.GetCurrentStatus()
            $state = [string]$status.InstallState
            $code = if ($null -ne $status.ErrorCode) { '0x{0:X8}' -f $status.ErrorCode.HResult } else { '0x00000000' }
            "$($item.ProductId): $state ($([int]$status.PercentComplete)%, $code)"
            if ($state -in @('Error', 'Canceled')) { $failed = $true; continue }
            if ($state -eq 'Completed') { continue }
            $active++
            if ($state -in @('ReadyToDownload', 'Paused') -and -not $restarted.ContainsKey($item.ProductId)) {
                $Manager.Restart($item.ProductId)
                $restarted[$item.ProductId] = $true
            }
        }
        $description = $descriptions -join '; '
        if ($description -cne $previous) {
            Write-AtlasLog -Message "NanaZip Microsoft Store: $description"
            $previous = $description
        }
        if ($active -eq 0) { return (-not $failed) }
        if ([DateTime]::UtcNow -ge $deadline) {
            throw 'NanaZip is still queued or installing in Microsoft Store. Finish its download or restart Windows before retrying; no fallback installer was started.'
        }
        Start-Sleep -Seconds 2
    } while ($true)
}

function Install-AtlasNanaZipFromStore {
    param($DismCommands)
    # Store is not ready during OOBE. The verified offline-provisioning path is
    # still available there, as well as when Store activation/entitlement fails.
    if ((Get-AtlasContext).IsOobe) {
        Write-AtlasLog -Message 'Skipping NanaZip Store installation during OOBE.'
        return $false
    }
    $journal = Get-AtlasNanaZipStoreJournal
    try {
        $manager = New-AtlasNanaZipStoreManager
        if (-not $manager.CanInstallForAllUsers) { throw 'Store cannot install for all users in this context.' }
        $items = @(Get-AtlasNanaZipStoreItems -Manager $manager)
    }
    catch {
        if ($journal.Pending) { throw 'An earlier NanaZip Store request has an unknown outcome. Restart Windows before retrying.' }
        Write-AtlasLog -Level Warning -Message "NanaZip Store is unavailable; using verified downloads. $($_.Exception.Message)"
        return $false
    }
    if ($journal.Pending -and $items.Count -eq 0) {
        throw 'An earlier NanaZip Store request has an unknown outcome. Restart Windows before retrying.'
    }
    if ($items.Count -gt 0) { Set-AtlasNanaZipStorePending -Journal $journal -Pending $true }
    if ($items.Count -eq 0) {
        try {
            Get-AtlasNanaZipStoreEntitlement -Manager $manager
        }
        catch {
            Write-AtlasLog -Level Warning -Message "NanaZip Store entitlement is unavailable; using verified downloads. $($_.Exception.Message)"
            return $false
        }
        Write-AtlasLog -Message 'Installing NanaZip from Microsoft Store (9N8G7TSCL18R) for all users.'
        Set-AtlasNanaZipStorePending -Journal $journal -Pending $true
        # Exceptions here are intentionally not converted into a download retry:
        # even a failed RPC may have queued deployment in the Store service.
        $items = @(Request-AtlasNanaZipStoreInstall -Manager $manager)
        if ($items.Count -eq 0) { throw 'Microsoft Store returned no NanaZip install operation. Restart Windows before retrying.' }
    }
    $completed = Wait-AtlasNanaZipStoreItems -Manager $manager -Items $items
    # Recheck the service queue before permitting a different installer.
    $queue = @(Get-AtlasNanaZipStoreItems -Manager $manager)
    if ($queue.Count -gt 0) { $completed = (Wait-AtlasNanaZipStoreItems -Manager $manager -Items $queue) -and $completed }
    # Provisioning can appear shortly after Store reports Completed.
    for ($attempt = 0; $attempt -lt 15; $attempt++) {
        $packages = @(& $DismCommands.GetProvisionedPackage -Online -ErrorAction Stop)
        if (Test-AtlasNanaZipProvisioned -Package $packages) {
            Set-AtlasNanaZipStorePending -Journal $journal -Pending $false
            Write-AtlasLog -Message 'Verified NanaZip Microsoft Store provisioning for all users.'
            return $true
        }
        if (-not $completed) { break }
        Start-Sleep -Seconds 2
    }
    if ($completed) {
        throw 'Microsoft Store completed NanaZip installation but machine provisioning could not be verified. Restart Windows before retrying.'
    }
    # Failed/canceled jobs are terminal. Clear only NanaZip's queue record and
    # confirm it is gone before starting the pinned GitHub/SourceForge fallback.
    $manager.Cancel('9N8G7TSCL18R')
    for ($attempt = 0; $attempt -lt 25; $attempt++) {
        if (@(Get-AtlasNanaZipStoreItems -Manager $manager).Count -eq 0) { break }
        Start-Sleep -Milliseconds 200
    }
    if ($attempt -eq 25) {
        throw 'Microsoft Store has not cleared the failed NanaZip operation. Restart Windows before retrying.'
    }
    Set-AtlasNanaZipStorePending -Journal $journal -Pending $false
    Write-AtlasLog -Level Warning -Message 'NanaZip Store installation failed and its queue is clear; using verified downloads.'
    return $false
}
