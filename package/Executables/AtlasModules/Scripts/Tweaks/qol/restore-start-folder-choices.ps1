# Companion of restore-start-folder-choices.psd1. The install runs as LocalSystem,
# which is required for device policy writes through the WMI bridge.
#
# Atlas 0.6.0 and 0.6.1 hid and locked the folder switches beside the Start power button
# through the local WMI bridge. The bridge enrols as an MDM provider whose ID differs on
# every PC, so a locked switch is Atlas's when Atlas's Start layout policy is set, the
# switch is still hidden, and its winning provider is enrolled as the WMI bridge. Other
# policy sources, such as a school's or employer's MDM, are left alone. Updates and
# reinstalls from any version run this, so a PC an earlier update missed is repaired.
$ErrorActionPreference = 'Stop'

try {
    $explorerPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
    $layout = Get-ItemProperty -LiteralPath $explorerPolicy -Name ConfigureStartPinsJSON -ErrorAction SilentlyContinue
    $atlasLayout = Join-Path ([Environment]::GetFolderPath('Windows')) 'AtlasModules\Other\StartLayout.json'
    if ($null -eq $layout -or [Environment]::ExpandEnvironmentVariables($layout.ConfigureStartPinsJSON) -ine $atlasLayout) {
        Write-AtlasLog -Level Info -Message "Start folder switches: Atlas's Start layout policy isn't set, so none are Atlas's to restore."
        return
    }

    $policyPath = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start'
    $policy = Get-ItemProperty -LiteralPath $policyPath -ErrorAction SilentlyContinue
    if ($null -eq $policy) {
        Write-AtlasLog -Level Info -Message 'Start folder switches: no Start policy is set.'
        return
    }

    $bridgeProviders = @{}
    $restored = @{}
    foreach ($name in @(
            'AllowPinnedFolderSettings'
            'AllowPinnedFolderFileExplorer'
            'AllowPinnedFolderDocuments'
            'AllowPinnedFolderDownloads'
            'AllowPinnedFolderMusic'
            'AllowPinnedFolderPictures'
            'AllowPinnedFolderVideos'
            'AllowPinnedFolderNetwork'
            'AllowPinnedFolderPersonalFolder'
        )) {
        $setting = $policy.PSObject.Properties[$name]
        $provider = $policy.PSObject.Properties["${name}_WinningProvider"]
        if ($null -eq $setting -or $setting.Value -ne 0 -or $null -eq $provider) { continue }
        $providerId = [string]$provider.Value
        if ($providerId -notmatch '^[0-9A-Fa-f]{8}(-[0-9A-Fa-f]{4}){3}-[0-9A-Fa-f]{12}$') { continue }
        if (-not $bridgeProviders.ContainsKey($providerId)) {
            $enrollment = Get-ItemProperty -LiteralPath "HKLM:\SOFTWARE\Microsoft\Enrollments\$providerId" `
                -Name ProviderID -ErrorAction SilentlyContinue
            $bridgeProviders[$providerId] = $null -ne $enrollment -and
                [string]$enrollment.ProviderID -eq 'WMI_Bridge_SCCM_Server'
        }
        if ($bridgeProviders[$providerId]) {
            # The Start CSP documents 65535 as user-editable.
            $restored[$name] = 65535
        }
    }
    if ($restored.Count -eq 0) {
        Write-AtlasLog -Level Info -Message 'Start folder switches: none are locked by an earlier Atlas install.'
        return
    }

    $instances = @(Get-CimInstance -Namespace 'root\cimv2\mdm\dmmap' -ClassName 'MDM_Policy_Config01_Start02' `
            -Filter "ParentID='./Vendor/MSFT/Policy/Config' and InstanceID='Start'" -ErrorAction Stop)
    if ($instances.Count -ne 1) { throw 'The Start CSP did not return one configuration instance.' }

    $applied = Set-CimInstance -InputObject $instances[0] -Property $restored -PassThru -ErrorAction Stop
    foreach ($name in $restored.Keys) {
        if ($applied.CimInstanceProperties[$name].Value -ne 65535) {
            throw "The Start CSP did not return '$name' to the user-editable value."
        }
    }
    Write-AtlasLog -Level Info -Message 'Restored user control of the Start folder switches.'
}
catch {
    Write-AtlasLog -Level Warning -Message "Could not restore the Start folder switches: $($_.Exception.Message)"
}
