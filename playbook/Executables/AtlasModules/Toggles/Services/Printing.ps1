function Set-AtlasPrintContextMenu {
    param($Toggle)

    $enable = $Toggle.State -ceq 'Enable'
    if ($enable) {
        if ($Toggle.Silent) {
            return
        }
        if (-not (Read-AtlasYesNo -Question "Add 'Print' to the file context menu?")) {
            return
        }
    }

    if (-not $Toggle.Silent) {
        if ($enable) {
            Write-AtlasStep -Text "Adding 'Print' to the file context menu..."
        }
        else {
            Write-AtlasStep -Text "Removing 'Print' from the file context menu..."
        }
    }

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
            Set-AtlasRegistryValue -Path $key -Name 'ProgrammaticAccessOnly' -Type String -Data ''
        }
    }

    foreach ($key in @(
            "$classesRoot\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\Print"
            "$classesRoot\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\PrintTo"
        )) {
        if ($enable) {
            foreach ($valueName in @('LegacyDisable', 'ProgrammaticAccessOnly', 'HideBasedOnVelocityId')) {
                Remove-AtlasRegistryValue -Path $key -Name $valueName
            }
        }
        else {
            Set-AtlasRegistryValue -Path $key -Name 'LegacyDisable' -Type String -Data ''
            Set-AtlasRegistryValue -Path $key -Name 'ProgrammaticAccessOnly' -Type String -Data ''
            Set-AtlasRegistryValue -Path $key -Name 'HideBasedOnVelocityId' -Type DWord -Data 6527944
        }
    }
}

function Set-AtlasPrintingMachineState {
    param($Toggle)

    $enable = $Toggle.State -ceq 'Enable'
    $verb = if ($enable) { 'Enabling' } else { 'Disabling' }

    if (-not $Toggle.Silent) {
        Write-AtlasStep -Text "$verb the printing services..."
    }
    Set-AtlasServiceStartup -Name 'Spooler' -StartupType $(if ($enable) { 2 } else { 4 })
    Set-AtlasServiceStartup -Name 'PrintWorkFlowUserSvc' -StartupType $(if ($enable) { 3 } else { 4 }) -AllowMissing

    Import-AtlasModule -Name Atlas.Shell
    $visibility = if ($enable) { 'unhide' } else { 'hide' }
    Set-AtlasSettingsPageVisibility -Operation $visibility -Page printers

    if (-not $Toggle.Silent) {
        Write-AtlasStep -Text "$verb the Windows printing features. This can take a while..."
    }
    $dism = Join-Path -Path $Toggle.WinDir -ChildPath 'System32\dism.exe'
    $featureOperation = if ($enable) { '/Enable-Feature' } else { '/Disable-Feature' }
    foreach ($feature in @(
            'Printing-Foundation-Features'
            'Printing-Foundation-InternetPrinting-Client'
            'Printing-XPSServices-Features'
            'Printing-PrintToPDFServices-Features'
        )) {
        Invoke-AtlasToggleNativeCommand -FilePath $dism `
            -ArgumentList ([string[]]@('/Online', $featureOperation, "/FeatureName:$feature", '/NoRestart')) `
            -AllowedExitCodes ([int[]]@(0, 3010)) | Out-Null
    }

    if (-not $enable) {
        return
    }

    if (-not $Toggle.Silent) {
        Write-AtlasStep -Text 'Adding the Print Management console. This can take a while...'
    }
    Invoke-AtlasToggleNativeCommand -FilePath $dism `
        -ArgumentList ([string[]]@('/Online', '/Add-Capability', '/CapabilityName:Print.Management.Console~~~~0.0.1.0', '/NoRestart')) `
        -AllowedExitCodes ([int[]]@(0, 3010)) | Out-Null

    if (-not $Toggle.Silent -and (Read-AtlasYesNo -Question 'Also add Windows Fax and Scan?')) {
        Write-AtlasStep -Text 'Adding Windows Fax and Scan...'
        Invoke-AtlasToggleNativeCommand -FilePath $dism `
            -ArgumentList ([string[]]@('/Online', '/Add-Capability', '/CapabilityName:Print.Fax.Scan~~~~0.0.1.0', '/NoRestart')) `
            -AllowedExitCodes ([int[]]@(0, 3010)) | Out-Null
    }
}
