BeforeAll {
    . (Join-Path $PSScriptRoot '..\playbook\Executables\AtlasModules\Scripts\Preparation\Update-Windows.ps1') -JobPath $TestDrive -FunctionsOnly
}

Describe 'Signed-in preparation ownership' {
    It 'rejects SYSTEM, session zero and another administrator account' {
        Mock Get-PreparationSessionOwner { 'S-1-5-21-1-2-3-1001' }
        { Assert-PreparationUser -UserSid 'S-1-5-18' -SessionId 1 } | Should -Throw '*session owner*'
        { Assert-PreparationUser -UserSid 'S-1-5-21-1-2-3-1001' -SessionId 0 } | Should -Throw '*session owner*'
        { Assert-PreparationUser -UserSid 'S-1-5-21-1-2-3-1002' -SessionId 1 } | Should -Throw '*session owner*'
        { Assert-PreparationUser -UserSid 'S-1-5-21-1-2-3-1001' -SessionId 1 } | Should -Not -Throw
    }
    It 'fails closed when Windows cannot identify the session owner' {
        Mock Get-PreparationSessionOwner { throw 'WTS unavailable' }
        { Assert-PreparationUser -UserSid 'S-1-5-21-1-2-3-1001' -SessionId 1 } | Should -Throw '*WTS unavailable*'
    }
}

Describe 'Protected preparation recovery journals' {
    It 'uses the same protected administrator-owned descriptor as recovery staging' {
        $security = Get-PreparationStateSecurity
        $security.GetSecurityDescriptorSddlForm([Security.AccessControl.AccessControlSections]::All) | Should -Be 'O:BAG:BAD:P(A;;FA;;;SY)(A;;FA;;;BA)(A;;0x1200a9;;;BU)'
    }
    It 'does not stop for an empty precreated cancellation marker' {
        Set-Variable -Name PersistentCancellation -Value $true
        $JobPath = Join-Path $TestDrive 'persistent-cancel'
        [void][IO.Directory]::CreateDirectory($JobPath)
        $marker = Join-Path $JobPath 'cancel'
        [IO.File]::WriteAllText($marker, '')
        { Assert-PreparationContinue } | Should -Not -Throw
        [IO.File]::WriteAllText($marker, 'cancel')
        { Assert-PreparationContinue } | Should -Throw '*stopped*'
        [IO.File]::WriteAllText($marker, 'stop requested')
        { Assert-PreparationContinue } | Should -Throw '*stopped*'
        [IO.File]::Delete($marker)
        { Assert-PreparationContinue } | Should -Throw
    }
    It 'atomically writes recovery records and refuses an existing temporary file' {
        Set-Variable -Name PersistentCancellation -Value $true
        $JobPath = Join-Path $TestDrive 'persistent-state'
        [void][IO.Directory]::CreateDirectory($JobPath)
        # Exercise real file creation/flush/replace under a fixture-only user ACL.
        # The exact production administrator descriptor is checked separately.
        Mock Get-PreparationStateSecurity {
            $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
            $security = New-Object Security.AccessControl.FileSecurity
            $security.SetSecurityDescriptorSddlForm("O:${sid}D:P(A;;FA;;;${sid})")
            return $security
        }
        Mock Get-ItemProperty { [pscustomobject]@{CurrentBuildNumber='26200'; UBR=9278} }
        Write-PreparationState running verify
        Write-PreparationState complete verify
        $path = Join-Path $JobPath 'state.json'
        $record = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        $record.status | Should -Be 'complete'
        $record.processStart | Should -BeGreaterThan 0
        (Get-Item -LiteralPath $path).GetAccessControl().AreAccessRulesProtected | Should -BeTrue
        $before = (Get-FileHash -LiteralPath $path).Hash
        $temporary = Join-Path $JobPath 'state.tmp'
        [IO.File]::WriteAllText($temporary, 'existing file')
        { Write-PreparationState failed verify } | Should -Throw
        [IO.File]::ReadAllText($temporary) | Should -Be 'existing file'
        (Get-FileHash -LiteralPath $path).Hash | Should -Be $before
    }
}

