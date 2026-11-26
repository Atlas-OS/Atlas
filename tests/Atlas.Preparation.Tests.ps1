BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    . (Join-Path $PSScriptRoot '..\package\Executables\AtlasModules\Scripts\Preparation\Update-Windows.ps1') -JobPath $TestDrive -FunctionsOnly
    # No test reads this PC's component store or starts DISM.
    $script:ComponentHealth = 'Healthy'
    function Get-AtlasTransitionImageHealth { if ($script:ComponentHealth -eq 'Throws') { throw 'DISM is unavailable' }; $script:ComponentHealth }
    function Invoke-PreparationRestoreHealth { throw 'A test started DISM without standing in for it.' }
    function Invoke-AtlasTransitionScanHealth { throw 'A test started DISM without standing in for it.' }
    # No test reads or writes this PC's record of what a restart was for.
    $script:RestartRecordText = ''
    function Get-PreparationRestartRecordText { $script:RestartRecordText }
    function Set-PreparationRestartRecordText([string]$Text) { $script:RestartRecordText = $Text }
    # Nor its record of AppX staging failures the Store repairs didn't help.
    $script:StagingRecordText = ''
    function Get-PreparationStagingRecordText { $script:StagingRecordText }
    function Set-PreparationStagingRecordText([string]$Text) { $script:StagingRecordText = $Text }
    # No test reads or starts this PC's Windows Update service.
    function Get-PreparationUpdateServiceStatus { 'Running' }
    function Start-PreparationUpdateService { throw 'A test started Windows Update without standing in for it.' }
    # Nor reads its servicing log, or reads or writes its record of failed repairs.
    $script:CbsLines = @()
    function Get-AtlasTransitionCbsLogTail { $script:CbsLines }
    $script:RepairRecordText = ''
    function Get-PreparationRepairRecordText { $script:RepairRecordText }
    function Set-PreparationRepairRecordText([string]$Text) { $script:RepairRecordText = $Text }
    # Nor its record of the last restart asked for and of a stale servicing marker,
    # what servicing has waiting, or whether Windows Update waits for a restart.
    $script:RestartAskedText = ''
    function Get-PreparationRestartAskedText { $script:RestartAskedText }
    function Set-PreparationRestartAskedText([string]$Text) { $script:RestartAskedText = $Text }
    $script:StaleMarkerText = ''
    function Set-PreparationServicingStaleText([string]$Text) { $script:StaleMarkerText = $Text }
    $script:ServicingPending = @()
    function Get-AtlasServicingPending { $script:ServicingPending }
    $script:UpdateRestart = $false
    function Test-AtlasTransitionUpdateRestartRequired { $script:UpdateRestart }
    function Get-AtlasTransitionBootId { 'boot:8' }
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
    It 'publishes progress after a reader releases the previous report' {
        Set-Variable -Name PersistentCancellation -Value $false
        $JobPath = Join-Path $TestDrive 'busy-report'
        [void][IO.Directory]::CreateDirectory($JobPath)
        Write-PreparationState running verify
        $path = Join-Path $JobPath 'state.json'
        $reader = [IO.File]::Open($path, 'Open', 'Read', 'Read')
        Mock Start-Sleep { $reader.Dispose() }
        try { Write-PreparationState complete verify } finally { $reader.Dispose() }
        Should -Invoke Start-Sleep -Times 1 -Exactly
        (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json).status | Should -Be 'complete'
        Test-Path (Join-Path $JobPath 'state.tmp') | Should -BeFalse
    }
    It 'replaces the report again once Windows can (<Name>)' -TestCases @(
        @{ Name = 'the old report could not be removed'; HResult = -2147023721; MovedAside = $false }
        @{ Name = 'the new report could not be moved in'; HResult = -2147023720; MovedAside = $true }
        @{ Name = 'the new report could not be moved in, with the old one renamed'; HResult = -2147023719; MovedAside = $true }
    ) {
        Set-Variable -Name PersistentCancellation -Value $false
        $JobPath = Join-Path $TestDrive "replace-$HResult"
        [void][IO.Directory]::CreateDirectory($JobPath)
        $path = Join-Path $JobPath 'state.json'
        Write-PreparationState running verify
        $script:refusals = 2
        Mock Start-Sleep {}
        Mock Invoke-AtlasTransitionFileReplace {
            if ($script:refusals -gt 0) {
                $script:refusals--
                # Without a backup name, ReplaceFile can leave the old file moved aside.
                if ($MovedAside -and [IO.File]::Exists($Path)) { [IO.File]::Move($Path, "$Path.aside") }
                throw [IO.IOException]::new('Windows refused the replacement.', $HResult)
            }
            if ([IO.File]::Exists($Path)) { [IO.File]::Replace($Temporary, $Path, [NullString]::Value) }
            else { [IO.File]::Move($Temporary, $Path) }
        }
        Write-PreparationState complete verify
        (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json).status | Should -Be 'complete' -Because $Name
        Test-Path (Join-Path $JobPath 'state.tmp') | Should -BeFalse
        Should -Invoke Invoke-AtlasTransitionFileReplace -Times 3 -Exactly
    }
    It 'keeps the earlier report whole, and the run going, while Windows refuses to replace it' {
        Set-Variable -Name PersistentCancellation -Value $true
        $JobPath = Join-Path $TestDrive 'replace-refused'
        [void][IO.Directory]::CreateDirectory($JobPath)
        Mock Get-PreparationStateSecurity {
            $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
            $security = New-Object Security.AccessControl.FileSecurity
            $security.SetSecurityDescriptorSddlForm("O:${sid}D:P(A;;FA;;;${sid})")
            return $security
        }
        $path = Join-Path $JobPath 'state.json'
        $script:PreparationStateHeld = $false
        Write-PreparationState running windows-search -Detail @{ currentUpdate = 'A long update title that makes this report longer than the next one' }
        $before = [IO.File]::ReadAllBytes($path)
        $script:slept = [Collections.Generic.List[int]]::new()
        Mock Start-Sleep { $script:slept.Add($Milliseconds) }
        Mock Invoke-AtlasTransitionFileReplace { throw [IO.IOException]::new('Unable to remove the file to be replaced.', -2147023721) }
        Write-PreparationState running verify
        Write-PreparationState running windows-search
        [IO.File]::ReadAllBytes($path) | Should -Be $before
        (Get-Item -LiteralPath $path).GetAccessControl().AreAccessRulesProtected | Should -BeTrue
        Test-Path (Join-Path $JobPath 'state.tmp') | Should -BeFalse
        # Each wait is longer than the last, and each report waits about five seconds in all.
        @($script:slept | Select-Object -First 5) | Should -Be @(100, 200, 400, 800, 1000)
        ($script:slept | Measure-Object -Sum).Sum | Should -Be 9000
        @(Select-String -LiteralPath (Join-Path $JobPath 'updates.log') -Pattern 'state\.json could not be replaced \(0x80070497: Unable to remove the file to be replaced\.\); it keeps the last report').Count | Should -Be 1
    }
    It 'waits longer for the report of how the run ended, then fails the run with Windows''s refusal when it can''t be written in place either' {
        Set-Variable -Name PersistentCancellation -Value $false
        $JobPath = Join-Path $TestDrive 'replace-refused-end'
        [void][IO.Directory]::CreateDirectory($JobPath)
        $path = Join-Path $JobPath 'state.json'
        Write-PreparationState running verify
        $before = [IO.File]::ReadAllBytes($path)
        $script:slept = 0
        Mock Start-Sleep { $script:slept += $Milliseconds }
        Mock Invoke-AtlasTransitionFileReplace { throw [IO.IOException]::new('Unable to remove the file to be replaced.', -2147023721) }
        Mock Write-AtlasTransitionFileInPlace { [IO.IOException]::new('The process cannot access the file because it is being used by another process.', -2147024864) }
        { Write-PreparationState complete verify } | Should -Throw '*Unable to remove the file to be replaced*'
        $script:slept | Should -BeGreaterThan 55000
        $script:slept | Should -Not -BeGreaterThan 60000
        [IO.File]::ReadAllBytes($path) | Should -Be $before
        Test-Path (Join-Path $JobPath 'state.tmp') | Should -BeFalse
        Get-Content -LiteralPath (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'could not be replaced \(0x80070497: .*\) or written in place \(0x80070020: '
    }
    It 'writes the report of how the run ended over the held one in place, keeping its protection, so the app gets a result' {
        Set-Variable -Name PersistentCancellation -Value $true
        $JobPath = Join-Path $TestDrive 'replace-held-end'
        [void][IO.Directory]::CreateDirectory($JobPath)
        Mock Get-PreparationStateSecurity {
            $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
            $security = New-Object Security.AccessControl.FileSecurity
            $security.SetSecurityDescriptorSddlForm("O:${sid}D:P(A;;FA;;;${sid})")
            return $security
        }
        $path = Join-Path $JobPath 'state.json'
        Write-PreparationState running windows-search -Detail @{ currentUpdate = 'A long update title that makes this report longer than the last one' }
        Mock Start-Sleep {}
        # Held for the whole run by something that lets the file be read and written,
        # but not removed, as a scanner can.
        $holder = [IO.File]::Open($path, 'Open', 'Read', 'ReadWrite')
        try { { Write-PreparationState complete verify } | Should -Not -Throw }
        finally { $holder.Dispose() }
        $report = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        $report.status | Should -Be 'complete'
        $report.activity.PSObject.Properties['currentUpdate'] | Should -BeNullOrEmpty -Because 'nothing of the longer report is left behind'
        (Get-Item -LiteralPath $path).GetAccessControl().AreAccessRulesProtected | Should -BeTrue
        Test-Path (Join-Path $JobPath 'state.tmp') | Should -BeFalse
        Get-Content -LiteralPath (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'the report of how the run ended was written over it in place'
    }
    It 'makes no report of its own when Windows moved the old one aside and the new one can''t take its name' {
        Set-Variable -Name PersistentCancellation -Value $false
        $JobPath = Join-Path $TestDrive 'replace-moved-aside'
        [void][IO.Directory]::CreateDirectory($JobPath)
        $path = Join-Path $JobPath 'state.json'
        Write-PreparationState running verify
        Mock Start-Sleep {}
        Mock Invoke-AtlasTransitionFileReplace {
            if ([IO.File]::Exists($Path)) {
                [IO.File]::Move($Path, "$Path.aside")
                throw [IO.IOException]::new('Unable to move the replacement file to the file to be replaced.', -2147023720)
            }
            throw [IO.IOException]::new('The process cannot access the file because it is being used by another process.', -2147024864)
        }
        Write-PreparationState running windows-search
        # Only a replacement puts a report in place, so none has any security but its own.
        Test-Path -LiteralPath $path | Should -BeFalse
        Test-Path (Join-Path $JobPath 'state.tmp') | Should -BeFalse
    }
    It 'keeps the earlier report for an error that waiting can''t help' {
        Set-Variable -Name PersistentCancellation -Value $false
        $JobPath = Join-Path $TestDrive 'replace-denied'
        [void][IO.Directory]::CreateDirectory($JobPath)
        $path = Join-Path $JobPath 'state.json'
        Write-PreparationState running verify
        $before = (Get-FileHash -LiteralPath $path).Hash
        Mock Start-Sleep {}
        Mock Invoke-AtlasTransitionFileReplace { throw [IO.IOException]::new('Access is denied.', -2147024891) }
        { Write-PreparationState complete verify } | Should -Throw '*Access is denied*'
        Should -Invoke Invoke-AtlasTransitionFileReplace -Times 1 -Exactly
        (Get-FileHash -LiteralPath $path).Hash | Should -Be $before
        Test-Path (Join-Path $JobPath 'state.tmp') | Should -BeFalse
    }
    It 'keeps the copy of the Windows Update record whole, and says why, when Windows keeps refusing to replace it' {
        $copy = Join-Path $TestDrive 'record-copy\journal.json'
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $copy))
        [IO.File]::WriteAllText($copy, '{"phase":"lifted","history":["an older and longer record"]}')
        Mock Get-AtlasTransitionCopyPath { $copy }
        Mock Start-Sleep {}
        Mock Invoke-AtlasTransitionFileReplace { throw [IO.IOException]::new('Unable to remove the file to be replaced.', -2147023721) }
        { Write-AtlasTransitionCopy '{"phase":"installed"}' } | Should -Throw 'Unable to remove the file to be replaced.'
        [IO.File]::ReadAllText($copy) | Should -BeExactly '{"phase":"lifted","history":["an older and longer record"]}'
        Test-Path "$copy.tmp" | Should -BeFalse
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

Describe 'Preparation logs' {
    It 'writes updates.log in UTF-8 whichever line comes first' {
        $JobPath = Join-Path $TestDrive 'utf8-log'
        [void][IO.Directory]::CreateDirectory($JobPath)
        $log = Join-Path $JobPath 'updates.log'
        # The app creates the log empty; the lines are a localized update title and
        # error position.
        [IO.File]::WriteAllBytes($log, [byte[]]@())
        $title = "Kumulatives Update f$([char]0xFC)r Windows 11"
        $position = "Au caract$([char]0xE8)re 12"
        Write-PreparationLog $title
        Write-PreparationLog $position
        $bytes = [IO.File]::ReadAllBytes($log)
        @($bytes[0..2]) | Should -Be @(0xEF, 0xBB, 0xBF)
        [Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3) | Should -BeExactly "$title`r`n$position`r`n"
    }

    It 'keeps the older transition log under a name diagnostics collect' {
        $script:AtlasTransitionEvidencePath = Join-Path $TestDrive 'windows-transition.log'
        try {
            [IO.File]::WriteAllText($script:AtlasTransitionEvidencePath, ('x' * 1MB) + 'an earlier step')
            Write-AtlasTransitionEvidence 'the next step'
            [IO.File]::ReadAllText((Join-Path $TestDrive 'windows-transition.old.log')) | Should -Match 'an earlier step$'
            [IO.File]::ReadAllText($script:AtlasTransitionEvidencePath) | Should -Match '^\S+ the next step\r\n$'
        }
        finally { $script:AtlasTransitionEvidencePath = $null }
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

    Context 'Servicing''s marker after a restart' {
        BeforeEach {
            $script:markerFixture = @{ Servicing = $true; WindowsUpdate = $false; Agent = $false }
            Mock Test-Path {
                ($script:markerFixture.Servicing -and $LiteralPath -like '*Component Based Servicing*') -or
                ($script:markerFixture.WindowsUpdate -and $LiteralPath -like '*Auto Update\RebootRequired')
            }
            Mock Get-ItemProperty { [pscustomobject]@{} }
            Mock New-Object { [pscustomobject]@{ RebootRequired = $script:markerFixture.Agent } } -ParameterFilter { $ComObject -eq 'Microsoft.Update.SystemInfo' }
            Mock Get-PreparationBootId { 'boot:8' }
            $script:ServicingPending = @()
            $script:UpdateRestart = $false
            $script:StaleMarkerText = ''
            $script:PreparationServicingSetAside = $false
            $script:PreparationServicingNoted = $false
            # The run before asked for a restart in the start of Windows before this one, with the marker there.
            $script:RestartAskedText = (@{ boot = 'boot:7'; at = [DateTime]::UtcNow.AddHours(-1).ToString('o'); reasons = @('servicing'); servicing = $true } | ConvertTo-Json -Compress)
            Remove-Item -LiteralPath (Join-Path $JobPath 'updates.log') -ErrorAction SilentlyContinue
        }
        AfterEach {
            $script:RestartAskedText = ''
            $script:PreparationServicingSetAside = $false
            $script:PreparationServicingNoted = $false
        }
        It 'sets the marker aside when servicing has nothing waiting and Windows Update needs no restart, and records it' {
            Test-PreparationRestart | Should -BeFalse
            @($script:PreparationRestartReasons) | Should -BeNullOrEmpty
            $script:PreparationServicingSetAside | Should -BeTrue
            $script:StaleMarkerText | Should -BeExactly 'boot:8'
            Should -Invoke New-Object -Times 0 -Exactly -ParameterFilter { $ComObject -eq 'Microsoft.Update.SystemInfo' }
            Test-PreparationRestart | Should -BeFalse
            @(Select-String -LiteralPath (Join-Path $JobPath 'updates.log') -Pattern 'stale restart marker: Windows servicing keeps RebootPending after restarting, but has nothing pending').Count | Should -Be 1 -Because 'the run notes it once'
        }
        It 'asks for the restart when <Case>' -TestCases @(
            @{ Case = 'no restart was asked for before'; Arrange = { $script:RestartAskedText = '' } }
            @{ Case = 'Windows hasn''t restarted since'; Arrange = { Mock Get-PreparationBootId { 'boot:7' } } }
            @{ Case = 'the marker wasn''t there when the restart was asked for'; Arrange = { $script:RestartAskedText = $script:RestartAskedText -replace '"servicing":true', '"servicing":false' } }
            @{ Case = 'the restart was asked for more than a week ago'; Arrange = { $script:RestartAskedText = (@{ boot = 'boot:7'; at = [DateTime]::UtcNow.AddDays(-8).ToString('o'); reasons = @('servicing'); servicing = $true } | ConvertTo-Json -Compress) } }
            @{ Case = 'servicing has something waiting'; Arrange = { $script:ServicingPending = @('pending.xml') } }
            @{ Case = 'Windows Update needs a restart'; Arrange = { $script:UpdateRestart = $true } }
            @{ Case = 'Windows Update''s own marker is there too'; Arrange = { $script:markerFixture.WindowsUpdate = $true } }
            @{ Case = 'the record can''t be read'; Arrange = { $script:RestartAskedText = '{not json' } }
            @{ Case = 'what servicing has waiting can''t be read'; Arrange = { Mock Get-AtlasServicingPending { throw 'Access is denied.' } } }
        ) {
            param($Case, $Arrange)
            & $Arrange
            Test-PreparationRestart | Should -BeTrue -Because $Case
            @($script:PreparationRestartReasons) | Should -Contain 'servicing'
            $script:PreparationServicingSetAside | Should -BeFalse
            $script:StaleMarkerText | Should -BeNullOrEmpty
        }
        It 'logs what servicing has waiting, once' {
            $script:ServicingPending = @('pending.xml', 'package Package_for_KB5132061~31bf3856ad364e35~amd64~~26100.9974.1.1 (CurrentState 96)')
            Test-PreparationRestart | Should -BeTrue
            Test-PreparationRestart | Should -BeTrue
            @(Select-String -LiteralPath (Join-Path $JobPath 'updates.log') -Pattern 'still asks for a restart after restarting, and has this waiting: pending\.xml, package Package_for_KB5132061').Count | Should -Be 1
        }
        It 'records the restart it asks for, with the start of Windows and whether the marker was there' {
            $script:RestartAskedText = ''
            Save-PreparationRestartAsked @('servicing', 'file-renames')
            $record = $script:RestartAskedText | ConvertFrom-Json
            $record.boot | Should -BeExactly 'boot:8'
            @($record.reasons) | Should -Be @('servicing', 'file-renames')
            $record.servicing | Should -BeTrue
            $script:markerFixture.Servicing = $false
            Save-PreparationRestartAsked @('windows-update')
            ($script:RestartAskedText | ConvertFrom-Json).servicing | Should -BeFalse
        }
        It 'stops instead of restarting again when Windows Update still asks for a restart after the marker was set aside' {
            { Assert-PreparationRestartHelps } | Should -Not -Throw
            Test-PreparationRestart | Should -BeFalse
            try { Assert-PreparationRestartHelps } catch { $thrown = $_.Exception }
            (Get-PreparationFailureDetail $thrown).reason | Should -BeExactly 'manual-updates'
            $thrown.Data['restartRepeated'] | Should -BeTrue
            $thrown.Message | Should -Match 'asks for a restart before it installs updates, although Windows has restarted for it'
        }
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
    It 'logs the offer and blocks before Store if Windows offers required updates' {
        Mock Write-PreparationLog {}
        Mock Find-PreparationWindowsUpdate {
            [pscustomobject]@{ Title='Required update'; KBArticleIDs=@('5127694') }
        }
        { Assert-PreparationCurrent } | Should -Throw '*Windows still offers*'
        Should -Invoke New-PreparationStoreManager -Times 0 -Exactly
        Should -Invoke Write-PreparationLog -Times 1 -Exactly -ParameterFilter { $Text -like '*before the Store check*' }
        Should -Invoke Write-PreparationLog -Times 1 -Exactly -ParameterFilter { $Text -eq 'Required update: Required update (KB: 5127694)' }
    }

    It 'logs a new offer that appears only after the Store check' {
        $script:verificationSearches = 0
        Mock Write-PreparationLog {}
        Mock Find-PreparationWindowsUpdate {
            $script:verificationSearches++
            if ($script:verificationSearches -eq 2) { [pscustomobject]@{ Title='New offer' } }
        }
        { Assert-PreparationCurrent } | Should -Throw '*additional updates during verification*'
        Should -Invoke Write-PreparationLog -Times 1 -Exactly -ParameterFilter { $Text -like '*after the Store check*' }
        Should -Invoke Write-PreparationLog -Times 1 -Exactly -ParameterFilter { $Text -eq 'Required update: New offer' }
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
        # No registration or repair may reach the PC running the tests, nor a read of its AppX log.
        Mock Register-PreparationStore { $true }
        Mock Invoke-PreparationStoreRepair { $script:Repairs.Add($Repair); $false }
        Mock Get-PreparationStagingFailure {}
        $script:PreparationStagingBootstrap = $null
        $script:StagingRecordText = ''
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

    It 'reports the HRESULT for the final Store failure message' {
        Mock Update-PreparationStoreItself {
            if ($script:Repairs.Count -eq 0) {
                throw (New-PreparationFailure 'First package failure' 'store-update-failed' 0x80240008)
            }
            throw (New-PreparationFailure 'Final package failure' 'store-update-failed' 0x80073CF9)
        }
        Mock Invoke-PreparationStoreRepair { $script:Repairs.Add($Repair); $true }

        try { Invoke-PreparationStoreStage } catch { $failure = $_.Exception }
        $detail = Get-PreparationFailureDetail $failure
        $detail.reason | Should -Be 'store-repair-failed'
        $detail.failureMessage | Should -Match 'Final package failure'
        $detail.errorCode | Should -Be '0x80073CF9'
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
        @{ Case = 'a Store slow to the end'; Failure = { $slow = New-PreparationFailure 'Store apps have not finished updating.' 'store-timeout'; $slow.Data['storeTransient'] = 'final'; $slow } }
    ) {
        $script:Failure = & $Failure
        Mock Invoke-PreparationStoreWithRetry { throw $script:Failure }
        { Invoke-PreparationStoreStage } | Should -Throw
        $script:Repairs.Count | Should -Be 0
    }

    It 'repairs a Store that <Case> through every try, as a Store failing every time can be broken' -TestCases @(
        @{ Case = 'kept cancelling an item'; Failure = { New-PreparationStoreFailure 'Microsoft.Windows.Photos_8wekyb3d8bbwe' 'Canceled' ([Runtime.InteropServices.COMException]::new('Operation aborted', -2147467260)) } }
        @{ Case = 'kept not answering'; Failure = { $silent = New-PreparationFailure 'Microsoft Store did not answer.' 'store-timeout'; $silent.Data['storeTransient'] = 'retry'; $silent } }
        @{ Case = 'kept refusing to resume a download'; Failure = { $refused = New-PreparationFailure 'Microsoft Store couldn''t resume Microsoft.ZuneMusic_8wekyb3d8bbwe.' 'store-timeout' -2147467259; $refused.Data['storeTransient'] = 'retry'; $refused } }
    ) {
        $script:Failure = & $Failure
        Mock Invoke-PreparationStoreWithRetry { throw $script:Failure }
        { Invoke-PreparationStoreStage } | Should -Throw
        @($script:Repairs) | Should -Be @('wsreset', 'bootstrap', 'storefixer') -Because $Case
    }

    It 'gives the Store''s own update its tries before the repairs, and one try after each' {
        Mock Update-PreparationStoreItself { if (-not $script:Fixed) { throw (New-PreparationFailure 'Microsoft Store is not registered for this user.' 'store-missing') }; $false }
        Mock Invoke-PreparationStoreRepair { $script:Repairs.Add($Repair); if ($Repair -eq 'bootstrap') { $script:Fixed = $true }; $true }
        Invoke-PreparationStoreStage
        Should -Invoke Update-PreparationStoreItself -Times 1 -Exactly -ParameterFilter { $Retry }
        Should -Invoke Update-PreparationStoreItself -Times 2 -Exactly -ParameterFilter { -not $Retry }
    }

    It 'restarts the Store''s install service first when the Store didn''t answer, and stops there when that''s what it needed' {
        $script:Silent = New-PreparationFailure 'Microsoft Store did not answer.' 'store-timeout'
        $script:Silent.Data['storeTransient'] = 'retry'
        $script:Silent.Data['storeSilent'] = $true
        Mock Update-PreparationStoreItself { if (-not $script:Fixed) { throw $script:Silent }; $false }
        Mock Invoke-PreparationStoreRepair { $script:Repairs.Add($Repair); if ($Repair -eq 'installservice') { $script:Fixed = $true }; $true }
        Invoke-PreparationStoreStage
        @($script:Repairs) | Should -Be @('installservice')
        (Get-PreparationOutcomeDetail).storeOutcome | Should -Be 'store-repaired'
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'works again after installservice'
    }

    It 'goes on to the usual repairs when restarting the install service doesn''t help' {
        $script:Silent = New-PreparationFailure 'Microsoft Store did not answer.' 'store-timeout'
        $script:Silent.Data['storeTransient'] = 'retry'
        $script:Silent.Data['storeSilent'] = $true
        Mock Update-PreparationStoreItself { throw $script:Silent }
        Mock Invoke-PreparationStoreRepair { $script:Repairs.Add($Repair); $true }
        try { Invoke-PreparationStoreStage } catch { $thrown = $_.Exception }
        @($script:Repairs) | Should -Be @('installservice', 'wsreset', 'bootstrap', 'storefixer')
        $detail = Get-PreparationFailureDetail $thrown
        $detail.reason | Should -Be 'store-repair-failed'
        $detail.failureMessage | Should -Match "\(installservice didn't help; wsreset didn't help; bootstrap didn't help; storefixer didn't help\)"
    }

    It 'says which repairs ran, failed or were skipped, and names a network problem' {
        Mock Update-PreparationStoreItself { throw (New-PreparationFailure 'Microsoft Store is not registered for this user.' 'store-missing') }
        Mock Invoke-PreparationStoreRepair {
            $script:Repairs.Add($Repair)
            switch ($Repair) {
                'bootstrap' { throw (New-PreparationNetworkFailure 'https://api.github.com/repos/microsoft/winget-cli' 'HTTP 403') }
                'storefixer' { 'skipped' }
                default { $false }
            }
        }
        try { Invoke-PreparationStoreStage } catch { $failure = $_.Exception }
        $detail = Get-PreparationFailureDetail $failure
        $detail.reason | Should -Be 'store-repair-failed'
        $detail.failureMessage | Should -Match '\(wsreset changed nothing; bootstrap failed, a network problem; storefixer skipped\): Microsoft Store is not registered'
        $log = Get-Content (Join-Path $JobPath 'updates.log') -Raw
        $log | Should -Match 'bootstrap failed, a network problem: A network problem stopped the download from api\.github\.com: HTTP 403'
        $log | Should -Match 'storefixer skipped'
        $log | Should -Not -Match 'storefixer changed nothing'
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

    Context 'App Installer for the bootstrap' {
        BeforeAll {
            function New-AppInstallerPackage([string]$Version, $Users = @(), [string]$Family = 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe') {
                [pscustomobject]@{
                    Version = $Version; PackageFamilyName = $Family; PackageUserInformation = $Users
                    PackageFullName = "Microsoft.DesktopAppInstaller_${Version}_x64__$($Family.Substring($Family.LastIndexOf('_') + 1))"
                }
            }
            function New-PackageUser([string]$Sid, [string]$Username, [string]$State) {
                [pscustomobject]@{ UserSecurityId = [pscustomobject]@{ Sid = $Sid; Username = $Username }; InstallState = $State }
            }
        }
        BeforeEach {
            # This user's App Installer, and the newest any account has or the PC has staged.
            $script:UserVersion = '1.27.459.0'
            $script:StagedVersion = '1.27.459.0'
            $script:RegisteredVersion = $null
            $script:UsersUnreadable = $false
            # Another publisher's package of the same name, for this user or another account.
            $script:Foreign = @{ User = @(); AllUsers = @() }
            Mock Get-AppxPackage {
                if ($AllUsers) {
                    # An entry without its account stands for one the worker's strict mode can't read.
                    $users = if ($script:UsersUnreadable) { @([pscustomobject]@{ InstallState = 'Staged' }) }
                    else { @((New-PackageUser 'S-1-5-18' 'S-1-5-18' 'Staged'), (New-PackageUser 'S-1-5-21-1-2-3-1002' 'DESKTOP-PC\Alice' 'Installed')) }
                    return @((New-AppInstallerPackage '1.27.459.0' @(New-PackageUser 'S-1-5-21-1-2-3-1001' 'DESKTOP-PC\Owner' 'Installed')),
                        (New-AppInstallerPackage $script:StagedVersion $users)) + $script:Foreign.AllUsers
                }
                @(if ($script:UserVersion) { New-AppInstallerPackage $script:UserVersion }) + $script:Foreign.User
            }
            # The provisioned bundle's version, never App Installer's own.
            Mock Get-AppxProvisionedPackage { @([pscustomobject]@{ DisplayName = 'Microsoft.DesktopAppInstaller'; Version = '2026.115.2221.0'; PackageName = 'Microsoft.DesktopAppInstaller_2026.115.2221.0_neutral_~_8wekyb3d8bbwe' }) }
            Mock Add-AppxPackage { if ($script:RegisteredVersion) { $script:UserVersion = $script:RegisteredVersion } }
            Mock Get-PreparationWingetPath { 'C:\Program Files\WindowsApps\winget.exe' }
            Mock Save-PreparationAppInstaller {}
            Mock Assert-PreparationWingetStoreSource {}
            Mock Invoke-PreparationStoreProcess { 0 }
        }

        It 'downloads App Installer when only the provisioned bundle''s version is higher than the user''s' {
            Install-PreparationStoreFromMicrosoft | Should -BeTrue
            Should -Invoke Add-AppxPackage -Times 0 -Exactly
            Should -Invoke Save-PreparationAppInstaller -Times 1 -Exactly
            Should -Invoke Invoke-PreparationStoreProcess -Times 1 -Exactly -ParameterFilter { $Arguments -like '*--id 9WZDNCRFJBMP --source msstore*' }
            Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'this user has 1\.27\.459\.0, and this PC has nothing newer'
        }

        It 'continues with the signed installed winget when Windows refuses to downgrade App Installer' {
            Mock Save-PreparationAppInstaller {
                throw [Runtime.InteropServices.COMException]::new('A newer package is installed', 0x80073D06)
            }

            Install-PreparationStoreFromMicrosoft | Should -BeTrue
            Should -Invoke Get-PreparationWingetPath -Times 1 -Exactly
            Should -Invoke Assert-PreparationWingetStoreSource -Times 1 -Exactly
            Should -Invoke Invoke-PreparationStoreProcess -Times 1 -Exactly -ParameterFilter {
                $Arguments -like '*--id 9WZDNCRFJBMP --source msstore*'
            }
            $script:PreparationStoreDownloaded | Should -BeFalse
            Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'trying the installed winget \(0x80073D06\)'
        }

        It 'still stops the bootstrap on an unrelated App Installer deployment failure' {
            Mock Save-PreparationAppInstaller {
                throw [Runtime.InteropServices.COMException]::new('App Installer deployment failed', 0x80073CF9)
            }

            { Install-PreparationStoreFromMicrosoft } | Should -Throw '*App Installer deployment failed*'
            Should -Invoke Get-PreparationWingetPath -Times 0 -Exactly
            Should -Invoke Invoke-PreparationStoreProcess -Times 0 -Exactly
        }

        It 'downloads App Installer when registering the newer copy this PC has leaves the user''s version as it was' {
            $script:StagedVersion = '1.28.220.0'
            Install-PreparationStoreFromMicrosoft | Should -BeTrue
            Should -Invoke Add-AppxPackage -Times 1 -Exactly -ParameterFilter { $RegisterByFamilyName -and $MainPackage -eq 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe' }
            Should -Invoke Save-PreparationAppInstaller -Times 1 -Exactly
            Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'registering the copy this PC has changed nothing; this user has 1\.27\.459\.0'
        }

        It 'registers a newer App Installer staged on this PC for the user, says where it was by SID only, and downloads nothing' {
            $script:StagedVersion = '1.28.220.0'
            $script:RegisteredVersion = '1.28.220.0'
            Install-PreparationStoreFromMicrosoft | Should -BeTrue
            Should -Invoke Add-AppxPackage -Times 1 -Exactly -ParameterFilter { $RegisterByFamilyName -and $MainPackage -eq 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe' }
            Should -Invoke Save-PreparationAppInstaller -Times 0 -Exactly
            Should -Invoke Invoke-PreparationStoreProcess -Times 1 -Exactly -ParameterFilter { $Arguments -like '*--id 9WZDNCRFJBMP --source msstore*' }
            $script:PreparationStoreDownloaded | Should -BeFalse
            $log = Get-Content (Join-Path $JobPath 'updates.log') -Raw
            $log | Should -Match 'this PC has 1\.28\.220\.0, Microsoft\.DesktopAppInstaller_1\.28\.220\.0_x64__8wekyb3d8bbwe \(S-1-5-18: Staged; S-1-5-21-1-2-3-1002: Installed\); registering it'
            $log | Should -Match 'registered the copy this PC has, 1\.27\.459\.0 -> 1\.28\.220\.0'
            $log | Should -Not -Match 'Alice' -Because 'account names would reach reports'
        }

        It 'still registers the newer copy when its accounts can''t be read' {
            $script:StagedVersion = '1.28.220.0'
            $script:RegisteredVersion = '1.28.220.0'
            $script:UsersUnreadable = $true
            Install-PreparationStoreFromMicrosoft | Should -BeTrue
            Should -Invoke Add-AppxPackage -Times 1 -Exactly
            Should -Invoke Save-PreparationAppInstaller -Times 0 -Exactly
            Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'this PC has 1\.28\.220\.0, Microsoft\.DesktopAppInstaller_1\.28\.220\.0_x64__8wekyb3d8bbwe; registering it'
        }

        It 'registers the newer copy for a user who has no App Installer, and downloads nothing' {
            $script:UserVersion = $null
            $script:StagedVersion = '1.28.220.0'
            $script:RegisteredVersion = '1.28.220.0'
            Install-PreparationStoreFromMicrosoft | Should -BeTrue
            Should -Invoke Add-AppxPackage -Times 1 -Exactly
            Should -Invoke Save-PreparationAppInstaller -Times 0 -Exactly
            $log = Get-Content (Join-Path $JobPath 'updates.log') -Raw
            $log | Should -Match 'App Installer: this user has none; this PC has 1\.28\.220\.0'
            $log | Should -Match 'registered the copy this PC has, none -> 1\.28\.220\.0'
        }

        It 'downloads App Installer when registering leaves a user who had none still without it' {
            $script:UserVersion = $null
            $script:StagedVersion = '1.28.220.0'
            Install-PreparationStoreFromMicrosoft | Should -BeTrue
            Should -Invoke Add-AppxPackage -Times 1 -Exactly
            Should -Invoke Save-PreparationAppInstaller -Times 1 -Exactly
            Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'registering the copy this PC has changed nothing; this user has none'
        }

        It 'ignores a newer package of that name from another publisher that another account has' {
            $script:Foreign.AllUsers = @(New-AppInstallerPackage '9.0.0.0' @(New-PackageUser 'S-1-5-21-1-2-3-1002' 'DESKTOP-PC\Alice' 'Installed') 'Microsoft.DesktopAppInstaller_a1b2c3d4e5f6g')
            Install-PreparationStoreFromMicrosoft | Should -BeTrue
            Should -Invoke Add-AppxPackage -Times 0 -Exactly
            Should -Invoke Save-PreparationAppInstaller -Times 1 -Exactly
            Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'this user has 1\.27\.459\.0, and this PC has nothing newer'
        }

        It 'ignores a newer package of that name from another publisher that this user has' {
            $script:Foreign.User = @(New-AppInstallerPackage '9.0.0.0' @() 'Microsoft.DesktopAppInstaller_a1b2c3d4e5f6g')
            $script:StagedVersion = '1.28.220.0'
            $script:RegisteredVersion = '1.28.220.0'
            Install-PreparationStoreFromMicrosoft | Should -BeTrue
            Should -Invoke Add-AppxPackage -Times 1 -Exactly
            Should -Invoke Save-PreparationAppInstaller -Times 0 -Exactly
            Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'registered the copy this PC has, 1\.27\.459\.0 -> 1\.28\.220\.0'
        }

        It 'downloads App Installer when this PC has nothing newer than the user' {
            $script:UserVersion = '1.28.220.0'
            $script:StagedVersion = '1.28.220.0'
            Install-PreparationStoreFromMicrosoft | Should -BeTrue
            Should -Invoke Add-AppxPackage -Times 0 -Exactly
            Should -Invoke Save-PreparationAppInstaller -Times 1 -Exactly
        }
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

    It 'lets the update stage run the Store stage between the Windows passes, and returns the second pass''s result' {
        $script:Order = [Collections.Generic.List[string]]::new()
        Mock Write-PreparationState {}
        Mock Invoke-PreparationWindows { $script:Order.Add('windows'); if ($script:Order.Count -eq 1) { 'complete' } else { 'reboot' } }
        Mock Invoke-PreparationStoreStage { $script:Order.Add('store') }
        Invoke-PreparationUpdates | Should -Be 'reboot'
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
        $script:PreparationStoreQueueRefreshed = $false
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

    Context 'An installed app fails during the current pass' {
        BeforeEach {
            $script:FreshFailure = $script:StoreManager.AppInstallItems[0]
            $script:FreshFailure.PackageFamilyName = 'Microsoft.Windows.Photos_8wekyb3d8bbwe'
            $script:FreshFailure.ProductId = '9WZDNCRFJBH4'
            $script:StoreManager.AppInstallItems = @()
            $script:StoreSearches = 0
            Mock Get-PreparationPackageVersion { @{ 'Microsoft.Windows.Photos_8wekyb3d8bbwe' = '2026.11090.22001.0' } }
            Mock Wait-PreparationStoreSearch {
                $script:StoreSearches++
                if ($script:StoreSearches -eq 1) {
                    $script:StoreManager.AppInstallItems = @($script:FreshFailure)
                    $script:FreshFailure
                } else { $script:Offered }
            }
        }

        It 'waits for the queue to settle and only succeeds after a fresh search' {
            Mock Start-Sleep { $script:StoreManager.AppInstallItems = @() }
            { Invoke-PreparationStore } | Should -Not -Throw
            Should -Invoke Start-Sleep -Times 1 -Exactly
            Should -Invoke Wait-PreparationStoreSearch -Times 2 -Exactly
            $log = Get-Content (Join-Path $JobPath 'updates.log') -Raw
            $log | Should -Match '2026\.11090\.22001\.0 -> 2026\.11090\.22001\.0, Error'
            $log | Should -Match 'waiting for the failed queue entry to settle, then searching again'
        }

        It 'bounds the wait and preserves the failure when the Store offers the failed update again' {
            $script:Offered = @($script:FreshFailure)
            { Invoke-PreparationStore } | Should -Throw '*Microsoft.Windows.Photos_8wekyb3d8bbwe, Error*'
            Should -Invoke Start-Sleep -Times 30 -Exactly -ParameterFilter { $Seconds -eq 2 }
            Should -Invoke Wait-PreparationStoreSearch -Times 2 -Exactly
            $script:StoreManager.AppInstallItems.Count | Should -Be 0 -Because 'the failed queue record was cleared before the rescan'
        }

        It 'preserves an initial installation failure without waiting for a stale update' {
            Mock Get-PreparationPackageVersion { @{} }
            { Invoke-PreparationStore } | Should -Throw '*Microsoft.Windows.Photos_8wekyb3d8bbwe, Error*'
            Should -Invoke Start-Sleep -Times 0 -Exactly
            Should -Invoke Wait-PreparationStoreSearch -Times 1 -Exactly
        }
    }

    It 'checks the live queue when the final search returns no new offers' {
        $script:SecondQueueItem = $script:StoreManager.AppInstallItems[0]
        $script:StoreManager.AppInstallItems = @()
        $script:StoreSearches = 0
        Mock Wait-PreparationStoreSearch {
            $script:StoreSearches++
            if ($script:StoreSearches -eq 1) {
                $completed = [pscustomobject]@{ PackageFamilyName = 'Microsoft.Windows.Photos_8wekyb3d8bbwe'; ProductId = '9WZDNCRFJBH4' }
                $completed | Add-Member ScriptMethod GetCurrentStatus { [pscustomobject]@{ InstallState = 'Completed' } }
                $completed
            }
            if ($script:StoreSearches -eq 2) { $script:StoreManager.AppInstallItems = @($script:SecondQueueItem) }
        }
        { Invoke-PreparationStore } | Should -Not -Throw
        Should -Invoke Wait-PreparationStoreSearch -Times 3 -Exactly
        $script:StoreManager.AppInstallItems.Count | Should -Be 0
    }
}

Describe 'Store items Windows refused to deploy' {
    BeforeAll {
        function New-StoreItem([string]$Family, [string]$Product, $ErrorCode) {
            $item = [pscustomobject]@{ PackageFamilyName = $Family; ProductId = $Product; Status = [pscustomobject]@{ InstallState = 'Error'; ErrorCode = $ErrorCode } }
            $item | Add-Member ScriptMethod GetCurrentStatus { $this.Status }
            return $item
        }
        function New-DeploymentEvent([int]$Id, [string]$Message, [int]$MinutesAgo) {
            [pscustomobject]@{ Id = $Id; TimeCreated = [DateTime]::Now.AddMinutes(-$MinutesAgo); Message = $Message }
        }
        function Get-DeploymentLine { @(Get-Content (Join-Path $JobPath 'updates.log') | Where-Object { $_ -like 'Microsoft Store: deployment of *' }) }
        # 0x80073CF9, the install failed, as the Store reports most deployment failures.
        $script:InstallFailed = [Runtime.InteropServices.COMException]::new('Install failed. Please contact your software vendor.', -2147009287)
        $script:Calculator = 'Microsoft.WindowsCalculator_11.2509.1.0_x64__8wekyb3d8bbwe'
        $script:Overlay = 'Microsoft.XboxGamingOverlay_7.326.10141.0_neutral_~_8wekyb3d8bbwe'
    }
    BeforeEach {
        Remove-Item -LiteralPath (Join-Path $JobPath 'updates.log') -ErrorAction SilentlyContinue
        $script:PreparationDeploymentSeen.Clear()
        $script:PreparationDeploymentWritten = 0
        $script:PreparationStateRepositoryRead = $false
        Mock Get-PreparationPackageVersion { @{ 'Microsoft.WindowsCalculator_8wekyb3d8bbwe' = '11.2508.4.0' } }
        # Newest first, as Get-WinEvent returns them; a failing Store logs the
        # same failure again on every retry.
        $script:Events = @(
            (New-DeploymentEvent 404 "AppX Deployment operation failed for package $script:Calculator with error 0x80073CF9. The specific error text for this failure is: Deployment Stage operation with target volume C: on Package $script:Calculator from: (a15291e6f81eeb6b) failed with error 0x80070490." 1)
            (New-DeploymentEvent 401 "Deployment Stage operation with target volume C: on Package $script:Calculator from: (a15291e6f81eeb6b) failed with error 0x80070490.`r`nSee http://go.microsoft.com/fwlink/?LinkId=235160 for help diagnosing app deployment issues." 2)
            (New-DeploymentEvent 404 "AppX Deployment operation failed for package $script:Overlay with error 0x80073CF9. The specific error text for this failure is: Deployment Stage operation with target volume C: on Package $script:Overlay from: (c0ffee) failed with error 0x80070490." 3)
            (New-DeploymentEvent 404 "AppX Deployment operation failed for package $script:Calculator with error 0x80073CF9. The specific error text for this failure is: Deployment Stage operation with target volume C: on Package $script:Calculator from: (a15291e6f81eeb6b) failed with error 0x80070490." 4)
        )
        Mock Get-WinEvent { $script:Events }
        Mock Get-WinEvent {} -ParameterFilter { $FilterHashtable[0].LogName -eq 'Microsoft-Windows-StateRepository/Operational' }
    }

    It 'follows the item with the deployment log''s events since the run started, under each package' {
        $script:AtlasTransitionEvidencePath = Join-Path $TestDrive 'deployment-evidence.log'
        Remove-Item -LiteralPath $script:AtlasTransitionEvidencePath -ErrorAction SilentlyContinue
        try { Write-PreparationStoreItem @(New-StoreItem 'Microsoft.WindowsCalculator_8wekyb3d8bbwe' '9WZDNCRFHVN5' $script:InstallFailed) @{ 'Microsoft.WindowsCalculator_8wekyb3d8bbwe' = '11.2508.4.0' } }
        finally { $script:AtlasTransitionEvidencePath = $null }
        # The move's own log notes them and leaves the text to updates.log.
        $evidence = Get-Content (Join-Path $TestDrive 'deployment-evidence.log') -Raw
        $evidence | Should -Match 'store: Microsoft\.WindowsCalculator_8wekyb3d8bbwe \(0x80073CF9\) failed to deploy; the AppX deployment log since this run started has 3 new event\(s\) 401 or 404; updates\.log has them'
        $evidence | Should -Not -Match 'says:|deployment of '
        Should -Invoke Get-WinEvent -Times 1 -Exactly -ParameterFilter {
            $FilterHashtable[0].LogName -eq 'Microsoft-Windows-AppXDeploymentServer/Operational' -and
            (@($FilterHashtable[0].Id) -join ',') -eq '401,404' -and $FilterHashtable[0].StartTime -eq $script:PreparationStartedAt
        }
        $log = Get-Content (Join-Path $JobPath 'updates.log') -Raw
        $log | Should -Match 'item Microsoft\.WindowsCalculator_8wekyb3d8bbwe \(9WZDNCRFHVN5\): 11\.2508\.4\.0 -> 11\.2508\.4\.0, Error, 0x80073CF9'
        $log | Should -Match 'Microsoft\.WindowsCalculator_8wekyb3d8bbwe \(0x80073CF9\) failed to deploy; the AppX deployment log since this run started says:'
        $lines = Get-DeploymentLine
        # The repeated 404 is written once; each package's events oldest first.
        $lines.Count | Should -Be 3
        $lines[0] | Should -Match "^Microsoft Store: deployment of $([regex]::Escape($script:Calculator)), event 401 at .+: Deployment Stage operation .+ failed with error 0x80070490\. See http://go\.microsoft\.com/fwlink/\?LinkId=235160 for help diagnosing app deployment issues\.$"
        $lines[1] | Should -Match "^Microsoft Store: deployment of $([regex]::Escape($script:Calculator)), event 404 at .+: AppX Deployment operation failed .+ with error 0x80073CF9\. .+ failed with error 0x80070490\.$"
        $lines[2] | Should -Match "^Microsoft Store: deployment of $([regex]::Escape($script:Overlay)), event 404 "
    }

    It 'writes each event once a run' {
        $item = New-StoreItem 'Microsoft.WindowsCalculator_8wekyb3d8bbwe' '9WZDNCRFHVN5' $script:InstallFailed
        Write-PreparationStoreItem @($item) @{}
        Write-PreparationStoreItem @($item) @{}
        (Get-DeploymentLine).Count | Should -Be 3
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match "since this run started has no event 401 or 404 that updates\.log doesn't have already"
    }

    It 'collects related StateRepository errors once when staging reports a missing element' {
        Mock Get-WinEvent {
            New-DeploymentEvent 801 'StateRepository could not find a record for Microsoft.WindowsCalculator.' 1
            New-DeploymentEvent 802 'Unrelated application event.' 1
        } -ParameterFilter { $FilterHashtable[0].LogName -eq 'Microsoft-Windows-StateRepository/Operational' }
        $item = New-StoreItem 'Microsoft.WindowsCalculator_8wekyb3d8bbwe' '9WZDNCRFHVN5' $script:InstallFailed
        Write-PreparationStoreItem @($item) @{}
        Write-PreparationStoreItem @($item) @{}
        Should -Invoke Get-WinEvent -Times 1 -Exactly -ParameterFilter {
            $FilterHashtable[0].LogName -eq 'Microsoft-Windows-StateRepository/Operational' -and $FilterHashtable[0].Level -eq 2
        }
        $log = Get-Content (Join-Path $JobPath 'updates.log') -Raw
        $log | Should -Match 'StateRepository event 801 .*Microsoft\.WindowsCalculator'
        $log | Should -Not -Match 'Unrelated application event'
    }

    It 'keeps the newest few for each package and only so many a run' {
        $script:Events = @(1..6 | ForEach-Object { New-DeploymentEvent 401 "Deployment Stage operation with target volume C: on Package $script:Calculator from: (attempt $_) failed with error 0x80070490." $_ })
        Write-PreparationStoreItem @(New-StoreItem 'Microsoft.WindowsCalculator_8wekyb3d8bbwe' '9WZDNCRFHVN5' $script:InstallFailed) @{}
        $lines = Get-DeploymentLine
        $lines.Count | Should -Be $script:PreparationDeploymentPerPackage
        $lines[0] | Should -Match '\(attempt 4\)'
        $lines[-1] | Should -Match '\(attempt 1\)'
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match '2 more deployment event\(s\) left out'

        Remove-Item -LiteralPath (Join-Path $JobPath 'updates.log')
        $script:PreparationDeploymentSeen.Clear()
        $script:PreparationDeploymentWritten = $script:PreparationDeploymentLimit - 1
        Write-PreparationStoreItem @(New-StoreItem 'Microsoft.WindowsCalculator_8wekyb3d8bbwe' '9WZDNCRFHVN5' $script:InstallFailed) @{}
        @(Get-DeploymentLine).Count | Should -Be 1
        $script:PreparationDeploymentWritten | Should -Be $script:PreparationDeploymentLimit
    }

    It 'writes what a limit left out when a later item fails' {
        $script:Events = @(1..6 | ForEach-Object { New-DeploymentEvent 401 "Deployment Stage operation with target volume C: on Package $script:Calculator from: (attempt $_) failed with error 0x80070490." $_ })
        $item = New-StoreItem 'Microsoft.WindowsCalculator_8wekyb3d8bbwe' '9WZDNCRFHVN5' $script:InstallFailed
        Write-PreparationStoreItem @($item) @{}
        Write-PreparationStoreItem @($item) @{}
        $lines = Get-DeploymentLine
        $lines.Count | Should -Be 6
        $lines[4] | Should -Match '\(attempt 6\)'
        $lines[5] | Should -Match '\(attempt 5\)'
        $script:PreparationDeploymentWritten | Should -Be 6
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Not -Match "doesn't have already"
    }

    It 'says how many the run''s limit left out once it is reached' {
        $script:PreparationDeploymentWritten = $script:PreparationDeploymentLimit
        Write-PreparationStoreItem @(New-StoreItem 'Microsoft.WindowsCalculator_8wekyb3d8bbwe' '9WZDNCRFHVN5' $script:InstallFailed) @{}
        @(Get-DeploymentLine).Count | Should -Be 0
        # The repeated 404 counts once.
        Get-Content (Join-Path $JobPath 'updates.log') -Raw |
            Should -Match "since this run started has 3 more event\(s\) 401 or 404, left out: updates\.log already has the $($script:PreparationDeploymentLimit) deployment events a run takes"
    }

    It 'cuts each event''s text at a length' {
        $long = "Deployment Stage operation with target volume C: on Package $script:Calculator from: (a15291e6f81eeb6b) failed with error 0x80070490. " + ('x' * 2000)
        $script:Events = @(New-DeploymentEvent 401 $long 1)
        Write-PreparationStoreItem @(New-StoreItem 'Microsoft.WindowsCalculator_8wekyb3d8bbwe' '9WZDNCRFHVN5' $script:InstallFailed) @{}
        $written = [regex]::Match(@(Get-DeploymentLine)[0], 'event 401 at \d{4}-\d\d-\d\d \d\d:\d\d:\d\d: (.*)$')
        $written.Success | Should -BeTrue
        $written.Groups[1].Value | Should -BeExactly ($long.Substring(0, $script:PreparationDeploymentLength) + '...')
    }

    It 'writes an event''s own values when Windows has no text for it' {
        $values = @('Windows cannot install package', $script:Calculator, -2147024784) | ForEach-Object { [pscustomobject]@{ Value = $_ } }
        $script:Events = @([pscustomobject]@{ Id = 404; TimeCreated = [DateTime]::Now; Message = $null; Properties = $values })
        Write-PreparationStoreItem @(New-StoreItem 'Microsoft.WindowsCalculator_8wekyb3d8bbwe' '9WZDNCRFHVN5' $script:InstallFailed) @{}
        @(Get-DeploymentLine)[0] | Should -Match "deployment of $([regex]::Escape($script:Calculator)), event 404 at .+: no text; values: Windows cannot install package; $([regex]::Escape($script:Calculator)); -2147024784$"
    }

    It 'never fails the run when the log can''t be read, and says so' {
        Mock Get-WinEvent { throw 'The RPC server is unavailable.' }
        { Write-PreparationStoreItem @(New-StoreItem 'Microsoft.WindowsCalculator_8wekyb3d8bbwe' '9WZDNCRFHVN5' $script:InstallFailed) @{} } | Should -Not -Throw
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match "since this run started couldn't be read: The RPC server is unavailable\."
    }

    It 'says when the log has nothing since the run started' {
        Mock Get-WinEvent {
            throw [Management.Automation.ErrorRecord]::new([Exception]::new('No events were found that match the specified selection criteria.'),
                'NoMatchingEventsFound,Microsoft.PowerShell.Commands.GetWinEventCommand', 'ObjectNotFound', $null)
        }
        Write-PreparationStoreItem @(New-StoreItem 'Microsoft.WindowsCalculator_8wekyb3d8bbwe' '9WZDNCRFHVN5' $script:InstallFailed) @{}
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match "since this run started has no event 401 or 404 that updates\.log doesn't have already"
    }

    It 'reads the log for each AppX deployment error: <Case>' -TestCases @(
        @{ Case = 'the first, 0x80073CF0'; Code = 0x80073CF0 }
        @{ Case = 'the last, 0x80073D53'; Code = 0x80073D53 }
    ) {
        Write-PreparationStoreItem @(New-StoreItem 'Microsoft.WindowsCalculator_8wekyb3d8bbwe' '9WZDNCRFHVN5' ([Runtime.InteropServices.COMException]::new('Deployment failed.', $Code))) @{}
        Should -Invoke Get-WinEvent -Times 1 -Exactly -ParameterFilter {
            $FilterHashtable[0].LogName -eq 'Microsoft-Windows-AppXDeploymentServer/Operational'
        }
    }

    It 'leaves the log alone for an error that isn''t a deployment error: <Case>' -TestCases @(
        @{ Case = 'the Store''s own'; Code = 0x803FB112 }
        @{ Case = 'just below the range, 0x80073CEF'; Code = 0x80073CEF }
        @{ Case = 'just above the range, 0x80073D54'; Code = 0x80073D54 }
        @{ Case = 'no code'; Code = $null }
    ) {
        $errorCode = if ($null -ne $Code) { [Runtime.InteropServices.COMException]::new('The Store failed.', $Code) }
        Write-PreparationStoreItem @(New-StoreItem 'Microsoft.WindowsCalculator_8wekyb3d8bbwe' '9WZDNCRFHVN5' $errorCode) @{}
        Should -Invoke Get-WinEvent -Times 0 -Exactly
    }
}

Describe 'Updates Windows can''t stage for built-in apps' {
    BeforeAll {
        $script:Calculator = 'Microsoft.WindowsCalculator_2021.2607.0.0_neutral_~_8wekyb3d8bbwe'
        $script:Music = 'Microsoft.ZuneMusic_11.2609.11.0_neutral_~_8wekyb3d8bbwe'
        $script:Photos = 'Microsoft.Windows.Photos_2026.11090.22001.0_neutral_~_8wekyb3d8bbwe'
        # Event 401 as Windows records it: DeploymentOperation, PackageFullName, Path, ErrorCode, then more.
        function New-StagingEvent([string]$Package, [int]$Operation = 4, $Code = -2147023728, [string]$Activity = [guid]::NewGuid().ToString(), [string]$Message) {
            $values = @($Operation, $Package, ' (x) ', $Code, 'C:') | ForEach-Object { [pscustomobject]@{ Value = $_ } }
            if (-not $Message) { $Message = "Deployment Stage operation with target volume C: on Package $Package from: (x) failed with error 0x80070490." }
            [pscustomobject]@{ Id = 401; TimeCreated = [DateTime]::Now; ActivityId = [guid]$Activity; Message = $Message; Properties = $values }
        }
        function New-Staging([string]$Package, [string]$Activity = '') {
            $name = ($Package -split '_')[0]
            [pscustomobject]@{ Name = $name; Family = "$($name)_8wekyb3d8bbwe"; Package = $Package; ActivityId = $Activity }
        }
        # 0x80073CF9, the install failed, as the Store reports a deployment that failed.
        $script:InstallFailed = [Runtime.InteropServices.COMException]::new('Install failed. Please contact your software vendor.', -2147009287)
        function Get-StagingLog { Get-Content (Join-Path $JobPath 'updates.log') -Raw }
    }
    BeforeEach {
        Remove-Item -LiteralPath (Join-Path $JobPath 'updates.log') -ErrorAction SilentlyContinue
        $script:PreparationStagingBootstrap = $null
        $script:PreparationStagingEvidenceWritten = $false
        $script:PreparationDeploymentSeen.Clear()
        $script:StagingRecordText = ''
        Mock Write-PreparationState {}
    }

    Context 'Reading them from the AppX deployment log' {
        It 'reads a Stage or an Add that failed with 0x80070490 from the event''s own values, in any language' {
            Get-PreparationStagingPackage (New-StagingEvent $script:Calculator 4) | Should -Be $script:Calculator
            Get-PreparationStagingPackage (New-StagingEvent $script:Calculator 1) | Should -Be $script:Calculator
            # The same code as an unsigned value.
            Get-PreparationStagingPackage (New-StagingEvent $script:Calculator 4 ([uint32]2147943568)) | Should -Be $script:Calculator
            # Simplified Chinese text, which keeps the operation's English name.
            $chinese = [regex]::Unescape('\u4ece (x) \u4f7f\u7528\u7a0b\u5e8f\u5305 {0} \u4e2d\u7684\u76ee\u6807\u5377 C: \u6267\u884c\u7684\u90e8\u7f72 Stage \u64cd\u4f5c\u5931\u8d25\uff0c\u9519\u8bef\u4e3a 0x80070490\u3002') -f $script:Calculator
            Get-PreparationStagingPackage (New-StagingEvent $script:Calculator 4 -Message $chinese) | Should -Be $script:Calculator
            Get-PreparationStagingPackage ([pscustomobject]@{ Id = 401; TimeCreated = [DateTime]::Now; Message = $chinese }) | Should -Be $script:Calculator
        }

        It 'leaves out a <Case>' -TestCases @(
            @{ Case = 'Register that failed with 0x80070490'; Operation = 6; Code = -2147023728 }
            @{ Case = 'Remove that failed with 0x80070490'; Operation = 2; Code = -2147023728 }
            @{ Case = 'Stage that failed with another error'; Operation = 4; Code = -2147009278 }
        ) {
            Get-PreparationStagingPackage (New-StagingEvent $script:Calculator $Operation $Code) | Should -BeExactly ''
        }

        It 'reads the text when Windows PowerShell has no values for the event' {
            $text = { param([string]$Message) [pscustomobject]@{ Id = 401; TimeCreated = [DateTime]::Now; Message = $Message } }
            Get-PreparationStagingPackage (& $text "Deployment Add operation with target volume C: on Package $script:Calculator from: (x) failed with error 0x80070490.") | Should -Be $script:Calculator
            Get-PreparationStagingPackage (& $text "Deployment Register operation with target volume C: on Package $script:Calculator from: (x) failed with error 0x80070490.") | Should -BeExactly ''
            Get-PreparationStagingPackage (& $text "Deployment Stage operation with target volume C: on Package $script:Calculator from: (x) failed with error 0x80073D02.") | Should -BeExactly ''
            Get-PreparationStagingPackage (& $text "The specified package full name $script:Calculator is not eligible for a StageUserDataAsync call. 0x80070490") | Should -BeExactly ''
        }

        It 'lists each app once, newest first, with its family and the deployment''s activity id' {
            $script:Newest = [guid]::NewGuid().ToString()
            Mock Get-WinEvent {
                New-StagingEvent $script:Music -Activity $script:Newest
                New-StagingEvent $script:Calculator
                New-StagingEvent $script:Music
                New-StagingEvent $script:Photos 6
            }
            $staging = @(Get-PreparationStagingFailure)
            $staging.Count | Should -Be 2
            $staging[0].Name | Should -Be 'Microsoft.ZuneMusic'
            $staging[0].Family | Should -Be 'Microsoft.ZuneMusic_8wekyb3d8bbwe'
            $staging[0].Package | Should -Be $script:Music
            $staging[0].ActivityId | Should -Be $script:Newest
            $staging[1].Name | Should -Be 'Microsoft.WindowsCalculator'
            Should -Invoke Get-WinEvent -Times 1 -Exactly -ParameterFilter {
                $FilterHashtable[0].LogName -eq 'Microsoft-Windows-AppXDeploymentServer/Operational' -and
                (@($FilterHashtable[0].Id) -join ',') -eq '401' -and $FilterHashtable[0].StartTime -eq $script:PreparationStartedAt
            }
        }

        It 'finds none in a log with nothing since the run started, and says so only when the log can''t be read' {
            Mock Get-WinEvent {
                throw [Management.Automation.ErrorRecord]::new([Exception]::new('No events were found that match the specified selection criteria.'),
                    'NoMatchingEventsFound,Microsoft.PowerShell.Commands.GetWinEventCommand', 'ObjectNotFound', $null)
            }
            @(Get-PreparationStagingFailure).Count | Should -Be 0
            Test-Path -LiteralPath (Join-Path $JobPath 'updates.log') | Should -BeFalse
            Mock Get-WinEvent { throw 'The RPC server is unavailable.' }
            @(Get-PreparationStagingFailure).Count | Should -Be 0
            Get-StagingLog | Should -Match "couldn't be read for staging failures: The RPC server is unavailable\."
        }

        It 'reads a deployment''s events through a query each AppX log filters itself' {
            $script:Activity = '162a6484-7af8-0002-6c48-2b16f87add01'
            Mock Get-WinEvent -ParameterFilter { $ListLog } {
                [pscustomobject]@{ LogName = 'Microsoft-Windows-AppXDeploymentServer/Operational'; IsEnabled = $true; LogType = 'Operational' }
                [pscustomobject]@{ LogName = 'Microsoft-Windows-AppxPackaging/Operational'; IsEnabled = $true; LogType = 'Operational' }
                [pscustomobject]@{ LogName = 'Microsoft-Windows-AppXDeploymentServer/Debug'; IsEnabled = $true; LogType = 'Debug' }
                [pscustomobject]@{ LogName = 'Microsoft-Windows-AppXDeployment/Operational'; IsEnabled = $false; LogType = 'Operational' }
            }
            Mock Get-WinEvent -ParameterFilter { $LogName -eq 'Microsoft-Windows-AppXDeploymentServer/Operational' } {
                [pscustomobject]@{ LogName = $LogName; Id = 404; TimeCreated = [DateTime]::Now; Message = 'second' }
            }
            Mock Get-WinEvent -ParameterFilter { $LogName -eq 'Microsoft-Windows-AppxPackaging/Operational' } {
                [pscustomobject]@{ LogName = $LogName; Id = 170; TimeCreated = [DateTime]::Now.AddSeconds(-5); Message = 'first' }
            }
            $events = @(Get-PreparationAppxActivityEvent $script:Activity)
            @($events | ForEach-Object Message) | Should -Be @('first', 'second')
            Should -Invoke Get-WinEvent -Times 2 -Exactly -ParameterFilter {
                $FilterXPath -eq "*[System[Correlation[@ActivityID='{162a6484-7af8-0002-6c48-2b16f87add01}']]]" -and $MaxEvents -eq $script:PreparationStagingActivityEvents
            }
            Should -Invoke Get-WinEvent -Times 0 -Exactly -ParameterFilter { $LogName -like '*Debug' -or $LogName -eq 'Microsoft-Windows-AppXDeployment/Operational' }
        }
    }

    Context 'A Store the repairs can''t mend' {
        BeforeEach {
            $script:PreparationStoreRepairsRun = $false
            $script:PreparationStoreOutcome = $null
            $script:Repairs = [Collections.Generic.List[string]]::new()
            $script:Staging = @((New-Staging $script:Music '11111111-1111-1111-1111-111111111111'), (New-Staging $script:Calculator '22222222-2222-2222-2222-222222222222'))
            $script:Failure = New-PreparationStoreFailure 'Microsoft.ZuneMusic_8wekyb3d8bbwe' 'Error' $script:InstallFailed
            Mock Assert-PreparationContinue {}
            Mock Write-PreparationStoreInventory {}
            Mock Test-PreparationStoreRemoved { $false }
            Mock Get-PreparationStoreVersion { '22610.1401.10.0' }
            Mock Register-PreparationStore { $true }
            Mock Update-PreparationStoreItself { $false }
            Mock Invoke-PreparationStoreWithRetry { throw $script:Failure }
            Mock Invoke-PreparationStoreRepair { $script:Repairs.Add($Repair); if ($Repair -eq 'storefixer') { 'skipped' } else { $true } }
            Mock Get-PreparationStagingFailure { $script:Staging }
            Mock Write-PreparationStagingEvidence {}
        }

        It 'names the apps after the repairs, leaves reinstalling Windows as the way on, and records the run' {
            try { Invoke-PreparationStoreStage } catch { $thrown = $_.Exception }
            @($script:Repairs) | Should -Be @('wsreset', 'bootstrap', 'storefixer')
            $detail = Get-PreparationFailureDetail $thrown
            $detail.reason | Should -Be 'store-appx-staging'
            $detail.errorCode | Should -Be '0x80070490'
            $detail.packageName | Should -Be 'ZuneMusic,WindowsCalculator'
            $detail.failureMessage | Should -Match 'Microsoft\.ZuneMusic, Microsoft\.WindowsCalculator'
            $detail.failureMessage | Should -Match "repairs didn't help \(wsreset didn't help; bootstrap didn't help; storefixer skipped\)"
            Should -Invoke Write-PreparationStagingEvidence -Times 1 -Exactly -ParameterFilter { ($Apps -join ',') -eq 'Microsoft.ZuneMusic,Microsoft.WindowsCalculator' }
            $record = $script:StagingRecordText | ConvertFrom-Json
            $record.repairs | Should -Be 1
            @($record.apps) | Should -Be @('Microsoft.ZuneMusic', 'Microsoft.WindowsCalculator')
        }

        It 'names the apps when the Store ends cancelling an item after Windows couldn''t stage updates' {
            $script:Failure = New-PreparationStoreFailure 'Microsoft.Windows.Photos_8wekyb3d8bbwe' 'Canceled' ([Runtime.InteropServices.COMException]::new('Operation aborted', -2147467260))
            try { Invoke-PreparationStoreStage } catch { $thrown = $_.Exception }
            $detail = Get-PreparationFailureDetail $thrown
            $detail.reason | Should -Be 'store-appx-staging'
            $detail.packageName | Should -Be 'ZuneMusic,WindowsCalculator'
        }

        It 'stays store-repair-failed for <Case>' -TestCases @(
            @{ Case = 'one app Windows couldn''t stage'; Staging = { @(New-Staging $script:Music) }; Failure = { $script:Failure } }
            @{ Case = 'none'; Staging = { @() }; Failure = { $script:Failure } }
            @{ Case = 'a Store that ends with another failure'; Staging = { $script:Staging }; Failure = { New-PreparationFailure 'Microsoft Store is not registered for this user.' 'store-missing' } }
            @{ Case = 'a Store that keeps cancelling an item in a run Windows staged everything in'; Staging = { @() }; Failure = { New-PreparationStoreFailure 'Microsoft.Windows.Photos_8wekyb3d8bbwe' 'Canceled' ([Runtime.InteropServices.COMException]::new('Operation aborted', -2147467260)) } }
        ) {
            $script:Staging = & $Staging
            $script:Failure = & $Failure
            try { Invoke-PreparationStoreStage } catch { $thrown = $_.Exception }
            (Get-PreparationFailureDetail $thrown).reason | Should -Be 'store-repair-failed'
            Should -Invoke Write-PreparationStagingEvidence -Times 0 -Exactly
            $script:StagingRecordText | Should -BeNullOrEmpty
        }

        It 'counts App Installer''s own bundle that the bootstrap couldn''t add' {
            $script:Staging = @()
            $script:Failure = New-PreparationFailure 'Microsoft Store is not registered for this user.' 'store-missing'
            Mock Invoke-PreparationStoreRepair {
                $script:Repairs.Add($Repair)
                if ($Repair -eq 'bootstrap') {
                    throw "Deployment failed with HRESULT: 0x80073CF9, Install failed.`r`n`r`nDeployment Add operation with target volume C: on Package Microsoft.DesktopAppInstaller_2026.917.151.0_neutral_~_8wekyb3d8bbwe from: (Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle) failed with error 0x80070490.`r`n`r`nNOTE: For additional information, look for [ActivityId] 162a6484-7af8-0000-3c60-2c16f87add01 in the Event Log or use the command line Get-AppPackageLog -ActivityID 162a6484-7af8-0000-3c60-2c16f87add01"
                }
                $false
            }
            try { Invoke-PreparationStoreStage } catch { $thrown = $_.Exception }
            $detail = Get-PreparationFailureDetail $thrown
            $detail.reason | Should -Be 'store-appx-staging'
            $detail.packageName | Should -Be 'DesktopAppInstaller'
            $script:PreparationStagingBootstrap | Should -Be '162a6484-7af8-0000-3c60-2c16f87add01'
        }

        It 'repairs once more in a run that tries again, and counts it' {
            $script:StagingRecordText = ConvertTo-Json -Compress -InputObject ([pscustomobject]@{ at = [DateTime]::UtcNow.AddDays(-1).ToString('o'); apps = @('Microsoft.ZuneMusic'); repairs = 1 })
            try { Invoke-PreparationStoreStage } catch { $thrown = $_.Exception }
            (Get-PreparationFailureDetail $thrown).reason | Should -Be 'store-appx-staging'
            @($script:Repairs) | Should -Be @('wsreset', 'bootstrap', 'storefixer')
            ($script:StagingRecordText | ConvertFrom-Json).repairs | Should -Be 2
        }

        It 'stops before the repairs once they''ve met the same apps in the runs they may take' {
            $script:StagingRecordText = ConvertTo-Json -Compress -InputObject ([pscustomobject]@{ at = [DateTime]::UtcNow.AddDays(-1).ToString('o'); apps = @('Microsoft.ZuneMusic', 'Microsoft.Xbox.TCUI'); repairs = 2 })
            try { Invoke-PreparationStoreStage } catch { $thrown = $_.Exception }
            $script:Repairs.Count | Should -Be 0
            $detail = Get-PreparationFailureDetail $thrown
            $detail.reason | Should -Be 'store-appx-staging'
            $detail.packageName | Should -Be 'ZuneMusic,WindowsCalculator'
            $detail.failureMessage | Should -Match "ran in 2 earlier runs without helping, so they didn't run again"
            Should -Invoke Write-PreparationStagingEvidence -Times 1 -Exactly
            $record = $script:StagingRecordText | ConvertFrom-Json
            $record.repairs | Should -Be 2
            @($record.apps) | Should -Contain 'Microsoft.WindowsCalculator'
            Get-StagingLog | Should -Match "Windows couldn't stage updates for Microsoft\.ZuneMusic, Microsoft\.WindowsCalculator again, as in 2 earlier runs whose repairs didn't help"
        }

        It 'repairs as usual when <Case>' -TestCases @(
            @{ Case = 'this run''s failure isn''t a staging failure of the recorded apps'; Apps = @('Microsoft.Xbox.TCUI'); Days = 1 }
            @{ Case = 'the record is more than 30 days old'; Apps = @('Microsoft.ZuneMusic'); Days = 31 }
        ) {
            $script:StagingRecordText = ConvertTo-Json -Compress -InputObject ([pscustomobject]@{ at = [DateTime]::UtcNow.AddDays(-$Days).ToString('o'); apps = $Apps; repairs = 2 })
            { Invoke-PreparationStoreStage } | Should -Throw
            @($script:Repairs) | Should -Be @('wsreset', 'bootstrap', 'storefixer')
            ($script:StagingRecordText | ConvertFrom-Json).repairs | Should -Be 1
        }

        It 'clears the record once the Store works, <Case>' -TestCases @(
            @{ Case = 'at once'; Works = { Mock Invoke-PreparationStoreWithRetry {} } }
            @{ Case = 'after a repair'; Works = { Mock Invoke-PreparationStoreWithRetry { if ($script:Repairs.Count -eq 0) { throw $script:Failure } } } }
        ) {
            & $Works
            $script:StagingRecordText = ConvertTo-Json -Compress -InputObject ([pscustomobject]@{ at = [DateTime]::UtcNow.ToString('o'); apps = @('Microsoft.ZuneMusic'); repairs = 2 })
            $script:Staging = @()
            Invoke-PreparationStoreStage
            $script:StagingRecordText | Should -BeNullOrEmpty
            Get-StagingLog | Should -Match 'the record of its AppX staging failures is cleared'
        }

        It 'writes nothing about a record a working Store never had' {
            Mock Invoke-PreparationStoreWithRetry {}
            Mock Set-PreparationStagingRecordText {}
            Invoke-PreparationStoreStage
            Should -Invoke Set-PreparationStagingRecordText -Times 0 -Exactly
        }
    }

    Context 'The evidence' {
        BeforeEach {
            $script:PreparationStagingSeconds = 90
            $script:Staging = @((New-Staging $script:Music '11111111-1111-1111-1111-111111111111'), (New-Staging $script:Calculator ''))
            Mock Get-PreparationAppxActivityEvent {
                [pscustomobject]@{ LogName = 'Microsoft-Windows-AppxPackaging/Operational'; Id = 157; TimeCreated = [DateTime]::Now; Message = 'Opening the package failed.' }
                [pscustomobject]@{ LogName = 'Microsoft-Windows-AppXDeploymentServer/Operational'; Id = 401; TimeCreated = [DateTime]::Now; Message = "Deployment Stage operation on Package $script:Music failed with error 0x80070490." }
            }
            $script:Seen = "AppX Deployment operation failed for package $script:Music with error 0x80073CF9."
            Mock Get-WinEvent {
                [pscustomobject]@{ Id = 404; TimeCreated = [DateTime]::Now; Message = $script:Seen }
                [pscustomobject]@{ Id = 465; TimeCreated = [DateTime]::Now; Message = 'Element not found while reading the package repository.' }
                [pscustomobject]@{ Id = 465; TimeCreated = [DateTime]::Now; Message = 'Element not found while reading the package repository.' }
            }
            Mock Get-AppxPackage {
                $users = @([pscustomobject]@{ UserSecurityId = [pscustomobject]@{ Sid = 'S-1-5-21-1-2-3-1001'; Username = 'DESKTOP-PC\Owner' }; InstallState = 'Installed' })
                [pscustomobject]@{ Name = $Name; PackageFamilyName = "$($Name)_8wekyb3d8bbwe"; PackageFullName = "$($Name)_11.2512.10.0_x64__8wekyb3d8bbwe"; Version = '11.2512.10.0'; Status = 'Ok'; PackageUserInformation = $users }
                [pscustomobject]@{ Name = $Name; PackageFamilyName = "$($Name)_othrpublisher1"; PackageFullName = "$($Name)_99.0.0.0_x64__othrpublisher1"; Version = '99.0.0.0'; Status = 'Ok'; PackageUserInformation = @() }
            }
            Mock Get-AppxProvisionedPackage { [pscustomobject]@{ DisplayName = 'Microsoft.ZuneMusic'; PackageName = 'Microsoft.ZuneMusic_11.2512.10.0_neutral_~_8wekyb3d8bbwe' } }
            Mock Get-PreparationAllUserStoreEntry {
                switch ($Place) {
                    'Applications' { [pscustomobject]@{ Key = 'Microsoft.ZuneMusic_11.2512.10.0_neutral_~_8wekyb3d8bbwe'; Path = (Join-Path $TestDrive 'missing\AppxBundleManifest.xml') } }
                    'InboxApplications' { [pscustomobject]@{ Key = 'Microsoft.ZuneMusicPlus_1.0.0.0_x64__8wekyb3d8bbwe'; Path = '' } }
                    'Deprovisioned' { [pscustomobject]@{ Key = 'Microsoft.WindowsCalculator_8wekyb3d8bbwe'; Path = '' } }
                }
            }
            Mock Test-PreparationAppRepositoryManifest { $PackageFullName -like 'Microsoft.ZuneMusic_*' }
            $script:PreparationDeploymentSeen.Clear()
            [void]$script:PreparationDeploymentSeen.Add("404 $script:Seen")
        }

        It 'reads each failing deployment, the run''s errors and warnings, and what Windows records of each app' {
            Write-PreparationStagingEvidence @('Microsoft.ZuneMusic', 'Microsoft.WindowsCalculator') $script:Staging
            $log = Get-StagingLog
            Should -Invoke Get-PreparationAppxActivityEvent -Times 1 -Exactly -ParameterFilter { $ActivityId -eq '11111111-1111-1111-1111-111111111111' }
            $log | Should -Match "staging evidence: deployment 11111111-1111-1111-1111-111111111111 \($([regex]::Escape($script:Music))\): 2 event\(s\)"
            $log | Should -Match 'staging evidence: deployment 11111111-1111-1111-1111-111111111111: Microsoft-Windows-AppxPackaging/Operational event 157 at .+: Opening the package failed\.'
            Should -Invoke Get-WinEvent -Times 1 -Exactly -ParameterFilter {
                $FilterHashtable[0].LogName -eq 'Microsoft-Windows-AppXDeploymentServer/Operational' -and (@($FilterHashtable[0].Level) -join ',') -eq '1,2,3' -and
                $FilterHashtable[0].StartTime -eq $script:PreparationStartedAt
            }
            # Each text once, and none updates.log has already.
            $log | Should -Match "errors and warnings since this run started that updates\.log doesn't have already: 1"
            ([regex]::Matches($log, 'Element not found while reading the package repository')).Count | Should -Be 1
            $log | Should -Not -Match 'event 404 at'
            $log | Should -Match 'staging evidence: Microsoft\.ZuneMusic: package Microsoft\.ZuneMusic_11\.2512\.10\.0_x64__8wekyb3d8bbwe, Ok \(S-1-5-21-1-2-3-1001: Installed\); AppRepository\\Microsoft\.ZuneMusic_11\.2512\.10\.0_x64__8wekyb3d8bbwe\.xml present'
            $log | Should -Match 'staging evidence: Microsoft\.WindowsCalculator: package Microsoft\.WindowsCalculator_11\.2512\.10\.0_x64__8wekyb3d8bbwe, Ok .+\.xml missing'
            $log | Should -Not -Match 'othrpublisher1' -Because 'a package of that name from another publisher is another app'
            $log | Should -Not -Match 'Owner' -Because 'account names would reach reports'
            $log | Should -Match 'staging evidence: Microsoft\.ZuneMusic: provisioned Microsoft\.ZuneMusic_11\.2512\.10\.0_neutral_~_8wekyb3d8bbwe'
            $log | Should -Match 'staging evidence: Microsoft\.WindowsCalculator: not provisioned'
            $log | Should -Match 'staging evidence: Microsoft\.ZuneMusic: AppxAllUserStore\\Applications\\Microsoft\.ZuneMusic_11\.2512\.10\.0_neutral_~_8wekyb3d8bbwe, .+AppxBundleManifest\.xml missing'
            $log | Should -Not -Match 'ZuneMusicPlus'
            $log | Should -Match 'staging evidence: Microsoft\.WindowsCalculator: AppxAllUserStore\\Deprovisioned\\Microsoft\.WindowsCalculator_8wekyb3d8bbwe'
        }

        It 'says when the AppX store''s registry has nothing of an app' {
            Mock Get-PreparationAllUserStoreEntry {}
            Write-PreparationStagingEvidence @('Microsoft.ZuneMusic') $script:Staging
            Get-StagingLog | Should -Match 'staging evidence: Microsoft\.ZuneMusic: no entry in AppxAllUserStore\\Applications, InboxApplications, Deprovisioned'
        }

        It 'reads the deployment the bootstrap''s App Installer bundle failed in' {
            $script:PreparationStagingBootstrap = '162a6484-7af8-0000-3c60-2c16f87add01'
            Write-PreparationStagingEvidence @('Microsoft.DesktopAppInstaller') @()
            Should -Invoke Get-PreparationAppxActivityEvent -Times 1 -Exactly -ParameterFilter { $ActivityId -eq '162a6484-7af8-0000-3c60-2c16f87add01' }
            Should -Invoke Get-AppxPackage -Times 1 -Exactly -ParameterFilter { $AllUsers -and $Name -eq 'Microsoft.DesktopAppInstaller' }
            Get-StagingLog | Should -Match 'Microsoft\.DesktopAppInstaller: package Microsoft\.DesktopAppInstaller_11\.2512\.10\.0_x64__8wekyb3d8bbwe'
        }

        It 'reads it once a run' {
            Write-PreparationStagingEvidence @('Microsoft.ZuneMusic') $script:Staging
            Write-PreparationStagingEvidence @('Microsoft.ZuneMusic') $script:Staging
            Should -Invoke Get-AppxPackage -Times 1 -Exactly
        }

        It 'takes so many apps, events and entries, and cuts each line at a length' {
            $script:Staging = @(1..10 | ForEach-Object { New-Staging "Microsoft.App$($_)_1.0.0.0_x64__8wekyb3d8bbwe" ([guid]::NewGuid().ToString()) })
            Mock Get-PreparationAppxActivityEvent { [pscustomobject]@{ LogName = 'Microsoft-Windows-AppxPackaging/Operational'; Id = 157; TimeCreated = [DateTime]::Now; Message = 'x' * 2000 } }
            Mock Get-WinEvent { 1..50 | ForEach-Object { [pscustomobject]@{ Id = 465; TimeCreated = [DateTime]::Now; Message = "warning $_" } } }
            Write-PreparationStagingEvidence @($script:Staging | ForEach-Object Name) $script:Staging
            Should -Invoke Get-PreparationAppxActivityEvent -Times $script:PreparationStagingApps -Exactly
            Should -Invoke Get-AppxPackage -Times $script:PreparationStagingApps -Exactly
            $lines = @(Get-Content (Join-Path $JobPath 'updates.log'))
            @($lines | Where-Object { $_ -match ': event 465 at ' }).Count | Should -Be $script:PreparationStagingRunEvents
            # Newest first, as Get-WinEvent returns them: the newest are kept, and written oldest first.
            @($lines | Where-Object { $_ -match 'warning (1|30)$' }).Count | Should -Be 2
            $lines | Where-Object { $_ -match 'warning 31$' } | Should -BeNullOrEmpty
            [array]::IndexOf($lines, @($lines -match 'warning 30$')[0]) | Should -BeLessThan ([array]::IndexOf($lines, @($lines -match 'warning 1$')[0]))
            foreach ($line in $lines) { $line.Length | Should -BeLessOrEqual ('Microsoft Store: staging evidence: '.Length + $script:PreparationStagingLength + 3) }
        }

        It 'stops reading once it has taken its time, and says so' {
            $script:PreparationStagingSeconds = 0
            try { Write-PreparationStagingEvidence @('Microsoft.ZuneMusic') $script:Staging }
            finally { $script:PreparationStagingSeconds = 90 }
            Should -Invoke Get-PreparationAppxActivityEvent -Times 0 -Exactly
            Should -Invoke Get-AppxPackage -Times 0 -Exactly
            Get-StagingLog | Should -Match 'staging evidence: stopped after 0 seconds; the rest is left out'
        }

        It 'notes a part that fails and goes on with the rest' {
            Mock Get-PreparationAppxActivityEvent { throw 'The event log service is unavailable.' }
            Mock Get-WinEvent { throw 'The RPC server is unavailable.' }
            Mock Get-AppxProvisionedPackage { throw 'Elevation is required.' }
            Mock Get-AppxPackage { throw 'Access is denied.' }
            Mock Get-PreparationAllUserStoreEntry { throw 'Requested registry access is not allowed.' }
            { Write-PreparationStagingEvidence @('Microsoft.ZuneMusic') $script:Staging } | Should -Not -Throw
            $log = Get-StagingLog
            $log | Should -Match "deployment 11111111-1111-1111-1111-111111111111 couldn't be read: The event log service is unavailable\."
            $log | Should -Match "the AppX deployment log couldn't be read: The RPC server is unavailable\."
            $log | Should -Match "the provisioned packages couldn't be listed: Elevation is required\."
            $log | Should -Match "Microsoft\.ZuneMusic: its packages couldn't be listed: Access is denied\."
            $log | Should -Match "AppxAllUserStore\\Applications couldn't be read: Requested registry access is not allowed\."
        }
    }
}

Describe 'A Store call that fails' {
    It 'ends with the Store''s own error and code, not the task''s wrapper' {
        Mock Write-PreparationState {}
        # 0x803FB112: a Store that can't update itself.
        $cause = [Runtime.InteropServices.COMException]::new('The Store needs an update it cannot install.', 0x803FB112)
        $failure = $null
        try { Wait-PreparationStoreTask ([Threading.Tasks.Task]::FromException($cause)) }
        catch { $failure = $_.Exception }

        $failure | Should -BeOfType ([Runtime.InteropServices.COMException])
        $detail = Get-PreparationFailureDetail $failure
        $detail.failureMessage | Should -BeExactly 'The Store needs an update it cannot install.'
        $detail.errorCode | Should -BeExactly '0x803FB112'
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
        # The offered update, of $Type, fails with ERROR_NO_MORE_ITEMS (0x80070103)
        # every time, and Windows Update offers it until something records it.
        function Set-NoMoreItemsFailure([int]$Type) {
            $script:offered | Add-Member NoteProperty Type $Type
            $script:record = @()
            Mock Read-PreparationReoffered { $script:record }
            Mock Write-PreparationReoffered { $script:record = @($Entries) }
            Mock Find-PreparationWindowsUpdate { if (@($script:record).Count -eq 0) { $script:offered } }
            $script:installation.RebootRequired = $false
            $script:installation.ResultCode = 4
            $script:installation | Add-Member ScriptMethod GetUpdateResult { [pscustomobject]@{ResultCode=4; HResult=-2147024637} } -Force
        }
    }
    BeforeEach {
        Mock Assert-PreparationContinue {}
        Mock Test-PreparationRestart { $false }
        Mock Test-PreparationNetwork { $true }
        Mock Write-PreparationState {}
        Mock Get-PreparationWindowsVersion { [pscustomobject]@{ Build = 26200; Ubr = 9168; DisplayVersion = '25H2'; EditionId = 'Professional' } }
        Mock Get-PreparationBootId { 'boot:1' }
        Remove-Item -LiteralPath (Join-Path $JobPath 'updates.log') -ErrorAction SilentlyContinue
        $script:PreparationBusyWaited = 0
        $script:PreparationOptionalFailed = @{}
        $script:RestartRecordText = ''
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
        $script:installation | Add-Member ScriptMethod GetUpdateResult { [pscustomobject]@{ResultCode=4; HResult=-2147023293} } -Force
        try { Invoke-PreparationWindows } catch { $thrown = $_.Exception }
        $thrown.Message | Should -BeLike '*could not install every update*'
        (Get-PreparationFailureDetail $thrown).errorCode | Should -Be '0x80070643'
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
    It 'counts a driver as done when the device already has one at least as good, and records it for the checks after' {
        Set-NoMoreItemsFailure 2
        Invoke-PreparationWindows | Should -Be 'complete'
        Should -Invoke Invoke-PreparationWindowsOperation -Times 1 -Exactly -ParameterFilter { $Kind -eq 'Install' }
        @($script:record.key) | Should -Be @('Fixture update id/0')
        $log = Get-Content (Join-Path $JobPath 'updates.log') -Raw
        $log | Should -Match "driver not needed, not installed again: 'Fixture update'"
        $log | Should -Not -Match 'Retrying'
    }
    It 'still counts the driver as done when the record can''t be written' {
        Set-NoMoreItemsFailure 2
        Mock Write-PreparationReoffered { throw 'Access is denied' }
        Invoke-PreparationWindows | Should -Be 'complete'
        Should -Invoke Invoke-PreparationWindowsOperation -Times 1 -Exactly -ParameterFilter { $Kind -eq 'Install' }
        $script:record | Should -BeNullOrEmpty
        $log = Get-Content (Join-Path $JobPath 'updates.log') -Raw
        $log | Should -Match 'The update could not be recorded: Access is denied'
        $log | Should -Not -Match 'Retrying'
    }
    It 'still retries and reports a software update that fails the same way' {
        Set-NoMoreItemsFailure 1
        try { Invoke-PreparationWindows } catch { $thrown = $_.Exception }
        (Get-PreparationFailureDetail $thrown).errorCode | Should -Be '0x80070103'
        Should -Invoke Invoke-PreparationWindowsOperation -Times 2 -Exactly -ParameterFilter { $Kind -eq 'Install' }
        $script:record | Should -BeNullOrEmpty
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
    It 'waits for another installation, then installs the update that met it' {
        $script:busy = [pscustomobject]@{ResultCode=4; RebootRequired=$false; HResult=0}
        $script:busy | Add-Member ScriptMethod GetUpdateResult { [pscustomobject]@{ResultCode=4; HResult=-2145124330} }
        $script:succeeded = [pscustomobject]@{ResultCode=2; RebootRequired=$false; HResult=0}
        $script:succeeded | Add-Member ScriptMethod GetUpdateResult { [pscustomobject]@{ResultCode=2; HResult=0} }
        $script:installs = 0
        Mock Invoke-PreparationWindowsOperation {
            if ($Kind -eq 'Download') { return $script:download }
            $script:installs++
            if ($script:installs -le 3) { return $script:busy }
            return $script:succeeded
        }
        $script:searches = 0
        Mock Find-PreparationWindowsUpdate { $script:searches++; if ($script:searches -le 4) { $script:offered } }
        Mock Start-Sleep {}
        Mock Test-PreparationInstallerBusy { $false }
        Invoke-PreparationWindows | Should -Be 'complete'
        $script:installs | Should -Be 4
        # Each wait lasts at least 30 seconds, in steps of two.
        Should -Invoke Start-Sleep -Times 45 -Exactly
        @(Select-String -LiteralPath (Join-Path $JobPath 'updates.log') -Pattern 'busy with another installation \(0x80240016\)').Count | Should -Be 3
    }
    It 'reports another installation''s refusal with its code once waiting for it hasn''t helped' {
        $script:installation.RebootRequired = $false
        $script:installation | Add-Member ScriptMethod GetUpdateResult { [pscustomobject]@{ResultCode=4; HResult=-2145124330} } -Force
        Mock Start-Sleep {}
        Mock Test-PreparationInstallerBusy { $false }
        try { Invoke-PreparationWindows } catch { $thrown = $_.Exception }
        (Get-PreparationFailureDetail $thrown).errorCode | Should -Be '0x80240016'
        Should -Invoke Invoke-PreparationWindowsOperation -Times 4 -Exactly -ParameterFilter { $Kind -eq 'Install' }
    }
    It 'waits at least 30 seconds and at most 10 minutes for another installation, and only so often in a run' {
        Mock Start-Sleep {}
        Mock Test-PreparationInstallerBusy { $true }
        Wait-PreparationInstallerIdle windows-install | Should -BeTrue
        Should -Invoke Start-Sleep -Times 300 -Exactly
        Wait-PreparationInstallerIdle windows-install | Should -BeTrue
        Wait-PreparationInstallerIdle windows-install | Should -BeTrue
        Wait-PreparationInstallerIdle windows-install | Should -BeFalse
        Should -Invoke Start-Sleep -Times 900 -Exactly
    }
    It 'reports the code Windows Update''s history gives an update whose result names none' {
        $script:installation.RebootRequired = $false
        $script:installation | Add-Member ScriptMethod GetUpdateResult { [pscustomobject]@{ResultCode=4; HResult=0} } -Force
        Mock Get-PreparationHistoryCode { -2146498270 }
        try { Invoke-PreparationWindows } catch { $thrown = $_.Exception }
        (Get-PreparationFailureDetail $thrown).errorCode | Should -Be '0x800F0922'
        Should -Invoke Get-PreparationHistoryCode -ParameterFilter { $UpdateId -eq 'Fixture update id' }
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'Fixture update: result=4, HRESULT=0, update history: 0x800F0922'
    }
    It 'installs the monthly update instead when the optional prerequisite that replaced it fails' {
        $preview = New-FixtureUpdate '2026-11 Preview Update (KB5132057) (26200.10075)'
        $monthly = New-FixtureUpdate '2026-11 Security Update (KB5132061) (26200.9974)'
        # As the real search does, an optional update that failed in this run isn't offered again.
        Mock Find-PreparationPrerequisiteUpdate { if (-not $script:PreparationOptionalFailed.ContainsKey((Get-PreparationUpdateKey $preview))) { $preview } }
        $script:searches = 0
        Mock Find-PreparationWindowsUpdate { $script:searches++; if ($script:searches -le 2) { $monthly } }
        $script:failedPreview = [pscustomobject]@{ResultCode=4; RebootRequired=$false; HResult=0}
        $script:failedPreview | Add-Member ScriptMethod GetUpdateResult { [pscustomobject]@{ResultCode=4; HResult=-2146498157} }
        $script:installedMonthly = [pscustomobject]@{ResultCode=2; RebootRequired=$false; HResult=0}
        $script:installedMonthly | Add-Member ScriptMethod GetUpdateResult { [pscustomobject]@{ResultCode=2; HResult=0} }
        Mock Invoke-PreparationWindowsOperation {
            if ($Kind -eq 'Download') { return $script:download }
            if ($Updates.Item(0).Title -like '*Preview*') { return $script:failedPreview }
            return $script:installedMonthly
        }
        Invoke-PreparationWindows | Should -Be 'complete'
        @($script:collections | Where-Object { $_.Count -gt 0 } | ForEach-Object { $_.Queued[0].Title }) | Should -Be @($preview.Title, $monthly.Title)
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match "Optional update '2026-11 Preview Update \(KB5132057\) \(26200\.10075\)' failed \(0x800F0993\); installing the monthly update it replaced instead"
    }
    It 'records what a restart is for' {
        $script:installation | Add-Member ScriptMethod GetUpdateResult { [pscustomobject]@{ResultCode=2; HResult=0; RebootRequired=$true} } -Force
        Invoke-PreparationWindows | Should -Be 'reboot'
        $record = $script:RestartRecordText | ConvertFrom-Json
        $record.boot | Should -BeExactly 'boot:1'
        @($record.updates.key) | Should -Be @('Fixture update id/0')
    }
    It 'stops instead of restarting again when an update Windows restarted for <Case>' -TestCases @(
        @{ Case = 'asks for another restart'; Code = 2; HResult = 0 }
        @{ Case = 'fails again'; Code = 4; HResult = -2147023293 }
    ) {
        param($Case, $Code, $HResult)
        $script:RestartRecordText = ConvertTo-Json -Compress -Depth 4 -InputObject @{
            boot = 'boot:1'; at = [DateTime]::UtcNow.ToString('o'); updates = @(@{ key = 'Fixture update id/0'; title = 'Fixture update' }) }
        Mock Get-PreparationBootId { 'boot:2' }
        $script:fixtureResult = [pscustomobject]@{ ResultCode = $Code; HResult = $HResult; RebootRequired = $true }
        $script:installation | Add-Member ScriptMethod GetUpdateResult { $script:fixtureResult } -Force
        try { Invoke-PreparationWindows } catch { $thrown = $_.Exception }
        $detail = Get-PreparationFailureDetail $thrown
        $detail.reason | Should -Be 'manual-updates' -Because $Case
        $detail.failureMessage | Should -Match 'even after restarting.*Fixture update'
        $script:RestartRecordText | Should -BeNullOrEmpty
    }
    It 'reports the update instead of restarting when updating ends with Windows wanting a restart' {
        $script:RestartRecordText = ConvertTo-Json -Compress -Depth 4 -InputObject @{
            boot = 'boot:1'; at = [DateTime]::UtcNow.ToString('o'); updates = @(@{ key = 'Fixture update id/0'; title = 'Fixture update' }) }
        Mock Get-PreparationBootId { 'boot:2' }
        $script:restartChecks = 0
        Mock Test-PreparationRestart { $script:restartChecks++; $script:restartChecks -gt 1 }
        Mock Invoke-PreparationStoreStage {}
        { Invoke-PreparationUpdates } | Should -Throw '*even after restarting*'
    }
    It 'restarts as usual <Case>' -TestCases @(
        @{ Case = 'for an update the last restart wasn''t for'; Boot = 'boot:2'; Key = 'Another update id/0'; Days = 0 }
        @{ Case = 'while Windows hasn''t restarted since'; Boot = 'boot:1'; Key = 'Fixture update id/0'; Days = 0 }
        @{ Case = 'once the record is more than a day old'; Boot = 'boot:2'; Key = 'Fixture update id/0'; Days = -2 }
    ) {
        $script:RestartRecordText = ConvertTo-Json -Compress -Depth 4 -InputObject @{
            boot = 'boot:1'; at = [DateTime]::UtcNow.AddDays($Days).ToString('o'); updates = @(@{ key = $Key; title = 'An update' }) }
        Mock Get-PreparationBootId { $Boot }
        Invoke-PreparationWindows | Should -Be 'reboot' -Because $Case
    }
    It 'gives an update Windows restarted for <Case> first, and installs it' -TestCases @(
        @{ Case = 'the wait for another installation'; HResult = -2145124330 }
        @{ Case = 'the store repair'; HResult = -2147010798 }
    ) {
        $script:RestartRecordText = ConvertTo-Json -Compress -Depth 4 -InputObject @{
            boot = 'boot:1'; at = [DateTime]::UtcNow.ToString('o'); updates = @(@{ key = 'Fixture update id/0'; title = 'Fixture update' }) }
        Mock Get-PreparationBootId { 'boot:2' }
        $script:met = [pscustomobject]@{ ResultCode = 4; RebootRequired = $false; HResult = 0; Code = $HResult }
        $script:met | Add-Member ScriptMethod GetUpdateResult { [pscustomobject]@{ ResultCode = 4; HResult = $this.Code } }
        $script:done = [pscustomobject]@{ ResultCode = 2; RebootRequired = $false; HResult = 0 }
        $script:done | Add-Member ScriptMethod GetUpdateResult { [pscustomobject]@{ ResultCode = 2; HResult = 0 } }
        $script:installs = 0
        Mock Invoke-PreparationWindowsOperation {
            if ($Kind -eq 'Download') { return $script:download }
            $script:installs++
            if ($script:installs -eq 1) { return $script:met }
            return $script:done
        }
        $script:searches = 0
        Mock Find-PreparationWindowsUpdate { $script:searches++; if ($script:searches -le 2) { $script:offered } }
        Mock Wait-PreparationInstallerIdle { $true }
        Mock Invoke-PreparationComponentRepair { $true }
        Invoke-PreparationWindows | Should -Be 'complete' -Because $Case
        $script:installs | Should -Be 2
    }
    It 'still stops when an update Windows restarted for meets another installation and asks for yet another restart' {
        $script:RestartRecordText = ConvertTo-Json -Compress -Depth 4 -InputObject @{
            boot = 'boot:1'; at = [DateTime]::UtcNow.ToString('o'); updates = @(@{ key = 'Fixture update id/0'; title = 'Fixture update' }) }
        Mock Get-PreparationBootId { 'boot:2' }
        $script:installation | Add-Member ScriptMethod GetUpdateResult { [pscustomobject]@{ ResultCode = 4; HResult = -2145124330 } } -Force
        Mock Wait-PreparationInstallerIdle { $true }
        try { Invoke-PreparationWindows } catch { $thrown = $_.Exception }
        (Get-PreparationFailureDetail $thrown).reason | Should -Be 'manual-updates'
        $thrown.Data['restartRepeated'] | Should -BeTrue
        Should -Invoke Wait-PreparationInstallerIdle -Times 0 -Exactly
    }
    It 'gives an optional prerequisite <Case> before leaving it for the monthly update' -TestCases @(
        @{ Case = 'the wait for another installation'; HResult = -2145124330 }
        @{ Case = 'the store repair'; HResult = -2147010798 }
    ) {
        $preview = New-FixtureUpdate '2026-11 Preview Update (KB5132057) (26200.10075)'
        $monthly = New-FixtureUpdate '2026-11 Security Update (KB5132061) (26200.9974)'
        $script:previewInstalls = 0
        Mock Find-PreparationPrerequisiteUpdate {
            if ($script:previewInstalls -lt 2 -and -not $script:PreparationOptionalFailed.ContainsKey((Get-PreparationUpdateKey $preview))) { $preview }
        }
        $script:searches = 0
        Mock Find-PreparationWindowsUpdate { $script:searches++; if ($script:searches -le 2) { $monthly } }
        $script:met = [pscustomobject]@{ ResultCode = 4; RebootRequired = $false; HResult = 0; Code = $HResult }
        $script:met | Add-Member ScriptMethod GetUpdateResult { [pscustomobject]@{ ResultCode = 4; HResult = $this.Code } }
        $script:done = [pscustomobject]@{ ResultCode = 2; RebootRequired = $false; HResult = 0 }
        $script:done | Add-Member ScriptMethod GetUpdateResult { [pscustomobject]@{ ResultCode = 2; HResult = 0 } }
        Mock Invoke-PreparationWindowsOperation {
            if ($Kind -eq 'Download') { return $script:download }
            if ($Updates.Item(0).Title -like '*Preview*') {
                $script:previewInstalls++
                if ($script:previewInstalls -eq 1) { return $script:met }
            }
            return $script:done
        }
        Mock Wait-PreparationInstallerIdle { $true }
        Mock Invoke-PreparationComponentRepair { $script:PreparationComponentRepairRun = $true; $true }
        $script:PreparationComponentRepairRun = $false
        Invoke-PreparationWindows | Should -Be 'complete' -Because $Case
        $script:previewInstalls | Should -Be 2
        $script:PreparationOptionalFailed.Count | Should -Be 0
    }
}

Describe 'A component store repair ahead of a move' {
    BeforeEach {
        $script:PreparationComponentRepairRun = $false
        Mock Write-PreparationState {}
        Mock Write-PreparationComponentEvidence {}
        Mock Get-PreparationComponentHealth { 'Repairable' }
    }

    It 'leaves the run its repair when it <Case>' -TestCases @(
        @{ Case = 'finds no source (0x800F081F)'; Restore = { -2146498529 } }
        @{ Case = 'can''t download its files (0x800F0906)'; Restore = { -2146498298 } }
        @{ Case = 'can''t run'; Restore = { throw 'DISM is unavailable' } }
    ) {
        $script:restore = $Restore
        Mock Invoke-PreparationRestoreHealth { & $script:restore }
        Invoke-PreparationComponentRepair 'damage before a move' -Ahead | Should -BeTrue
        $script:PreparationComponentRepairRun | Should -BeFalse -Because $Case
        Invoke-PreparationComponentRepair '1 update(s) failed on it (0x80073712)' | Should -BeTrue
        Invoke-PreparationComponentRepair 'another update failed on it' | Should -BeFalse
        Should -Invoke Invoke-PreparationRestoreHealth -Times 2 -Exactly
    }

    It 'uses up the run''s repair when it <Case>' -TestCases @(
        @{ Case = 'succeeds'; Code = 0; Ahead = $true }
        @{ Case = 'succeeds with a restart to finish it'; Code = 3010; Ahead = $true }
        @{ Case = 'is the one for an update that failed, and fails too'; Code = -2146498529; Ahead = $false }
    ) {
        $script:code = $Code
        Mock Invoke-PreparationRestoreHealth { $script:code }
        Invoke-PreparationComponentRepair 'the store' -Ahead:$Ahead | Should -BeTrue
        $script:PreparationComponentRepairRun | Should -BeTrue -Because $Case
        Invoke-PreparationComponentRepair 'again' | Should -BeFalse
    }
}

Describe 'A damaged component store' {
    BeforeAll {
        # An install whose one update ended with $HResult; 0 is success.
        function New-InstallResult([int]$HResult) {
            $code = if ($HResult -eq 0) { 2 } else { 4 }
            $result = [pscustomobject]@{ ResultCode = $code; RebootRequired = $false; HResult = 0; Update = [pscustomobject]@{ ResultCode = $code; HResult = $HResult } }
            $result | Add-Member ScriptMethod GetUpdateResult { $this.Update }
            $result
        }
    }
    BeforeEach {
        $script:PreparationComponentChecked = $false
        $script:PreparationComponentRepairRun = $false
        $script:ComponentHealth = 'Healthy'
        $script:Restart = $false
        # What the run did, in order, and the installs still to come.
        $script:Steps = [Collections.Generic.List[string]]::new()
        $script:Installs = [Collections.Generic.Queue[object]]::new()
        Remove-Item -LiteralPath (Join-Path $JobPath 'updates.log') -ErrorAction SilentlyContinue
        Mock Assert-PreparationContinue {}
        Mock Test-PreparationRestart { $script:Restart }
        Mock Test-PreparationNetwork { $true }
        Mock Write-PreparationState { if ($Stage -eq 'windows-repair') { $script:Steps.Add('repair stage') } }
        Mock Get-AtlasInstalledAtlasPackage { @() }
        Mock Invoke-PreparationRestoreHealth { $script:Steps.Add('repair'); $script:ComponentHealth = 'Healthy'; 0 }
        Mock Find-PreparationWindowsUpdate {
            $script:Steps.Add('search')
            if ($script:Installs.Count -gt 0) {
                [pscustomobject]@{
                    Title = 'Fixture update'; EulaAccepted = $true; Identity = [pscustomobject]@{ UpdateID = 'fixture' }
                    InstallationBehavior = [pscustomobject]@{ CanRequestUserInput = $false; Impact = 0 }
                }
            }
        }
        Mock Invoke-PreparationWindowsOperation {
            if ($Kind -eq 'Download') { return [pscustomobject]@{ ResultCode = 2; HResult = 0 } }
            $script:Steps.Add('install')
            $script:Installs.Dequeue()
        }
        $script:RepairInstaller = [pscustomobject]@{ Updates = $null; ForceQuiet = $false; AllowSourcePrompts = $true; RebootRequiredBeforeInstallation = $false }
        $script:RepairSession = [pscustomobject]@{ ClientApplicationID = '' }
        $script:RepairSession | Add-Member ScriptMethod CreateUpdateInstaller { $script:RepairInstaller }
        $script:RepairSession | Add-Member ScriptMethod CreateUpdateDownloader { [pscustomobject]@{ Updates = $null } }
        Mock New-Object {
            if ($ComObject -eq 'Microsoft.Update.Session') { return $script:RepairSession }
            if ($ComObject -eq 'Microsoft.Update.UpdateColl') {
                $collection = [pscustomobject]@{ Count = 0; Queued = [Collections.ArrayList]::new() }
                $collection | Add-Member ScriptMethod Add { param($Update); [void]$this.Queued.Add($Update); $this.Count++ }
                $collection | Add-Member ScriptMethod Item { param($Index); $this.Queued[$Index] }
                return $collection
            }
            throw 'Unexpected provider'
        }
    }
    It 'repairs damage Windows records before the first search, once a run' {
        $script:ComponentHealth = 'Repairable'
        Invoke-PreparationWindows | Should -Be 'complete'
        Invoke-PreparationWindows | Should -Be 'complete'
        @($script:Steps) | Should -Be @('repair stage', 'repair', 'search', 'search')
        $log = Get-Content (Join-Path $JobPath 'updates.log') -Raw
        $log | Should -Match 'Component store: Windows records damage to it; repairing it with DISM RestoreHealth'
        $log | Should -Match 'Component store: the repair ended with 0x00000000; Windows now records it as Healthy'
    }
    It 'leaves a store alone that Windows records as <Health>' -TestCases @(
        @{ Health = 'Healthy'; Logged = '^$' }
        @{ Health = 'Throws'; Logged = 'its health could not be read \(0x[0-9A-F]{8}\): DISM is unavailable' }
    ) {
        param($Health, $Logged)
        $script:ComponentHealth = $Health
        Invoke-PreparationWindows | Should -Be 'complete'
        Should -Invoke Invoke-PreparationRestoreHealth -Times 0 -Exactly
        [string](Get-Content (Join-Path $JobPath 'updates.log') -Raw -ErrorAction SilentlyContinue) | Should -Match $Logged
    }
    It 'leaves a repairable store alone on a PC with Atlas packages, which keep it reading so' {
        $script:ComponentHealth = 'Repairable'
        Mock Get-AtlasInstalledAtlasPackage { 'Z-Atlas-NoTelemetry-Package~31bf3856ad364e35~amd64~~5.0.0.0' }
        Invoke-PreparationWindows | Should -Be 'complete'
        Should -Invoke Invoke-PreparationRestoreHealth -Times 0 -Exactly
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'repairable, with Atlas packages installed \(Z-Atlas-NoTelemetry-Package[^)]*\); left as it is'
    }
    It 'stops before any search when Windows records damage it can''t repair' {
        $script:ComponentHealth = 'NonRepairable'
        $thrown = $null
        try { Invoke-PreparationWindows } catch { $thrown = $_.Exception }
        (Get-PreparationFailureDetail $thrown).reason | Should -BeExactly 'component-store-unrepairable'
        @($script:Steps) | Should -BeNullOrEmpty
    }
    It 'restarts first when the repair leaves a restart' {
        $script:ComponentHealth = 'Repairable'
        Mock Invoke-PreparationRestoreHealth { $script:Steps.Add('repair'); $script:Restart = $true; 0 }
        Invoke-PreparationWindows | Should -Be 'reboot'
        @($script:Steps) | Should -Not -Contain 'search'
    }
    It 'goes on to the updates when the repair can''t run' {
        $script:ComponentHealth = 'Repairable'
        Mock Invoke-PreparationRestoreHealth { throw 'Dism.exe is missing' }
        Invoke-PreparationWindows | Should -Be 'complete'
        @($script:Steps) | Should -Be @('repair stage', 'search')
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'the repair could not run: Dism\.exe is missing'
    }
    It 'repairs the store when an update fails on it, then tries that update again even after its retry' {
        foreach ($code in @(-1, $script:ComponentStoreCorrupt, 0)) { $script:Installs.Enqueue((New-InstallResult $code)) }
        Invoke-PreparationWindows | Should -Be 'complete'
        @($script:Steps) | Should -Be @('search', 'install', 'search', 'install', 'repair stage', 'repair', 'search', 'install', 'search')
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match '1 update\(s\) failed on it \(0x80073712\); repairing it'
    }
    It 'reports an update that still fails on the store after the repair, with its code' {
        foreach ($code in @($script:ComponentStoreCorrupt, $script:ComponentStoreCorrupt)) { $script:Installs.Enqueue((New-InstallResult $code)) }
        $thrown = $null
        try { Invoke-PreparationWindows } catch { $thrown = $_.Exception }
        (Get-PreparationFailureDetail $thrown).errorCode | Should -BeExactly '0x80073712'
        Should -Invoke Invoke-PreparationRestoreHealth -Times 1 -Exactly
        @($script:Steps | Where-Object { $_ -eq 'install' }).Count | Should -Be 2
    }
    It 'repairs once a run, also when an update then fails on the store' {
        $script:ComponentHealth = 'Repairable'
        foreach ($code in @($script:ComponentStoreCorrupt, $script:ComponentStoreCorrupt)) { $script:Installs.Enqueue((New-InstallResult $code)) }
        try { Invoke-PreparationWindows } catch { $null = $_ }
        Should -Invoke Invoke-PreparationRestoreHealth -Times 1 -Exactly
    }
    It 'repairs the store when an update is missing its files (0x800F0831), then names the update and the code when it still fails' {
        foreach ($code in @($script:StoreCorruption, $script:StoreCorruption)) { $script:Installs.Enqueue((New-InstallResult $code)) }
        $thrown = $null
        try { Invoke-PreparationWindows } catch { $thrown = $_.Exception }
        $detail = Get-PreparationFailureDetail $thrown
        $detail.reason | Should -BeExactly 'component-store-unrepairable'
        $detail.errorCode | Should -BeExactly '0x800F0831'
        $detail.failureMessage | Should -BeExactly "Windows couldn't install Fixture update (0x800F0831, CBS_E_STORE_CORRUPTION): its component store is missing files the update needs, and Windows's repair didn't put them back."
        @($script:Steps) | Should -Be @('search', 'install', 'repair stage', 'repair', 'search', 'install')
        $log = Get-Content (Join-Path $JobPath 'updates.log') -Raw
        $log | Should -Match '1 update\(s\) failed on it \(0x800F0831\); repairing it'
        $log | Should -Match 'updates still fail on it after the repair \(0x800F0831\): Fixture update'
    }
    It 'names the monthly update that is missing its files after the run''s repair reported the store healthy' {
        $script:ComponentHealth = 'Repairable'
        foreach ($code in @($script:StoreCorruption, $script:StoreCorruption)) { $script:Installs.Enqueue((New-InstallResult $code)) }
        $thrown = $null
        try { Invoke-PreparationWindows } catch { $thrown = $_.Exception }
        (Get-PreparationFailureDetail $thrown).reason | Should -BeExactly 'component-store-unrepairable'
        Should -Invoke Invoke-PreparationRestoreHealth -Times 1 -Exactly
        @($script:Steps | Where-Object { $_ -eq 'install' }).Count | Should -Be 2 -Because 'the update gets its one more try'
    }
    It 'installs an update the repair put its files back for' {
        foreach ($code in @($script:StoreCorruption, 0)) { $script:Installs.Enqueue((New-InstallResult $code)) }
        Invoke-PreparationWindows | Should -Be 'complete'
        Should -Invoke Invoke-PreparationRestoreHealth -Times 1 -Exactly
    }

    Context 'A repair that fails on missing manifests' {
        BeforeEach {
            $script:RepairRecordText = ''
            $script:CbsLines = @()
            $script:ComponentHealth = 'Repairable'
            # DISM ends with 0x800F0915; servicing reports Features on Demand manifests missing.
            Mock Invoke-PreparationRestoreHealth {
                $script:Steps.Add('repair')
                $now = '{0:yyyy-MM-dd HH:mm:ss}' -f [DateTime]::Now
                $script:CbsLines = @(
                    "$now, Info                  CBS    Store corruption, manifest missing for package: Microsoft-Windows-PowerShell-ISE-FOD-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.9974"
                    "$now, Error                 CBS    Failed to resolve package 'Microsoft-Windows-PowerShell-ISE-FOD-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.9974' [HRESULT = 0x800f0831 - CBS_E_STORE_CORRUPTION]"
                    "$now, Info                  CBS    Store corruption, manifest missing for package: OpenSSH-Client-Package~31bf3856ad364e35~amd64~~10.0.26100.9974"
                )
                -2146498283
            }
            function Reset-Run { $script:PreparationComponentChecked = $false; $script:PreparationComponentRepairRun = $false }
        }
        It 'stops before any update with the unrepairable result, and records the failure' {
            $thrown = $null
            try { Invoke-PreparationWindows } catch { $thrown = $_.Exception }
            $detail = Get-PreparationFailureDetail $thrown
            $detail.reason | Should -BeExactly 'component-store-unrepairable'
            $detail.errorCode | Should -BeExactly '0x800F0915'
            $detail.failureMessage | Should -Match 'manifests missing for 2 package\(s\), such as Microsoft-Windows-PowerShell-ISE-FOD-Package~\S+, OpenSSH-Client-Package~'
            @($script:Steps) | Should -Be @('repair stage', 'repair')
            ($script:RepairRecordText | ConvertFrom-Json).failures | Should -Be 1
            ($script:RepairRecordText | ConvertFrom-Json).code | Should -BeExactly '0x800F0915'
        }
        It 'repairs once more on the next try, then stops at once without repairing again' {
            foreach ($try in 1..3) {
                Reset-Run
                try { Invoke-PreparationWindows } catch { $detail = Get-PreparationFailureDetail $_.Exception }
                $detail.reason | Should -BeExactly 'component-store-unrepairable' -Because "try $try"
            }
            Should -Invoke Invoke-PreparationRestoreHealth -Times 2 -Exactly
            ($script:RepairRecordText | ConvertFrom-Json).failures | Should -Be 2
            Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'its repair already failed 2 times on missing manifests, most recently with 0x800F0915, so it isn''t repaired again'
        }
        It 'repairs again, and goes on as before, once the store has read healthy' {
            foreach ($try in 1..2) { Reset-Run; try { Invoke-PreparationWindows } catch { $null = $_ } }
            # Repaired since, by other means.
            $script:ComponentHealth = 'Healthy'
            Reset-Run
            Invoke-PreparationWindows | Should -Be 'complete'
            $script:RepairRecordText | Should -BeNullOrEmpty
        }
        It 'goes on to the updates when servicing reported the missing manifests only before the repair' {
            Mock Invoke-PreparationRestoreHealth {
                $script:Steps.Add('repair')
                $script:CbsLines = @('2001-01-01 00:00:00, Info                  CBS    Store corruption, manifest missing for package: OpenSSH-Client-Package~31bf3856ad364e35~amd64~~10.0.26100.9974')
                -2146498283
            }
            Invoke-PreparationWindows | Should -Be 'complete'
            @($script:Steps) | Should -Be @('repair stage', 'repair', 'search')
            $script:RepairRecordText | Should -BeNullOrEmpty
        }
        It 'goes on to the updates when the repair fixes the store' {
            Mock Invoke-PreparationRestoreHealth { $script:Steps.Add('repair'); $script:ComponentHealth = 'Healthy'; 0 }
            $script:RepairRecordText = '{"failures":1,"code":"0x800F0915","at":"' + [DateTime]::UtcNow.ToString('o') + '"}'
            Invoke-PreparationWindows | Should -Be 'complete'
            $script:RepairRecordText | Should -BeNullOrEmpty
        }
        It 'leaves a record older than 30 days out' {
            $script:RepairRecordText = '{"failures":2,"code":"0x800F0915","at":"' + [DateTime]::UtcNow.AddDays(-31).ToString('o') + '"}'
            try { Invoke-PreparationWindows } catch { $null = $_ }
            Should -Invoke Invoke-PreparationRestoreHealth -Times 1 -Exactly
            ($script:RepairRecordText | ConvertFrom-Json).failures | Should -Be 1
        }
    }
}

Describe 'How a failure names an update' {
    It 'gives <Case>' -TestCases @(
        @{ Case = 'the title when it names the KB'; Title = '2026-11 Security Update (KB5132061) (26300.9974)'; Kb = @('5132061'); Name = '2026-11 Security Update (KB5132061) (26300.9974)' }
        @{ Case = 'the KB after a title without it'; Title = 'Security Update  for Windows'; Kb = @('5132061'); Name = 'Security Update for Windows (KB5132061)' }
        @{ Case = 'the title alone without a KB'; Title = 'Realtek - Net - 1125.21.903.2024'; Kb = @(); Name = 'Realtek - Net - 1125.21.903.2024' }
    ) {
        param($Case, $Title, $Kb, $Name)
        Format-PreparationUpdateName ([pscustomobject]@{ Title = $Title; KBArticleIDs = $Kb }) | Should -BeExactly $Name -Because $Case
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
            $result | Add-Member ScriptMethod GetUpdateResult { param($Index) $null = $Index; [pscustomobject]@{ ResultCode = $this.ResultCode; HResult = $(if ($this.ResultCode -eq 2) { 0 } else { -2147023293 }) } }
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
        Mock Get-PreparationUpdateExclusion { '' }
        $found = @(Find-PreparationWindowsUpdate ([pscustomobject]@{}))
        @($found.Title) | Should -Be @('Another update')
    }
}

Describe 'Microsoft Defender''s own updates' {
    BeforeAll {
        function New-Offered([string]$Title, [string]$Kb, [string]$Id) {
            [pscustomobject]@{ Title = $Title; KBArticleIDs = @($Kb); Identity = [pscustomobject]@{ UpdateID = $Id; RevisionNumber = 1 } }
        }
    }
    BeforeEach {
        $script:intelligence = New-Offered 'Security Intelligence Update for Microsoft Defender Antivirus - KB2267602 (Version 1.463.439.0) - Current Channel (Broad)' '2267602' 'intelligence'
        $script:platform = New-Offered 'Update for Microsoft Defender Antivirus antimalware platform - KB4052623 (Version 4.18.26100.4) - Current Channel (Broad)' '4052623' 'platform'
        $script:monthly = New-Offered '2026-11 Security Update (KB5132061) (26200.9974)' '5132061' 'monthly'
        Mock Invoke-PreparationSearch { @($script:intelligence, $script:platform, $script:monthly) }
        Mock Get-PreparationUpdateExclusion { '' }
        $script:record = @()
        Mock Read-PreparationReoffered { $script:record }
        Mock Write-PreparationReoffered { $script:record = @($Entries) }
        $script:PreparationDefenderSkipped = @{}
        Set-Variable -Name VerifyOnly -Value ([switch]$false)
        Remove-Item -LiteralPath (Join-Path $JobPath 'updates.log') -ErrorAction SilentlyContinue
    }

    It 'leaves them out, and records them, once Atlas has removed Defender' {
        Mock Test-PreparationDefenderRemoved { $true }
        @((Find-PreparationWindowsUpdate ([pscustomobject]@{})).Title) | Should -Be @($script:monthly.Title)
        @($script:record.key) | Should -Be @('intelligence/1', 'platform/1')
        @($script:record.why) | Should -Be @('defender-removed', 'defender-removed')
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match "defender update not needed, not installed: 'Security Intelligence Update for Microsoft Defender Antivirus - KB2267602"
        Should -Invoke Test-PreparationDefenderRemoved -Times 1 -Exactly
    }

    It 'keeps them required while Defender is on this PC' {
        Mock Test-PreparationDefenderRemoved { $false }
        @((Find-PreparationWindowsUpdate ([pscustomobject]@{})).Title) | Should -Be @($script:intelligence.Title, $script:platform.Title, $script:monthly.Title)
        $script:record | Should -BeNullOrEmpty
    }

    It 'leaves them out of the check before the install, which records nothing' {
        Set-Variable -Name VerifyOnly -Value ([switch]$true)
        Mock Test-PreparationDefenderRemoved { $true }
        @((Find-PreparationWindowsUpdate ([pscustomobject]@{})).Title) | Should -Be @($script:monthly.Title)
        Should -Invoke Write-PreparationReoffered -Times 0 -Exactly
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'defender update not needed'
    }

    It 'waits for them again once Defender is back, whatever the record says' {
        Mock Test-PreparationDefenderRemoved { $false }
        $script:record = @([pscustomobject]@{ key = 'intelligence/1'; kb = '2267602'; title = 'x'; at = [DateTime]::UtcNow.ToString('o'); why = 'defender-removed' })
        @((Find-PreparationWindowsUpdate ([pscustomobject]@{})).Title) | Should -Contain $script:intelligence.Title
    }

    It 'keeps one record for each Defender update however often a new one comes' {
        Mock Test-PreparationDefenderRemoved { $true }
        $script:record = @([pscustomobject]@{ key = 'driver/1'; kb = ''; title = 'A driver'; at = [DateTime]::UtcNow.ToString('o') })
        [void](Find-PreparationWindowsUpdate ([pscustomobject]@{}))
        $script:intelligence.Identity.UpdateID = 'intelligence-next'
        $script:PreparationDefenderSkipped = @{}
        [void](Find-PreparationWindowsUpdate ([pscustomobject]@{}))
        @($script:record.key) | Should -Be @('driver/1', 'intelligence-next/1', 'platform/1')
    }

    It 'counts Defender as removed only with the NoDefender package installed and Defender unable to run: <Case>' -TestCases @(
        @{ Case = 'no WinDefend service'; Package = 'Installed'; Service = $false; Engine = $true; Removed = $true }
        @{ Case = 'no Defender engine'; Package = 'Installed'; Service = $true; Engine = $false; Removed = $true }
        @{ Case = 'the service and the engine there'; Package = 'Installed'; Service = $true; Engine = $true; Removed = $false }
        @{ Case = 'no NoDefender package'; Package = $null; Service = $false; Engine = $false; Removed = $false }
        @{ Case = 'the package waiting for a restart'; Package = 'InstallPending'; Service = $false; Engine = $false; Removed = $false }
    ) {
        Mock Get-AtlasTransitionDefenderPackageState { $Package }
        Mock Test-AtlasTransitionKey { $Service } -ParameterFilter { $Path -eq 'SYSTEM\CurrentControlSet\Services\WinDefend' }
        Mock Test-PreparationDefenderEngine { $Engine }
        Test-PreparationDefenderRemoved | Should -Be $Removed -Because $Case
    }
}

Describe 'Windows Update searches that end with errors' {
    BeforeEach {
        # Each search returns the next result; a warning names the part that failed.
        $warning = [pscustomobject]@{ HResult = -2145107924; Context = 1; Message = 'The server could not be reached. ' }
        $script:results = New-Object System.Collections.Queue
        $script:session = [pscustomobject]@{}
        $script:session | Add-Member ScriptMethod CreateUpdateSearcher {
            $searcher = [pscustomobject]@{ Online = $false; ServerSelection = 0; ServiceID = ''; IncludePotentiallySupersededUpdates = $false }
            $searcher | Add-Member ScriptMethod BeginSearch {
                $job = [pscustomobject]@{ IsCompleted = $true }
                $job | Add-Member ScriptMethod CleanUp { }
                $job
            }
            $searcher | Add-Member ScriptMethod EndSearch {
                $next = $script:results.Dequeue()
                if ($next -is [Exception]) { throw $next }
                $next
            }
            $searcher
        }
        $script:partial = [pscustomobject]@{ ResultCode = 3; Updates = @(); Warnings = @($warning) }
        Mock Get-PreparationServerSelection { 2 }
        Mock New-PreparationCallback { [pscustomobject]@{} }
        Mock Write-AtlasTransitionEvidence { }
        Mock Wait-PreparationSeconds { }
        Mock Get-PreparationUpdateServiceStatus { 'Running' }
        Remove-Item -LiteralPath (Join-Path $TestDrive 'updates.log') -ErrorAction SilentlyContinue
    }

    It 'searches again after a partial failure and logs what failed' {
        $script:results.Enqueue($script:partial)
        $script:results.Enqueue([pscustomobject]@{ ResultCode = 2; Updates = @([pscustomobject]@{ Title = 'Cumulative update' }) })
        $found = @(Invoke-PreparationSearch $script:session 'IsInstalled=0')
        @($found.Title) | Should -Be @('Cumulative update')
        Should -Invoke Wait-PreparationSeconds -Times 1 -Exactly
        Get-Content -LiteralPath (Join-Path $TestDrive 'updates.log') -Raw | Should -Match 'result 3 on attempt 1 of 3: 0x8024402C \(context 1\) The server could not be reached\.'
    }

    It 'stops with the code of the part that failed when every attempt fails' {
        1..3 | ForEach-Object { $script:results.Enqueue($script:partial) }
        try { Invoke-PreparationSearch $script:session 'IsInstalled=0'; throw 'expected a failure' }
        catch { $detail = Get-PreparationFailureDetail $_.Exception }
        $detail.errorCode | Should -Be '0x8024402C'
        $detail.failureMessage | Should -Match '^Windows update search failed: 3 \(0x8024402C'
        $detail.ContainsKey('reason') | Should -BeFalse
        Should -Invoke Wait-PreparationSeconds -Times 2 -Exactly
    }

    It 'searches again after Windows Update stopped for a moment (<Code>)' -TestCases @(
        @{ Code = '0x8024001E'; HResult = -2145124322 }
        # Windows Update can drop a search as it restarts, as after a component store repair.
        @{ Code = '0x80240069'; HResult = -2145124247 }
    ) {
        param($Code, $HResult)
        $script:results.Enqueue([Runtime.InteropServices.COMException]::new("Exception from HRESULT: $Code", $HResult))
        $script:results.Enqueue([pscustomobject]@{ ResultCode = 2; Updates = @([pscustomobject]@{ Title = 'Cumulative update' }) })
        @((Invoke-PreparationSearch $script:session 'IsInstalled=0').Title) | Should -Be @('Cumulative update')
        Should -Invoke Wait-PreparationSeconds -Times 1 -Exactly -ParameterFilter { $Seconds -eq 30 }
        Should -Invoke Get-PreparationUpdateServiceStatus -Times 1 -Exactly
        Get-Content -LiteralPath (Join-Path $TestDrive 'updates.log') -Raw | Should -Match "search failed on attempt 1 of 3: $Code"
    }

    It 'waits for Windows Update to run again before it searches again, starting a stopped service once' {
        $script:statuses = [Collections.Queue]::new(@('StopPending', 'Stopped', 'Stopped', 'StartPending', 'Running'))
        Mock Get-PreparationUpdateServiceStatus { $script:statuses.Dequeue() }
        Mock Start-PreparationUpdateService { }
        Mock Assert-PreparationContinue { }
        Mock Write-PreparationState { }
        Mock Start-Sleep { }
        $script:results.Enqueue([Runtime.InteropServices.COMException]::new('Exception from HRESULT: 0x80240069', -2145124247))
        $script:results.Enqueue([pscustomobject]@{ ResultCode = 2; Updates = @() })
        @(Invoke-PreparationSearch $script:session 'IsInstalled=0') | Should -HaveCount 0
        Should -Invoke Get-PreparationUpdateServiceStatus -Times 5 -Exactly
        Should -Invoke Start-PreparationUpdateService -Times 1 -Exactly
        $script:results.Count | Should -Be 0 -Because 'the search ran again once the service ran'
    }

    It 'searches again anyway when Windows Update doesn''t run in time, and logs it' {
        Mock Get-PreparationUpdateServiceStatus { 'StopPending' }
        Mock Start-PreparationUpdateService { throw 'never started for a stopping service' }
        Mock Assert-PreparationContinue { }
        Mock Write-PreparationState { }
        Mock Start-Sleep { }
        $script:results.Enqueue([Runtime.InteropServices.COMException]::new('Exception from HRESULT: 0x8024001E', -2145124322))
        $script:results.Enqueue([pscustomobject]@{ ResultCode = 2; Updates = @() })
        @(Invoke-PreparationSearch $script:session 'IsInstalled=0') | Should -HaveCount 0
        Should -Invoke Start-Sleep -Times ($script:PreparationServiceWaitSeconds / 2) -Exactly
        Get-Content -LiteralPath (Join-Path $TestDrive 'updates.log') -Raw | Should -Match 'Windows Update still reports StopPending after 120 seconds; searching again anyway\.'
    }

    It 'waits longer each time, then names the cause when Windows Update stays out of reach (<Code>)' -TestCases @(
        @{ Code = '0x80240438'; HResult = -2145123272 }
        @{ Code = '0x80244018'; HResult = -2145107944 }
    ) {
        param($Code, $HResult)
        1..3 | ForEach-Object { $script:results.Enqueue([Runtime.InteropServices.COMException]::new("Exception from HRESULT: $Code", $HResult)) }
        try { Invoke-PreparationSearch $script:session 'IsInstalled=0'; throw 'expected a failure' }
        catch { $detail = Get-PreparationFailureDetail $_.Exception }
        $detail.reason | Should -Be 'windows-update-unreachable'
        $detail.errorCode | Should -Be $Code
        Should -Invoke Wait-PreparationSeconds -Times 1 -Exactly -ParameterFilter { $Seconds -eq 30 }
        Should -Invoke Wait-PreparationSeconds -Times 1 -Exactly -ParameterFilter { $Seconds -eq 60 }
    }

    It 'names the cause when part of every search couldn''t reach Windows Update' {
        $warning = [pscustomobject]@{ HResult = -2145123272; Context = 4; Message = '' }
        1..3 | ForEach-Object { $script:results.Enqueue([pscustomobject]@{ ResultCode = 3; Updates = @(); Warnings = @($warning) }) }
        try { Invoke-PreparationSearch $script:session 'IsInstalled=0'; throw 'expected a failure' }
        catch { $detail = Get-PreparationFailureDetail $_.Exception }
        $detail.reason | Should -Be 'windows-update-unreachable'
        $detail.errorCode | Should -Be '0x80240438'
    }

    It 'stops at once for a search error that doesn''t pass on its own' {
        $script:results.Enqueue([Runtime.InteropServices.COMException]::new('invalid criteria', -2145124302))
        try { Invoke-PreparationSearch $script:session 'IsInstalled=0'; throw 'expected a failure' }
        catch { $thrown = $_.Exception }
        Get-PreparationHResult $thrown | Should -Be -2145124302
        Should -Invoke Wait-PreparationSeconds -Times 0 -Exactly
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
    It 'waits for another installation when Windows Update won''t start this one, then starts it' {
        $script:refusals = 1
        $script:provider | Add-Member ScriptMethod BeginInstall {
            if ($script:refusals-- -gt 0) { throw ([Runtime.InteropServices.COMException]::new('Another installation is in progress.', -2145124330)) }
            $script:job
        } -Force
        Mock Wait-PreparationInstallerIdle { $true }
        (Invoke-PreparationWindowsOperation $script:provider $script:updates Install).ResultCode | Should -Be 3
        Should -Invoke Wait-PreparationInstallerIdle -Times 1 -Exactly -ParameterFilter { $Stage -eq 'windows-install' }
    }
    It 'reports the refusal to start once waiting for another installation is used up' {
        $script:provider | Add-Member ScriptMethod BeginInstall { throw ([Runtime.InteropServices.COMException]::new('Another installation is in progress.', -2145124330)) } -Force
        Mock Wait-PreparationInstallerIdle { $false }
        { Invoke-PreparationWindowsOperation $script:provider $script:updates Install } | Should -Throw '*Another installation is in progress*'
        $script:cleaned | Should -BeFalse
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
        Get-PreparationUpdateExclusion ([pscustomobject]@{ BrowseOnly = $false; Categories = @() }) | Should -BeExactly ''
        Get-PreparationUpdateExclusion ([pscustomobject]@{ BrowseOnly = $true; Categories = @() }) | Should -Match 'optional preview'
        Get-PreparationUpdateExclusion ([pscustomobject]@{ BrowseOnly = $false; Categories = @([pscustomobject]@{ CategoryID = '3689bdc8-b205-4af4-8d4a-a63924c5e9d5' }) }) | Should -Match 'feature update'
    }
    It 'excludes drivers in manual mode while retaining Windows software updates' {
        $previousMode = $DriverMode
        try {
            $DriverMode = 'manual'
            Get-PreparationUpdateExclusion ([pscustomobject]@{ BrowseOnly = $false; Type = 2; Categories = @() }) | Should -Match 'Install drivers myself'
            Get-PreparationUpdateExclusion ([pscustomobject]@{ BrowseOnly = $false; Type = 1; Categories = @() }) | Should -BeExactly ''
        } finally { $DriverMode = $previousMode }
    }
    It 'logs each offer it leaves out of a pass, and why' {
        Mock Read-PreparationReoffered {}
        Remove-Item -LiteralPath (Join-Path $JobPath 'updates.log') -ErrorAction SilentlyContinue
        $script:searchResult = @(
            [pscustomobject]@{ Title = '2026-10 Cumulative Update Preview for Windows 11 (KB5124011)'; BrowseOnly = $true; Type = 1; Categories = @() }
            [pscustomobject]@{ Title = 'Windows 11, version 26H2'; BrowseOnly = $false; Type = 1; Categories = @([pscustomobject]@{ CategoryID = '3689BDC8-B205-4AF4-8D4A-A63924C5E9D5' }) }
            [pscustomobject]@{ Title = 'Intel Corporation - Display - 32.0.101.6881'; BrowseOnly = $false; Type = 2; Categories = @() }
            [pscustomobject]@{ Title = '2026-10 Cumulative Update for Windows 11 (KB5124010)'; BrowseOnly = $false; Type = 1; Categories = @(); Identity = [pscustomobject]@{ UpdateID = 'cumulative'; RevisionNumber = 1 } }
        )
        Mock Invoke-PreparationSearch { $script:searchResult }
        $previousMode = $DriverMode
        try {
            $DriverMode = 'manual'
            $found = @(Find-PreparationWindowsUpdate ([pscustomobject]@{}))
        } finally { $DriverMode = $previousMode }
        @($found.Title) | Should -Be @('2026-10 Cumulative Update for Windows 11 (KB5124010)')
        $log = Get-Content (Join-Path $JobPath 'updates.log') -Raw
        $log | Should -Match "Left '2026-10 Cumulative Update Preview for Windows 11 \(KB5124011\)': an optional preview \(browse-only\), which installing Atlas doesn't need\."
        $log | Should -Match "Left 'Windows 11, version 26H2': a feature update, which only a move to another Windows release installs, through its own search\."
        $log | Should -Match "Left 'Intel Corporation - Display - 32\.0\.101\.6881': a driver, and drivers are left to the user \(Install drivers myself\)\."
        $log | Should -Not -Match 'Left ''2026-10 Cumulative Update for Windows 11'
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
        Mock Get-PreparationStagingFailure {}
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
    It 'tries again after the Store <Case>' -TestCases @(
        @{ Case = 'cancelled an item (E_ABORT)'; Failure = { New-PreparationStoreFailure 'Microsoft.Windows.Photos_8wekyb3d8bbwe' 'Canceled' ([Runtime.InteropServices.COMException]::new('Operation aborted', -2147467260)) } }
        @{ Case = 'didn''t answer'; Failure = { $silent = New-PreparationFailure 'Microsoft Store did not answer.' 'store-timeout'; $silent.Data['storeTransient'] = 'retry'; $silent } }
    ) {
        param($Case, $Failure)
        $script:failure = & $Failure
        Mock Invoke-PreparationStore { $script:storeAttempts++; if ($script:storeAttempts -le 2) { throw $script:failure } }
        { Invoke-PreparationStoreWithRetry } | Should -Not -Throw -Because $Case
        Should -Invoke Invoke-PreparationStore -Times 3 -Exactly
    }
    It 'leaves a Store that keeps cancelling to the repairs once its tries are used up' {
        Mock Invoke-PreparationStore { throw (New-PreparationStoreFailure 'Microsoft.Windows.Photos_8wekyb3d8bbwe' 'Canceled' ([Runtime.InteropServices.COMException]::new('Operation aborted', -2147467260))) }
        try { Invoke-PreparationStoreWithRetry } catch { $thrown = $_.Exception }
        Should -Invoke Invoke-PreparationStore -Times 4 -Exactly
        Test-PreparationStoreRepairable $thrown | Should -BeTrue
    }
    It 'tries again after an app was in use (0x80073D02), and says which' {
        Mock Write-PreparationStoreEvidence {}
        Mock Invoke-PreparationStore {
            $script:storeAttempts++
            if ($script:storeAttempts -le 2) {
                throw (New-PreparationStoreFailure 'MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy' 'Error' ([Runtime.InteropServices.COMException]::new('Resources are in use.', -2147009278)))
            }
        }
        { Invoke-PreparationStoreWithRetry } | Should -Not -Throw
        Should -Invoke Invoke-PreparationStore -Times 3 -Exactly
        Should -Invoke Start-Sleep -Times 30 -Exactly -ParameterFilter { $Seconds -eq 1 }
        Should -Invoke Write-PreparationStoreEvidence -Times 1 -Exactly -ParameterFilter { $Text -eq 'WebExperience is in use (0x80073D02); trying again in 15 seconds (attempt 2 of 4)' }
    }
    It 'leaves an app still in use after four tries to the user to close, without the repairs' {
        Mock Write-PreparationStoreEvidence {}
        Mock Invoke-PreparationStore { throw (New-PreparationStoreFailure 'Microsoft.WindowsNotepad_8wekyb3d8bbwe' 'Error' ([Runtime.InteropServices.COMException]::new('Resources are in use.', -2147009278))) }
        try { Invoke-PreparationStoreWithRetry } catch { $thrown = $_.Exception }
        Should -Invoke Invoke-PreparationStore -Times 4 -Exactly
        $detail = Get-PreparationFailureDetail $thrown
        $detail.errorCode | Should -Be '0x80073D02'
        $detail.packageName | Should -Be 'WindowsNotepad'
        Test-PreparationStoreRepairable $thrown | Should -BeFalse
    }
    It 'goes on to the repairs at once when an item is cancelled after Windows couldn''t stage updates' {
        Mock Get-PreparationStagingFailure { [pscustomobject]@{ Name = 'Microsoft.WindowsCalculator'; Family = 'Microsoft.WindowsCalculator_8wekyb3d8bbwe'; Package = ''; ActivityId = '' } }
        Mock Invoke-PreparationStore { throw (New-PreparationStoreFailure 'Microsoft.Windows.Photos_8wekyb3d8bbwe' 'Canceled' ([Runtime.InteropServices.COMException]::new('Operation aborted', -2147467260))) }
        try { Invoke-PreparationStoreWithRetry } catch { $thrown = $_.Exception }
        Should -Invoke Invoke-PreparationStore -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
        (Get-PreparationFailureDetail $thrown).errorCode | Should -Be '0x80070490'
        Test-PreparationStoreRepairable $thrown | Should -BeTrue
    }
    It 'doesn''t wait again for a Store that was slow until the end' {
        $script:slow = New-PreparationFailure 'Store apps have not finished updating.' 'store-timeout'
        $script:slow.Data['storeTransient'] = 'final'
        Mock Invoke-PreparationStore { throw $script:slow }
        { Invoke-PreparationStoreWithRetry } | Should -Throw '*have not finished*'
        Should -Invoke Invoke-PreparationStore -Times 1 -Exactly
    }
}

Describe 'A Store that is slow or briefly fails' {
    BeforeEach {
        Mock Write-PreparationState {}
        Mock Write-PreparationStoreEvidence {}
        Mock Get-PreparationStagingFailure {}
        $script:now = [DateTime]::new(2026, 1, 1, 12, 0, 0, [DateTimeKind]::Utc)
        Mock Get-PreparationStoreTime { $script:now }
    }

    It 'names an item the Store cancelled (E_ABORT) as a wait, and other failures as they were' {
        $aborted = New-PreparationStoreFailure 'Microsoft.Windows.Photos_8wekyb3d8bbwe' 'Canceled' ([Runtime.InteropServices.COMException]::new('Operation aborted', -2147467260))
        (Get-PreparationFailureDetail $aborted).reason | Should -Be 'store-timeout'
        (Get-PreparationFailureDetail $aborted).errorCode | Should -Be '0x80004004'
        Get-PreparationStoreTransient $aborted | Should -Be 'retry'
        Should -Invoke Get-PreparationStagingFailure -Times 1 -Exactly
        $failed = New-PreparationStoreFailure 'Microsoft.Windows.Photos_8wekyb3d8bbwe' 'Error' ([Runtime.InteropServices.COMException]::new('Install failed', -2147009287))
        (Get-PreparationFailureDetail $failed).ContainsKey('reason') | Should -BeFalse
        Get-PreparationStoreTransient $failed | Should -Be ''
        Test-PreparationStoreRepairable $failed | Should -BeTrue
        # Only an E_ABORT reads the AppX deployment log.
        Should -Invoke Get-PreparationStagingFailure -Times 1 -Exactly
    }

    It 'reports the 0x80070490 an E_ABORT hides when Windows couldn''t stage updates earlier in the run' {
        Mock Get-PreparationStagingFailure {
            [pscustomobject]@{ Name = 'Microsoft.WindowsCalculator'; Family = 'Microsoft.WindowsCalculator_8wekyb3d8bbwe'; Package = ''; ActivityId = '' }
            [pscustomobject]@{ Name = 'Microsoft.ZuneMusic'; Family = 'Microsoft.ZuneMusic_8wekyb3d8bbwe'; Package = ''; ActivityId = '' }
        }
        $hidden = New-PreparationStoreFailure 'Microsoft.Windows.Photos_8wekyb3d8bbwe' 'Canceled' ([Runtime.InteropServices.COMException]::new('Operation aborted', -2147467260))
        $detail = Get-PreparationFailureDetail $hidden
        $detail.errorCode | Should -Be '0x80070490'
        $detail.ContainsKey('reason') | Should -BeFalse -Because 'a Store that gave up after a staging failure is no wait'
        $detail.packageName | Should -Be 'Photos'
        $detail.failureMessage | Should -Match 'Microsoft\.Windows\.Photos_8wekyb3d8bbwe, Canceled, .*Operation aborted'
        $detail.failureMessage | Should -Match "couldn't stage updates in this run \(0x80070490, element not found\): Microsoft\.WindowsCalculator, Microsoft\.ZuneMusic$"
        Get-PreparationStoreTransient $hidden | Should -Be ''
        Test-PreparationStoreRepairable $hidden | Should -BeTrue
    }

    It 'names a Store that refuses to resume a download as a wait, with its code' {
        $manager = [pscustomobject]@{}
        $manager | Add-Member ScriptMethod Restart { throw ([Runtime.InteropServices.COMException]::new('Error HRESULT E_FAIL has been returned from a call to a COM component.', -2147467259)) }
        $item = [pscustomobject]@{ ProductId = '9WZDNCRFJ3PT'; PackageFamilyName = 'Microsoft.ZuneMusic_8wekyb3d8bbwe' }
        try { Resume-PreparationStoreItem $manager $item } catch { $thrown = $_.Exception }
        $detail = Get-PreparationFailureDetail $thrown
        $detail.reason | Should -Be 'store-timeout'
        $detail.errorCode | Should -Be '0x80004005'
        Get-PreparationStoreTransient $thrown | Should -Be 'retry'
    }

    It 'names a Store that doesn''t answer as a wait' {
        $source = [Threading.Tasks.TaskCompletionSource[object]]::new()
        Mock Get-PreparationStoreTime { $script:now = $script:now.AddMinutes(4); $script:now }
        try { Wait-PreparationStoreTask $source.Task } catch { $thrown = $_.Exception }
        $thrown.Message | Should -Be 'Microsoft Store did not answer.'
        (Get-PreparationFailureDetail $thrown).reason | Should -Be 'store-timeout'
        Get-PreparationStoreTransient $thrown | Should -Be 'retry'
        $thrown.Data['storeSilent'] | Should -BeTrue -Because 'the repairs restart the install service first for it'
    }

    Context 'The Store''s own update' {
        BeforeEach {
            Mock Assert-PreparationContinue {}
            Mock Start-Sleep {}
            Mock Test-PreparationRestart { $false }
            $script:manager = [pscustomobject]@{}
            $script:manager | Add-Member ScriptMethod UpdateAppByPackageFamilyNameAsync { param($Family) $Family }
            Mock New-PreparationStoreManager { $script:manager }
            $script:StoreCalls = 0
            Mock Wait-PreparationStoreCall {
                if ($Operation -ne 'Microsoft.WindowsStore_8wekyb3d8bbwe') { return $null }
                $script:StoreCalls++
                if ($script:StoreCalls -le 2) {
                    $silent = New-PreparationFailure 'Microsoft Store did not answer.' 'store-timeout'
                    $silent.Data['storeTransient'] = 'retry'
                    $silent.Data['storeSilent'] = $true
                    throw $silent
                }
            }
            $null = [Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallItem, Windows.ApplicationModel.Store.Preview.InstallControl, ContentType=WindowsRuntime]
        }

        It 'gets the tries the Store apps get, so a Store that answers later updates without the repairs' {
            Update-PreparationStoreItself -Retry | Should -BeFalse
            $script:StoreCalls | Should -Be 3
            Should -Invoke Start-Sleep -Times 30 -Exactly -ParameterFilter { $Seconds -eq 1 }
            Should -Invoke Write-PreparationStoreEvidence -Times 1 -Exactly -ParameterFilter { $Text -eq 'Microsoft Store did not answer; trying again in 15 seconds (attempt 2 of 4)' }
            Should -Invoke Write-PreparationStoreEvidence -Times 1 -Exactly -ParameterFilter { $Text -eq 'Microsoft.WindowsStore_8wekyb3d8bbwe has no update' }
        }

        It 'fails for the repairs once its tries are used up, still marked as not answering' {
            Mock Wait-PreparationStoreCall {
                if ($Operation -ne 'Microsoft.WindowsStore_8wekyb3d8bbwe') { return $null }
                $script:StoreCalls++
                $silent = New-PreparationFailure 'Microsoft Store did not answer.' 'store-timeout'
                $silent.Data['storeTransient'] = 'retry'
                $silent.Data['storeSilent'] = $true
                throw $silent
            }
            try { Update-PreparationStoreItself -Retry } catch { $thrown = $_.Exception }
            $script:StoreCalls | Should -Be 4
            $thrown.Data['storeSilent'] | Should -BeTrue
            Test-PreparationStoreRepairable $thrown | Should -BeTrue
        }

        It 'gets one try after a repair, which says whether it helped' {
            { Update-PreparationStoreItself } | Should -Throw 'Microsoft Store did not answer.'
            $script:StoreCalls | Should -Be 1
            Should -Invoke Start-Sleep -Times 0 -Exactly
        }
    }

    Context 'Restarting the Store''s install service' {
        BeforeEach {
            Mock Start-Sleep {}
            $script:Service = [pscustomobject]@{ Status = 'Running'; StartType = 'Manual'; Calls = [Collections.Generic.List[string]]::new(); Stops = $true }
            $script:Service | Add-Member ScriptMethod Stop { $this.Calls.Add('Stop'); if ($this.Stops) { $this.Status = 'Stopped' } }
            $script:Service | Add-Member ScriptMethod Start { $this.Calls.Add('Start'); $this.Status = 'Running' }
            $script:Service | Add-Member ScriptMethod Refresh {}
            Mock Get-Service { $script:Service }
        }

        It 'stops it, starts it again and says so' {
            Restart-PreparationStoreService | Should -BeTrue
            @($script:Service.Calls) | Should -Be @('Stop', 'Start')
            Should -Invoke Get-Service -Times 1 -Exactly -ParameterFilter { $Name -eq 'InstallService' }
            Should -Invoke Write-PreparationStoreEvidence -Times 1 -Exactly -ParameterFilter { $Text -eq 'installservice: restarted the Microsoft Store Install Service, which was Running' }
        }

        It 'starts one that isn''t running' {
            $script:Service.Status = 'Stopped'
            Restart-PreparationStoreService | Should -BeTrue
            @($script:Service.Calls) | Should -Be @('Start')
        }

        It 'leaves alone one that''s turned off, which couldn''t start again' {
            $script:Service.StartType = 'Disabled'
            { Restart-PreparationStoreService } | Should -Throw '*turned off*'
            $script:Service.Calls.Count | Should -Be 0
        }

        It 'fails after a minute when it doesn''t stop, and never starts it meanwhile' {
            $script:Service.Stops = $false
            { Restart-PreparationStoreService } | Should -Throw "*isn't stopped after a minute; it's Running*"
            @($script:Service.Calls) | Should -Be @('Stop')
            Should -Invoke Start-Sleep -Times 30 -Exactly
        }
    }

    It 'keeps App Installer as it is, and goes on, when the Store briefly fails to update it' {
        Mock Assert-PreparationContinue {}
        $script:manager = [pscustomobject]@{}
        $script:manager | Add-Member ScriptMethod UpdateAppByPackageFamilyNameAsync { param($Family) $Family }
        Mock New-PreparationStoreManager { $script:manager }
        Mock Wait-PreparationStoreCall {
            if ($Operation -eq 'Microsoft.WindowsStore_8wekyb3d8bbwe') { return $null }
            $silent = New-PreparationFailure 'Microsoft Store did not answer.' 'store-timeout'
            $silent.Data['storeTransient'] = 'retry'
            throw $silent
        }
        $null = [Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallItem, Windows.ApplicationModel.Store.Preview.InstallControl, ContentType=WindowsRuntime]
        Update-PreparationStoreItself | Should -BeFalse
        Should -Invoke Write-PreparationStoreEvidence -Times 1 -Exactly -ParameterFilter { $Text -eq 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe could not be updated, going on: Microsoft Store did not answer.' }
    }

    It 'gives up on a Store that stops moving, for the repairs' {
        $clock = New-PreparationStoreClock
        Assert-PreparationStoreProgress $clock 'Downloading 10' 'Not finished.'
        $script:now = $script:now.AddMinutes(29)
        Assert-PreparationStoreProgress $clock 'Downloading 10' 'Not finished.'
        $script:now = $script:now.AddMinutes(2)
        try { Assert-PreparationStoreProgress $clock 'Downloading 10' 'Not finished.' } catch { $thrown = $_.Exception }
        (Get-PreparationFailureDetail $thrown).reason | Should -Be 'store-timeout'
        Test-PreparationStoreRepairable $thrown | Should -BeTrue
    }

    It 'waits for a Store that keeps moving, then gives up without the repairs' {
        $clock = New-PreparationStoreClock
        for ($minute = 0; $minute -le 90; $minute += 10) {
            $script:now = $clock.Started.AddMinutes($minute)
            Assert-PreparationStoreProgress $clock "Downloading $minute" 'Not finished.'
        }
        $script:now = $clock.Started.AddMinutes(91)
        try { Assert-PreparationStoreProgress $clock 'Downloading 91' 'Not finished.' } catch { $thrown = $_.Exception }
        (Get-PreparationFailureDetail $thrown).reason | Should -Be 'store-timeout'
        Get-PreparationStoreTransient $thrown | Should -Be 'final'
        Test-PreparationStoreRepairable $thrown | Should -BeFalse
    }

    It 'ends a wait with a limit of its own at that limit' {
        $clock = New-PreparationStoreClock 15
        $script:now = $clock.Started.AddMinutes(14)
        Assert-PreparationStoreProgress $clock 'Downloading 50' 'Not finished.'
        $script:now = $clock.Started.AddMinutes(16)
        { Assert-PreparationStoreProgress $clock 'Downloading 60' 'Not finished.' } | Should -Throw 'Not finished.'
    }

    It 'names a refused or cut download as a network problem: <Case>' -TestCases @(
        @{ Case = 'GitHub''s limit'; Status = 403; Network = $true }
        @{ Case = 'too many requests'; Status = 429; Network = $true }
        @{ Case = 'a proxy asking for credentials'; Status = 407; Network = $true }
        @{ Case = 'a missing file'; Status = 404; Network = $false }
    ) {
        param($Case, $Status, $Network)
        $failure = Get-PreparationHttpFailure 'https://api.github.com/repos/microsoft/winget-cli' $Status
        $failure.Data.Contains('network') | Should -Be $Network -Because $Case
        $failure.Message | Should -Match "HTTP (status )?$Status"
        if ($Network) { $failure.Message | Should -Match '^A network problem stopped the download from api\.github\.com' }
    }

    It 'names a connection that fails as a network problem' {
        $file = Join-Path $TestDrive 'refused.json'
        try { Save-PreparationDownload 'https://127.0.0.1:9/' $file 1KB 10 } catch { $thrown = $_.Exception }
        $thrown.Data.Contains('network') | Should -BeTrue
        $thrown.Message | Should -Match '^A network problem stopped the download from 127\.0\.0\.1: '
        Test-Path -LiteralPath $file | Should -BeFalse
    }
}

Describe 'App Installer the latest release has' {
    BeforeEach {
        Remove-Item -LiteralPath (Join-Path $JobPath 'updates.log') -ErrorAction SilentlyContinue
        Mock Write-PreparationState {}
        Mock Get-PreparationWingetRelease { [pscustomobject]@{ tag_name = 'v1.29.380' } }
        Mock Save-PreparationReleaseAsset { throw 'downloading the release' }
        $script:installed = [version]'1.30.310.0'
        $script:client = [version]'1.30.310'
        Mock Get-PreparationAppInstallerVersion { $script:installed }
        Mock Get-PreparationWingetVersion { $script:client }
    }

    It 'downloads nothing when this user has that release or a newer one' {
        Save-PreparationAppInstaller | Should -BeFalse
        Should -Invoke Save-PreparationReleaseAsset -Times 0 -Exactly
        Get-Content (Join-Path $JobPath 'updates.log') -Raw | Should -Match 'this user has App Installer 1\.30\.310\.0 with winget 1\.30\.310, at least the latest stable release v1\.29\.380; not downloading it'
        $script:installed = [version]'1.29.380.0'
        $script:client = [version]'1.29.380'
        Save-PreparationAppInstaller | Should -BeFalse
    }

    It 'downloads the release when <Case>' -TestCases @(
        @{ Case = 'this user''s App Installer is older'; Installed = '1.28.240.0'; Client = '1.28.240' }
        @{ Case = 'this user has no App Installer'; Installed = $null; Client = $null }
        @{ Case = 'its winget reports an older version'; Installed = '1.30.310.0'; Client = '1.15.100' }
        @{ Case = 'its winget reports no version'; Installed = '1.30.310.0'; Client = $null }
    ) {
        param($Case, $Installed, $Client)
        $script:installed = if ($Installed) { [version]$Installed } else { $null }
        $script:client = if ($Client) { [version]$Client } else { $null }
        { Save-PreparationAppInstaller } | Should -Throw '*downloading the release*' -Because $Case
    }

    It 'downloads the release when its tag names no version' {
        Mock Get-PreparationWingetRelease { [pscustomobject]@{ tag_name = 'latest' } }
        { Save-PreparationAppInstaller } | Should -Throw '*downloading the release*'
    }
}

Describe 'How Windows moved, once the record says' {
    BeforeEach {
        Mock Write-PreparationJournal {}
        # The Atlas install's Defender choice uninstalled the package the record lists.
        Mock Get-AtlasInstalledAtlasPackage { @() }
        $script:RebuildFacts = [pscustomobject]@{ WindowsOld = $false; SetupFolder = $false; PantherWritten = $false; AtlasModules = $true }
        Mock Get-AtlasTransitionRebuildFact { $script:RebuildFacts }
        $script:Journal = [pscustomobject]@{
            createdAt = '2026-10-01T00:00:00Z'
            atlasPackages = @('Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~5.0.0.0')
            rebuild = [pscustomobject]@{ rebuilt = $false; signals = @(); checkedAt = '2026-10-02T00:00:00Z' }
        }
    }

    It 'stops again on the components it found gone without a sign of Setup' {
        $script:Journal.rebuild.signals = @('windows-old', 'packages-missing')
        try { Test-PreparationRebuild $script:Journal } catch { $thrown = $_.Exception }
        $thrown.Data['reason'] | Should -BeExactly 'feature-components-lost'
        Get-AtlasTransitionRebuildDecision $script:Journal | Should -BeExactly 'components-lost'
        Should -Invoke Write-PreparationJournal -Times 0 -Exactly
    }
}
