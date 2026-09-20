BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module (Join-Path $PSScriptRoot '..\playbook\Executables\AtlasModules\Scripts\Modules\Atlas.Software\Atlas.Software.psd1') -Force
}

Describe 'NanaZip Store installation' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Software
        Mock Get-AtlasContext -ModuleName Atlas.Software { [pscustomobject]@{ IsOobe = $false } }
        Mock Get-AtlasNanaZipStoreJournal -ModuleName Atlas.Software { [pscustomobject]@{ Pending = $false } }
        Mock Set-AtlasNanaZipStorePending -ModuleName Atlas.Software
        Mock Start-Sleep -ModuleName Atlas.Software
    }

    It 'falls back before any Store request during OOBE' {
        Mock Get-AtlasContext -ModuleName Atlas.Software { [pscustomobject]@{ IsOobe = $true } }
        Mock New-AtlasNanaZipStoreManager -ModuleName Atlas.Software { throw 'must not activate Store' }
        InModuleScope Atlas.Software { Install-AtlasNanaZipFromStore -DismCommands @{} | Should -BeFalse }
        Should -Invoke New-AtlasNanaZipStoreManager -ModuleName Atlas.Software -Times 0 -Exactly
    }

    It 'falls back when Store cannot activate and there is no pending request' {
        Mock New-AtlasNanaZipStoreManager -ModuleName Atlas.Software { throw 'Store unavailable' }
        InModuleScope Atlas.Software { Install-AtlasNanaZipFromStore -DismCommands @{} | Should -BeFalse }
        Should -Invoke Set-AtlasNanaZipStorePending -ModuleName Atlas.Software -Times 0 -Exactly
    }

    It 'does not fall back when a previous request is unresolved' {
        Mock Get-AtlasNanaZipStoreJournal -ModuleName Atlas.Software { [pscustomobject]@{ Pending = $true } }
        Mock New-AtlasNanaZipStoreManager -ModuleName Atlas.Software { throw 'Store unavailable' }
        InModuleScope Atlas.Software { { Install-AtlasNanaZipFromStore -DismCommands @{} } | Should -Throw '*unknown outcome*' }
    }

    It 'requires provisioning after a completed Store operation' {
        InModuleScope Atlas.Software {
            Mock New-AtlasNanaZipStoreManager { [pscustomobject]@{ CanInstallForAllUsers = $true } }
            Mock Get-AtlasNanaZipStoreItems { [pscustomobject]@{ ProductId = '9N8G7TSCL18R' } }
            Mock Wait-AtlasNanaZipStoreItems { $true }
            $commands = @{ GetProvisionedPackage = { @() } }
            { Install-AtlasNanaZipFromStore -DismCommands $commands } | Should -Throw '*provisioning could not be verified*'
            Should -Invoke Set-AtlasNanaZipStorePending -Times 0 -Exactly -ParameterFilter { -not $Pending }
        }
    }

    It 'accepts verified provisioning and clears the pending marker' {
        InModuleScope Atlas.Software {
            Mock New-AtlasNanaZipStoreManager { [pscustomobject]@{ CanInstallForAllUsers = $true } }
            Mock Get-AtlasNanaZipStoreItems { [pscustomobject]@{ ProductId = '9N8G7TSCL18R' } }
            Mock Wait-AtlasNanaZipStoreItems { $true }
            $commands = @{ GetProvisionedPackage = { [pscustomobject]@{ DisplayName = '40174MouriNaruto.NanaZip' } } }
            Install-AtlasNanaZipFromStore -DismCommands $commands | Should -BeTrue
            Should -Invoke Set-AtlasNanaZipStorePending -Times 1 -Exactly -ParameterFilter { -not $Pending }
        }
    }

    It 'does not clear pending state if the Store queue cannot be read' {
        InModuleScope Atlas.Software {
            Mock Get-AtlasNanaZipStoreJournal { [pscustomobject]@{ Pending = $true } }
            Mock New-AtlasNanaZipStoreManager { [pscustomobject]@{ CanInstallForAllUsers = $true } }
            Mock Get-AtlasNanaZipStoreItems { throw 'queue unavailable' }
            { Install-AtlasNanaZipFromStore -DismCommands @{} } | Should -Throw '*unknown outcome*'
            Should -Invoke Set-AtlasNanaZipStorePending -Times 0 -Exactly
        }
    }

    It 'never falls back while a deployment is still active' {
        InModuleScope Atlas.Software {
            Mock New-AtlasNanaZipStoreManager { [pscustomobject]@{ CanInstallForAllUsers = $true } }
            Mock Get-AtlasNanaZipStoreItems { [pscustomobject]@{ ProductId = '9N8G7TSCL18R' } }
            Mock Wait-AtlasNanaZipStoreItems { throw 'still installing' }
            { Install-AtlasNanaZipFromStore -DismCommands @{} } | Should -Throw '*still installing*'
            Should -Invoke Set-AtlasNanaZipStorePending -Times 0 -Exactly -ParameterFilter { -not $Pending }
        }
    }

    It 'records pending state before requesting a fresh installation' {
        InModuleScope Atlas.Software {
            $script:storePending = $false
            Mock New-AtlasNanaZipStoreManager { [pscustomobject]@{ CanInstallForAllUsers = $true } }
            Mock Get-AtlasNanaZipStoreItems { @() }
            Mock Get-AtlasNanaZipStoreEntitlement
            Mock Set-AtlasNanaZipStorePending { $script:storePending = $Pending }
            Mock Request-AtlasNanaZipStoreInstall {
                $script:storePending | Should -BeTrue
                throw 'lost RPC response'
            }
            { Install-AtlasNanaZipFromStore -DismCommands @{} } | Should -Throw '*lost RPC response*'
            $script:storePending | Should -BeTrue
        }
    }

    It 'falls back on entitlement failure without requesting deployment' {
        InModuleScope Atlas.Software {
            Mock New-AtlasNanaZipStoreManager { [pscustomobject]@{ CanInstallForAllUsers = $true } }
            Mock Get-AtlasNanaZipStoreItems { @() }
            Mock Get-AtlasNanaZipStoreEntitlement { throw 'network unavailable' }
            Mock Request-AtlasNanaZipStoreInstall { throw 'must not deploy' }
            Install-AtlasNanaZipFromStore -DismCommands @{} | Should -BeFalse
            Should -Invoke Request-AtlasNanaZipStoreInstall -Times 0 -Exactly
        }
    }

    It 'allows fallback only after failed jobs are terminal and removed from the queue' {
        InModuleScope Atlas.Software {
            $script:queueReads = 0
            $manager = [pscustomobject]@{ CanInstallForAllUsers = $true }
            $manager | Add-Member ScriptMethod Cancel { param($ProductId) $ProductId | Should -BeExactly '9N8G7TSCL18R' }
            Mock New-AtlasNanaZipStoreManager { $manager }
            Mock Get-AtlasNanaZipStoreItems {
                $script:queueReads++
                if ($script:queueReads -le 2) { [pscustomobject]@{ ProductId='9N8G7TSCL18R' } }
            }
            Mock Wait-AtlasNanaZipStoreItems { $false }
            Install-AtlasNanaZipFromStore -DismCommands @{ GetProvisionedPackage = { @() } } | Should -BeFalse
            $script:queueReads | Should -Be 3
            Should -Invoke Set-AtlasNanaZipStorePending -Times 1 -Exactly -ParameterFilter { -not $Pending }
        }
    }
}