Describe 'Live preparation verification without installing updates' {
    BeforeEach {
        $script:OfferedUpdates = @()
        $script:StoreOptions = [pscustomobject]@{ AllowForcedAppRestart=$true; AutomaticallyDownloadAndInstallUpdateIfFound=$true }
        $script:StoreManager = [pscustomobject]@{ AppInstallItems=@() }
        $script:StoreManager | Add-Member ScriptMethod SearchForAllUpdatesAsync {
            param($Correlation, $Client, $Options)
            $script:SearchArguments = @($Correlation, $Client, $Options)
            return $null
        }
        $script:StoreManager | Add-Member ScriptMethod Restart { throw 'Verification must not start Store updates.' }
        $script:StoreManager | Add-Member ScriptMethod Cancel { throw 'Verification must not cancel another queue.' }
        Mock Assert-PreparationContinue {}
        Mock Assert-PreparationUser {}
        Mock Test-PreparationRestart { $false }
        Mock Test-PreparationNetwork { $true }
        Mock Write-PreparationState {}
        Mock Find-PreparationWindowsUpdate { @() }
        Mock New-PreparationStoreManager { $script:StoreManager }
        Mock Wait-PreparationStoreSearch { $script:OfferedUpdates }
        Mock New-Object {
            if ($ComObject -eq 'Microsoft.Update.Session') { return [pscustomobject]@{ ClientApplicationID='' } }
            if ($TypeName -eq 'Windows.ApplicationModel.Store.Preview.InstallControl.AppUpdateOptions') { return $script:StoreOptions }
            throw 'Unexpected provider construction.'
        }
    }
    It 'accepts completed live scans and never requests downloads or app restarts' {
        { Assert-PreparationCurrent } | Should -Not -Throw
        $script:StoreOptions.AllowForcedAppRestart | Should -BeFalse
        $script:StoreOptions.AutomaticallyDownloadAndInstallUpdateIfFound | Should -BeFalse
        Should -Invoke Find-PreparationWindowsUpdate -Times 2 -Exactly
        Should -Invoke Wait-PreparationStoreSearch -Times 1 -Exactly
    }
    It 'blocks before Store if Windows offers required updates' {
        Mock Find-PreparationWindowsUpdate { [pscustomobject]@{ Title='Required update' } }
        { Assert-PreparationCurrent } | Should -Throw '*Windows still offers*'
        Should -Invoke New-PreparationStoreManager -Times 0 -Exactly
    }
    It 'does not treat an empty new Store search as completion while its queue is active' {
        $item = [pscustomobject]@{}
        $item | Add-Member ScriptMethod GetCurrentStatus { [pscustomobject]@{ InstallState='Downloading' } }
        $script:StoreManager.AppInstallItems = @($item)
        { Assert-PreparationCurrent } | Should -Throw '*Store apps still need updates*'
    }
    It 'blocks paused updates returned by the Store search without resuming them' {
        $item = [pscustomobject]@{}
        $item | Add-Member ScriptMethod GetCurrentStatus { [pscustomobject]@{ InstallState='Paused' } }
        $script:OfferedUpdates = @($item)
        { Assert-PreparationCurrent } | Should -Throw '*queued updates*'
    }
    It 'blocks unavailable Store providers rather than trusting an earlier receipt' {
        Mock New-PreparationStoreManager { throw 'Store unavailable' }
        { Assert-PreparationCurrent } | Should -Throw '*Store unavailable*'
    }
    It 'checks user ownership and connectivity before touching providers' {
        Mock Assert-PreparationUser { throw 'wrong account' }
        { Assert-PreparationCurrent } | Should -Throw '*wrong account*'
        Should -Invoke Find-PreparationWindowsUpdate -Times 0 -Exactly
        Mock Assert-PreparationUser {}
        Mock Test-PreparationNetwork { $false }
        { Assert-PreparationCurrent } | Should -Throw '*unrestricted internet*'
        Should -Invoke Find-PreparationWindowsUpdate -Times 0 -Exactly
    }
}

