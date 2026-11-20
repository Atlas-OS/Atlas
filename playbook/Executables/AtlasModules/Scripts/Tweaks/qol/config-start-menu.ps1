# Companion of config-start-menu.psd1.
$ErrorActionPreference = 'Stop'

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

    try {
        $instances = @(Get-CimInstance -Namespace $namespace -ClassName $className `
                -Filter "ParentID='$parentId' and InstanceID='$instanceId'" `
                -ErrorAction Stop)
    }
    catch {
        Write-Warning "Start policy CSP query failed: $($_.Exception.Message). Applying registry fallback."
        $policyManagerPath = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start'
        if (-not (Test-Path -LiteralPath $policyManagerPath)) {
            New-Item -Path $policyManagerPath -Force -ErrorAction SilentlyContinue | Out-Null
        }
        foreach ($name in $folderProperties) {
            Set-ItemProperty -Path $policyManagerPath -Name $name -Value 0 -Type DWord -ErrorAction SilentlyContinue
        }
        return
    }

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
        try {
            $instance = New-CimInstance -Namespace $namespace -ClassName $className `
                -Property $properties -ErrorAction Stop
        }
        catch {
            Write-Warning "Start pinned-folder policy via MDM bridge was not supported on this build: $($_.Exception.Message). Applying registry fallback."
            $policyManagerPath = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start'
            if (-not (Test-Path -LiteralPath $policyManagerPath)) {
                New-Item -Path $policyManagerPath -Force -ErrorAction SilentlyContinue | Out-Null
            }
            foreach ($name in $folderProperties) {
                Set-ItemProperty -Path $policyManagerPath -Name $name -Value 0 -Type DWord -ErrorAction SilentlyContinue
            }
            return
        }
    }
    else {
        $instance = $instances[0]
        foreach ($name in $folderProperties) {
            $instance.CimInstanceProperties[$name].Value = 0
        }
        try {
            $instance = Set-CimInstance -CimInstance $instance -PassThru -ErrorAction Stop
        }
        catch {
            Write-Warning "Start pinned-folder policy update via MDM bridge was not supported on this build: $($_.Exception.Message). Applying registry fallback."
            $policyManagerPath = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start'
            if (-not (Test-Path -LiteralPath $policyManagerPath)) {
                New-Item -Path $policyManagerPath -Force -ErrorAction SilentlyContinue | Out-Null
            }
            foreach ($name in $folderProperties) {
                Set-ItemProperty -Path $policyManagerPath -Name $name -Value 0 -Type DWord -ErrorAction SilentlyContinue
            }
            return
        }
    }

    foreach ($name in $folderProperties) {
        if ([int]$instance.CimInstanceProperties[$name].Value -ne 0) {
            throw "Start pinned-folder policy '$name' did not apply the hidden state."
        }
    }
}

# Set the Start Menu layout for every user.
Import-AtlasModule -Name Atlas.Shell
Set-AtlasStartLayout

# Keep every optional folder beside the Start power button hidden.
Set-AtlasStartPinnedFolderPolicy

# Clear the Start Menu experience host cache so the new layout takes effect.
Import-AtlasModule -Name Atlas.Appx
Invoke-AtlasUserAppxCacheCleanup -Mode StartMenu
