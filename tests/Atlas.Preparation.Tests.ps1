BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    . (Join-Path $PSScriptRoot '..\playbook\Executables\AtlasModules\Scripts\Preparation\Update-Windows.ps1') -JobPath $TestDrive -FunctionsOnly
}

Describe 'Signed-in preparation ownership' {
    It 'preserves the Store app and HRESULT through PowerShell exception handling' {
        $native = [Runtime.InteropServices.COMException]::new('Resources are in use.', -2147009278)
        try { throw (New-PreparationStoreFailure '40174MouriNaruto.NanaZip_gnj4mf6z9tkrc' 'Error' $native) }
        catch { $detail = Get-PreparationFailureDetail $_.Exception }
        $detail.packageName | Should -Be 'NanaZip'
        $detail.errorCode | Should -Be '0x80073D02'
        $detail.failureMessage | Should -Match 'Resources are in use'
    }

    It 'preserves unexpected provider failures without inventing an app name or error code' {
        $detail = Get-PreparationFailureDetail ([Exception]::new('Update service unavailable'))
        $detail.failureMessage | Should -Be 'Update service unavailable'
        $detail.ContainsKey('packageName') | Should -BeFalse
        $detail.ContainsKey('errorCode') | Should -BeFalse
        try { throw 'Script failure' } catch { $detail = Get-PreparationFailureDetail $_.Exception }
        $detail.failureMessage | Should -Be 'Script failure'
        $detail.ContainsKey('errorCode') | Should -BeFalse
    }

    It 'reports the Windows code a wrapped failure carries and never a PowerShell or CLR code' {
        try { [void][IO.File]::ReadAllText((Join-Path $TestDrive 'missing\file.txt')) } catch { $wrapped = $_.Exception }
        (Get-PreparationFailureDetail $wrapped).errorCode | Should -Be '0x80070003'
        $win32 = [Management.Automation.MethodInvocationException]::new('Session lookup failed', [ComponentModel.Win32Exception]::new(5))
        (Get-PreparationFailureDetail $win32).errorCode | Should -Be '0x80070005'
        $provider = [Runtime.InteropServices.COMException]::new('Download failed', -2145099768)
        (Get-PreparationFailureDetail $provider).errorCode | Should -Be '0x80246008'
        try { [void][int]'not a number' } catch { $cast = $_.Exception }
        (Get-PreparationFailureDetail $cast).ContainsKey('errorCode') | Should -BeFalse
    }

    It 'names the causes the app words itself and keeps the worker message' {
        try { throw (New-PreparationFailure 'Store is missing.' 'store-missing') } catch { $detail = Get-PreparationFailureDetail $_.Exception }
        $detail.reason | Should -Be 'store-missing'
        $detail.failureMessage | Should -Be 'Store is missing.'
        $detail.ContainsKey('errorCode') | Should -BeFalse
        $battery = Get-PreparationFailureDetail (New-PreparationStoreFailure 'Microsoft.WindowsStore_8wekyb3d8bbwe' 'PausedLowBattery' $null)
        $battery.reason | Should -Be 'store-paused-battery'
        $battery.failureMessage | Should -Be 'Microsoft Store needs attention: Microsoft.WindowsStore_8wekyb3d8bbwe, PausedLowBattery'
        $battery.ContainsKey('errorCode') | Should -BeFalse
        (Get-PreparationFailureDetail (New-PreparationStoreFailure 'Microsoft.WindowsStore_8wekyb3d8bbwe' 'PausedWiFiRequired' $null)).reason | Should -Be 'store-paused-network'
        (Get-PreparationFailureDetail (New-PreparationStoreFailure 'Microsoft.WindowsStore_8wekyb3d8bbwe' 'Error' $null)).ContainsKey('reason') | Should -BeFalse
    }

    It 'rejects SYSTEM, session zero and another administrator account' {
        Mock Get-PreparationSessionOwner { 'S-1-5-21-1-2-3-1001' }
        { Assert-PreparationUser -UserSid 'S-1-5-18' -SessionId 1 } | Should -Throw '*session owner*'
        { Assert-PreparationUser -UserSid 'S-1-5-21-1-2-3-1001' -SessionId 0 } | Should -Throw '*session owner*'
        { Assert-PreparationUser -UserSid 'S-1-5-21-1-2-3-1002' -SessionId 1 } | Should -Throw '*session owner*'
        { Assert-PreparationUser -UserSid 'S-1-5-21-1-2-3-1001' -SessionId 1 } | Should -Not -Throw
        try { Assert-PreparationUser -UserSid 'S-1-5-18' -SessionId 1 } catch { $refusal = $_.Exception }
        (Get-PreparationFailureDetail $refusal).reason | Should -Be 'session-owner'
    }
    It 'fails closed when Windows cannot identify the session owner' {
        Mock Get-PreparationSessionOwner { throw 'WTS unavailable' }
        { Assert-PreparationUser -UserSid 'S-1-5-21-1-2-3-1001' -SessionId 1 } | Should -Throw '*WTS unavailable*'
    }
}