Describe 'Archive installer Store-first routing' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Software
        Mock Test-Path -ModuleName Atlas.Software -ParameterFilter { $LiteralPath -like '*7-Zip*' } { $false }
        Mock Get-AtlasDismProvisioningCommands -ModuleName Atlas.Software { @{ GetProvisionedPackage = { @() } } }
        Mock Install-AtlasNanaZip -ModuleName Atlas.Software { throw 'download must not start' }
        Mock Get-AtlasPinnedNanaZipReleaseAssets -ModuleName Atlas.Software { throw 'assets must not be fetched' }
    }

    It 'does not download installers when Store succeeds' {
        Mock Install-AtlasNanaZipFromStore -ModuleName Atlas.Software { $true }
        InModuleScope Atlas.Software { Install-AtlasArchiveTool -TempDir 'C:\unused' }
        Should -Invoke Install-AtlasNanaZip -ModuleName Atlas.Software -Times 0 -Exactly
        Should -Invoke Get-AtlasPinnedNanaZipReleaseAssets -ModuleName Atlas.Software -Times 0 -Exactly
    }

    It 'does not start download fallback after an uncertain Store result' {
        Mock Install-AtlasNanaZipFromStore -ModuleName Atlas.Software { throw 'deployment uncertain' }
        InModuleScope Atlas.Software { { Install-AtlasArchiveTool -TempDir 'C:\unused' } | Should -Throw '*deployment uncertain*' }
        Should -Invoke Install-AtlasNanaZip -ModuleName Atlas.Software -Times 0 -Exactly
    }
}

Describe 'Store deployment state handling' {
    It 'waits for every returned item, including dependencies' {
        InModuleScope Atlas.Software {
            Mock Write-AtlasLog
            $done = [pscustomobject]@{}
            $done | Add-Member ScriptMethod GetCurrentStatus { [pscustomobject]@{ InstallState='Completed'; PercentComplete=100; ErrorCode=$null } }
            $done | Add-Member NoteProperty ProductId '9N8G7TSCL18R'
            $active = [pscustomobject]@{ ProductId='dependency' }
            $active | Add-Member ScriptMethod GetCurrentStatus { [pscustomobject]@{ InstallState='Downloading'; PercentComplete=10; ErrorCode=$null } }
            { Wait-AtlasNanaZipStoreItems -Manager @{} -Items @($done,$active) -TimeoutSeconds 0 } | Should -Throw '*still queued or installing*'
            Wait-AtlasNanaZipStoreItems -Manager @{} -Items @($done) | Should -BeTrue
        }
    }
}
