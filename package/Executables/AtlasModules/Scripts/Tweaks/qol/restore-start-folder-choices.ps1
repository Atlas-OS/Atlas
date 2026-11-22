# Companion of restore-start-folder-choices.psd1. The install runs as LocalSystem,
# which is required for device policy writes through the WMI bridge.
$ErrorActionPreference = 'Stop'

try {
    Import-AtlasModule -Name Atlas.InstallState
    if ((Get-AtlasInstalledVersion) -notin @('0.6.0', '0.6.1')) { return }

    $explorerPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
    $layout = Get-ItemProperty -LiteralPath $explorerPolicy -Name ConfigureStartPinsJSON -ErrorAction SilentlyContinue
    $atlasLayout = Join-Path ([Environment]::GetFolderPath('Windows')) 'AtlasModules\Other\StartLayout.json'
    if ($null -eq $layout -or [Environment]::ExpandEnvironmentVariables($layout.ConfigureStartPinsJSON) -ine $atlasLayout) { return }

    $policyPath = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start'
    $policy = Get-ItemProperty -LiteralPath $policyPath -ErrorAction SilentlyContinue
    if ($null -eq $policy) { return }

    # Atlas used the local WMI bridge. Only repair effective policies still owned
    # by that provider and still set to hidden. Leave other policy sources alone.
    $localProvider = 'C49328F1-A48C-408A-BA0C-972F051825D7'
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
        if ($null -ne $setting -and $setting.Value -eq 0 -and
            $null -ne $provider -and $provider.Value -eq $localProvider) {
            # The Start CSP documents 65535 as user-editable.
            $restored[$name] = 65535
        }
    }
    if ($restored.Count -eq 0) { return }

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