Describe 'Protected preparation recovery journals' {
    It 'uses the same protected administrator-owned descriptor as recovery staging' {
        $sections = [Security.AccessControl.AccessControlSections]::All
        $stageApp = Join-Path $PSScriptRoot '..\app\resources\prepare\Stage-App.ps1'
        $staging = & { . $stageApp -FunctionsOnly; (Get-AtlasRecoveryFileSecurity).GetSecurityDescriptorSddlForm($sections) }
        $journal = (Get-PreparationStateSecurity).GetSecurityDescriptorSddlForm($sections)
        $journal | Should -BeExactly $staging
        $journal | Should -BeExactly 'O:BAG:BAD:P(A;;FA;;;SY)(A;;FA;;;BA)(A;;0x1200a9;;;BU)' `
            -Because 'only SYSTEM and administrators may change the journal'
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
        { Assert-PreparationContinue } | Should -Throw '*marker is missing*'
    }
    It 'stops for any cancellation marker when the app did not precreate one' {
        # Install-Atlas -VerifyOnly runs the worker this way.
        Set-Variable -Name PersistentCancellation -Value $false
        $JobPath = Join-Path $TestDrive 'one-shot-cancel'
        [void][IO.Directory]::CreateDirectory($JobPath)
        { Assert-PreparationContinue } | Should -Not -Throw
        [IO.File]::WriteAllText((Join-Path $JobPath 'cancel'), '')
        { Assert-PreparationContinue } | Should -Throw '*stopped*'
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

Describe 'Restart markers' {
    It 'reports <Case>' -TestCases @(
        @{ Case = 'every registry marker it saw rather than stopping at the first'
            Servicing = $true; Renames = @('\??\C:\old.dll', ''); Agent = $false
            Restart = $true; Reasons = @('servicing', 'file-renames') }
        @{ Case = 'no restart when no marker is set'
            Servicing = $false; Renames = $null; Agent = $false
            Restart = $false; Reasons = @() }
        # Xbox Gaming Services queues a file rename at every boot, so restarting for one
        # would never end.
        @{ Case = 'deferred file replacements without requiring a restart for them'
            Servicing = $false; Renames = @('\??\C:\old.dll', ''); Agent = $false
            Restart = $false; Reasons = @('file-renames') }
        @{ Case = 'the update provider''s restart alongside file replacements'
            Servicing = $false; Renames = @('\??\C:\old.dll', ''); Agent = $true
            Restart = $true; Reasons = @('file-renames', 'update-agent') }
        @{ Case = 'nothing for empty rename entries'
            Servicing = $false; Renames = @('', ' '); Agent = $false
            Restart = $false; Reasons = @() }
    ) {
        $script:markerFixture = @{ Servicing = $Servicing; Renames = $Renames; Agent = $Agent }
        Mock Test-Path { $script:markerFixture.Servicing -and $LiteralPath -like '*Component Based Servicing*' }
        Mock Get-ItemProperty {
            if ($null -eq $script:markerFixture.Renames) { return [pscustomobject]@{} }
            [pscustomobject]@{ PendingFileRenameOperations = [string[]]$script:markerFixture.Renames }
        }
        Mock New-Object { [pscustomobject]@{ RebootRequired = $script:markerFixture.Agent } } `
            -ParameterFilter { $ComObject -eq 'Microsoft.Update.SystemInfo' }

        Test-PreparationRestart | Should -Be $Restart
        $script:PreparationRestartReasons -join ',' | Should -BeExactly ($Reasons -join ',')
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
        Mock Test-PreparationStoreRemoved { $false }
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
    It 'checks nothing in a Store the user removed' {
        Mock Test-PreparationStoreRemoved { $true }
        { Assert-PreparationCurrent } | Should -Not -Throw
        Should -Invoke New-PreparationStoreManager -Times 0 -Exactly
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
        Mock Test-PreparationStoreRemoved { $false }
        Mock Write-PreparationStoreInventory {}
        Mock Update-PreparationStoreItself { $false }
        Mock Invoke-PreparationStoreRepair { $false }
        Mock Get-PreparationStoreVersion { '22608.1401.5.0' }
        Mock Register-PreparationStore { $true }
        $script:PreparationStoreRepairsRun = $false
        Remove-Item -LiteralPath (Join-Path $JobPath 'updates.log') -ErrorAction SilentlyContinue
    }
    It 'reports a <Provider> failure as restart required when Windows has pending changes' -TestCases @(
        @{ Provider = 'Store'; Message = 'Store deployment failed'; StoreRuns = 1 }
        @{ Provider = 'Windows'; Message = 'Windows install failed'; StoreRuns = 0 }
    ) {
        $script:providerFailure = $Message
        Mock "Invoke-Preparation$Provider" { throw $script:providerFailure }
        Mock Test-PreparationRestart { $true }
        Invoke-PreparationUpdates | Should -Be 'reboot'
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match $Message
        Should -Invoke Invoke-PreparationWindows -Times 1 -Exactly
        Should -Invoke Invoke-PreparationStore -Times $StoreRuns -Exactly
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
    It 'rechecks Windows after Store completion' {
        $script:windowsPass = 0
        Mock Invoke-PreparationWindows { $script:windowsPass++; if ($script:windowsPass -eq 1) { 'complete' } else { 'reboot' } }
        Invoke-PreparationUpdates | Should -Be 'reboot'
        Should -Invoke Invoke-PreparationStore -Times 1 -Exactly
    }
}

Describe 'A Store the user removed' {
    It 'reads the removed choice from the toggle record, unless the Store is back for this user' {
        $record = { $LiteralPath -eq 'HKLM:\SOFTWARE\AtlasOS\Services\MicrosoftStore' -and $Name -eq 'state' }
        Mock Get-ItemProperty { throw "read another value: $LiteralPath $Name" }
        Mock Get-ItemProperty -ParameterFilter $record { [pscustomobject]@{ state = 0 } }
        Mock Get-PreparationStoreVersion { '' }
        Test-PreparationStoreRemoved | Should -BeTrue
        Mock Get-PreparationStoreVersion { '22409.1401.5.0' }
        Test-PreparationStoreRemoved | Should -BeFalse
        Mock Get-ItemProperty -ParameterFilter $record { [pscustomobject]@{ state = 1 } }
        Mock Get-PreparationStoreVersion { '' }
        Test-PreparationStoreRemoved | Should -BeFalse
        Mock Get-ItemProperty -ParameterFilter $record { $null }
        Test-PreparationStoreRemoved | Should -BeFalse
    }
}

Describe 'Microsoft Store before the Store apps' {
    BeforeEach {
        $script:PreparationStoreRepairsRun = $false
        $script:PreparationStoreOutcome = $null
        $script:Repairs = [Collections.Generic.List[string]]::new()
        $script:Fixed = $false
        Remove-Item -LiteralPath (Join-Path $JobPath 'updates.log') -ErrorAction SilentlyContinue
        Mock Assert-PreparationContinue {}
        Mock Write-PreparationState {}
        Mock Write-PreparationStoreInventory {}
        Mock Test-PreparationStoreRemoved { $false }
        Mock Invoke-PreparationStoreWithRetry {}
        Mock Update-PreparationStoreItself { $false }
        Mock Get-PreparationStoreVersion { '22608.1401.5.0' }
        $script:PreparationStoreDownloaded = $false
        # No registration or repair may reach the PC running the tests.
        Mock Register-PreparationStore { $true }
        Mock Invoke-PreparationStoreRepair { $script:Repairs.Add($Repair); $false }
    }

    It 'skips the Store when the recorded choice removed it, and never repairs or reinstalls it' {
        Mock Test-PreparationStoreRemoved { $true }
        Invoke-PreparationStoreStage
        Should -Invoke Update-PreparationStoreItself -Times 0 -Exactly
        Should -Invoke Invoke-PreparationStoreWithRetry -Times 0 -Exactly
        $script:Repairs.Count | Should -Be 0
        (Get-PreparationOutcomeDetail).storeOutcome | Should -Be 'store-skipped-removed'
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'skipped'
    }

    It 'registers a Store this user has not registered before anything else, and says it repaired it' {
        $script:Registered = $false
        Mock Get-PreparationStoreVersion { if ($script:Registered) { '22608.1401.5.0' } else { '' } }
        Mock Register-PreparationStore { $script:Registered = $true; $true }
        Mock Update-PreparationStoreItself { if (-not $script:Registered) { throw 'registered too late' }; $false }
        Invoke-PreparationStoreStage
        Should -Invoke Register-PreparationStore -Times 1 -Exactly
        $script:Repairs.Count | Should -Be 0
        (Get-PreparationOutcomeDetail).storeOutcome | Should -Be 'store-repaired'
    }

    It 'leaves a registered Store registered as it is' {
        Invoke-PreparationStoreStage
        Should -Invoke Register-PreparationStore -Times 0 -Exactly
    }

    It 'goes on to the repairs when registering a missing Store fails' {
        Mock Get-PreparationStoreVersion { '' }
        Mock Register-PreparationStore { throw 'Deployment failed' }
        Mock Update-PreparationStoreItself { throw (New-PreparationFailure 'Microsoft Store is not registered for this user.' 'store-missing') }
        { Invoke-PreparationStoreStage } | Should -Throw
        @($script:Repairs) | Should -Be @('wsreset', 'bootstrap', 'storefixer')
        (Get-Content (Join-Path $JobPath 'updates.log') -Raw) | Should -Match 'registering it failed: Deployment failed'
    }

    It 'updates the Store itself before the apps and says so' {
        Mock Update-PreparationStoreItself { $true }
        Invoke-PreparationStoreStage
        Should -Invoke Invoke-PreparationStoreWithRetry -Times 1 -Exactly
        $script:Repairs.Count | Should -Be 0
        (Get-PreparationOutcomeDetail).storeOutcome | Should -Be 'store-updated'
    }

    It 'says nothing about the Store when it was already current' {
        Invoke-PreparationStoreStage
        (Get-PreparationOutcomeDetail).ContainsKey('storeOutcome') | Should -BeFalse
    }

    It 'repairs in order and stops at the first repair after which the Store works' {
        Mock Update-PreparationStoreItself { if (-not $script:Fixed) { throw (New-PreparationFailure 'Microsoft Store is not registered for this user.' 'store-missing') }; $false }
        Mock Invoke-PreparationStoreRepair {
            $script:Repairs.Add($Repair)
            if ($Repair -eq 'bootstrap') { $script:Fixed = $true; $script:PreparationStoreDownloaded = $true }
            $true
        }
        Invoke-PreparationStoreStage
        @($script:Repairs) | Should -Be @('wsreset', 'bootstrap')
        (Get-PreparationOutcomeDetail).storeOutcome | Should -Be 'store-bootstrapped'
        # The first try, after wsreset, after the bootstrap.
        Should -Invoke Update-PreparationStoreItself -Times 3 -Exactly
        Should -Invoke Invoke-PreparationStoreWithRetry -Times 1 -Exactly
        $log = Get-Content (Join-Path $JobPath 'updates.log') -Raw
        $log | Should -Match 'still failing after wsreset'
        $log | Should -Match 'works again after bootstrap'
    }

    It 'says repaired, not downloaded, when the bootstrap used the App Installer this PC had' {
        Mock Update-PreparationStoreItself { if (-not $script:Fixed) { throw (New-PreparationFailure 'Microsoft Store is not registered for this user.' 'store-missing') }; $false }
        Mock Invoke-PreparationStoreRepair { $script:Repairs.Add($Repair); if ($Repair -eq 'bootstrap') { $script:Fixed = $true }; $true }
        Invoke-PreparationStoreStage
        (Get-PreparationOutcomeDetail).storeOutcome | Should -Be 'store-repaired'
    }

    It 'says the Store was repaired when wsreset was what it needed' {
        Mock Invoke-PreparationStoreWithRetry { if (-not $script:Fixed) { throw 'Microsoft Store needs attention: Microsoft.WindowsStore_8wekyb3d8bbwe, Error' } }
        Mock Invoke-PreparationStoreRepair { $script:Repairs.Add($Repair); $script:Fixed = $true; $true }
        Invoke-PreparationStoreStage
        @($script:Repairs) | Should -Be @('wsreset')
        (Get-PreparationOutcomeDetail).storeOutcome | Should -Be 'store-repaired'
    }

    It 'tries the Store again only after a repair that changed something' {
        Mock Update-PreparationStoreItself { throw (New-PreparationFailure 'Microsoft Store is not registered for this user.' 'store-missing') }
        Mock Invoke-PreparationStoreRepair { $script:Repairs.Add($Repair); $Repair -eq 'bootstrap' }
        { Invoke-PreparationStoreStage } | Should -Throw
        @($script:Repairs) | Should -Be @('wsreset', 'bootstrap', 'storefixer')
        # The first try and the one after the bootstrap.
        Should -Invoke Update-PreparationStoreItself -Times 2 -Exactly
    }

    It 'goes on to the next repair when one fails, and fails with its own reason after the last' {
        Mock Update-PreparationStoreItself { throw (New-PreparationFailure 'Microsoft Store is not registered for this user.' 'store-missing') }
        Mock Invoke-PreparationStoreRepair { $script:Repairs.Add($Repair); throw "$Repair broke" }
        try { Invoke-PreparationStoreStage } catch { $failure = $_.Exception }
        @($script:Repairs) | Should -Be @('wsreset', 'bootstrap', 'storefixer')
        $detail = Get-PreparationFailureDetail $failure
        $detail.reason | Should -Be 'store-repair-failed'
        $detail.failureMessage | Should -Match 'not registered'
        (Get-Content (Join-Path $JobPath 'updates.log') -Raw) | Should -Match 'storefixer failed: storefixer broke'
    }

    It 'goes through the repairs once per run' {
        Mock Update-PreparationStoreItself { throw (New-PreparationFailure 'Microsoft Store is not registered for this user.' 'store-missing') }
        { Invoke-PreparationStoreStage } | Should -Throw
        $script:Repairs.Count | Should -Be 3
        { Invoke-PreparationStoreStage } | Should -Throw '*not registered*'
        $script:Repairs.Count | Should -Be 3
    }

    It 'leaves failures no repair helps to the user: <Case>' -TestCases @(
        @{ Case = 'paused for battery'; Failure = { New-PreparationStoreFailure 'Microsoft.WindowsStore_8wekyb3d8bbwe' 'PausedLowBattery' $null } }
        @{ Case = 'an app in use'; Failure = { New-PreparationStoreFailure '40174MouriNaruto.NanaZip_gnj4mf6z9tkrc' 'Error' ([Runtime.InteropServices.COMException]::new('Resources are in use.', -2147009278)) } }
        @{ Case = 'Stop'; Failure = { New-Object OperationCanceledException 'Preparation stopped after the current operation.' } }
    ) {
        $script:Failure = & $Failure
        Mock Invoke-PreparationStoreWithRetry { throw $script:Failure }
        { Invoke-PreparationStoreStage } | Should -Throw
        $script:Repairs.Count | Should -Be 0
    }

    It 'stops the repairs when the user chooses Stop' {
        Mock Update-PreparationStoreItself { throw (New-PreparationFailure 'Microsoft Store is not registered for this user.' 'store-missing') }
        Mock Invoke-PreparationStoreRepair { $script:Repairs.Add($Repair); throw (New-Object OperationCanceledException 'Preparation stopped after the current operation.') }
        { Invoke-PreparationStoreStage } | Should -Throw -ExceptionType ([OperationCanceledException])
        $script:Repairs.Count | Should -Be 1
    }

    It 'runs wsreset -i, never plain wsreset, and follows what it queued' {
        $wsreset = Join-Path $TestDrive 'WSReset.exe'
        [IO.File]::WriteAllText($wsreset, '')
        Mock Get-PreparationWsResetPath { $wsreset }
        Mock Invoke-PreparationStoreProcess { 0 }
        Mock Wait-PreparationStoreQueue {}
        Invoke-PreparationWsReset | Should -BeTrue
        Should -Invoke Invoke-PreparationStoreProcess -Times 1 -Exactly
        Should -Invoke Invoke-PreparationStoreProcess -Times 1 -Exactly -ParameterFilter { $FilePath -eq $wsreset -and $Arguments -eq '-i' }
        Should -Invoke Wait-PreparationStoreQueue -Times 1 -Exactly
        Should -Invoke Write-PreparationStoreInventory -Times 1 -Exactly -ParameterFilter { $When -eq 'after wsreset -i' }
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'wsreset -i exited 0'
    }

    It 'registers the newer App Installer this PC has for the user before downloading one' {
        $script:Registered = $false
        Mock Get-AppxPackage {
            if ($AllUsers) { return @([pscustomobject]@{ Version = '1.26.509.0' }, [pscustomobject]@{ Version = '1.26.509.0' }) }
            if ($script:Registered) { return [pscustomobject]@{ Version = '2025.926.104.0' } }
            return [pscustomobject]@{ Version = '1.26.509.0' }
        }
        Mock Get-AppxProvisionedPackage { @([pscustomobject]@{ DisplayName = 'Microsoft.DesktopAppInstaller'; Version = '2025.926.104.0' }) }
        Mock Add-AppxPackage { $script:Registered = $true }
        Mock Get-PreparationWingetPath { 'C:\Program Files\WindowsApps\winget.exe' }
        Mock Save-PreparationAppInstaller {}
        Mock Assert-PreparationWingetStoreSource {}
        Mock Invoke-PreparationStoreProcess { 0 }
        Install-PreparationStoreFromMicrosoft | Should -BeTrue
        Should -Invoke Add-AppxPackage -Times 1 -Exactly -ParameterFilter { $RegisterByFamilyName -and $MainPackage -eq 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe' }
        Should -Invoke Save-PreparationAppInstaller -Times 0 -Exactly
        Should -Invoke Invoke-PreparationStoreProcess -Times 1 -Exactly -ParameterFilter { $Arguments -like '*--id 9WZDNCRFJBMP --source msstore*' }
        $script:PreparationStoreDownloaded | Should -BeFalse
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'registered the copy this PC has, 1\.26\.509\.0 -> 2025\.926\.104\.0'
    }

    It 'downloads App Installer when this PC has nothing newer than the user' {
        Mock Get-AppxPackage { [pscustomobject]@{ Version = '2025.926.104.0' } }
        Mock Get-AppxProvisionedPackage { @([pscustomobject]@{ DisplayName = 'Microsoft.DesktopAppInstaller'; Version = '2025.926.104.0' }) }
        Mock Add-AppxPackage { throw 'must not register' }
        Mock Get-PreparationWingetPath { 'C:\Program Files\WindowsApps\winget.exe' }
        Mock Save-PreparationAppInstaller {}
        Mock Assert-PreparationWingetStoreSource {}
        Mock Invoke-PreparationStoreProcess { 0 }
        Install-PreparationStoreFromMicrosoft | Should -BeTrue
        Should -Invoke Save-PreparationAppInstaller -Times 1 -Exactly
    }

    It 'names each Store item with its product id, versions and how it ended' {
        $item = [pscustomobject]@{ PackageFamilyName = 'Microsoft.WindowsStore_8wekyb3d8bbwe'; ProductId = '9WZDNCRFJBMP' }
        $item | Add-Member ScriptMethod GetCurrentStatus { [pscustomobject]@{ InstallState = 'Completed' } }
        $new = [pscustomobject]@{ PackageFamilyName = 'Microsoft.StorePurchaseApp_8wekyb3d8bbwe'; ProductId = '' }
        $new | Add-Member ScriptMethod GetCurrentStatus { [pscustomobject]@{ InstallState = 'Error' } }
        Mock Get-PreparationPackageVersion { @{ 'Microsoft.WindowsStore_8wekyb3d8bbwe' = '22608.1401.5.0'; 'Microsoft.StorePurchaseApp_8wekyb3d8bbwe' = '22504.1401.5.0' } }
        Write-PreparationStoreItem @($item, $new) @{ 'Microsoft.WindowsStore_8wekyb3d8bbwe' = '22409.1401.5.0' }
        $log = Get-Content (Join-Path $JobPath 'updates.log') -Raw
        $log | Should -Match 'item Microsoft\.WindowsStore_8wekyb3d8bbwe \(9WZDNCRFJBMP\): 22409\.1401\.5\.0 -> 22608\.1401\.5\.0, Completed'
        $log | Should -Match 'item Microsoft\.StorePurchaseApp_8wekyb3d8bbwe: none -> 22504\.1401\.5\.0, Error'
    }

    It 'lets the update stage run the Store stage between the Windows passes' {
        $script:Order = [Collections.Generic.List[string]]::new()
        Mock Write-PreparationState {}
        Mock Invoke-PreparationWindows { $script:Order.Add('windows'); 'complete' }
        Mock Invoke-PreparationStoreStage { $script:Order.Add('store') }
        Invoke-PreparationUpdates | Should -Be 'complete'
        @($script:Order) | Should -Be @('windows', 'store', 'windows')

        # A restart the first pass needs comes before the Store.
        $script:Order.Clear()
        Mock Invoke-PreparationWindows { $script:Order.Add('windows'); 'reboot' }
        Invoke-PreparationUpdates | Should -Be 'reboot'
        @($script:Order) | Should -Be @('windows')
    }
}

Describe 'Store items an earlier round left failed' {
    BeforeEach {
        Remove-Item -LiteralPath (Join-Path $JobPath 'updates.log') -ErrorAction SilentlyContinue
        $script:Offered = @()
        $failed = [pscustomobject]@{ PackageFamilyName = 'Microsoft.Xbox.TCUI_8wekyb3d8bbwe'; ProductId = '9NKNC0LD5NN6' }
        $failed | Add-Member ScriptMethod GetCurrentStatus { [pscustomobject]@{ InstallState = 'Error'; PercentComplete = 0; ErrorCode = $null } }
        $script:StoreManager = [pscustomobject]@{ AppInstallItems = @($failed) }
        $script:StoreManager | Add-Member ScriptMethod Cancel {
            param($Product)
            $this.AppInstallItems = @($this.AppInstallItems | Where-Object ProductId -ne $Product)
        }
        $script:StoreManager | Add-Member ScriptMethod SearchForAllUpdatesAsync { return $null }
        $script:StoreManager | Add-Member ScriptMethod Restart {}
        Mock Assert-PreparationContinue {}
        Mock Test-PreparationNetwork { $true }
        Mock Write-PreparationState {}
        Mock Start-Sleep {}
        Mock New-PreparationStoreManager { $script:StoreManager }
        Mock Wait-PreparationStoreSearch { $script:Offered }
        Mock New-Object {
            if ($TypeName -eq 'Windows.ApplicationModel.Store.Preview.InstallControl.AppUpdateOptions') { return [pscustomobject]@{ AllowForcedAppRestart = $false; AutomaticallyDownloadAndInstallUpdateIfFound = $false } }
            throw 'Unexpected provider construction.'
        }
        Mock Get-PreparationPackageVersion { @{ 'Microsoft.Xbox.TCUI_8wekyb3d8bbwe' = '1.24.10001.0' } }
    }

    It 'counts an item the fresh search no longer offers as up to date, and says so' {
        { Invoke-PreparationStore } | Should -Not -Throw
        $script:StoreManager.AppInstallItems.Count | Should -Be 0 -Because 'the failed queue record is cleared first'
        Get-Content (Join-Path $JobPath 'updates.log') -Raw |
            Should -Match "item Microsoft\.Xbox\.TCUI_8wekyb3d8bbwe: no longer offered after it ended Error; this user has 1\.24\.10001\.0, so it's up to date"
    }

    It 'waits for an item the Store offers again, and fails the pass when it fails again' {
        $again = [pscustomobject]@{ PackageFamilyName = 'Microsoft.Xbox.TCUI_8wekyb3d8bbwe'; ProductId = '9NKNC0LD5NN6' }
        $again | Add-Member ScriptMethod GetCurrentStatus { [pscustomobject]@{ InstallState = 'Error'; PercentComplete = 0; ErrorCode = $null } }
        $script:Offered = @($again)
        { Invoke-PreparationStore } | Should -Throw '*Microsoft.Xbox.TCUI_8wekyb3d8bbwe, Error*'
        Get-Content (Join-Path $JobPath 'updates.log') -Raw |
            Should -Match 'item Microsoft\.Xbox\.TCUI_8wekyb3d8bbwe: offered again after it ended Error; updating it again'
    }
}

Describe 'Windows installation results requiring restart' {
    BeforeAll {
        function New-FixtureUpdate([string]$Title, [switch]$Interactive, [int]$Impact = 0) {
            [pscustomobject]@{
                Title = $Title; EulaAccepted = $true; Identity = [pscustomobject]@{ UpdateID = "$Title id" }
                InstallationBehavior = [pscustomobject]@{ CanRequestUserInput = [bool]$Interactive; Impact = $Impact }
            }
        }
    }
    BeforeEach {
        Mock Assert-PreparationContinue {}
        Mock Test-PreparationRestart { $false }
        Mock Test-PreparationNetwork { $true }
        Mock Write-PreparationState {}
        Mock Get-PreparationWindowsVersion { [pscustomobject]@{ Build = 26200; Ubr = 9168; DisplayVersion = '25H2'; EditionId = 'Professional' } }
        Remove-Item -LiteralPath (Join-Path $JobPath 'updates.log') -ErrorAction SilentlyContinue
        $script:offered = New-FixtureUpdate 'Fixture update'
        $script:download = [pscustomobject]@{ResultCode=2; HResult=0}
        Mock Invoke-PreparationWindowsOperation {
            if ($Kind -eq 'Download') { return $script:download }
            return $script:installation
        }
        Mock Find-PreparationWindowsUpdate { $script:offered }
        # Each search fills a new collection, as WUA's UpdateColl would.
        $script:collections = @()
        $script:installation = [pscustomobject]@{ResultCode=3; RebootRequired=$true; HResult=0}
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
            if ($ComObject -eq 'Microsoft.Update.UpdateColl') {
                $collection = [pscustomobject]@{ Count = 0; Queued = [Collections.ArrayList]::new() }
                $collection | Add-Member ScriptMethod Add { param($Update); [void]$this.Queued.Add($Update); $script:queuedUpdate = $Update; $this.Count++ }
                $collection | Add-Member ScriptMethod Item { param($Index); $this.Queued[$Index] }
                $script:collections += $collection
                return $collection
            }
            throw 'Unexpected provider'
        }
    }
    It 'prioritizes restart over partial failure and keeps per-update diagnostics' {
        Invoke-PreparationWindows | Should -Be 'reboot'
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'Fixture update: result=4, HRESULT=-1'
    }
    It 'installs quiet updates before asking for an interactive driver' {
        $script:driver = New-FixtureUpdate 'Interactive driver' -Interactive
        Mock Find-PreparationWindowsUpdate { @($script:driver, $script:offered) }
        Invoke-PreparationWindows | Should -Be 'reboot'
        $script:queuedUpdate.Title | Should -Be 'Fixture update'
        $script:PreparationRestartReasons | Should -Contain 'windows-update'
    }
    It 'tries quiet installation before asking the user to finish an interactive update' {
        $script:driver = New-FixtureUpdate 'Interactive driver' -Interactive
        Mock Find-PreparationWindowsUpdate { $script:driver }
        $script:installation.RebootRequired = $false
        try { Invoke-PreparationWindows } catch { $thrown = $_.Exception }
        $thrown.Message | Should -BeLike '*Windows Settings*Interactive driver*'
        (Get-PreparationFailureDetail $thrown).reason | Should -Be 'manual-updates'
        Should -Invoke Invoke-PreparationWindowsOperation -Times 1 -Exactly -ParameterFilter { $Kind -eq 'Install' }
        $script:installer.ForceQuiet | Should -BeTrue
        $script:installer.AllowSourcePrompts | Should -BeFalse
    }
    It 'accepts a quietly installed update that could have requested input' {
        $script:driver = New-FixtureUpdate 'Interactive driver' -Interactive
        $script:searches = 0
        Mock Find-PreparationWindowsUpdate { $script:searches++; if ($script:searches -eq 1) { $script:driver } }
        $script:installation.ResultCode = 2
        $script:installation.RebootRequired = $false
        $script:installation | Add-Member ScriptMethod GetUpdateResult { [pscustomobject]@{ResultCode=2; HResult=0} } -Force
        Invoke-PreparationWindows | Should -Be 'complete'
    }
    It 'retries a failed update once after a fresh search, then reports it with its Windows code' {
        $script:installation.RebootRequired = $false
        $script:installation | Add-Member ScriptMethod GetUpdateResult { [pscustomobject]@{ResultCode=4; HResult=-2145124330} } -Force
        try { Invoke-PreparationWindows } catch { $thrown = $_.Exception }
        $thrown.Message | Should -BeLike '*could not install every update*'
        (Get-PreparationFailureDetail $thrown).errorCode | Should -Be '0x80240016'
        Should -Invoke Find-PreparationWindowsUpdate -Times 2 -Exactly
        Should -Invoke Invoke-PreparationWindowsOperation -Times 2 -Exactly -ParameterFilter { $Kind -eq 'Install' }
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'Retrying 1 failed update'
    }
    It 'installs a transiently failed update on the next pass' {
        $script:installation.RebootRequired = $false
        $script:succeeded = [pscustomobject]@{ResultCode=2; RebootRequired=$false; HResult=0}
        $script:succeeded | Add-Member ScriptMethod GetUpdateResult { [pscustomobject]@{ResultCode=2; HResult=0} }
        $script:installs = 0
        Mock Invoke-PreparationWindowsOperation {
            if ($Kind -eq 'Download') { return $script:download }
            $script:installs++
            if ($script:installs -eq 1) { return $script:installation }
            return $script:succeeded
        }
        $script:searches = 0
        Mock Find-PreparationWindowsUpdate { $script:searches++; if ($script:searches -le 2) { $script:offered } }
        Invoke-PreparationWindows | Should -Be 'complete'
        Should -Invoke Invoke-PreparationWindowsOperation -Times 2 -Exactly -ParameterFilter { $Kind -eq 'Install' }
    }
    It 'reports a failure no update accounts for at once, with the result code' {
        $script:installation.RebootRequired = $false
        $script:installation.ResultCode = 4
        $script:installation.HResult = -2145124330
        $script:installation | Add-Member ScriptMethod GetUpdateResult { [pscustomobject]@{ResultCode=2; HResult=0} } -Force
        try { Invoke-PreparationWindows } catch { $thrown = $_.Exception }
        $thrown.Message | Should -BeLike '*could not install every update*'
        (Get-PreparationFailureDetail $thrown).errorCode | Should -Be '0x80240016'
        Should -Invoke Invoke-PreparationWindowsOperation -Times 1 -Exactly -ParameterFilter { $Kind -eq 'Install' }
    }
    It 'retries a failed download once and reports the update''s Windows code' {
        $script:download = [pscustomobject]@{ResultCode=4; HResult=0}
        $script:download | Add-Member ScriptMethod GetUpdateResult { [pscustomobject]@{ResultCode=4; HResult=-2145099768} }
        try { Invoke-PreparationWindows } catch { $thrown = $_.Exception }
        $thrown.Message | Should -BeLike '*download failed*'
        (Get-PreparationFailureDetail $thrown).errorCode | Should -Be '0x80246008'
        Should -Invoke Invoke-PreparationWindowsOperation -Times 2 -Exactly -ParameterFilter { $Kind -eq 'Download' }
        Should -Invoke Invoke-PreparationWindowsOperation -Times 0 -Exactly -ParameterFilter { $Kind -eq 'Install' }
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'Fixture update: download result=4, HRESULT=-2145099768'
    }
    It 'installs an exclusive update on its own' {
        $normal = New-FixtureUpdate 'Normal update'
        $exclusive = New-FixtureUpdate 'Exclusive update' -Impact 2
        $script:found = @($normal, $exclusive)
        Mock Find-PreparationWindowsUpdate { $script:found }
        Invoke-PreparationWindows | Should -Be 'reboot'
        @($script:collections[-1].Queued.Title) | Should -Be @('Normal update')
        $script:found = @($exclusive, $normal)
        Invoke-PreparationWindows | Should -Be 'reboot'
        @($script:collections[-1].Queued.Title) | Should -Be @('Exclusive update')
    }
    It 'honours the installer prerequisite before invoking Install' {
        $script:installer.RebootRequiredBeforeInstallation = $true
        $script:installer | Add-Member ScriptMethod Install { throw 'Install must not run' } -Force
        Invoke-PreparationWindows | Should -Be 'reboot'
        Should -Invoke Invoke-PreparationWindowsOperation -Times 0 -Exactly -ParameterFilter { $Kind -eq 'Install' }
    }
}

Describe 'Cumulative updates a newer one in the same pass replaces' {
    BeforeAll {
        function New-Cumulative([string]$Title, [string]$Id, [string[]]$Superseded = $null) {
            $update = [pscustomobject]@{ Title = $Title; Identity = [pscustomobject]@{ UpdateID = $Id; RevisionNumber = 1 } }
            if ($null -ne $Superseded) { $update | Add-Member NoteProperty SupersededUpdateIDs $Superseded }
            $update
        }
    }
    BeforeEach {
        Mock Get-PreparationWindowsVersion { [pscustomobject]@{ Build = 26200; Ubr = 9168; DisplayVersion = '25H2'; EditionId = 'Professional' } }
        Remove-Item -LiteralPath (Join-Path $JobPath 'updates.log') -ErrorAction SilentlyContinue
    }

    It 'installs only the newest cumulative update for this build, with the other updates' {
        $monthly = New-Cumulative '2026-09 Cumulative Update for Windows 11, version 25H2 (KB5124009) (26200.9457)' 'monthly'
        $preview = New-Cumulative '2026-09 Preview Update (KB5124010) (26200.9550)' 'preview'
        $dotnet = New-Cumulative '2026-09 Cumulative Update for .NET Framework (KB5126052)' 'dotnet'
        @((Select-PreparationNewestUpdate @($monthly, $dotnet, $preview)).Title) | Should -Be @($dotnet.Title, $preview.Title)
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'Left .*26200\.9457.* a newer update in this pass replaces it'
    }

    It 'leaves an update another one lists as superseded' {
        $old = New-Cumulative 'Security Intelligence Update (Version 1.1)' 'old'
        $new = New-Cumulative 'Security Intelligence Update (Version 1.2)' 'new' @('old')
        @((Select-PreparationNewestUpdate @($old, $new)).Title) | Should -Be @($new.Title)
        @(Select-PreparationNewestUpdate @($old)).Count | Should -Be 1
    }
}

Describe 'Updates Windows offers again after they installed' {
    BeforeAll {
        function New-ReofferedUpdate([string]$Title = 'Update for Windows Security platform - KB5007651 (Version 10.0.29628.1000)') {
            [pscustomobject]@{
                Title = $Title; EulaAccepted = $true; KBArticleIDs = @('5007651')
                Identity = [pscustomobject]@{ UpdateID = '0d5c1a3b-3a2b-4c6d-9e1f-2a3b4c5d6e7f'; RevisionNumber = 200 }
                InstallationBehavior = [pscustomobject]@{ CanRequestUserInput = $false; Impact = 0 }
            }
        }
        function New-InstallResult([int]$Code) {
            $result = [pscustomobject]@{ ResultCode = $Code; RebootRequired = $false; HResult = 0 }
            # One update per collection, so every index reports the same result.
            $result | Add-Member ScriptMethod GetUpdateResult { param($Index) $null = $Index; [pscustomobject]@{ ResultCode = $this.ResultCode; HResult = $(if ($this.ResultCode -eq 2) { 0 } else { -2145124330 }) } }
            return $result
        }
    }
    BeforeEach {
        Mock Assert-PreparationContinue {}
        Mock Test-PreparationRestart { $false }
        Mock Test-PreparationNetwork { $true }
        Mock Write-PreparationState {}
        Mock Read-PreparationReoffered {}
        Mock Write-PreparationReoffered { $script:record = @($Entries) }
        Mock Get-PreparationInstalledVersion { 'Microsoft.SecHealthUI 1000.26100.9168.0' }
        Remove-Item -LiteralPath (Join-Path $JobPath 'updates.log') -ErrorAction SilentlyContinue
        $script:record = @()
        $script:results = @()
        Mock Invoke-PreparationWindowsOperation {
            if ($Kind -eq 'Download') { return [pscustomobject]@{ ResultCode = 2; HResult = 0 } }
            $result = $script:results[0]
            if ($script:results.Count -gt 1) { $script:results = $script:results[1..($script:results.Count - 1)] }
            return $result
        }
        Mock Find-PreparationWindowsUpdate { New-ReofferedUpdate }
        $script:session = [pscustomobject]@{ ClientApplicationID = '' }
        $script:session | Add-Member ScriptMethod CreateUpdateInstaller { [pscustomobject]@{ Updates = $null; ForceQuiet = $false; AllowSourcePrompts = $true; RebootRequiredBeforeInstallation = $false } }
        $script:session | Add-Member ScriptMethod CreateUpdateDownloader { [pscustomobject]@{ Updates = $null } }
        Mock New-Object {
            if ($ComObject -eq 'Microsoft.Update.Session') { return $script:session }
            if ($ComObject -eq 'Microsoft.Update.UpdateColl') {
                $collection = [pscustomobject]@{ Count = 0; Queued = [Collections.ArrayList]::new() }
                $collection | Add-Member ScriptMethod Add { param($Update); [void]$this.Queued.Add($Update); $this.Count++ }
                $collection | Add-Member ScriptMethod Item { param($Index); $this.Queued[$Index] }
                return $collection
            }
            throw 'Unexpected provider'
        }
    }

    It 'installs it once, then finishes without counting it against the passes' {
        $script:results = @(New-InstallResult 2)
        Invoke-PreparationWindows | Should -Be 'complete'
        Should -Invoke Invoke-PreparationWindowsOperation -Times 1 -Exactly -ParameterFilter { $Kind -eq 'Install' }
        $log = Get-Content (Join-Path $JobPath 'updates.log') -Raw
        $log | Should -Match "reoffered-after-success, not installed again: 'Update for Windows Security platform - KB5007651 \(Version 10\.0\.29628\.1000\)' KB=5007651 offered=10\.0\.29628\.1000 installed=Microsoft\.SecHealthUI 1000\.26100\.9168\.0"
        $script:record.Count | Should -Be 1
        $script:record[0].key | Should -BeExactly '0d5c1a3b-3a2b-4c6d-9e1f-2a3b4c5d6e7f/200'
    }

    It 'still fails an update that fails every time (result <Code>)' -TestCases @(@{ Code = 4 }, @{ Code = 5 }) {
        param($Code)
        $script:results = @(New-InstallResult $Code)
        try { Invoke-PreparationWindows } catch { $thrown = $_.Exception }
        $thrown.Message | Should -BeLike '*could not install every update*'
        Should -Invoke Invoke-PreparationWindowsOperation -Times 2 -Exactly -ParameterFilter { $Kind -eq 'Install' }
        $script:record.Count | Should -Be 0
    }

    It 'retries an update offered again after a failed install, within the limit' {
        $script:results = @((New-InstallResult 4), (New-InstallResult 2))
        $script:searches = 0
        Mock Find-PreparationWindowsUpdate { $script:searches++; if ($script:searches -le 2) { New-ReofferedUpdate } }
        Invoke-PreparationWindows | Should -Be 'complete'
        Should -Invoke Invoke-PreparationWindowsOperation -Times 2 -Exactly -ParameterFilter { $Kind -eq 'Install' }
        $script:record.Count | Should -Be 0
    }

}

Describe 'The install''s own check after an update was offered again' {
    BeforeAll {
        function New-ReofferedUpdate([string]$Title = 'Update for Windows Security platform - KB5007651 (Version 10.0.29628.1000)') {
            [pscustomobject]@{
                Title = $Title; KBArticleIDs = @('5007651')
                Identity = [pscustomobject]@{ UpdateID = '0d5c1a3b-3a2b-4c6d-9e1f-2a3b4c5d6e7f'; RevisionNumber = 200 }
            }
        }
    }

    It 'leaves a recorded update out of the search the install''s own check runs' {
        Mock Read-PreparationReoffered { [pscustomobject]@{ key = '0d5c1a3b-3a2b-4c6d-9e1f-2a3b4c5d6e7f/200'; at = [DateTime]::UtcNow.ToString('o') } }
        $other = New-ReofferedUpdate 'Another update'
        $other.Identity = [pscustomobject]@{ UpdateID = 'other'; RevisionNumber = 1 }
        $script:searchResult = @((New-ReofferedUpdate), $other)
        Mock Invoke-PreparationSearch { $script:searchResult }
        Mock Test-PreparationUpdate { $true }
        $found = @(Find-PreparationWindowsUpdate ([pscustomobject]@{}))
        @($found.Title) | Should -Be @('Another update')
    }
}

Describe 'Provider progress without interrupting servicing' {
    BeforeEach {
        $script:ticks = 0
        $script:cleaned = $false
        $script:ended = $false
        $script:progress = [pscustomobject]@{
            PercentComplete=37; CurrentUpdateIndex=1
            TotalBytesDownloaded='37000000'; TotalBytesToDownload='100000000'
        }
        $script:progress | Add-Member ScriptMethod GetUpdateResult {
            param($Index)
            if ($Index -eq 0) { return [pscustomobject]@{ResultCode=2} }
            throw 'No result for the active update yet'
        }
        $script:updates = [pscustomobject]@{Count=2}
        $script:updates | Add-Member ScriptMethod Item { param($Index); [pscustomobject]@{Title="Update $Index"} }
        $script:job = [pscustomobject]@{}
        $script:job | Add-Member ScriptProperty IsCompleted { $script:ticks -ge 2 }
        $script:job | Add-Member ScriptMethod GetProgress { $script:progress }
        $script:job | Add-Member ScriptMethod CleanUp { $script:cleaned=$true }
        $script:provider = [pscustomobject]@{}
        $script:provider | Add-Member ScriptMethod BeginDownload { param($Progress, $Completed, $State); if ($null -eq $Progress -or $null -eq $Completed -or $null -ne $State) { throw 'Invalid callbacks' }; $script:job }
        $script:provider | Add-Member ScriptMethod BeginInstall { param($Progress, $Completed, $State); if ($null -eq $Progress -or $null -eq $Completed -or $null -ne $State) { throw 'Invalid callbacks' }; $script:job }
        $script:provider | Add-Member ScriptMethod EndDownload { param($Job); if ($Job -ne $script:job) { throw 'Wrong job' }; $script:ended=$true; [pscustomobject]@{ResultCode=3} }
        $script:provider | Add-Member ScriptMethod EndInstall { param($Job); if ($Job -ne $script:job) { throw 'Wrong job' }; $script:ended=$true; [pscustomobject]@{ResultCode=3; RebootRequired=$true} }
        Mock New-PreparationCallback { [pscustomobject]@{} }
        Mock Start-Sleep { $script:ticks++ }
        Mock Write-PreparationState {}
        Mock Assert-PreparationContinue { throw 'Do not abandon an active provider job for a stop request' }
    }
    It 'reports bytes, the update title and provider percentage without equating the index with success' {
        Write-PreparationWindowsProgress $script:job $script:updates windows-download
        Should -Invoke Write-PreparationState -Times 1 -Exactly -ParameterFilter {
            $Stage -eq 'windows-download' -and $Completed -eq 1 -and $Total -eq 2 -and
            $Detail.percent -eq 37 -and $Detail.currentUpdate -eq 'Update 1' -and
            $Detail.bytesDownloaded -eq 37000000 -and $Detail.bytesTotal -eq 100000000
        }
    }
    It 'keeps unknown progress indeterminate when telemetry is unavailable' {
        $script:job | Add-Member ScriptMethod GetProgress { throw 'temporarily unavailable' } -Force
        Write-PreparationWindowsProgress $script:job $script:updates windows-install
        Should -Invoke Write-PreparationState -Times 1 -Exactly -ParameterFilter { $Detail.Count -eq 0 -and $Completed -eq 0 }
    }
    It 'waits for <Kind>, keeps the provider result and cleans up the completed job' -TestCases @(
        @{Kind='Download'}, @{Kind='Install'}
    ) {
        param($Kind)
        $result = Invoke-PreparationWindowsOperation $script:provider $script:updates $Kind
        $script:ticks | Should -Be 2
        $script:ended | Should -BeTrue
        $script:cleaned | Should -BeTrue
        $result.ResultCode | Should -Be 3
        if ($Kind -eq 'Install') { $result.RebootRequired | Should -BeTrue }
        Should -Invoke Write-PreparationState -Times 2 -Exactly
        Should -Invoke Assert-PreparationContinue -Times 0 -Exactly
    }
    It 'does not abandon an active installation when the progress journal cannot be written' {
        Mock Write-PreparationState { throw 'disk write failed' }
        { Invoke-PreparationWindowsOperation $script:provider $script:updates Install } | Should -Throw '*disk write failed*'
        $script:ticks | Should -Be 2
        $script:ended | Should -BeTrue
        $script:cleaned | Should -BeTrue
    }
}

Describe 'Progress freshness' {
    It 'distinguishes unchanged provider progress from a fresh heartbeat' {
        $JobPath = Join-Path $TestDrive 'heartbeat'
        [void][IO.Directory]::CreateDirectory($JobPath)
        $savedClock = $script:PreparationClock
        try {
            $script:PreparationClock = [pscustomobject]@{Elapsed=[TimeSpan]::FromSeconds(5)}
            Write-PreparationState running windows-download -Detail @{percent=20}
            $script:PreparationClock.Elapsed = [TimeSpan]::FromSeconds(70)
            Write-PreparationState running windows-download -Detail @{percent=20}
            $record = Get-Content (Join-Path $JobPath 'state.json') -Raw | ConvertFrom-Json
            $record.activity.elapsedSeconds | Should -Be 70
            $record.activity.unchangedSeconds | Should -Be 65
            Write-PreparationState running windows-download -Detail @{percent=21; restartReasons=@('servicing', 'file-renames')}
            $record = Get-Content (Join-Path $JobPath 'state.json') -Raw | ConvertFrom-Json
            $record.activity.unchangedSeconds | Should -Be 0
            @($record.activity.restartReasons) | Should -Be @('servicing', 'file-renames')
        } finally { $script:PreparationClock = $savedClock }
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
        $script:PreparationNetworkReason | Should -BeNullOrEmpty
        foreach ($kind in @('Fixed','Variable','Unknown')) {
            $script:networkCost.NetworkCostType = $kind
            Test-PreparationNetwork | Should -BeFalse
            $script:PreparationNetworkReason | Should -Be 'metered'
        }
        $script:networkCost.NetworkCostType = 'Unrestricted'
        $script:networkCost.OverDataLimit = $true
        Test-PreparationNetwork | Should -BeFalse
        $script:PreparationNetworkReason | Should -Be 'metered'
        $script:networkCost.OverDataLimit = $false
        $script:networkCost.Roaming = $true
        Test-PreparationNetwork | Should -BeFalse
        $script:PreparationNetworkReason | Should -Be 'roaming'
        $script:networkCost.Roaming = $false
        foreach ($level in @('ConstrainedInternetAccess', 'LocalAccess')) {
            $script:networkLevel = $level
            Test-PreparationNetwork | Should -BeFalse
            $script:PreparationNetworkReason | Should -Be 'limited'
        }
        $script:networkLevel = 'None'
        Test-PreparationNetwork | Should -BeFalse
        $script:PreparationNetworkReason | Should -Be 'offline'
        Mock Get-PreparationNetworkProfile { $null }
        Test-PreparationNetwork | Should -BeFalse
        $script:PreparationNetworkReason | Should -Be 'offline'
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

Describe 'Transient Store deployment recovery' {
    BeforeEach {
        Mock Assert-PreparationContinue {}
        Mock Write-PreparationState {}
        Mock Start-Sleep {}
        Mock Test-PreparationRestart { $false }
        $script:storeAttempts = 0
        Mock Invoke-PreparationStore {
            $script:storeAttempts++
            if ($script:storeAttempts -le 2) {
                throw (New-PreparationStoreFailure 'Microsoft.Xbox.TCUI_8wekyb3d8bbwe' 'Error' ([Runtime.InteropServices.COMException]::new('Deployment busy', -2145124330)))
            }
        }
    }
    It 'recovers a busy Store without returning an error to the caller' {
        { Invoke-PreparationStoreWithRetry } | Should -Not -Throw
        Should -Invoke Invoke-PreparationStore -Times 3 -Exactly
        Should -Invoke Start-Sleep -Times 30 -Exactly
    }
    It 'stops retrying a persistent conflict after four attempts' {
        Mock Invoke-PreparationStore { throw (New-PreparationStoreFailure 'Microsoft.Xbox.TCUI_8wekyb3d8bbwe' 'Error' ([Runtime.InteropServices.COMException]::new('Deployment busy', -2145124330))) }
        { Invoke-PreparationStoreWithRetry } | Should -Throw '*Deployment busy*'
        Should -Invoke Invoke-PreparationStore -Times 4 -Exactly
    }
    It 'does not delay a required restart' {
        Mock Test-PreparationRestart { $true }
        { Invoke-PreparationStoreWithRetry } | Should -Throw '*Deployment busy*'
        Should -Invoke Invoke-PreparationStore -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }
    It 'preserves unknown errors without repeatedly invoking the provider' {
        Mock Invoke-PreparationStore { throw 'Unknown provider failure' }
        { Invoke-PreparationStoreWithRetry } | Should -Throw '*Unknown provider failure*'
        Should -Invoke Invoke-PreparationStore -Times 1 -Exactly
    }
    It 'honours cancellation during the retry delay' {
        Mock Assert-PreparationContinue { throw [OperationCanceledException]::new('Stopped') }
        { Invoke-PreparationStoreWithRetry } | Should -Throw '*Stopped*'
        Should -Invoke Invoke-PreparationStore -Times 1 -Exactly
    }
}