Describe 'Preparation restart recovery after provider failures' {
    BeforeEach {
        Mock Assert-PreparationContinue {}
        Mock Write-PreparationState {}
        Mock Invoke-PreparationWindows { 'complete' }
        Mock Invoke-PreparationStore {}
        Mock Test-PreparationRestart { $false }
    }
    It 'reports a Store failure as restart required when Windows has pending changes' {
        Mock Invoke-PreparationStore { throw 'Store deployment failed' }
        Mock Test-PreparationRestart { $true }
        Invoke-PreparationUpdates | Should -Be 'reboot'
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'Store deployment failed'
        Should -Invoke Invoke-PreparationWindows -Times 1 -Exactly
    }
    It 'preserves a provider failure when no restart is pending' {
        Mock Invoke-PreparationStore { throw 'Store deployment failed' }
        { Invoke-PreparationUpdates } | Should -Throw '*Store deployment failed*'
    }
    It 'preserves the original error when restart detection itself fails' {
        Mock Invoke-PreparationWindows { throw 'Windows install failed' }
        Mock Test-PreparationRestart { throw 'Restart detection failed' }
        { Invoke-PreparationUpdates } | Should -Throw '*Windows install failed*'
    }
    It 'detects a restart after a thrown Windows installer error' {
        Mock Invoke-PreparationWindows { throw 'Windows install failed' }
        Mock Test-PreparationRestart { $true }
        Invoke-PreparationUpdates | Should -Be 'reboot'
        Should -Invoke Invoke-PreparationStore -Times 0 -Exactly
    }
    It 'rechecks Windows after Store completion' {
        $script:windowsPass = 0
        Mock Invoke-PreparationWindows { $script:windowsPass++; if ($script:windowsPass -eq 1) { 'complete' } else { 'reboot' } }
        Invoke-PreparationUpdates | Should -Be 'reboot'
        Should -Invoke Invoke-PreparationStore -Times 1 -Exactly
    }
}

Describe 'Windows installation results requiring restart' {
    BeforeEach {
        Mock Assert-PreparationContinue {}
        Mock Test-PreparationRestart { $false }
        Mock Test-PreparationNetwork { $true }
        Mock Write-PreparationState {}
        $script:offered = [pscustomobject]@{ Title='Fixture update'; EulaAccepted=$true; InstallationBehavior=[pscustomobject]@{CanRequestUserInput=$false} }
        Mock Find-PreparationWindowsUpdate { $script:offered }
        $script:collection = [pscustomobject]@{Count=0}
        $script:collection | Add-Member ScriptMethod Add { param($Update); $script:queuedUpdate = $Update; $this.Count++ }
        $script:collection | Add-Member ScriptMethod Item { param($Index); if ($Index -ne 0) { throw 'Unexpected update index' }; $script:queuedUpdate }
        $script:installation = [pscustomobject]@{ResultCode=3; RebootRequired=$true}
        $script:installation | Add-Member ScriptMethod GetUpdateResult { param($Index); if ($Index -ne 0) { throw 'Unexpected result index' }; [pscustomobject]@{ResultCode=4; HResult=-1} }
        $script:installer = [pscustomobject]@{Updates=$null; ForceQuiet=$false; AllowSourcePrompts=$true; RebootRequiredBeforeInstallation=$false}
        $script:installer | Add-Member ScriptMethod Install { $script:installation }
        $script:downloader = [pscustomobject]@{Updates=$null}
        $script:downloader | Add-Member ScriptMethod Download { [pscustomobject]@{ResultCode=2} }
        $script:session = [pscustomobject]@{ClientApplicationID=''}
        $script:session | Add-Member ScriptMethod CreateUpdateInstaller { $script:installer }
        $script:session | Add-Member ScriptMethod CreateUpdateDownloader { $script:downloader }
        Mock New-Object {
            if ($ComObject -eq 'Microsoft.Update.Session') { return $script:session }
            if ($ComObject -eq 'Microsoft.Update.UpdateColl') { return $script:collection }
            throw 'Unexpected provider'
        }
    }
    It 'prioritizes restart over partial failure and keeps per-update diagnostics' {
        Invoke-PreparationWindows | Should -Be 'reboot'
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'Fixture update: result=4, HRESULT=-1'
    }
    It 'still fails a partial installation that does not require restart' {
        $script:installation.RebootRequired = $false
        { Invoke-PreparationWindows } | Should -Throw '*could not install every update*'
    }
    It 'honours the installer prerequisite before invoking Install' {
        $script:installer.RebootRequiredBeforeInstallation = $true
        $script:installer | Add-Member ScriptMethod Install { throw 'Install must not run' } -Force
        Invoke-PreparationWindows | Should -Be 'reboot'
    }
}

