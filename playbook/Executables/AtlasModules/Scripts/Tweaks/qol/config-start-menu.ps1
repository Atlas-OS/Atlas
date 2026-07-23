# Companion of config-start-menu.psd1.
$ErrorActionPreference = 'Stop'
$windir = [Environment]::GetFolderPath('Windows')
$scriptsRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).ProviderPath

function Set-AtlasStartPinnedFolderPolicy {
    # These are device-scoped Start CSP settings. Microsoft exposes no equivalent
    # GPO or Start-layout JSON field, so apply them through the supported WMI bridge.
    # The install phase already runs as LocalSystem, as required by the provider.
    $namespace = 'root\cimv2\mdm\dmmap'
    $className = 'MDM_Policy_Config01_Start02'
    $parentId = './Vendor/MSFT/Policy/Config'
    $instanceId = 'Start'
    $folderProperties = @(
        'AllowPinnedFolderSettings'
        'AllowPinnedFolderFileExplorer'
        'AllowPinnedFolderDocuments'
        'AllowPinnedFolderDownloads'
        'AllowPinnedFolderMusic'
        'AllowPinnedFolderPictures'
        'AllowPinnedFolderVideos'
        'AllowPinnedFolderNetwork'
        'AllowPinnedFolderPersonalFolder'
    )

    $instances = @(Get-CimInstance -Namespace $namespace -ClassName $className `
            -Filter "ParentID='$parentId' and InstanceID='$instanceId'" `
            -ErrorAction Stop)
    if ($instances.Count -gt 1) {
        throw "The Start policy CSP returned more than one configuration instance."
    }

    if ($instances.Count -eq 0) {
        $properties = @{
            ParentID = $parentId
            InstanceID = $instanceId
        }
        foreach ($name in $folderProperties) {
            $properties[$name] = 0
        }
        $instance = New-CimInstance -Namespace $namespace -ClassName $className `
            -Property $properties -ErrorAction Stop
    }
    else {
        $instance = $instances[0]
        foreach ($name in $folderProperties) {
            $instance.CimInstanceProperties[$name].Value = 0
        }
        $instance = Set-CimInstance -CimInstance $instance -PassThru -ErrorAction Stop
    }

    foreach ($name in $folderProperties) {
        if ([int]$instance.CimInstanceProperties[$name].Value -ne 0) {
            throw "Start pinned-folder policy '$name' did not apply the hidden state."
        }
    }
}

# Set the Start Menu layout for every user.
& (Join-Path -Path $windir -ChildPath 'AtlasModules\Scripts\Internal\Set-StartLayout.ps1')

# Keep every optional folder beside the Start power button hidden.
Set-AtlasStartPinnedFolderPolicy

# Clear the Start Menu experience host cache so the new layout takes effect.
Import-Module -Name (Join-Path $scriptsRoot 'Modules\Atlas.Appx\Atlas.Appx.psd1') `
    -Force -ErrorAction Stop
Invoke-AtlasUserAppxCacheCleanup -Mode StartMenu
