BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:freshTweak = Join-Path $script:AtlasTestScriptsRoot 'Tweaks\qol\config-start-menu.ps1'
    $script:upgradeTweak = Join-Path $script:AtlasTestScriptsRoot 'Tweaks\qol\restore-start-folder-choices.ps1'
    # The local WMI bridge's provider ID differs on every PC; its enrollment names it.
    $script:folderPolicyWinner = '1CE5F9CB-B407-455C-A1F6-3DE4A511B361'
    $script:organisationProvider = 'B375585A-FFA3-42C4-89EE-F7E3E5BEE7C5'
    $script:folders = @(
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

    function Import-AtlasModule { param([string]$Name) [void]$Name }
    function Set-AtlasStartLayout { }
    function Invoke-AtlasUserAppxCacheCleanup { param([string]$Mode) [void]$Mode }
    function Write-AtlasLog { param([string]$Level, [string]$Message) $null = $Level; $null = $Message }
}

Describe 'Start folder choices during a fresh install' {
    It 'applies the layout and refreshes Start without configuring folder policies' {
        Mock Set-AtlasStartLayout
        Mock Invoke-AtlasUserAppxCacheCleanup
        Mock Get-CimInstance { throw 'Fresh installs do not need the Start CSP.' }
        Mock New-CimInstance { throw 'Fresh installs must not create a Start CSP policy.' }
        Mock Set-CimInstance { throw 'Fresh installs must not set a Start CSP policy.' }

        & $script:freshTweak

        Should -Invoke Set-AtlasStartLayout -Times 1 -Exactly
        Should -Invoke Invoke-AtlasUserAppxCacheCleanup -Times 1 -Exactly -ParameterFilter { $Mode -eq 'StartMenu' }
        Should -Not -Invoke Get-CimInstance
        Should -Not -Invoke New-CimInstance
        Should -Not -Invoke Set-CimInstance
    }
}

Describe 'Restoring Start folder choices on upgrade' {
    BeforeEach {
        $script:folderPolicyFixture = @{}
        foreach ($name in $script:folders) {
            $script:folderPolicyFixture[$name] = 0
            $script:folderPolicyFixture["${name}_WinningProvider"] = $script:folderPolicyWinner
        }
        $script:enrollments = @{
            $script:folderPolicyWinner = 'WMI_Bridge_SCCM_Server'
            $script:organisationProvider = 'MS DM Server'
        }
        Mock Get-ItemProperty { [pscustomobject]$script:folderPolicyFixture } -ParameterFilter { $LiteralPath -like '*\current\device\Start' }
        Mock Get-ItemProperty {
            $id = Split-Path -Leaf $LiteralPath
            if ($script:enrollments.ContainsKey($id)) { [pscustomobject]@{ ProviderID = $script:enrollments[$id] } }
        } -ParameterFilter { $LiteralPath -like '*\Microsoft\Enrollments\*' }
        Mock Get-ItemProperty {
            [pscustomobject]@{ ConfigureStartPinsJSON = '%SystemRoot%\AtlasModules\Other\StartLayout.json' }
        } -ParameterFilter { $Name -eq 'ConfigureStartPinsJSON' }
        Mock Get-CimInstance { [pscustomobject]@{ InstanceID = 'Start' } }
        Mock Set-CimInstance {
            $applied = @{}
            foreach ($propertyName in $Property.Keys) {
                $applied[$propertyName] = [pscustomobject]@{ Value = $Property[$propertyName] }
            }
            [pscustomobject]@{ CimInstanceProperties = $applied }
        } -RemoveParameterType 'InputObject'
        Mock Write-AtlasLog
    }

    It 'restores user choice for the nine Atlas folder policies through the existing CSP instance' {
        . $script:upgradeTweak

        Should -Invoke Get-ItemProperty -Times 1 -Exactly -ParameterFilter { $Name -eq 'ConfigureStartPinsJSON' }
        # One enrollment lookup for the one provider all nine values share.
        Should -Invoke Get-ItemProperty -Times 1 -Exactly -ParameterFilter { $LiteralPath -like '*\Microsoft\Enrollments\*' }
        Should -Invoke Get-ItemProperty -Times 1 -Exactly -ParameterFilter { $LiteralPath -like '*\current\device\Start' }
        Should -Invoke Get-CimInstance -Times 1 -Exactly -ParameterFilter {
            $Namespace -eq 'root\cimv2\mdm\dmmap' -and $ClassName -eq 'MDM_Policy_Config01_Start02' -and
            $Filter -eq "ParentID='./Vendor/MSFT/Policy/Config' and InstanceID='Start'"
        }
        Should -Invoke Set-CimInstance -Times 1 -Exactly -ParameterFilter {
            $InputObject.InstanceID -eq 'Start' -and $PassThru -and $Property.Count -eq $script:folders.Count -and
            @($script:folders | Where-Object { $Property[$_] -ne 65535 }).Count -eq 0
        }
        Should -Invoke Write-AtlasLog -Times 1 -Exactly -ParameterFilter { $Level -eq 'Info' }
    }

    It 'skips organisation-managed, already editable, visible, and absent folder values' {
        $script:folderPolicyFixture['AllowPinnedFolderSettings_WinningProvider'] = $script:organisationProvider
        $script:folderPolicyFixture['AllowPinnedFolderPictures'] = 65535
        $script:folderPolicyFixture['AllowPinnedFolderDocuments'] = 1
        $script:folderPolicyFixture.Remove('AllowPinnedFolderMusic')

        . $script:upgradeTweak

        Should -Invoke Set-CimInstance -Times 1 -Exactly -ParameterFilter {
            $Property.Count -eq 5 -and
            -not $Property.ContainsKey('AllowPinnedFolderSettings') -and
            -not $Property.ContainsKey('AllowPinnedFolderPictures') -and
            -not $Property.ContainsKey('AllowPinnedFolderDocuments') -and
            -not $Property.ContainsKey('AllowPinnedFolderMusic')
        }
    }

    It 'skips an installation without an Atlas Start layout policy' {
        Mock Get-ItemProperty {
            [pscustomobject]@{ ConfigureStartPinsJSON = 'C:\Managed\Start.json' }
        } -ParameterFilter { $Name -eq 'ConfigureStartPinsJSON' }

        . $script:upgradeTweak

        Should -Not -Invoke Get-CimInstance
        Should -Not -Invoke Set-CimInstance
    }

    It 'skips values from a provider with no enrollment, or an ID that is not a GUID' {
        $script:enrollments.Remove($script:folderPolicyWinner)
        $script:folderPolicyFixture['AllowPinnedFolderVideos_WinningProvider'] = '..\..\Policies'

        . $script:upgradeTweak

        Should -Not -Invoke Get-ItemProperty -ParameterFilter { $LiteralPath -like '*Policies' -and $LiteralPath -like '*Enrollments*' }
        Should -Not -Invoke Get-CimInstance
        Should -Not -Invoke Set-CimInstance
        Should -Invoke Write-AtlasLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Info' -and $Message -like '*none are locked*'
        }
    }

    It 'logs a warning and continues when the policy provider fails' {
        Mock Set-CimInstance { throw 'CSP unavailable' } -RemoveParameterType 'InputObject'

        { . $script:upgradeTweak } | Should -Not -Throw

        Should -Invoke Write-AtlasLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -like '*CSP unavailable*'
        }
    }
}
