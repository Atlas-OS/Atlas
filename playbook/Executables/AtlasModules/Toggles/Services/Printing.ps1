# Toggle: Printing services, features and 'Print' context menu entries.
# ContextAction remains independently callable through /justcontext.
$contextAction = {
    param($Toggle)

    $enable = $Toggle.State -ceq 'Enable'
    if ($enable) {
        if ($Toggle.Silent) {
            return
        }
        if ((Read-Host "Would you like to add 'Print' to the context menu? [Y/N]") `
            -notmatch '^(y|yes)$') {
            return
        }
    }

    $message = if ($enable) {
        "Adding 'Print' to context menu..."
    }
    else {
        "Removing 'Print' from context menu..."
    }
    Write-Host $message
    Import-Module -Name (Join-Path $Toggle.ScriptsPath `
            'Modules\Atlas.Registry\Atlas.Registry.psd1') `
        -Force -ErrorAction Stop

    $classesRoot = 'HKLM:\SOFTWARE\Classes'
    $printKeys = @("$classesRoot\SystemFileAssociations\image\shell\print")
    foreach ($fileType in @(
            'batfile', 'cmdfile', 'docxfile', 'fonfile', 'htmlfile', 'inffile', 'inifile',
            'JSEFile', 'otffile', 'pfmfile', 'regfile', 'rtffile', 'ttcfile', 'ttffile',
            'txtfile', 'VBEFile', 'VBSFile', 'WSFFile'
        )) {
        $printKeys += "$classesRoot\$fileType\shell\print"
    }
    foreach ($key in $printKeys) {
        if ($enable) {
            Remove-AtlasRegistryValue -Path $key -Name 'ProgrammaticAccessOnly'
        }
        else {
            Set-AtlasRegistryValue -Path $key -Name 'ProgrammaticAccessOnly' `
                -Type String -Data ''
        }
    }

    if ($Toggle.WindowsBuild -ge 22000) {
        foreach ($key in @(
                "$classesRoot\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\Print"
                "$classesRoot\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\PrintTo"
            )) {
            if ($enable) {
                foreach ($valueName in @(
                        'LegacyDisable', 'ProgrammaticAccessOnly', 'HideBasedOnVelocityId'
                    )) {
                    Remove-AtlasRegistryValue -Path $key -Name $valueName
                }
            }
            else {
                Set-AtlasRegistryValue -Path $key -Name 'LegacyDisable' -Type String -Data ''
                Set-AtlasRegistryValue -Path $key -Name 'ProgrammaticAccessOnly' `
                    -Type String -Data ''
                Set-AtlasRegistryValue -Path $key -Name 'HideBasedOnVelocityId' `
                    -Type DWord -Data 6527944
            }
        }
    }
}

$action = {
    param($Toggle)

    $enable = $Toggle.State -ceq 'Enable'
    $verb = if ($enable) { 'Enabling' } else { 'Disabling' }
    Write-Host "$verb services..."
    $setServiceStartup = Join-Path -Path $Toggle.ScriptsPath `
        -ChildPath 'Internal\Set-ServiceStartup.ps1'
    $spoolerStart = if ($enable) { 2 } else { 4 }
    $workflowStart = if ($enable) { 3 } else { 4 }
    & $setServiceStartup -Name 'Spooler' -Start $spoolerStart
    & $setServiceStartup -Name 'PrintWorkFlowUserSvc' `
        -Start $workflowStart -AllowMissing

    $settingsPages = Join-Path -Path $Toggle.ScriptsPath `
        -ChildPath 'Internal\Set-SettingsPageVisibility.ps1'
    $visibility = if ($enable) { 'unhide' } else { 'hide' }
    & $settingsPages $visibility printers -Silent:$Toggle.Silent

    Write-Host "$verb features..."
    $dism = "$($Toggle.WinDir)\System32\dism.exe"
    $featureOperation = if ($enable) { '/Enable-Feature' } else { '/Disable-Feature' }
    foreach ($feature in @(
            'Printing-Foundation-Features'
            'Printing-Foundation-InternetPrinting-Client'
            'Printing-XPSServices-Features'
            'Printing-PrintToPDFServices-Features'
        )) {
        Invoke-AtlasToggleNativeCommand `
            -FilePath $dism `
            -ArgumentList ([string[]]@(
                '/Online', $featureOperation, "/FeatureName:$feature", '/NoRestart'
            )) `
            -AllowedExitCodes ([int[]]@(0, 3010)) | Out-Null
    }

    if (-not $enable) {
        return
    }

    Write-Host 'Enabling capabilities (this might take a while)...'
    Invoke-AtlasToggleNativeCommand `
        -FilePath $dism `
        -ArgumentList ([string[]]@(
            '/Online'
            '/Add-Capability'
            '/CapabilityName:Print.Management.Console~~~~0.0.1.0'
            '/NoRestart'
        )) `
        -AllowedExitCodes ([int[]]@(0, 3010)) | Out-Null

    if (-not $Toggle.Silent -and
        (Read-Host 'Would you want to enable Fax and Scan functionality? [Y/N]') `
            -match '^(y|yes)$') {
        Invoke-AtlasToggleNativeCommand `
            -FilePath $dism `
            -ArgumentList ([string[]]@(
                '/Online'
                '/Add-Capability'
                '/CapabilityName:Print.Fax.Scan~~~~0.0.1.0'
                '/NoRestart'
            )) `
            -AllowedExitCodes ([int[]]@(0, 3010)) | Out-Null
    }
}

@{
    Name      = 'Printing'
    Elevation = 'Admin'
    Warning   = 'WARNING: This script will modify system services. Modifying services can lead to potential breakage of features and bugs. Proceed with caution, and refer to Atlas docs for more information!'
    States    = [ordered]@{
        Disable = @{
            StateValue    = 0
            ReplayScope   = 'Machine'
            Launcher      = '6. Advanced Configuration\Services\Printing\Disable Printing.cmd'
            Reboot        = 'Recommend'
            ContextAction = $contextAction
            Action        = $action
        }
        Enable  = @{
            StateValue    = 1
            ReplayScope   = 'Machine'
            Launcher      = '6. Advanced Configuration\Services\Printing\Enable Printing (default).cmd'
            Reboot        = 'Recommend'
            ContextAction = $contextAction
            Action        = $action
        }
    }
}