Describe 'Windows preparation prerequisites' {
    It 'accepts internet access and rejects metered or roaming profiles regardless of adapter type' {
        $script:networkCost = [pscustomobject]@{ NetworkCostType='Unrestricted'; Roaming=$false; OverDataLimit=$false; BackgroundDataUsageRestricted=$false }
        $script:networkLevel = 'InternetAccess'
        $script:networkProfile = [pscustomobject]@{}
        $script:networkProfile | Add-Member ScriptMethod GetNetworkConnectivityLevel { $script:networkLevel }
        $script:networkProfile | Add-Member ScriptMethod GetConnectionCost { $script:networkCost }
        Mock Get-PreparationNetworkProfile { $script:networkProfile }
        Test-PreparationNetwork | Should -BeTrue
        foreach ($kind in @('Fixed','Variable','Unknown')) {
            $script:networkCost.NetworkCostType = $kind
            Test-PreparationNetwork | Should -BeFalse
        }
        $script:networkCost.NetworkCostType = 'Unrestricted'
        $script:networkCost.Roaming = $true
        Test-PreparationNetwork | Should -BeFalse
        $script:networkCost.Roaming = $false
        $script:networkLevel = 'ConstrainedInternetAccess'
        Test-PreparationNetwork | Should -BeFalse
    }
    It 'requires a restart for deferred file replacements without asking the update provider' {
        Mock Test-Path { $false }
        Mock Get-ItemProperty { [pscustomobject]@{ PendingFileRenameOperations = [string[]]@('\??\C:\old.dll', '') } }
        Mock New-Object { throw 'The file replacement marker already requires a restart.' }
        Test-PreparationRestart | Should -BeTrue
    }
    It 'does not treat empty rename entries as a pending restart' {
        Mock Test-Path { $false }
        Mock Get-ItemProperty { [pscustomobject]@{ PendingFileRenameOperations = [string[]]@('', ' ') } }
        Mock New-Object { [pscustomobject]@{ RebootRequired = $false } }
        Test-PreparationRestart | Should -BeFalse
    }
    It 'atomically replaces an existing progress record on Windows PowerShell' {
        Write-PreparationState running windows-search
        Write-PreparationState complete verify
        (Get-Content -LiteralPath (Join-Path $TestDrive 'state.json') -Raw | ConvertFrom-Json).status | Should -Be 'complete'
    }
    It 'includes recommended updates but excludes optional previews and feature upgrades' {
        Test-PreparationUpdate ([pscustomobject]@{ BrowseOnly = $false; Categories = @() }) | Should -BeTrue
        Test-PreparationUpdate ([pscustomobject]@{ BrowseOnly = $true; Categories = @() }) | Should -BeFalse
        Test-PreparationUpdate ([pscustomobject]@{ BrowseOnly = $false; Categories = @([pscustomobject]@{ CategoryID = '3689bdc8-b205-4af4-8d4a-a63924c5e9d5' }) }) | Should -BeFalse
    }
    It 'excludes drivers in manual mode while retaining Windows software updates' {
        $previousMode = $DriverMode
        try {
            $DriverMode = 'manual'
            Test-PreparationUpdate ([pscustomobject]@{ BrowseOnly = $false; Type = 2; Categories = @() }) | Should -BeFalse
            Test-PreparationUpdate ([pscustomobject]@{ BrowseOnly = $false; Type = 1; Categories = @() }) | Should -BeTrue
        } finally { $DriverMode = $previousMode }
    }
    It 'does not search Windows Update when the network is unavailable or restricted' {
        Mock Test-PreparationRestart { $false }
        Mock Test-PreparationNetwork { $false }
        Mock Write-PreparationState { throw 'The network gate must run before a search.' }
        { Invoke-PreparationWindows } | Should -Throw
        Should -Invoke Test-PreparationNetwork -Times 1 -Exactly
        Should -Invoke Write-PreparationState -Times 0 -Exactly
    }
    It 'honours cancellation before asking Windows to update' {
        New-Item -ItemType File -Path (Join-Path $TestDrive 'cancel') -Force | Out-Null
        { Assert-PreparationContinue } | Should -Throw '*stopped*'
        Remove-Item -LiteralPath (Join-Path $TestDrive 'cancel')
    }
    It 'reports a pending restart without searching or installing updates' {
        Mock Test-PreparationRestart { $true }
        Mock Write-PreparationState { throw 'No search should start while a restart is pending.' }
        Invoke-PreparationWindows | Should -Be 'reboot'
    }
    It 'does not mark missing Store registration as up to date' {
        Mock Get-AppxPackage { $null }
        { New-PreparationStoreManager } | Should -Throw '*not registered*'
    }
}
