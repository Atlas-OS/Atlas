# Toggle: Printing services, features and 'Print' context menu entries.
#
# The ContextAction handles only the 'Print' context menu entries so that callers can use
# /justcontext (e.g. the "Remove 'Printing' from Context Menus" tweak) without touching
# services, settings pages or Windows features.
#
# NOTE: Action scriptblocks run in a fresh scope, so all data they need is defined inside
# each block instead of at the top of this file.
@{
    Name      = 'Printing'
    Elevation = 'Admin'
    Warning   = 'WARNING: This script will modify system services. Modifying services can lead to potential breakage of features and bugs. Proceed with caution, and refer to Atlas docs for more information!'
    States    = [ordered]@{
        Disable = @{
            StateValue    = 0
            Launcher      = '6. Advanced Configuration\Services\Printing\Disable Printing.cmd'
            Reboot        = 'Recommend'
            ContextAction = {
                param($Toggle)

                Write-Host "Removing 'Print' from context menu..."

                $printKeys = @('Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\image\shell\print')
                foreach ($fileType in @(
                    'batfile', 'cmdfile', 'docxfile', 'fonfile', 'htmlfile', 'inffile', 'inifile',
                    'JSEFile', 'otffile', 'pfmfile', 'regfile', 'rtffile', 'ttcfile', 'ttffile',
                    'txtfile', 'VBEFile', 'VBSFile', 'WSFFile'
                )) {
                    $printKeys += "Registry::HKEY_CLASSES_ROOT\$fileType\shell\print"
                }
                foreach ($key in $printKeys) {
                    if (-not (Test-Path -LiteralPath $key)) {
                        New-Item -Path $key -Force | Out-Null
                    }
                    New-ItemProperty -LiteralPath $key -Name 'ProgrammaticAccessOnly' -Value '' -PropertyType String -Force | Out-Null
                }

                if ($Toggle.WindowsBuild -ge 22000) {
                    foreach ($key in @(
                        'Registry::HKEY_CLASSES_ROOT\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\Print'
                        'Registry::HKEY_CLASSES_ROOT\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\PrintTo'
                    )) {
                        if (-not (Test-Path -LiteralPath $key)) {
                            New-Item -Path $key -Force | Out-Null
                        }
                        New-ItemProperty -LiteralPath $key -Name 'LegacyDisable' -Value '' -PropertyType String -Force | Out-Null
                        New-ItemProperty -LiteralPath $key -Name 'ProgrammaticAccessOnly' -Value '' -PropertyType String -Force | Out-Null
                        New-ItemProperty -LiteralPath $key -Name 'HideBasedOnVelocityId' -Value 6527944 -PropertyType DWord -Force | Out-Null
                    }
                }
            }
            Action        = {
                param($Toggle)

                Write-Host 'Disabling services...'
                $setServiceStartup = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-ServiceStartup.ps1'
                & $setServiceStartup -Name 'Spooler' -Start 4
                & $setServiceStartup -Name 'PrintWorkFlowUserSvc' -Start 4

                $settingsPages = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-SettingsPageVisibility.ps1'
                & $settingsPages hide printers -Silent:$Toggle.Silent

                Write-Host 'Disabling features...'
                foreach ($feature in @(
                    'Printing-Foundation-Features'
                    'Printing-Foundation-InternetPrinting-Client'
                    'Printing-XPSServices-Features'
                    'Printing-PrintToPDFServices-Features'
                )) {
                    & "$($Toggle.WinDir)\System32\dism.exe" /Online /Disable-Feature /FeatureName:$feature /NoRestart | Out-Null
                }
            }
        }
        Enable  = @{
            StateValue    = 1
            Launcher      = '6. Advanced Configuration\Services\Printing\Enable Printing (default).cmd'
            Reboot        = 'Recommend'
            ContextAction = {
                param($Toggle)

                # Silent mode skips the context menu prompt entirely.
                if ($Toggle.Silent) {
                    return
                }

                $answer = Read-Host "Would you like to add 'Print' to the context menu? [Y/N]"
                if ($answer -notmatch '^(y|yes)$') {
                    return
                }

                Write-Host "Adding 'Print' to context menu..."

                $printKeys = @('Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\image\shell\print')
                foreach ($fileType in @(
                    'batfile', 'cmdfile', 'docxfile', 'fonfile', 'htmlfile', 'inffile', 'inifile',
                    'JSEFile', 'otffile', 'pfmfile', 'regfile', 'rtffile', 'ttcfile', 'ttffile',
                    'txtfile', 'VBEFile', 'VBSFile', 'WSFFile'
                )) {
                    $printKeys += "Registry::HKEY_CLASSES_ROOT\$fileType\shell\print"
                }
                foreach ($key in $printKeys) {
                    Remove-ItemProperty -LiteralPath $key -Name 'ProgrammaticAccessOnly' -Force -ErrorAction SilentlyContinue
                }

                if ($Toggle.WindowsBuild -ge 22000) {
                    foreach ($key in @(
                        'Registry::HKEY_CLASSES_ROOT\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\Print'
                        'Registry::HKEY_CLASSES_ROOT\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\PrintTo'
                    )) {
                        foreach ($valueName in @('LegacyDisable', 'ProgrammaticAccessOnly', 'HideBasedOnVelocityId')) {
                            Remove-ItemProperty -LiteralPath $key -Name $valueName -Force -ErrorAction SilentlyContinue
                        }
                    }
                }
            }
            Action        = {
                param($Toggle)

                Write-Host 'Enabling services...'
                $setServiceStartup = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-ServiceStartup.ps1'
                & $setServiceStartup -Name 'Spooler' -Start 2
                & $setServiceStartup -Name 'PrintWorkFlowUserSvc' -Start 3

                $settingsPages = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-SettingsPageVisibility.ps1'
                & $settingsPages unhide printers -Silent:$Toggle.Silent

                Write-Host 'Enabling features...'
                $dism = "$($Toggle.WinDir)\System32\dism.exe"
                foreach ($feature in @(
                    'Printing-Foundation-Features'
                    'Printing-Foundation-InternetPrinting-Client'
                    'Printing-XPSServices-Features'
                    'Printing-PrintToPDFServices-Features'
                )) {
                    & $dism /Online /Enable-Feature /FeatureName:$feature /NoRestart | Out-Null
                }

                Write-Host 'Enabling capabilities (this might take a while)...'
                & $dism /Online /Add-Capability /CapabilityName:'Print.Management.Console~~~~0.0.1.0' /NoRestart | Out-Null

                if (-not $Toggle.Silent) {
                    $answer = Read-Host 'Would you want to enable Fax and Scan functionality? [Y/N]'
                    if ($answer -match '^(y|yes)$') {
                        & $dism /Online /Add-Capability /CapabilityName:'Print.Fax.Scan~~~~0.0.1.0' /NoRestart | Out-Null
                    }
                }
            }
        }
    }
}
