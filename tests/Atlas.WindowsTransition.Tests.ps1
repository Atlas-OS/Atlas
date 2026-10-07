[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter',
    '',
    Justification = 'The machine doubles declare the parameter surface of the commands they stand in for.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidOverwritingBuiltInCmdlets',
    '',
    Justification = 'The registry cmdlets are shadowed so no test can reach the live HKLM policy key.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseSingularNouns',
    '',
    Justification = 'The doubles keep the names of the module commands they stand in for.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments',
    '',
    Justification = 'Worker switches are read by the worker functions through dynamic scope.'
)]
param()

BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:Library = Join-Path $script:AtlasTestScriptsRoot 'Preparation\WindowsTransition.ps1'
    . (Join-Path $script:AtlasTestScriptsRoot 'Preparation\Update-Windows.ps1') -JobPath $TestDrive -FunctionsOnly

    $script:Policy = 'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
    $script:Ux = 'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
    $script:PauseKey = 'SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings'
    $script:Services = 'SYSTEM\CurrentControlSet\Services'
    $script:Record = 'SOFTWARE\AtlasOS\WindowsTransition'

    # An in-memory HKLM: every registry and service access of the library goes
    # through these doubles, which also record each change in order.
    function Reset-Machine {
        $script:Registry = @{}
        $script:Tasks = @{ 'Microsoft\Windows\WindowsUpdate\sih' = 'Enabled'; 'Microsoft\Windows\WindowsUpdate\sihboot' = 'Enabled' }
        $script:Writes = [Collections.Generic.List[string]]::new()
        $script:FailWrite = @{}
        $script:Packages = @('Z-Atlas-NoTelemetry-Package~31bf3856ad364e35~amd64~~5.0.0.0')
        $script:FreeBytes = 40GB
        $script:Health = 'Healthy'
        $script:Windows = [pscustomobject]@{ CurrentBuildNumber = '26100'; UBR = 9550; DisplayVersion = '24H2'; EditionID = 'Professional' }
        $script:BootId = 7
        $script:Copy = $null
        $script:CbsLines = @()
        $script:ToggleRecords = @{}
        $script:RebuildFacts = [pscustomobject]@{ WindowsOld = $false; SetupFolder = $false; PantherWritten = $false; AtlasModules = $true }
        Set-Fake $script:Services\BITS Start DWord 3
        Set-Fake $script:Services\CryptSvc Start DWord 3
        Set-Fake $script:Services\TrustedInstaller Start DWord 3
        Set-Fake $script:Services\wuauserv Start DWord 3
        Set-Fake $script:Services\UsoSvc Start DWord 2
        Set-Fake 'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' BootId DWord 7
        $script:Writes.Clear()
    }
    function Set-Fake([string]$Path, [string]$Name, [string]$Kind, $Data) {
        $script:Registry["$Path|$Name"] = [pscustomobject]@{ Kind = $Kind; Data = $Data }
    }
    function Get-Fake([string]$Path, [string]$Name) { $script:Registry["$Path|$Name"] }
    function Get-AtlasTransitionValue([string]$Path, [string]$Name) {
        $entry = $script:Registry["$Path|$Name"]
        if ($null -eq $entry) { return [pscustomobject]@{ Present = $false; Kind = $null; Data = $null } }
        return [pscustomobject]@{ Present = $true; Kind = $entry.Kind; Data = $entry.Data }
    }
    function Set-AtlasTransitionValue([string]$Path, [string]$Name, [string]$Kind, $Data) {
        $script:Writes.Add("set $Path|$Name")
        if ($script:FailWrite.ContainsKey("$Path|$Name")) { return }
        Set-Fake $Path $Name $Kind $Data
    }
    function Remove-AtlasTransitionValue([string]$Path, [string]$Name) {
        $script:Writes.Add("remove $Path|$Name")
        if ($script:FailWrite.ContainsKey("$Path|$Name")) { return }
        $script:Registry.Remove("$Path|$Name")
    }
    function Test-AtlasTransitionKey([string]$Path) {
        foreach ($key in $script:Registry.Keys) { if ($key.StartsWith("$Path|") -or $key.StartsWith("$Path\")) { return $true } }
        return $false
    }
    function New-AtlasTransitionJournalKey([string]$Path) { }
    function Set-AtlasTransitionServiceStart([string]$Name, [int]$Start) {
        $script:Writes.Add("service $Name $Start")
        Set-Fake "$script:Services\$Name" Start DWord $Start
    }
    function Start-AtlasTransitionService([string]$Name) { $script:Writes.Add("start $Name") }
    function Get-AtlasTransitionTask([string]$Path, [string]$Name) {
        $state = $script:Tasks["$Path\$Name"]
        if ($null -eq $state) { return [pscustomobject]@{ Present = $false; Kind = $null; Data = $null } }
        return [pscustomobject]@{ Present = $true; Kind = 'Task'; Data = $state }
    }
    function Set-AtlasTransitionTask([string]$Path, [string]$Name, [string]$State) {
        $script:Writes.Add("task $Name $State")
        $script:Tasks["$Path\$Name"] = $State
    }
    function Stop-AtlasTransitionService([string]$Name) { $script:Writes.Add("stop $Name") }
    function Get-AtlasInstalledAtlasPackage { $script:Packages }
    function Get-AtlasTransitionCbsLogTail { $script:CbsLines }
    function Write-AtlasTransitionCopy([string]$Json) { $script:Writes.Add('write copy'); $script:Copy = $Json }
    function Read-AtlasTransitionCopy { $script:Copy }
    function Remove-AtlasTransitionCopy { $script:Writes.Add('remove copy'); $script:Copy = $null }
    function Get-AtlasTransitionRebuildFact([DateTime]$Since, [string]$WindowsPath) { $script:RebuildFacts }
    function Get-AtlasTransitionCarry([string[]]$AtlasPackages) { ConvertTo-AtlasTransitionCarry (New-Atlas050Fact) $AtlasPackages }
    function Get-AtlasToggleStateRecords { $script:ToggleRecords.Clone() }
    function Set-AtlasToggleState([string]$Name, [int]$State) { $script:Writes.Add("toggle $Name $State"); $script:ToggleRecords[$Name] = $State }
    # What Atlas 0.5.0 leaves that the record keeps: its markers, the toggle records
    # its choices wrote, Edge and Snipping Tool removed, OneDrive gone.
    function New-Atlas050Fact {
        [pscustomobject]@{
            State = $null; LegacyVersions = @('0.5.0')
            Toggles = @(
                [pscustomobject]@{ name = 'Mitigations'; state = 2 }
                [pscustomobject]@{ name = 'AutomaticUpdates'; state = 0 }
                [pscustomobject]@{ name = 'Hibernation'; state = 0 }
                [pscustomobject]@{ name = 'PowerSaving'; state = 1 }
                [pscustomobject]@{ name = 'FileSharing'; state = 0 }
            )
            Browser = 'Brave'; AtlasModules = $true; Edge = $false; OneDrive = $false; Defender = $false
            Appx = @('Microsoft.WindowsCalculator_8wekyb3d8bbwe', 'Microsoft.Paint_8wekyb3d8bbwe')
            Toolbox = $true; CoreIsolationOff = $true; Browsers = @('browser-brave')
        }
    }
    function Get-AtlasTransitionFreeSpace { $script:FreeBytes }
    function Get-AtlasTransitionImageHealth { if ($script:Health -eq 'Throws') { throw 'DISM is unavailable' }; $script:Health }

    # The pin writer uses the registry cmdlets; HKLM paths go to the double too.
    function ConvertTo-FakePath([string]$Path) { $Path -replace '^HKLM:\\', '' }
    function Test-Path {
        param([string]$LiteralPath, [string]$Path, $PathType)
        $target = if ($LiteralPath) { $LiteralPath } else { $Path }
        if ($target -like 'HKLM:*') { return Test-AtlasTransitionKey (ConvertTo-FakePath $target) }
        Microsoft.PowerShell.Management\Test-Path -LiteralPath $target
    }
    function New-Item {
        param([string]$Path, $ItemType, [switch]$Force)
        if ($Path -notlike 'HKLM:*') { throw "Unexpected New-Item $Path" }
        $script:Writes.Add("create $(ConvertTo-FakePath $Path)")
        Set-Fake (ConvertTo-FakePath $Path) '(key)' 'Key' ''
    }
    function New-ItemProperty {
        param([string]$Path, [string]$Name, $Value, [string]$PropertyType, [switch]$Force)
        if ($Path -notlike 'HKLM:*') { throw "Unexpected New-ItemProperty $Path" }
        Set-AtlasTransitionValue (ConvertTo-FakePath $Path) $Name $PropertyType $Value
    }
    function Get-ItemProperty {
        param([string]$LiteralPath, [string]$Path, $Name, $ErrorAction)
        $target = ConvertTo-FakePath $(if ($LiteralPath) { $LiteralPath } else { $Path })
        if ($target -eq 'SOFTWARE\Microsoft\Windows NT\CurrentVersion') { return $script:Windows }
        $values = [ordered]@{}
        foreach ($key in $script:Registry.Keys) {
            $parts = $key -split '\|', 2
            if ($parts[0] -eq $target -and $parts[1] -ne '(key)') { $values[$parts[1]] = $script:Registry[$key].Data }
        }
        if ($values.Count -eq 0) { return $null }
        return [pscustomobject]$values
    }
    foreach ($double in @('Get-AtlasTransitionValue', 'Set-AtlasTransitionValue', 'Remove-AtlasTransitionValue', 'Set-AtlasTransitionServiceStart', 'Set-AtlasTransitionTask', 'New-ItemProperty', 'Write-AtlasTransitionCopy', 'Remove-AtlasTransitionCopy', 'Set-AtlasToggleState')) {
        if ((Get-Command -Name $double -CommandType Function).ScriptBlock.ToString() -notmatch 'script:(Registry|Writes|Tasks)|Set-AtlasTransitionValue') {
            throw "$double is not the in-memory double; no test may reach the live registry."
        }
    }

    function Read-Journal { (Get-Fake $script:Record 'Journal').Data | ConvertFrom-Json }
    function Get-Item-Value([string]$Path, [string]$Name) { $entry = Get-Fake $Path $Name; if ($entry) { $entry.Data } }

    # Atlas 0.5.0's "Disable Windows Updates": wuauserv stopped and disabled, the
    # sih and sihboot tasks disabled, and its choice recorded.
    function Set-Atlas050UpdatesOff {
        Set-Fake "$script:Services\wuauserv" Start DWord 4
        $script:Tasks['Microsoft\Windows\WindowsUpdate\sih'] = 'Disabled'
        $script:Tasks['Microsoft\Windows\WindowsUpdate\sihboot'] = 'Disabled'
        Set-Fake 'SOFTWARE\AtlasOS\Services\ToggleWindowsUpdates' state DWord 0
        Set-Fake 'SOFTWARE\AtlasOS\Services\ToggleWindowsUpdates' path String 'C:\Windows\AtlasDesktop\3. General Configuration\Windows Updates\Toggle Windows Updates.cmd'
    }

    # Windows Update turned off and paused as Atlas 0.6's own toggles do it, or as
    # a user's tools can, on a PC that still has Atlas 0.5.0's malformed pin.
    function Set-HeldBackUpdate {
        Set-Fake $script:Policy DisableWindowsUpdateAccess DWord 1
        Set-Fake $script:Policy DoNotConnectToWindowsUpdateInternetLocations DWord 1
        Set-Fake "$script:Policy\AU" NoAutoUpdate DWord 1
        Set-Fake "$script:Services\wuauserv" Start DWord 4
        Set-Fake "$script:Services\UsoSvc" Start DWord 4
        Set-Fake "$script:Services\WaaSMedicSvc" Start DWord 4
        $script:Tasks['Microsoft\Windows\WindowsUpdate\sih'] = 'Disabled'
        Set-Fake $script:PauseKey PausedFeatureStatus DWord 1
        Set-Fake $script:PauseKey PausedQualityStatus DWord 1
        Set-Fake $script:Ux PauseUpdatesExpiryTime String '3000-12-31T14:03:37Z'
        Set-Fake $script:Ux PauseFeatureUpdatesStartTime String '2001-10-25T10:03:37Z'
        Set-Fake $script:Ux FlightSettingsMaxPauseDays DWord 356000
        Set-Fake $script:Ux HideMCTLink DWord 1
        Set-Fake $script:Ux RestartNotificationsAllowed2 DWord 0
        Set-Fake 'SYSTEM\Setup\UpgradeNotification' UpgradeAvailable DWord 0
        Set-Fake 'SOFTWARE\AtlasOS\Services\ToggleWindowsUpdates' state DWord 0
        Set-Fake 'SOFTWARE\AtlasOS\Services\PauseUpdates' state DWord 1
        # 0.5.0's malformed pin: a string where Windows expects 1, and no release.
        Set-Fake $script:Policy TargetReleaseVersion String '24H2'
        Set-Fake $script:Policy ProductVersion String 'Windows 11'
        Set-Fake $script:Policy ManagePreviewBuilds DWord 1
    }

    function Use-TransitionRun {
        Set-Variable -Scope 1 -Name WindowsTarget -Value '26H2'
        Set-Variable -Scope 1 -Name TargetBuild -Value 26300
        Set-Variable -Scope 1 -Name SourceBuilds -Value '26100,26200'
        Set-Variable -Scope 1 -Name FeatureKb -Value '5121794,5129195'
        Set-Variable -Scope 1 -Name PrerequisiteKb -Value '5124010'
        Set-Variable -Scope 1 -Name MinimumRevision -Value 9546
        Set-Variable -Scope 1 -Name AcceptLicense -Value ([switch]$true)
    }

    function New-Offer {
        param([string]$Title, [string[]]$Kb = @(), [switch]$Upgrade, [switch]$BrowseOnly, [bool]$Eula = $true, [int]$Type = 1)
        $category = if ($Upgrade) { [pscustomobject]@{ CategoryID = '3689bdc8-b205-4af4-8d4a-a63924c5e9d5'; Name = 'Upgrades' } }
        else { [pscustomobject]@{ CategoryID = '0fa1201d-4330-4fa8-8ae9-b877473b6441'; Name = 'Security Updates' } }
        $offer = [pscustomobject]@{
            Title = $Title; KBArticleIDs = $Kb; Categories = @($category); BrowseOnly = [bool]$BrowseOnly
            IsMandatory = $false; EulaAccepted = $Eula; DeploymentAction = 'Installation'; Type = $Type; MaxDownloadSize = 96GB
            InstallationBehavior = [pscustomobject]@{ RebootBehavior = 1; Impact = 0; CanRequestUserInput = $false }
            Identity = [pscustomobject]@{ UpdateID = [guid]::NewGuid().ToString(); RevisionNumber = 1 }
        }
        $offer | Add-Member ScriptMethod AcceptEula { $this.EulaAccepted = $true; $script:EulaAccepted++ }
        return $offer
    }
    function New-Result([int]$Code = 2, [int]$HResult = 0, [bool]$Restart = $true) {
        $result = [pscustomobject]@{ ResultCode = $Code; HResult = $HResult; RebootRequired = $Restart }
        $result | Add-Member ScriptMethod GetUpdateResult { param($Index) [pscustomobject]@{ ResultCode = $this.ResultCode; HResult = $this.HResult } }
        return $result
    }
    function New-Session {
        $session = [pscustomobject]@{ ClientApplicationID = '' }
        $session | Add-Member ScriptMethod CreateUpdateDownloader { [pscustomobject]@{ Updates = $null } }
        $session | Add-Member ScriptMethod CreateUpdateInstaller {
            $script:Installer = [pscustomobject]@{ Updates = $null; ForceQuiet = $false; AllowSourcePrompts = $true; RebootRequiredBeforeInstallation = $false }
            $script:Installer
        }
        return $session
    }
}

Describe 'Legacy automatic-update record recovery' {
    BeforeEach { Reset-Machine }
    It 'reads the real update policy when a CPU menu launcher overwrote its record' -ForEach @(
        @{ Kind = 'DWord'; Data = 2; Expected = 0 }
        @{ Kind = 'DWord'; Data = 4; Expected = 1 }
        @{ Kind = 'absent'; Data = 0; Expected = 1 }
        @{ Kind = 'String'; Data = '2'; Expected = $null }
        @{ Kind = 'DWord'; Data = 9; Expected = $null }
    ) {
        if ($Kind -ne 'absent') { Set-Fake 'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'AUOptions' $Kind $Data }
        Get-AtlasTransitionAutomaticUpdatesPolicyState | Should -Be $Expected
        $script:Writes.Count | Should -Be 0
    }
}

AfterAll {
    foreach ($shadow in @('Test-Path', 'New-Item', 'New-ItemProperty', 'Get-ItemProperty')) {
        Microsoft.PowerShell.Management\Remove-Item -LiteralPath "Function:\$shadow" -ErrorAction SilentlyContinue
    }
}

Describe 'Windows transition library' {
    It 'leaves PowerShell module resolution and loaded modules as it found them' {
        $probe = Join-Path $TestDrive 'hygiene.ps1'
        [IO.File]::WriteAllText($probe, @'
param([string]$Library)
$env:PSModulePath = 'C:\atlas-sentinel-path'
$before = @(Get-Module).Count
. $Library
[Console]::WriteLine('PATH:' + $env:PSModulePath)
[Console]::WriteLine('MODULES:' + (@(Get-Module).Count - $before))
[Console]::WriteLine('FUNCTIONS:' + @(Get-ChildItem Function:\ | Where-Object Name -like '*AtlasWindowsTransition*').Count)
'@)
        $output = & (Join-Path $PSHOME 'powershell.exe') -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $probe -Library $script:Library
        ($output -join "`n") | Should -Match 'PATH:C:\\atlas-sentinel-path'
        ($output -join "`n") | Should -Match 'MODULES:0'
        ($output -join "`n") | Should -Match 'FUNCTIONS:[1-9]'
    }

    It 'lists exactly the items in the fixture the app also checks' {
        $fixture = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures\windows-transition\items.json') -Raw | ConvertFrom-Json
        $items = @(& { . $script:Library; Get-AtlasWindowsTransitionItem })
        $items.Count | Should -Be @($fixture).Count
        for ($i = 0; $i -lt $items.Count; $i++) {
            $expected = $fixture[$i]
            $items[$i].Id | Should -BeExactly $expected.id
            $items[$i].Group | Should -BeExactly $expected.group
            $items[$i].Path | Should -BeExactly $expected.path
            $items[$i].Name | Should -BeExactly $expected.name
            (@($items[$i].Kinds) -join ',') | Should -BeExactly (@($expected.kinds) -join ',')
            $items[$i].Lift | Should -Be $expected.lift
            $items[$i].Owner | Should -Be $expected.owner
            $items[$i].Rule | Should -BeExactly $expected.rule
        }
    }

    It 'never lists what is not a Windows Update blocker or belongs to the toggle store' {
        $paths = @(Get-AtlasWindowsTransitionItem | ForEach-Object { "$($_.Path)\$($_.Name)" })
        foreach ($forbidden in @('HideMCTLink', 'RestartNotificationsAllowed2', 'UpgradeAvailable', 'WaaSMedicSvc', 'DisableWUfBSafeguards', 'SettingsPageVisibility', 'DeferFeatureUpdates', 'AUOptions', 'AtlasOS')) {
            @($paths | Where-Object { $_ -match [regex]::Escape($forbidden) }) | Should -BeNullOrEmpty -Because "$forbidden must never be lifted"
        }
    }
}

Describe 'Windows Update blockers' {
    BeforeEach { Reset-Machine }

    It 'finds what the update toggles hold back and whether a recorded choice owns it' {
        Set-HeldBackUpdate
        $blockers = @(Get-AtlasWindowsUpdateBlocker)
        $ids = @($blockers.Id)
        foreach ($id in @('policy.DisableWindowsUpdateAccess', 'policy.DoNotConnectToWindowsUpdateInternetLocations', 'policy.AU.NoAutoUpdate',
                'service.wuauserv', 'service.UsoSvc', 'pause.PausedFeatureStatus', 'pause.PausedQualityStatus',
                'pause.PauseUpdatesExpiryTime', 'pause.PauseFeatureUpdatesStartTime', 'pause.FlightSettingsMaxPauseDays')) {
            $ids | Should -Contain $id
        }
        @($blockers | Where-Object { -not $_.OwnerRecord }) | Should -BeNullOrEmpty
    }

    It 'ignores a pause that has ended and settings at their open values' {
        Set-Fake $script:PauseKey PausedFeatureStatus DWord 0
        Set-Fake $script:Ux PauseUpdatesExpiryTime String '2020-01-01T00:00:00Z'
        Set-Fake $script:Ux PauseUpdatesStartTime String '2019-12-01T00:00:00Z'
        Set-Fake $script:Policy DisableWindowsUpdateAccess DWord 0
        Set-Fake "$script:Services\wuauserv" Start DWord 3
        @(Get-AtlasWindowsUpdateBlocker) | Should -BeNullOrEmpty
    }

    It 'counts a 0.5.0 quality-update delay without an owner record' {
        Set-Fake $script:Policy DeferQualityUpdates DWord 1
        Set-Fake $script:Policy DeferQualityUpdatesPeriodInDays DWord 30
        $blockers = @(Get-AtlasWindowsUpdateBlocker)
        @($blockers.Id) | Should -Be @('policy.DeferQualityUpdates', 'policy.DeferQualityUpdatesPeriodInDays')
        @($blockers | Where-Object OwnerRecord) | Should -BeNullOrEmpty
    }
}

Describe 'The record of what Atlas changes' {
    BeforeEach { Reset-Machine; Set-HeldBackUpdate }

    It 'records type and absence, including a string target and a missing release, before changing anything' {
        $journal = Save-AtlasWindowsTransitionSnapshot -Kind transition -Source ([pscustomobject]@{ build = 26100 }) `
            -Target ([pscustomobject]@{ release = '26H2'; build = 26300; kb = '5121794' }) -UserSid 'S-1-5-21-1-2-3-1001' -AtlasPackages $script:Packages
        @($script:Writes) | Should -Be @("set $script:Record|Journal", 'write copy')
        $saved = Read-Journal
        $entry = @($saved.items | Where-Object id -eq 'pin.TargetReleaseVersion')[0]
        $entry.present | Should -BeTrue
        $entry.kind | Should -BeExactly 'String'
        $entry.data | Should -BeExactly '24H2'
        $entry.lifted | Should -BeFalse
        @($saved.items | Where-Object id -eq 'pin.TargetReleaseVersionInfo')[0].present | Should -BeFalse
        @($saved.items | Where-Object id -eq 'service.wuauserv')[0].data | Should -Be 4
        @($saved.items | Where-Object id -eq 'policy.DisableWindowsUpdateAccess')[0].lifted | Should -BeTrue
        $saved.phase | Should -BeExactly 'lifted'
        @($saved.atlasPackages) | Should -Be $script:Packages
        $journal.kind | Should -BeExactly 'transition'
    }

    It 'keeps the first record on a rerun, so lifted values never become the originals' {
        $target = [pscustomobject]@{ release = '26H2'; build = 26300; kb = '5121794' }
        $journal = Save-AtlasWindowsTransitionSnapshot -Kind transition -Source ([pscustomobject]@{ build = 26100 }) -Target $target -UserSid 'S'
        Invoke-AtlasWindowsUpdateLift $journal
        $again = Save-AtlasWindowsTransitionSnapshot -Kind transition -Source ([pscustomobject]@{ build = 26100 }) -Target $target -UserSid 'S'
        @($again.items | Where-Object id -eq 'policy.DisableWindowsUpdateAccess')[0].data | Should -Be 1
        @((Read-Journal).items | Where-Object id -eq 'service.wuauserv')[0].data | Should -Be 4
    }

    It 'adds the pin originals when a plain update''s record becomes a move' {
        $access = Save-AtlasWindowsTransitionSnapshot -Kind access -Source ([pscustomobject]@{ build = 26200 }) -Target $null -UserSid 'S'
        @($access.items | Where-Object id -like 'pin.*') | Should -BeNullOrEmpty
        Invoke-AtlasWindowsUpdateLift $access
        $moved = Save-AtlasWindowsTransitionSnapshot -Kind transition -Source ([pscustomobject]@{ build = 26200 }) `
            -Target ([pscustomobject]@{ release = '26H2'; build = 26300; kb = '5121794' }) -UserSid 'S' -AtlasPackages $script:Packages
        $moved.kind | Should -BeExactly 'transition'
        @($moved.items | Where-Object id -eq 'pin.TargetReleaseVersion')[0].data | Should -BeExactly '24H2'
        @($moved.items | Where-Object id -eq 'policy.DisableWindowsUpdateAccess')[0].data | Should -Be 1 -Because 'the first record''s originals stay'
    }

    It 'records a blocker that appeared after the record with its value then' {
        Reset-Machine
        $journal = Save-AtlasWindowsTransitionSnapshot -Kind access -Source ([pscustomobject]@{ build = 26200 }) -Target $null -UserSid 'S'
        @($journal.items | Where-Object lifted) | Should -BeNullOrEmpty
        # An earlier Atlas's launcher turns Windows Update off again.
        Set-Fake $script:Policy DisableWindowsUpdateAccess DWord 1
        Update-AtlasTransitionLiftSet $journal
        $entry = @((Read-Journal).items | Where-Object id -eq 'policy.DisableWindowsUpdateAccess')[0]
        $entry.lifted | Should -BeTrue
        $entry.data | Should -Be 1
        Invoke-AtlasWindowsUpdateLift (Read-Journal)
        Get-Fake $script:Policy DisableWindowsUpdateAccess | Should -BeNullOrEmpty
    }

    It 'refuses to start a move when a pin value can''t be recorded, before changing anything' {
        Set-Fake $script:Policy TargetReleaseVersionInfo String 'C:\evil'
        $script:Writes.Clear()
        $thrown = $null
        try {
            [void](Save-AtlasWindowsTransitionSnapshot -Kind transition -Source ([pscustomobject]@{ build = 26100 }) `
                -Target ([pscustomobject]@{ release = '26H2'; build = 26300; kb = '5121794' }) -UserSid 'S')
        }
        catch { $thrown = $_.Exception }
        $thrown.Data['reason'] | Should -BeExactly 'feature-pin'
        $thrown.Data['setting'] | Should -BeExactly 'TargetReleaseVersionInfo'
        @($script:Writes) | Should -BeNullOrEmpty
    }

    It 'records a pin written in lower case, as Windows reads it' {
        Set-Fake $script:Policy TargetReleaseVersionInfo String '24h2'
        $journal = Save-AtlasWindowsTransitionSnapshot -Kind transition -Source ([pscustomobject]@{ build = 26100 }) `
            -Target ([pscustomobject]@{ release = '26H2'; build = 26300; kb = '5121794' }) -UserSid 'S'
        @($journal.items | Where-Object id -eq 'pin.TargetReleaseVersionInfo')[0].data | Should -BeExactly '24h2'
    }

    It 'refuses a record missing an item''s flag as not valid, under the worker''s strict mode' {
        $journal = Save-AtlasWindowsTransitionSnapshot -Kind transition -Source ([pscustomobject]@{ build = 26100 }) `
            -Target ([pscustomobject]@{ release = '26H2'; build = 26300; kb = '5121794' }) -UserSid 'S'
        @($journal.items)[0].PSObject.Properties.Remove('lifted')
        Set-StrictMode -Version 3.0
        try { [void](Test-AtlasWindowsTransitionJournal $journal) } catch { $thrown = $_.Exception }
        $thrown.Data['reason'] | Should -BeExactly 'feature-journal'
    }

    It 'refuses a record that names <Case> and changes nothing' -TestCases @(
        @{ Case = 'an unknown item'; Mutate = { param($j) $j.items += [pscustomobject]@{ id = 'policy.Unknown'; present = $true; kind = 'DWord'; data = 1; ownerRecord = $false; lifted = $true } } }
        @{ Case = 'a service start out of range'; Mutate = { param($j) @($j.items | Where-Object id -eq 'service.wuauserv')[0].data = 9 } }
        @{ Case = 'a kind the item cannot have'; Mutate = { param($j) @($j.items | Where-Object id -eq 'policy.DisableWindowsUpdateAccess')[0].kind = 'String' } }
        @{ Case = 'a malformed target'; Mutate = { param($j) @($j.items | Where-Object id -eq 'pin.TargetReleaseVersion')[0].data = 'C:\evil' } }
        @{ Case = 'another schema'; Mutate = { param($j) $j.schema = 2 } }
    ) {
        param($Case, $Mutate)
        $journal = Save-AtlasWindowsTransitionSnapshot -Kind transition -Source ([pscustomobject]@{ build = 26100 }) `
            -Target ([pscustomobject]@{ release = '26H2'; build = 26300; kb = '5121794' }) -UserSid 'S'
        & $Mutate $journal
        Set-Fake $script:Record Journal String ($journal | ConvertTo-Json -Depth 8 -Compress)
        $script:Writes.Clear()
        try { Restore-AtlasWindowsTransition -Outcome Abandoned } catch { $thrown = $_.Exception }
        $thrown.Data['reason'] | Should -BeExactly 'feature-journal'
        @($script:Writes) | Should -BeNullOrEmpty -Because 'the record stays, and nothing is restored from it'
        (Test-AtlasWindowsTransitionOpen).Readable | Should -BeFalse
    }
}

Describe 'Turning Windows Update on' {
    BeforeEach {
        Reset-Machine
        Set-HeldBackUpdate
        $script:Journal = Save-AtlasWindowsTransitionSnapshot -Kind transition -Source ([pscustomobject]@{ build = 26100 }) `
            -Target ([pscustomobject]@{ release = '26H2'; build = 26300; kb = '5121794' }) -UserSid 'S'
        $script:Writes.Clear()
    }

    It 'lifts only the blockers and leaves the rest of Windows Update and the toggle store alone' {
        Invoke-AtlasWindowsUpdateLift $script:Journal
        Get-Fake $script:Policy DisableWindowsUpdateAccess | Should -BeNullOrEmpty
        (Get-Fake "$script:Services\wuauserv" Start).Data | Should -Be 3
        (Get-Fake "$script:Services\UsoSvc" Start).Data | Should -Be 3
        (Get-Fake $script:PauseKey PausedFeatureStatus).Data | Should -Be 0
        Get-Fake $script:Ux PauseUpdatesExpiryTime | Should -BeNullOrEmpty
        (Get-Fake "$script:Services\WaaSMedicSvc" Start).Data | Should -Be 4
        (Get-Fake $script:Ux HideMCTLink).Data | Should -Be 1
        (Get-Fake $script:Ux RestartNotificationsAllowed2).Data | Should -Be 0
        (Get-Fake 'SYSTEM\Setup\UpgradeNotification' UpgradeAvailable).Data | Should -Be 0
        (Get-Fake $script:Policy TargetReleaseVersion).Data | Should -BeExactly '24H2' -Because 'the target changes only when the move starts'
        @($script:Writes | Where-Object { $_ -match 'AtlasOS\\Services' }) | Should -BeNullOrEmpty
    }

    It 'changes nothing when run again' {
        Invoke-AtlasWindowsUpdateLift $script:Journal
        $script:Writes.Clear()
        Invoke-AtlasWindowsUpdateLift $script:Journal
        @($script:Writes | Where-Object { $_ -notlike 'start *' }) | Should -BeNullOrEmpty
    }

    It 'reports a value that does not stay put as set by a policy' {
        $script:FailWrite["$script:Policy|DisableWindowsUpdateAccess"] = $true
        try { Invoke-AtlasWindowsUpdateLift $script:Journal } catch { $thrown = $_.Exception }
        $thrown.Data['reason'] | Should -BeExactly 'feature-policy'
        $thrown.Data['setting'] | Should -BeExactly 'DisableWindowsUpdateAccess'
    }
}

Describe 'What Atlas 0.5.0 gave users' {
    BeforeEach {
        Reset-Machine
        $script:Journal = $null
    }

    It 'turns Windows Update and its tasks back on after "Disable Windows Updates", and nothing else' {
        Set-Atlas050UpdatesOff
        @(Get-AtlasWindowsUpdateBlocker).Id | Should -Be @('service.wuauserv', 'task.sih', 'task.sihboot')
        $journal = Save-AtlasWindowsTransitionSnapshot -Kind transition -Source ([pscustomobject]@{ build = 26100 }) `
            -Target ([pscustomobject]@{ release = '26H2'; build = 26300; kb = '5121794' }) -UserSid 'S'
        $script:Writes.Clear()
        Invoke-AtlasWindowsUpdateLift $journal
        @($script:Writes) | Should -Be @('service wuauserv 3', 'start wuauserv', 'task sih Enabled', 'task sihboot Enabled')
        # Put back before the move: exactly as the launcher left it.
        [void](Restore-AtlasWindowsTransition -Outcome Abandoned)
        (Get-Fake "$script:Services\wuauserv" Start).Data | Should -Be 4
        $script:Tasks['Microsoft\Windows\WindowsUpdate\sih'] | Should -BeExactly 'Disabled'
        $script:Tasks['Microsoft\Windows\WindowsUpdate\sihboot'] | Should -BeExactly 'Disabled'
        (Get-Fake 'SOFTWARE\AtlasOS\Services\ToggleWindowsUpdates' state).Data | Should -Be 0
    }

    It 'leaves the recorded "Disable Windows Updates" to the Atlas install''s replay' {
        Set-Atlas050UpdatesOff
        $journal = Save-AtlasWindowsTransitionSnapshot -Kind transition -Source ([pscustomobject]@{ build = 26100 }) `
            -Target ([pscustomobject]@{ release = '26H2'; build = 26300; kb = '5121794' }) -UserSid 'S'
        Invoke-AtlasWindowsUpdateLift $journal
        $result = Restore-AtlasWindowsTransition -Outcome Installed
        @($result.owned) | Should -Be @('service.wuauserv', 'task.sih', 'task.sihboot')
        @($result.restored) | Should -BeNullOrEmpty
    }

    It 'lifts the quality-update deferral "Set Windows Update Deferral" set and puts it back, leaving the feature deferral the target overrides' {
        Set-Fake $script:Policy DeferFeatureUpdates DWord 1
        Set-Fake $script:Policy DeferFeatureUpdatesPeriodInDays DWord 365
        Set-Fake $script:Policy DeferQualityUpdates DWord 1
        Set-Fake $script:Policy DeferQualityUpdatesPeriodInDays DWord 30
        # The launcher's records went to a misspelt key, which no toggle owns.
        Set-Fake 'SOFTWARE\AtlasOS\ServicesQualityUpdateDeferrals' days DWord 30
        Set-Fake 'SOFTWARE\AtlasOS\ServicesFeatureUpdateDeferrals' days DWord 365
        $journal = Save-AtlasWindowsTransitionSnapshot -Kind transition -Source ([pscustomobject]@{ build = 26100 }) `
            -Target ([pscustomobject]@{ release = '26H2'; build = 26300; kb = '5121794' }) -UserSid 'S'
        $script:Writes.Clear()
        Invoke-AtlasWindowsUpdateLift $journal
        @($script:Writes) | Should -Be @("remove $script:Policy|DeferQualityUpdates", "remove $script:Policy|DeferQualityUpdatesPeriodInDays")
        $result = Restore-AtlasWindowsTransition -Outcome Installed
        (Get-Fake $script:Policy DeferQualityUpdates).Data | Should -Be 1
        (Get-Fake $script:Policy DeferQualityUpdatesPeriodInDays).Data | Should -Be 30
        (Get-Fake $script:Policy DeferFeatureUpdatesPeriodInDays).Data | Should -Be 365
        @($result.restored) | Should -Be @('policy.DeferQualityUpdates', 'policy.DeferQualityUpdatesPeriodInDays')
    }

    It 'leaves the automatic update, notification and driver choices alone: none stops an update Atlas runs' {
        # "Disable Automatic Updates (default)", "Disable Update Notifications" and
        # "Disable Drivers from Windows Update".
        Set-Fake "$script:Policy\AU" AUOptions DWord 2
        Set-Fake $script:Policy SetAutoRestartNotificationDisable DWord 1
        Set-Fake $script:Policy SetUpdateNotificationLevel DWord 2
        Set-Fake $script:Ux RestartNotificationsAllowed2 DWord 0
        Set-Fake $script:Policy ExcludeWUDriversInQualityUpdate DWord 1
        @(Get-AtlasWindowsUpdateBlocker) | Should -BeNullOrEmpty
        $journal = Save-AtlasWindowsTransitionSnapshot -Kind access -Source ([pscustomobject]@{ build = 26200 }) -Target $null -UserSid 'S'
        $script:Writes.Clear()
        Invoke-AtlasWindowsUpdateLift $journal
        @($script:Writes) | Should -BeNullOrEmpty
    }

    It 'keeps the update tasks as they are when Windows Update itself is on' {
        $script:Tasks['Microsoft\Windows\WindowsUpdate\sih'] = 'Disabled'
        @(Get-AtlasWindowsUpdateBlocker) | Should -BeNullOrEmpty
    }

    It 'goes on when a task can''t be turned on: Windows Update doesn''t need it' {
        Set-Atlas050UpdatesOff
        Mock Set-AtlasTransitionTask { throw 'Access is denied.' }
        $journal = Save-AtlasWindowsTransitionSnapshot -Kind transition -Source ([pscustomobject]@{ build = 26100 }) `
            -Target ([pscustomobject]@{ release = '26H2'; build = 26300; kb = '5121794' }) -UserSid 'S'
        { Invoke-AtlasWindowsUpdateLift $journal } | Should -Not -Throw
        (Get-Fake "$script:Services\wuauserv" Start).Data | Should -Be 3
    }
}

Describe 'Atlas 0.5.0 with Windows Update off, paused and delayed' {
    BeforeAll {
        $script:Atlas050 = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures\windows-transition\atlas050-updates-off-paused-delayed.json') -Raw | ConvertFrom-Json
        $script:RealBlocker = (Get-Command Get-AtlasWindowsUpdateBlocker -CommandType Function).ScriptBlock
    }
    BeforeEach {
        Reset-Machine
        $table = @{}
        foreach ($item in Get-AtlasWindowsTransitionItem) { $table[$item.Id] = $item }
        foreach ($property in $script:Atlas050.values.PSObject.Properties) {
            $item = $table[$property.Name]
            if ($property.Value -is [string]) { Set-Fake $item.Path $item.Name String $property.Value }
            else { Set-Fake $item.Path $item.Name DWord ([int64]$property.Value) }
        }
        foreach ($record in $script:Atlas050.toggleRecords.PSObject.Properties) { Set-Fake "SOFTWARE\AtlasOS\Services\$($record.Name)" state DWord ([int64]$record.Value) }
        # The pause dates are read against the fixture's readAt time.
        $script:ReadAt = [DateTime]::Parse($script:Atlas050.readAt, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AdjustToUniversal)
        Mock Get-AtlasWindowsUpdateBlocker { & $script:RealBlocker -Now $script:ReadAt }
        $script:AtlasTransitionEvidencePath = Join-Path $TestDrive 'atlas050-evidence.log'
        Remove-Item -LiteralPath $script:AtlasTransitionEvidencePath -ErrorAction SilentlyContinue
        $script:Journal = Save-AtlasWindowsTransitionSnapshot -Kind access -Source ([pscustomobject]@{ build = 26200 }) -UserSid 'S'
    }

    It 'records the service as it is, off, with the toggle that owns it, and lifts it with the pause and the delay' {
        $entry = @($script:Journal.items | Where-Object id -eq 'service.wuauserv')[0]
        $entry.present | Should -BeTrue
        $entry.data | Should -Be 4
        $entry.lifted | Should -BeTrue
        $entry.ownerRecord | Should -BeTrue
        $lifted = @($script:Journal.items | Where-Object lifted | ForEach-Object id)
        foreach ($id in @('policy.DeferQualityUpdates', 'pause.PausedFeatureStatus', 'pause.PauseUpdatesExpiryTime')) { $lifted | Should -Contain $id }
        @($script:Journal.items | Where-Object id -eq 'service.UsoSvc')[0].lifted | Should -BeFalse
        Get-Content -LiteralPath $script:AtlasTransitionEvidencePath -Raw | Should -Match 'recorded service\.wuauserv: DWord 4 \(will lift\) \(owner record\)'
    }

    It 'leaves the service to the replayed choice after the install and names it' {
        Invoke-AtlasWindowsUpdateLift $script:Journal
        (Get-Fake "$script:Services\wuauserv" Start).Data | Should -Be 3
        $result = Restore-AtlasWindowsTransition -Outcome Installed
        @($result.owned) | Should -Be @('service.wuauserv')
        @($result.restored) | Should -Contain 'pause.PauseUpdatesExpiryTime'
    }

    It 'turns the service off again exactly when the update is stopped' {
        Invoke-AtlasWindowsUpdateLift $script:Journal
        $result = Restore-AtlasWindowsTransition -Outcome Abandoned
        @($result.restored) | Should -Contain 'service.wuauserv'
        (Get-Fake "$script:Services\wuauserv" Start).Data | Should -Be 4
    }

    AfterAll { $script:AtlasTransitionEvidencePath = $null }
}

Describe 'Owners of the lifted settings' {
    It 'only lifts what the owner toggle''s own states write' {
        $toggles = Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Toggles'
        $pause = Import-PowerShellDataFile -LiteralPath (Join-Path $toggles 'General\PauseUpdates.psd1')
        $paused = @(($pause.States | Where-Object Name -eq 'Enable').Registry | ForEach-Object { "$($_.Path -replace '^HKLM:\\', '')\$($_.Name)" })
        @(Get-AtlasWindowsTransitionItem | Where-Object Owner -eq 'PauseUpdates').Count | Should -BeGreaterThan 0
        @(Get-AtlasWindowsTransitionItem | Where-Object Owner -eq 'ToggleWindowsUpdates').Count | Should -BeGreaterThan 0
        foreach ($item in @(Get-AtlasWindowsTransitionItem | Where-Object Owner -eq 'PauseUpdates')) {
            $paused | Should -Contain "$($item.Path)\$($item.Name)"
        }
        $written = [Collections.Generic.List[string]]::new()
        Add-Type -AssemblyName System.ServiceProcess
        & {
            function Set-AtlasRegistryValue { param($Path, $Name, $Type, $Data) $written.Add("$($Path -replace '^HKLM:\\', '')\$Name") }
            function Set-AtlasServiceStartup { param($Name, $StartupType) $written.Add("SYSTEM\CurrentControlSet\Services\$Name\Start") }
            function Get-Service { param($Name) [pscustomobject]@{ Status = [ServiceProcess.ServiceControllerStatus]::Stopped } }
            function Import-AtlasModule { param($Name) }
            function Set-AtlasSettingsPageVisibility { param($Operation, $Page) }
            function Write-AtlasStep { param($Text) }
            . (Join-Path $toggles 'Advanced\ToggleWindowsUpdates.ps1')
            # After the definition file, which has its own: no task may really change.
            function Set-AtlasWindowsUpdateTaskState {
                param($Enabled)
                foreach ($path in Get-AtlasWindowsUpdateTaskPaths) { $written.Add($path) }
            }
            Disable-AtlasWindowsUpdates ([pscustomobject]@{ Silent = $true })
        }
        foreach ($item in @(Get-AtlasWindowsTransitionItem | Where-Object Owner -eq 'ToggleWindowsUpdates')) {
            $written | Should -Contain "$($item.Path)\$($item.Name)"
        }
    }
}

Describe 'The feature-update target' {
    BeforeEach { Reset-Machine; Set-HeldBackUpdate; Set-Fake "$script:Policy\AU" AUOptions DWord 2 }

    It 'replaces a string target with a working one and keeps the values beside it' {
        Set-AtlasFeatureUpdateTarget -Release '26H2'
        $enable = Get-Fake $script:Policy TargetReleaseVersion
        $enable.Kind | Should -BeExactly 'DWord'
        $enable.Data | Should -Be 1
        (Get-Fake $script:Policy ProductVersion).Data | Should -BeExactly 'Windows 11'
        (Get-Fake $script:Policy TargetReleaseVersionInfo).Data | Should -BeExactly '26H2'
        (Get-Fake $script:Policy ManagePreviewBuilds).Data | Should -Be 1
        (Get-Fake "$script:Policy\AU" AUOptions).Data | Should -Be 2
        @($script:Writes | Where-Object { $_ -like 'create *' }) | Should -BeNullOrEmpty -Because 'recreating the key drops the values beside it'
        @($script:Writes | Where-Object { $_ -match 'DisableWUfBSafeguards' }) | Should -BeNullOrEmpty
    }

    It 'creates the policy key only when something deleted it' {
        foreach ($key in @($script:Registry.Keys | Where-Object { $_ -like "$script:Policy|*" -or $_ -like "$script:Policy\*" })) { $script:Registry.Remove($key) }
        Set-AtlasFeatureUpdateTarget -Release '26H2'
        @($script:Writes | Where-Object { $_ -like 'create *' }) | Should -Be @("create $script:Policy")
        (Get-Fake $script:Policy TargetReleaseVersionInfo).Data | Should -BeExactly '26H2'
    }

    It 'fails when Windows does not keep the target' {
        $script:FailWrite["$script:Policy|TargetReleaseVersionInfo"] = $true
        { Set-AtlasFeatureUpdateTarget -Release '26H2' } | Should -Throw '*did not keep*'
    }
}

Describe 'Checks before anything changes' {
    BeforeEach {
        Reset-Machine
        Set-HeldBackUpdate
        Use-TransitionRun
        $script:Writes.Clear()
        Mock Test-PreparationRestart { $false }
        Mock Test-PreparationNetwork { $true }
        Mock Invoke-PreparationWindows { throw 'No update may run after a refused check.' }
        Mock Write-PreparationState {}
    }

    It 'changes nothing without a usable connection, for a move or a plain update' {
        Mock Test-PreparationNetwork { $false }
        { Invoke-PreparationTransition } | Should -Throw -ExceptionType ([System.Net.NetworkInformation.NetworkInformationException])
        { Invoke-PreparationAccess } | Should -Throw -ExceptionType ([System.Net.NetworkInformation.NetworkInformationException])
        @($script:Writes) | Should -BeNullOrEmpty
    }

    It 'stops for <Case> with <Reason> and writes nothing' -TestCases @(
        @{ Case = 'an organisation''s update server'; Reason = 'feature-managed'; Arrange = { Set-Fake "$script:Policy\AU" UseWUServer DWord 1 } }
        @{ Case = 'a disabled BITS'; Reason = 'feature-blocked'; Arrange = { Set-Fake "$script:Services\BITS" Start DWord 4 } }
        @{ Case = 'too little free space'; Reason = 'feature-disk-space'; Arrange = { $script:FreeBytes = 2GB } }
        @{ Case = 'a component store Windows can no longer repair'; Reason = 'feature-servicing'; Arrange = { $script:Health = 'NonRepairable' } }
        @{ Case = 'a Windows build that is neither source nor target'; Reason = 'feature-build'; Arrange = { $script:Windows.CurrentBuildNumber = '22631' } }
    ) {
        param($Case, $Reason, $Arrange)
        & $Arrange
        try { Invoke-PreparationTransition } catch { $thrown = $_.Exception }
        $thrown.Data['reason'] | Should -BeExactly $Reason
        @($script:Writes) | Should -BeNullOrEmpty
    }

    It 'checks before moving Windows after plain updates left their record open' {
        [void](Save-AtlasWindowsTransitionSnapshot -Kind access -Source ([pscustomobject]@{ build = 26100 }) -Target $null -UserSid 'S')
        $script:FreeBytes = 2GB
        $script:Writes.Clear()
        try { Invoke-PreparationTransition } catch { $thrown = $_.Exception }
        $thrown.Data['reason'] | Should -BeExactly 'feature-disk-space'
        @($script:Writes) | Should -BeNullOrEmpty -Because 'the record isn''t turned into a move and nothing is retargeted'
    }

    It 'names the service and the space it found' {
        Set-Fake "$script:Services\CryptSvc" Start DWord 4
        try { Invoke-PreparationTransition } catch { $blocked = Get-PreparationFailureDetail $_.Exception }
        $blocked.setting | Should -BeExactly 'CryptSvc'
        Set-Fake "$script:Services\CryptSvc" Start DWord 3
        $script:FreeBytes = 3GB
        try { Invoke-PreparationTransition } catch { $space = Get-PreparationFailureDetail $_.Exception }
        $space.freeGb | Should -Be '3'
        $space.neededGb | Should -Be '6'
        $space.drive | Should -Match '^[A-Z]:$'
    }

    It 'asks for a pending restart before recording anything' {
        Mock Test-PreparationRestart { $true }
        Invoke-PreparationTransition | Should -Be 'reboot'
        @($script:Writes) | Should -BeNullOrEmpty
    }

    It 'goes on with a store Windows <Case>' -TestCases @(
        @{ Case = 'can repair'; Health = 'Repairable' }
        @{ Case = 'could not check'; Health = 'Throws' }
    ) {
        param($Case, $Health)
        $script:Health = $Health
        { Invoke-PreparationTransition } | Should -Throw '*No update may run*'
        Get-Fake $script:Record Journal | Should -Not -BeNullOrEmpty
    }
}

Describe 'A component store that reads as repairable' {
    BeforeAll {
        $script:AppInvLog = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures\windows-transition\cbs-appinv-baseline.txt'))
    }
    BeforeEach {
        Reset-Machine
        $script:Health = 'Repairable'
        $script:AtlasTransitionEvidencePath = Join-Path $TestDrive 'store-evidence.log'
        Remove-Item -LiteralPath $script:AtlasTransitionEvidencePath -ErrorAction SilentlyContinue
    }

    It 'reads the newest store check from the servicing log' {
        $finding = Get-AtlasTransitionStoreFinding $script:AppInvLog
        $finding.Total | Should -Be 2
        @($finding.Items.Path) | Should -Be @(
            'amd64_microsoft-windows-a..n-experience-appinv_31bf3856ad364e35_10.0.26100.1591_none_b8a08e9482a41bbe\aeinvext.dll'
            'amd64_microsoft-windows-a..n-experience-appinv_31bf3856ad364e35_10.0.26100.1591_none_b8a08e9482a41bbe\Microsoft.Management.Deployment.winmd')
        $finding.Counts['CSI Payload Corruption'] | Should -Be 2
        $finding.Counts['CBS Manifest Corruption'] | Should -Be 0
    }

    It 'goes on and records <Case>' -TestCases @(
        @{ Case = 'the AppInv files the NoTelemetry package leaves after a store cleanup'; Label = 'the known Atlas package pattern'; Change = { $script:CbsLines = $script:AppInvLog } }
        @{ Case = 'the files a repair leaves instead'; Label = 'other'; Change = {
                $script:CbsLines = $script:AppInvLog -replace 'n-experience-appinv_31bf3856ad364e35_10\.0\.26100\.1591_none_b8a08e9482a41bbe\\aeinvext\.dll', 'entory-data-sources_31bf3856ad364e35_10.0.26100.1591_none_0\r\devinv.dll' } }
        @{ Case = 'a manifest corruption beside it'; Label = 'other'; Change = { $script:CbsLines = $script:AppInvLog -replace 'CSI Manifest Corruption:\t0', "CSI Manifest Corruption:`t1" } }
        @{ Case = 'the same files without the NoTelemetry package'; Label = 'other'; Change = { $script:CbsLines = $script:AppInvLog; $script:Packages = @() } }
        @{ Case = 'no store check in the servicing log'; Label = 'other'; Change = { $script:CbsLines = @('2026-10-01 21:44:29, Info CBS Exec: nothing') } }
    ) {
        param($Case, $Label, $Change)
        & $Change
        { Test-AtlasWindowsTransitionPreflight } | Should -Not -Throw -Because $Case
        $evidence = Get-Content -LiteralPath $script:AtlasTransitionEvidencePath -Raw
        $evidence | Should -Match ([regex]::Escape("component store is repairable ($Label)"))
        $evidence | Should -Match 'going on'
    }

    It 'lists the corrupt items the servicing log names' {
        $script:CbsLines = $script:AppInvLog
        Test-AtlasWindowsTransitionPreflight
        Get-Content -LiteralPath $script:AtlasTransitionEvidencePath -Raw | Should -Match 'CSI Payload Corrupt amd64_microsoft-windows-a\.\.n-experience-appinv_.*\\aeinvext\.dll; CSI Payload Corrupt .*Microsoft\.Management\.Deployment\.winmd'
    }

    It 'stops for a store Windows can no longer repair' {
        $script:CbsLines = $script:AppInvLog
        $script:Health = 'NonRepairable'
        try { Test-AtlasWindowsTransitionPreflight } catch { $thrown = $_.Exception }
        $thrown.Data['reason'] | Should -BeExactly 'feature-servicing'
    }

    It 'goes on and logs the error when the store check cannot run' {
        $script:Health = 'Throws'
        { Test-AtlasWindowsTransitionPreflight } | Should -Not -Throw
        Get-Content -LiteralPath $script:AtlasTransitionEvidencePath -Raw | Should -Match 'component store health could not be read \(0x[0-9A-F]{8}\): DISM is unavailable; going on'
    }
}

Describe 'Moving Windows' {
    BeforeEach {
        Reset-Machine
        Set-HeldBackUpdate
        Use-TransitionRun
        $script:EulaAccepted = 0
        $script:Offers = @{ default = @(); optional = @(); hidden = @() }
        $script:Collections = @()
        Mock Test-PreparationRestart { $false }
        Mock Test-PreparationNetwork { $true }
        Mock Write-PreparationState {}
        Mock Assert-PreparationContinue {}
        Mock Invoke-PreparationWindows { 'complete' }
        Mock Invoke-PreparationUpdates { 'complete' }
        Mock Restart-PreparationUpdateService { $false }
        Mock Get-PreparationFeatureHistory {}
        Mock Get-PreparationHardwareGap {}
        Mock Invoke-PreparationCommitCall {}
        Mock Add-PreparationWindowsUpdate { throw 'The move never goes through the quality-pass installer.' }
        Mock New-Object -ParameterFilter { $ComObject -eq 'Microsoft.Update.Session' } { New-Session }
        Mock New-Object -ParameterFilter { $ComObject -eq 'Microsoft.Update.UpdateColl' } {
            $collection = [pscustomobject]@{ Count = 0; Items = [Collections.ArrayList]::new() }
            $collection | Add-Member ScriptMethod Add { param($Update) [void]$this.Items.Add($Update); $this.Count++ }
            $script:Collections += $collection
            $collection
        }
        Mock Invoke-PreparationSearch {
            if ($Criteria -match 'IsHidden=1') { return $script:Offers.hidden }
            if ($Criteria -match 'OptionalInstallation') { return $script:Offers.optional }
            return $script:Offers.default
        }
        $script:Download = New-Result
        $script:Install = New-Result
        Mock Invoke-PreparationWindowsOperation { if ($Kind -eq 'Download') { $script:Download } else { $script:Install } }
        # Fake time: every wait only adds to the clock.
        $script:PreparationPolicyWaitSeconds = 120
        $script:PreparationTargetReread = $false
        $script:PreparationServiceRestarts = 0
        $script:Waited = 0
        Mock Wait-PreparationSeconds { $script:Waited += $Seconds }
        $script:AtlasTransitionEvidencePath = Join-Path $TestDrive 'evidence.log'
        Remove-Item -LiteralPath $script:AtlasTransitionEvidencePath -ErrorAction SilentlyContinue
    }

    It 'records first, lifts, brings monthly updates current, then retargets and installs only the package, alone' {
        $script:Offers.default = @(
            (New-Offer 'Windows 11, version 25H2' @('5054156') -Upgrade)
            (New-Offer 'Windows 11, version 26H2' @() -Upgrade)
            (New-Offer 'Feature update to Windows 11, version 26H2' @('5121794') -Upgrade -Eula $false)
        )
        Invoke-PreparationTransition | Should -Be 'reboot'
        $script:PreparationRestartReasons | Should -Be @('feature-update')
        $script:Writes[0] | Should -BeExactly "set $script:Record|Journal" -Because 'the originals are recorded before the first change'
        $retarget = $script:Writes.IndexOf("set $script:Policy|TargetReleaseVersionInfo")
        $retarget | Should -BeGreaterThan $script:Writes.IndexOf("remove $script:Policy|DisableWindowsUpdateAccess")
        Should -Invoke Invoke-PreparationWindows -Times 1 -Exactly
        $script:Collections[-1].Count | Should -Be 1
        $script:Collections[-1].Items[0].KBArticleIDs | Should -Be @('5121794')
        $script:EulaAccepted | Should -Be 1
        $script:Installer.ForceQuiet | Should -BeTrue
        $script:Installer.AllowSourcePrompts | Should -BeFalse
        (Read-Journal).phase | Should -BeExactly 'installed'
        Should -Invoke Invoke-PreparationCommitCall -Times 0 -Exactly -Because 'Atlas commits only just before its own restart'
        $evidence = Get-Content -LiteralPath $script:AtlasTransitionEvidencePath -Raw
        $evidence | Should -Match "unexpected-offer, not installed: 'Windows 11, version 25H2' KB=5054156"
        $evidence | Should -Match 'lifted policy.DisableWindowsUpdateAccess: DWord 1 -> absent'
    }

    It 'takes the one upgrade naming the target release when Windows Update offers it under a new KB' {
        $script:Offers.default = @(
            (New-Offer 'Windows 11, version 25H2' @('5054156') -Upgrade)
            (New-Offer 'Windows 11, version 26H2' @('5139999') -Upgrade -Eula $false)
        )
        Invoke-PreparationTransition | Should -Be 'reboot'
        $script:Collections[-1].Count | Should -Be 1
        $script:Collections[-1].Items[0].KBArticleIDs | Should -Be @('5139999')
        $journal = Read-Journal
        $journal.offer.kb | Should -BeExactly '5139999'
        $journal.offer.updateId | Should -BeExactly $script:Offers.default[1].Identity.UpdateID
        $journal.offer.title | Should -BeExactly 'Windows 11, version 26H2'
        $evidence = Get-Content -LiteralPath $script:AtlasTransitionEvidencePath -Raw
        $evidence | Should -Match "offer, chosen by the release 26H2 in its title: 'Windows 11, version 26H2' KB=5139999 id=\S+ rev 1"
        $evidence | Should -Match "unexpected-offer, not installed: 'Windows 11, version 25H2'"
    }

    It 'chooses none of several unknown upgrades naming the target, and installs nothing' {
        $script:Offers.default = @(
            (New-Offer 'Windows 11, version 26H2' @('5139998') -Upgrade)
            (New-Offer 'Windows 11, version 26H2 (repair)' @('5139999') -Upgrade)
        )
        try { Invoke-PreparationTransition } catch { $thrown = $_.Exception }
        $thrown.Data['reason'] | Should -BeExactly 'feature-failed'
        Should -Invoke Invoke-PreparationWindowsOperation -Times 0 -Exactly
    }

    It 'never takes an upgrade to another release' {
        $script:Offers.default = @(New-Offer 'Windows 11, version 25H2' @('5054156') -Upgrade)
        try { Invoke-PreparationTransition } catch { $thrown = $_.Exception }
        $thrown.Data['reason'] | Should -BeExactly 'feature-not-offered'
        Should -Invoke Invoke-PreparationWindowsOperation -Times 0 -Exactly
    }

    It 'restarts for an update whose install leaves work for the restart, whatever its result code' {
        $script:Offers.default = @(New-Offer 'Windows 11, version 26H2' @('5129195') -Upgrade)
        $script:Install = New-Result 3 0 $true
        Invoke-PreparationTransition | Should -Be 'reboot'
        $script:PreparationRestartReasons | Should -Be @('feature-update')
        (Read-Journal).phase | Should -BeExactly 'installed'
    }

    It 'restarts Windows Update to read the new target before it searches' {
        $script:Offers.default = @(New-Offer 'Windows 11, version 26H2' @('5129195') -Upgrade)
        $script:Restarts = 0
        Mock Restart-PreparationUpdateService {
            $script:Restarts++
            Set-Fake 'SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\PolicyState' TargetReleaseVersion String '26H2'
            $true
        }
        Invoke-PreparationTransition | Should -Be 'reboot'
        $script:Restarts | Should -Be 1
        $evidence = Get-Content -LiteralPath $script:AtlasTransitionEvidencePath -Raw
        $evidence | Should -Match "policy state before the search: target ''"
        $evidence | Should -Match "restarted wuauserv, policy state now: target '26H2'"
    }

    It 'searches again after a restart when the first search ran on the old policy' {
        # Busy finishing the monthly updates, Windows Update answers the first
        # search on the old policy and only takes the new target with it.
        $script:Restarts = 0
        Mock Restart-PreparationUpdateService { $script:Restarts++; $script:Restarts -gt 1 }
        $script:DefaultSearches = 0
        $script:Offer = New-Offer 'Windows 11, version 26H2' @('5129195') -Upgrade
        Mock Invoke-PreparationSearch {
            if ($Criteria -match 'IsHidden=1|OptionalInstallation') { return @() }
            $script:DefaultSearches++
            Set-Fake 'SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\PolicyState' TargetReleaseVersion String '26H2'
            if ($script:DefaultSearches -ge 2) { return @($script:Offer) }
            @()
        }
        Invoke-PreparationTransition | Should -Be 'reboot'
        $script:Restarts | Should -Be 2
        $script:DefaultSearches | Should -Be 2
        $script:Collections[-1].Items[0].KBArticleIDs | Should -Be @('5129195')
        Get-Content -LiteralPath $script:AtlasTransitionEvidencePath -Raw | Should -Match 'no offer on the first search; restarted wuauserv'
    }

    It 'restarts once and keeps searching for 10 minutes when the target is read but nothing is offered, then says so' {
        Set-Fake 'SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\PolicyState' TargetReleaseVersion String '26H2'
        $script:Restarts = 0
        Mock Restart-PreparationUpdateService { $script:Restarts++; $true }
        try { Invoke-PreparationTransition } catch { $thrown = $_.Exception }
        $thrown.Data['reason'] | Should -BeExactly 'feature-not-offered'
        $script:Restarts | Should -Be 1
        $script:Waited | Should -Be 600
        # The first search, then after 30, 60, 90 and every 120 seconds up to 600.
        Should -Invoke Invoke-PreparationSearch -Times 8 -Exactly -ParameterFilter { $Criteria -notmatch 'OptionalInstallation|IsHidden=1' }
        Get-Content -LiteralPath $script:AtlasTransitionEvidencePath -Raw | Should -Match 'no offer within 600 s'
    }

    It 'installs the offer that appears on the third search after the wait starts' {
        Set-Fake 'SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\PolicyState' TargetReleaseVersion String '26H2'
        Mock Restart-PreparationUpdateService { $true }
        $script:DefaultSearches = 0
        $script:Offer = New-Offer 'Windows 11, version 26H2' @('5129195') -Upgrade
        Mock Invoke-PreparationSearch {
            if ($Criteria -match 'IsHidden=1|OptionalInstallation') { return @() }
            $script:DefaultSearches++
            if ($script:DefaultSearches -eq 4) { return @($script:Offer) }
            @()
        }
        Invoke-PreparationTransition | Should -Be 'reboot'
        $script:Waited | Should -Be 180 -Because 'it stops at the first offer, after 30, 60 and 90 seconds'
        $script:Collections[-1].Items[0].KBArticleIDs | Should -Be @('5129195')
    }

    It 'restarts Windows Update at most twice in a run, however long it waits' {
        $script:Restarts = 0
        Mock Restart-PreparationUpdateService { $script:Restarts++; $true }
        # The policy state never shows the target and nothing is ever offered;
        # the first search is refused once, so the run looks a second time.
        $script:refusals = 0
        Mock Find-PreparationFeatureOffer {
            $script:refusals++
            if ($script:refusals -eq 1) { throw ([Runtime.InteropServices.COMException]::new('policy', -2145124305)) }
        }
        try { Invoke-PreparationTransition } catch { $thrown = $_.Exception }
        $thrown.Data['reason'] | Should -BeExactly 'feature-not-offered'
        $script:Restarts | Should -Be 2
        $log = Get-Content -LiteralPath $script:AtlasTransitionEvidencePath -Raw
        $log | Should -Match 'not the target after 120 seconds'
        $log | Should -Match 'already restarted 2 times in this run'
    }

    It 'reports the wait as one while it waits, and stops when the user stops' {
        Set-Fake 'SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\PolicyState' TargetReleaseVersion String '26H2'
        Mock Restart-PreparationUpdateService { $true }
        Mock Wait-PreparationSeconds {
            $script:WaitDetail = $script:PreparationSearchDetail.Clone()
            throw (New-Object OperationCanceledException 'Preparation stopped after the current operation.')
        }
        { Invoke-PreparationTransition } | Should -Throw -ExceptionType ([OperationCanceledException])
        $script:WaitDetail.waiting | Should -BeExactly 'feature-offer'
        $script:PreparationSearchDetail.Count | Should -Be 0 -Because 'later searches are not the wait'
    }

    It 'rechecks only the offer once the target is set, and installs nothing else again' {
        Set-Fake 'SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\PolicyState' TargetReleaseVersion String '26H2'
        $journal = Save-AtlasWindowsTransitionSnapshot -Kind transition -Source ([pscustomobject]@{ build = 26100 }) `
            -Target ([pscustomobject]@{ release = '26H2'; build = 26300; kb = '5121794,5129195' }) -UserSid 'S'
        $journal.phase = 'targeted'
        Write-AtlasWindowsTransition $journal
        Mock Invoke-PreparationWindows { throw 'A recheck never runs the monthly updates again.' }
        $script:Restarts = 0
        Mock Restart-PreparationUpdateService { $script:Restarts++; $true }
        Set-Variable -Name OfferOnly -Value ([switch]$true)
        try { Invoke-PreparationTransition } catch { $thrown = $_.Exception }
        $thrown.Data['reason'] | Should -BeExactly 'feature-not-offered'
        $script:Restarts | Should -Be 0
        $script:Waited | Should -Be 0 -Because 'the app waits between rechecks, not the worker'
        Should -Invoke Invoke-PreparationWindows -Times 0 -Exactly
        $script:Offers.default = @(New-Offer 'Windows 11, version 26H2' @('5129195') -Upgrade)
        $script:PreparationTargetReread = $false
        Invoke-PreparationTransition | Should -Be 'reboot'
        $script:Collections[-1].Items[0].KBArticleIDs | Should -Be @('5129195')
        Should -Invoke Invoke-PreparationWindows -Times 0 -Exactly
    }

    It 'keeps the target unset while the monthly updates ask for a restart' {
        Mock Invoke-PreparationWindows { 'reboot' }
        Invoke-PreparationTransition | Should -Be 'reboot'
        (Get-Fake $script:Policy TargetReleaseVersion).Data | Should -BeExactly '24H2'
        (Read-Journal).phase | Should -BeExactly 'lifted'
    }

    It 'never accepts the licence terms without the user''s acceptance' {
        Set-Variable -Name AcceptLicense -Value ([switch]$false)
        $script:Offers.default = @(New-Offer 'Feature update' @('5121794') -Upgrade -Eula $false)
        try { Invoke-PreparationTransition } catch { $thrown = $_.Exception }
        $thrown.Data['reason'] | Should -BeExactly 'feature-terms'
        $script:EulaAccepted | Should -Be 0
        Should -Invoke Invoke-PreparationWindowsOperation -Times 0 -Exactly
    }

    It 'asks for an optional offer when the plain search finds nothing' {
        $script:Offers.optional = @(New-Offer 'Feature update' @('5121794') -Upgrade)
        Invoke-PreparationTransition | Should -Be 'reboot'
        Should -Invoke Invoke-PreparationSearch -ParameterFilter { $Criteria -match "DeploymentAction='OptionalInstallation'" -and $Criteria -match 'CategoryIDs' }
    }

    It 'treats a client that cannot search for optional offers as no offer' {
        Mock Invoke-PreparationSearch {
            if ($Criteria -match 'OptionalInstallation') { throw ([Runtime.InteropServices.COMException]::new('invalid criteria', -2145124302)) }
            @()
        }
        try { Invoke-PreparationTransition } catch { $thrown = $_.Exception }
        $thrown.Data['reason'] | Should -BeExactly 'feature-not-offered'
    }

    It 'tells <Reason> apart when nothing is offered' -TestCases @(
        @{ Reason = 'feature-hidden'; Arrange = { $script:Offers.hidden = @(New-Offer 'Feature update' @('5121794') -Upgrade) } }
        @{ Reason = 'feature-prerequisite'; Arrange = { $script:Windows.UBR = 9278 } }
        @{ Reason = 'feature-hardware'; Arrange = { Mock Get-PreparationHardwareGap { 'tpm'; 'uefi' } } }
        @{ Reason = 'feature-not-offered'; Arrange = { } }
    ) {
        param($Reason, $Arrange)
        & $Arrange
        try { Invoke-PreparationTransition } catch { $detail = Get-PreparationFailureDetail $_.Exception }
        $detail.reason | Should -BeExactly $Reason
        if ($Reason -eq 'feature-hardware') { $detail.hardware | Should -BeExactly 'tpm,uefi' }
        (Get-Fake $script:Policy TargetReleaseVersionInfo).Data | Should -BeExactly '26H2' -Because 'a PC that waits for the offer keeps asking for it'
    }

    It 'treats a package Windows installed on its own as installed' {
        Mock Get-PreparationFeatureHistory { [pscustomobject]@{ Date = [DateTime]::UtcNow.AddMinutes(5); ResultCode = 2; HResult = 0; Title = 'KB5121794' } }
        Invoke-PreparationTransition | Should -Be 'reboot'
        $script:PreparationRestartReasons | Should -Be @('feature-update')
        (Read-Journal).phase | Should -BeExactly 'installed'
    }

    It 'turns Windows Update on again when the search is refused by policy, once' {
        $script:Offers.default = @(New-Offer 'Feature update' @('5121794') -Upgrade)
        $script:refusals = 0
        Mock Find-PreparationFeatureUpdate {
            $script:refusals++
            if ($script:refusals -eq 1) { throw ([Runtime.InteropServices.COMException]::new('policy', -2145124305)) }
            [pscustomobject]@{ Update = $script:Offers.default[0]; Hidden = $false }
        }
        Mock Invoke-AtlasWindowsUpdateLift {}
        Invoke-PreparationTransition | Should -Be 'reboot'
        Should -Invoke Invoke-AtlasWindowsUpdateLift -Times 2 -Exactly
        Mock Find-PreparationFeatureUpdate { throw ([Runtime.InteropServices.COMException]::new('policy', -2145124305)) }
        Reset-Machine
        Set-HeldBackUpdate
        try { Invoke-PreparationTransition } catch { $detail = Get-PreparationFailureDetail $_.Exception }
        $detail.reason | Should -BeExactly 'feature-blocked'
        $detail.errorCode | Should -BeExactly '0x8024002F'
    }

    It 'looks for a hidden package among superseded updates too' {
        { Invoke-PreparationTransition } | Should -Throw '*does not offer*'
        Should -Invoke Invoke-PreparationSearch -ParameterFilter { $Criteria -match 'IsHidden=1' -and $IncludeSuperseded }
    }

    It 'retries a failed install once after a fresh search, then reports Windows''s code' {
        $script:Offers.default = @(New-Offer 'Feature update' @('5121794') -Upgrade)
        $script:Install = New-Result 4 -2145116149 $false
        try { Invoke-PreparationTransition } catch { $detail = Get-PreparationFailureDetail $_.Exception }
        $detail.reason | Should -BeExactly 'feature-failed'
        $detail.errorCode | Should -BeExactly '0x8024200B'
        Should -Invoke Invoke-PreparationWindowsOperation -Times 2 -Exactly -ParameterFilter { $Kind -eq 'Install' }
        (Read-Journal).phase | Should -BeExactly 'targeted'
    }

    It 'turns Windows Update on again once when it was turned off mid-install, then names what blocks it' {
        $script:Offers.default = @(New-Offer 'Feature update' @('5121794') -Upgrade)
        $script:Install = New-Result 4 -2145124306 $false
        Mock Invoke-AtlasWindowsUpdateLift {}
        Mock Get-AtlasWindowsUpdateBlocker { [pscustomobject]@{ Id = 'policy.DisableWindowsUpdateAccess' } }
        try { Invoke-PreparationTransition } catch { $detail = Get-PreparationFailureDetail $_.Exception }
        Should -Invoke Invoke-AtlasWindowsUpdateLift -Times 2 -Exactly
        $detail.reason | Should -BeExactly 'feature-blocked'
        $detail.setting | Should -BeExactly 'DisableWindowsUpdateAccess'
        $detail.errorCode | Should -BeExactly '0x8024002E'
    }
}

Describe 'The record of updates Windows offers again after they installed' {
    BeforeEach {
        Reset-Machine
        Mock Get-PreparationInstalledVersion { 'Microsoft.SecHealthUI 1000.26100.9168.0' }
    }

    It 'keeps each update once, reads back what it wrote, and lets old entries lapse' {
        $update = New-Offer 'Update for Windows Security platform - KB5007651 (Version 10.0.29628.1000)' @('5007651')
        Add-PreparationReoffered $update
        Add-PreparationReoffered $update
        $entries = @(Read-PreparationReoffered)
        $entries.Count | Should -Be 1
        $entries[0].key | Should -BeExactly "$($update.Identity.UpdateID)/1"
        (Get-PreparationReofferedKey).Contains("$($update.Identity.UpdateID)/1") | Should -BeTrue
        (Get-Fake 'SOFTWARE\AtlasOS\Preparation' Reoffered).Kind | Should -BeExactly 'String'
        $stale = @([pscustomobject]@{ key = 'old/1'; at = [DateTime]::UtcNow.AddDays(-40).ToString('o') }) + $entries
        Set-Fake 'SOFTWARE\AtlasOS\Preparation' Reoffered String (ConvertTo-Json -InputObject $stale -Compress)
        @(Read-PreparationReoffered).key | Should -Be @("$($update.Identity.UpdateID)/1")
        Set-Fake 'SOFTWARE\AtlasOS\Preparation' Reoffered String '{not json'
        @(Read-PreparationReoffered) | Should -BeNullOrEmpty
    }
}

Describe 'The update service a search asks' {
    BeforeEach {
        Reset-Machine
        Mock Write-PreparationState {}
        $script:AtlasTransitionEvidencePath = Join-Path $TestDrive 'search-evidence.log'
        Remove-Item -LiteralPath $script:AtlasTransitionEvidencePath -ErrorAction SilentlyContinue
        $script:Searcher = [pscustomobject]@{ Online = $false; ServerSelection = 0; ServiceID = '00000000-0000-0000-0000-000000000000'; IncludePotentiallySupersededUpdates = $false }
        $script:Searcher | Add-Member ScriptMethod BeginSearch {
            param($Criteria, $Callback, $State)
            $job = [pscustomobject]@{ IsCompleted = $true }
            $job | Add-Member ScriptMethod CleanUp {}
            $job
        }
        $script:Searcher | Add-Member ScriptMethod EndSearch { param($Job) [pscustomobject]@{ ResultCode = 2; Updates = @() } }
        $script:SearchSession = [pscustomobject]@{}
        $script:SearchSession | Add-Member ScriptMethod CreateUpdateSearcher { $script:Searcher }
    }

    It 'asks the Windows Update service itself, online' {
        @(Invoke-PreparationSearch $script:SearchSession "IsInstalled=0 and Type='Software'") | Should -BeNullOrEmpty
        $script:Searcher.ServerSelection | Should -Be 2
        $script:Searcher.Online | Should -BeTrue
        Get-Content -LiteralPath $script:AtlasTransitionEvidencePath -Raw | Should -Match "search on ServerSelection=2 \(Windows Update\): result 2, 0 update\(s\) for IsInstalled=0 and Type='Software'"
    }

    It 'leaves a PC whose updates come from its organisation''s server on that server' {
        Set-Fake 'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' UseWUServer DWord 1
        [void](Invoke-PreparationSearch $script:SearchSession 'IsInstalled=0')
        $script:Searcher.ServerSelection | Should -Be 0
    }

    It 'names the service a search asks, never a ServiceID that means nothing there' {
        Format-PreparationService ([pscustomobject]@{ ServerSelection = 2; ServiceID = '00000000-0000-0000-0000-000000000000' }) | Should -BeExactly 'ServerSelection=2 (Windows Update)'
        Format-PreparationService ([pscustomobject]@{ ServerSelection = 0; ServiceID = '00000000-0000-0000-0000-000000000000' }) | Should -BeExactly 'ServerSelection=0 (the default service)'
        Format-PreparationService ([pscustomobject]@{ ServerSelection = 3; ServiceID = '855e8a7c-ecb4-4ca3-b045-1dfa50104289' }) | Should -BeExactly 'ServerSelection=3 (service 855e8a7c-ecb4-4ca3-b045-1dfa50104289)'
    }

    It 'records no offer yet and a missing prerequisite as outcomes, and anything else as a failure' {
        Get-PreparationEndStep @{ reason = 'feature-not-offered' } | Should -Be 'outcome'
        Get-PreparationEndStep @{ reason = 'feature-prerequisite' } | Should -Be 'outcome'
        Get-PreparationEndStep @{ reason = 'feature-hardware' } | Should -Be 'failed'
        Get-PreparationEndStep @{ failureMessage = 'Windows update search failed: 4' } | Should -Be 'failed'
    }

    It 'logs no offer yet as one outcome line and keeps the error record and stack trace for a failure' {
        $stop = {
            param($Reason)
            try { throw (New-AtlasTransitionFailure 'Windows Update does not offer 26H2 to this PC yet.' $Reason) }
            catch { return $_ }
        }
        $record = & $stop 'feature-not-offered'
        $text = Format-PreparationStop $record (Get-PreparationFailureDetail $record.Exception)
        $text | Should -BeExactly 'Outcome (feature-not-offered): Windows Update does not offer 26H2 to this PC yet.'

        $record = & $stop 'feature-failed'
        $text = Format-PreparationStop $record (Get-PreparationFailureDetail $record.Exception)
        $text | Should -Match 'Windows Update does not offer 26H2'
        $text | Should -Match 'At .+:\d+ char:\d+'
    }

    It 'keeps one history entry, with a count and the first and last times, for repeated no-offer outcomes' {
        $journal = [pscustomobject]@{ history = @([pscustomobject]@{ at = '2026-10-02T09:00:00Z'; event = 'targeted'; detail = '' }) }
        $detail = 'reason=feature-not-offered code= Windows Update does not offer 26H2 to this PC yet.'
        foreach ($recheck in 1..11) { Add-AtlasTransitionHistory $journal 'outcome' $detail }
        @($journal.history).Count | Should -Be 2
        $journal.history[-1].count | Should -Be 11
        $journal.history[-1].lastAt | Should -Not -BeNullOrEmpty
        # A different outcome, or a failure, starts a new entry.
        Add-AtlasTransitionHistory $journal 'failed' 'reason=feature-hardware code= TPM'
        Add-AtlasTransitionHistory $journal 'outcome' $detail
        @($journal.history).Count | Should -Be 4
        $journal.history[-1].PSObject.Properties['count'] | Should -BeNullOrEmpty
        # The record stays small.
        foreach ($step in 1..50) { Add-AtlasTransitionHistory $journal "step-$step" '' }
        @($journal.history).Count | Should -Be 40
    }
}

Describe 'Optional prerequisites' {
    BeforeEach {
        Reset-Machine
        Use-TransitionRun
        $script:Windows.UBR = 9550
        $script:Optional = @(
            (New-Offer '2026-09 Cumulative Update Preview for Windows 11 Version 24H2 for x64-based Systems (KB5124010) (26100.9600)' @('5124010'))
            (New-Offer '2026-10 Cumulative Update Preview for Windows 11 Version 24H2 for x64-based Systems (KB5130001) (26100.9700)' @('5130001'))
            (New-Offer '2026-09 Cumulative Update Preview for .NET Framework 3.5 and 4.8.1 (KB5199999)' @('5199999'))
            (New-Offer 'An older cumulative update (KB5100000) (26100.9000)' @('5100000'))
            (New-Offer 'Windows 11, version 26H2' @('5124010') -Upgrade)
            (New-Offer 'Intel - System - 1.2.3.4' @() -Type 2)
        )
        foreach ($offer in $script:Optional) { $offer.DeploymentAction = 'OptionalInstallation' }
        Mock Invoke-PreparationSearch {
            if ($Criteria -match "DeploymentAction='OptionalInstallation'") { return $script:Optional }
            throw "Unexpected search $Criteria"
        }
    }

    It 'takes the cumulative update the move needs, or a newer one for this build, and no other optional update' {
        $found = @(Find-PreparationPrerequisiteUpdate (New-Session))
        @($found.KBArticleIDs) | Should -Be @('5124010', '5130001')
        Should -Invoke Invoke-PreparationSearch -Times 1 -Exactly -ParameterFilter { $Criteria -eq "IsInstalled=0 and IsHidden=0 and Type='Software' and DeploymentAction='OptionalInstallation'" }
    }

    It 'falls back to browse-only updates on a client that cannot ask for optional ones' {
        Mock Invoke-PreparationSearch {
            if ($Criteria -match 'OptionalInstallation') { throw ([Runtime.InteropServices.COMException]::new('invalid criteria', -2145124302)) }
            if ($Criteria -match 'BrowseOnly=1') { return @($script:Optional[0]) }
            throw "Unexpected search $Criteria"
        }
        @(Find-PreparationPrerequisiteUpdate (New-Session)).KBArticleIDs | Should -Be @('5124010')
    }

    It 'takes nothing once Windows has moved, or outside a move' {
        $script:Windows.CurrentBuildNumber = '26300'
        @(Find-PreparationPrerequisiteUpdate (New-Session)) | Should -BeNullOrEmpty
        $script:Windows.CurrentBuildNumber = '26100'
        Set-Variable -Name WindowsTarget -Value ''
        @(Find-PreparationPrerequisiteUpdate (New-Session)) | Should -BeNullOrEmpty
        Should -Invoke Invoke-PreparationSearch -Times 0 -Exactly
    }
}

Describe 'The new version in Windows Update history' {
    BeforeEach { Use-TransitionRun }

    It 'is the update Atlas installed, or one named for the release, never a monthly update sharing its KB' {
        $id = 'ba6eafb7-6fd3-4fb9-8462-3d86b81835b3'
        Test-PreparationFeatureHistoryEntry 'Windows 11, version 26H2' '' '' | Should -BeTrue
        Test-PreparationFeatureHistoryEntry 'Feature update to Windows 11, version 26H2 (KB5121794)' 'other' $id | Should -BeTrue
        Test-PreparationFeatureHistoryEntry 'Update with no release in its title' $id $id | Should -BeTrue
        Test-PreparationFeatureHistoryEntry '2026-09 Security Update (KB5129195) (26200.9457)' 'monthly' $id | Should -BeFalse
        Test-PreparationFeatureHistoryEntry 'Windows 11, version 25H2' 'other' $id | Should -BeFalse
    }
}

Describe 'Restarting into the new version' {
    BeforeEach {
        Reset-Machine
        Set-HeldBackUpdate
        Use-TransitionRun
        Mock Test-PreparationRestart { $false }
        Mock Write-PreparationState {}
        Mock Invoke-PreparationUpdates { 'complete' }
        Mock Invoke-PreparationCommitCall { $script:Commits++ }
        Mock Get-PreparationFeatureHistory { [pscustomobject]@{ Date = [DateTime]::UtcNow; ResultCode = 4; HResult = -2145116149; Title = 'KB5121794' } }
        $script:Commits = 0
        $journal = Save-AtlasWindowsTransitionSnapshot -Kind transition -Source ([pscustomobject]@{ build = 26100 }) `
            -Target ([pscustomobject]@{ release = '26H2'; build = 26300; kb = '5121794' }) -UserSid 'S' -AtlasPackages $script:Packages
        Set-PreparationInstalled $journal 'update=fixture'
    }

    It 'commits once per boot, only when asked, and records the boot' {
        Invoke-PreparationCommit
        Invoke-PreparationCommit
        $script:Commits | Should -Be 1
        (Read-Journal).commitBoot | Should -BeExactly 'boot:7'
        Set-Fake 'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' BootId DWord 8
        Invoke-PreparationCommit
        $script:Commits | Should -Be 2
    }

    It 'commits the update it installed, and restarts anyway when the commit fails' {
        $journal = Read-Journal
        $update = New-Offer 'Windows 11, version 26H2' @('5129195') -Upgrade
        Set-PreparationInstalled $journal 'update=offer' $update
        Mock Invoke-PreparationCommitCall { throw ([Runtime.InteropServices.COMException]::new('not initialised', -2145124348)) }
        { Invoke-PreparationCommit } | Should -Not -Throw
        Should -Invoke Invoke-PreparationCommitCall -Times 1 -Exactly -ParameterFilter { $UpdateId -eq $update.Identity.UpdateID }
        $after = Read-Journal
        $after.commitBoot | Should -BeExactly 'boot:7'
        $after.history[-1].detail | Should -Match 'commit failed 0x80240004.*restarting anyway'
    }

    It 'waits for the restart while still in the boot that installed it' {
        Invoke-PreparationTransition | Should -Be 'reboot'
        $script:PreparationRestartReasons | Should -Be @('feature-update')
        (Read-Journal).commitRetried | Should -BeFalse
    }

    It 'asks for one more restart after a restart without Atlas''s commit, then reports the rollback' {
        Set-Fake 'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' BootId DWord 8
        Invoke-PreparationTransition | Should -Be 'reboot'
        $script:PreparationRestartReasons | Should -Be @('feature-commit')
        Set-Fake 'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' BootId DWord 9
        try { Invoke-PreparationTransition } catch { $detail = Get-PreparationFailureDetail $_.Exception }
        $detail.reason | Should -BeExactly 'feature-rolled-back'
        $detail.errorCode | Should -BeExactly '0x8024200B'
    }

    It 'reports a rollback at once after a restart Atlas committed' {
        Invoke-PreparationCommit
        Set-Fake 'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' BootId DWord 8
        try { Invoke-PreparationTransition } catch { $thrown = $_.Exception }
        $thrown.Data['reason'] | Should -BeExactly 'feature-rolled-back'
    }

    It 'finishes the updates on the new version when the Atlas components are all there' {
        $script:Windows.CurrentBuildNumber = '26300'
        $script:Windows.DisplayVersion = '26H2'
        Invoke-PreparationTransition | Should -Be 'complete'
        (Read-Journal).phase | Should -BeExactly 'on-target'
        Should -Invoke Invoke-PreparationUpdates -Times 1 -Exactly
    }

    It 'stops when the Atlas components are gone with no sign that Setup ran' {
        $script:Windows.CurrentBuildNumber = '26300'
        $script:Packages = @()
        try { Invoke-PreparationTransition } catch { $thrown = $_.Exception }
        $thrown.Data['reason'] | Should -BeExactly 'feature-components-lost'
        Should -Invoke Invoke-PreparationUpdates -Times 0 -Exactly
        (Read-Journal).rebuild.rebuilt | Should -BeFalse
    }

    It 'records that Windows switched on in place and finishes the updates' {
        $script:Windows.CurrentBuildNumber = '26300'
        Invoke-PreparationTransition | Should -Be 'complete'
        $journal = Read-Journal
        $journal.rebuild.rebuilt | Should -BeFalse
        @($journal.rebuild.signals) | Should -BeNullOrEmpty
        $journal.history[-2].event | Should -BeExactly 'moved'
        $journal.history[-2].detail | Should -Match 'switched on in place'
        Get-AtlasWindowsTransitionRebase | Should -BeNullOrEmpty
    }

    It 'records a rebuild by Setup, keeps going, and gives the Atlas install the recorded version and choices' {
        $script:Windows.CurrentBuildNumber = '26300'
        $journal = Read-Journal
        $journal | Add-Member -NotePropertyName carry -NotePropertyValue (ConvertTo-AtlasTransitionCarry (New-Atlas050Fact) $script:Packages) -Force
        Write-AtlasWindowsTransition $journal
        $script:Packages = @()
        $script:RebuildFacts = [pscustomobject]@{ WindowsOld = $true; SetupFolder = $true; PantherWritten = $true; AtlasModules = $false }
        Invoke-PreparationTransition | Should -Be 'complete'
        $after = Read-Journal
        $after.rebuild.rebuilt | Should -BeTrue
        @($after.rebuild.signals) | Should -Be @('windows-old', 'setup-folder', 'setup-log', 'packages-missing', 'atlas-files-missing')
        Should -Invoke Invoke-PreparationUpdates -Times 1 -Exactly
        $rebase = Get-AtlasWindowsTransitionRebase
        $rebase.AtlasVersion | Should -BeExactly '0.5.0'
        @($rebase.Options) | Should -Contain 'mitigations-default'
    }
}

Describe 'Putting the settings back' {
    BeforeEach {
        Reset-Machine
        Set-HeldBackUpdate
        Set-Fake $script:Policy DeferQualityUpdates DWord 1
        Set-Fake $script:Policy DeferQualityUpdatesPeriodInDays DWord 30
        $journal = Save-AtlasWindowsTransitionSnapshot -Kind transition -Source ([pscustomobject]@{ build = 26100 }) `
            -Target ([pscustomobject]@{ release = '26H2'; build = 26300; kb = '5121794' }) -UserSid 'S'
        Invoke-AtlasWindowsUpdateLift $journal
        Set-AtlasFeatureUpdateTarget -Release '26H2'
        $script:Writes.Clear()
    }

    It 'puts back everything, the malformed target included, when Windows did not move' {
        $result = Restore-AtlasWindowsTransition -Outcome Abandoned
        (Get-Fake $script:Policy DisableWindowsUpdateAccess).Data | Should -Be 1
        (Get-Fake "$script:Services\wuauserv" Start).Data | Should -Be 4
        (Get-Fake $script:Ux PauseUpdatesExpiryTime).Data | Should -BeExactly '3000-12-31T14:03:37Z'
        (Get-Fake $script:Policy DeferQualityUpdatesPeriodInDays).Data | Should -Be 30
        $pin = Get-Fake $script:Policy TargetReleaseVersion
        $pin.Kind | Should -BeExactly 'String'
        $pin.Data | Should -BeExactly '24H2'
        Get-Fake $script:Policy TargetReleaseVersionInfo | Should -BeNullOrEmpty
        $result.pin | Should -BeExactly 'restored'
    }

    It 'keeps the new target after Windows moved' {
        $result = Restore-AtlasWindowsTransition -Outcome Moved
        (Get-Fake $script:Policy TargetReleaseVersionInfo).Data | Should -BeExactly '26H2'
        (Get-Fake $script:Policy TargetReleaseVersion).Kind | Should -BeExactly 'DWord'
        (Get-Fake $script:Policy DisableWindowsUpdateAccess).Data | Should -Be 1
        $result.pin | Should -BeExactly 'kept'
    }

    It 'leaves what the install''s replay owns and restores what nothing owns' {
        $result = Restore-AtlasWindowsTransition -Outcome Installed
        Get-Fake $script:Policy DisableWindowsUpdateAccess | Should -BeNullOrEmpty -Because 'the replayed toggle decides it'
        (Get-Fake "$script:Services\wuauserv" Start).Data | Should -Be 3
        (Get-Fake $script:Policy DeferQualityUpdates).Data | Should -Be 1 -Because 'no toggle owns the 0.5.0 delay'
        @($result.owned) | Should -Contain 'service.wuauserv'
        @($result.restored) | Should -Contain 'policy.DeferQualityUpdates'
    }

    It 'puts back what a toggle owned when the install cleared its recorded state' {
        # The key stays, with its path, after the replay clears a state it no longer uses.
        Remove-AtlasTransitionValue 'SOFTWARE\AtlasOS\Services\ToggleWindowsUpdates' 'state'
        $result = Restore-AtlasWindowsTransition -Outcome Installed
        (Get-Fake "$script:Services\wuauserv" Start).Data | Should -Be 4
        @($result.restored) | Should -Contain 'service.wuauserv'
        @($result.owned) | Should -Not -Contain 'service.wuauserv'
    }

    It 'leaves a value someone changed after Atlas lifted it' {
        Set-Fake "$script:Services\wuauserv" Start DWord 2
        $result = Restore-AtlasWindowsTransition -Outcome Abandoned
        (Get-Fake "$script:Services\wuauserv" Start).Data | Should -Be 2
        @($result.changed) | Should -Contain 'service.wuauserv'
    }

    # The app reads these fixtures; the worker must accept each record and write
    # results with the same fields, so neither side drifts from them.
    It 'accepts the records and writes the result the app''s fixtures show' {
        $fixtures = Join-Path $PSScriptRoot 'fixtures\windows-transition'
        foreach ($name in @('journal-access.json', 'journal-transition.json', 'journal-rebuilt.json')) {
            $record = Get-Content -LiteralPath (Join-Path $fixtures $name) -Raw | ConvertFrom-Json
            Test-AtlasWindowsTransitionJournal $record | Should -BeTrue -Because $name
        }
        $expected = @((Get-Content -LiteralPath (Join-Path $fixtures 'last-result.json') -Raw | ConvertFrom-Json).PSObject.Properties.Name)
        $result = Restore-AtlasWindowsTransition -Outcome Abandoned
        @($result.PSObject.Properties.Name) | Should -Be $expected
    }

    It 'puts back what it can when one setting fails, keeps the record open, and only retries that one' {
        $script:FailService = $true
        Mock Set-AtlasTransitionServiceStart {
            if ($script:FailService -and $Name -eq 'wuauserv') { throw 'Access is denied' }
            Set-Fake "$script:Services\$Name" Start DWord $Start
        }
        $failure = $null
        try { [void](Restore-AtlasWindowsTransition -Outcome Abandoned) } catch { $failure = $_.Exception }
        $failure.Data['reason'] | Should -BeExactly 'feature-restore'
        $failure.Data['setting'] | Should -BeExactly 'service.wuauserv'
        (Get-Fake $script:Policy DeferQualityUpdatesPeriodInDays).Data | Should -Be 30 -Because 'the others went back'
        (Get-Fake "$script:Services\wuauserv" Start).Data | Should -Be 3
        $open = Read-AtlasWindowsTransition
        @($open.items | Where-Object lifted | ForEach-Object id) | Should -Be @('service.wuauserv')

        $script:FailService = $false
        $result = Restore-AtlasWindowsTransition -Outcome Abandoned
        (Get-Fake "$script:Services\wuauserv" Start).Data | Should -Be 4
        @($result.restored) | Should -Be @('service.wuauserv')
        @($result.changed) | Should -BeNullOrEmpty -Because 'what went back the first time is not taken for a change'
        Read-AtlasWindowsTransition | Should -BeNullOrEmpty
    }

    It 'closes the record last, keeps the result, and does nothing a second time' {
        [void](Restore-AtlasWindowsTransition -Outcome Abandoned)
        $script:Writes[-2] | Should -BeExactly "remove $script:Record|Journal"
        $script:Writes[-1] | Should -BeExactly "set $script:Record|LastResult"
        $last = (Get-Fake $script:Record LastResult).Data | ConvertFrom-Json
        $last.outcome | Should -BeExactly 'Abandoned'
        @($last.history.event) | Should -Contain 'restore'
        $script:Writes.Clear()
        Restore-AtlasWindowsTransition -Outcome Abandoned | Should -BeNullOrEmpty
        @($script:Writes) | Should -BeNullOrEmpty
    }

    It 'keeps the new target when put back before the owed restart' {
        Use-TransitionRun
        $journal = Read-Journal
        Set-PreparationInstalled $journal 'update=fixture'
        Mock Write-PreparationState {}
        $saved = $env:WINDIR
        try {
            $env:WINDIR = $TestDrive
            Invoke-PreparationRestore
        }
        finally { $env:WINDIR = $saved }
        (Get-Fake $script:Policy TargetReleaseVersionInfo).Data | Should -BeExactly '26H2'
        ((Get-Fake $script:Record LastResult).Data | ConvertFrom-Json).outcome | Should -BeExactly 'Moved'
    }

    It 'refuses while an Atlas install is unfinished' {
        $saved = $env:WINDIR
        try {
            $env:WINDIR = $TestDrive
            [void][IO.Directory]::CreateDirectory((Join-Path $TestDrive 'AtlasOS\Install'))
            [IO.File]::WriteAllText((Join-Path $TestDrive 'AtlasOS\Install\active.json'), '{}')
            try { Invoke-PreparationRestore } catch { $thrown = $_.Exception }
        }
        finally {
            $env:WINDIR = $saved
            Remove-Item -LiteralPath (Join-Path $TestDrive 'AtlasOS') -Recurse -Force
        }
        $thrown.Data['reason'] | Should -BeExactly 'feature-install-active'
        @($script:Writes) | Should -BeNullOrEmpty
    }

    It 'leaves the record of a Windows that rebuilt itself to the install that puts Atlas back' {
        $journal = Read-Journal
        $journal | Add-Member -NotePropertyName carry -NotePropertyValue ([pscustomobject]@{
                atlasVersion = '0.5.0'; options = @('defender-disable'); optionSource = 'observed'; toggles = @(); browser = $null
                atlasModules = $true; edge = $false; oneDrive = $false; defender = $false; appx = @('Microsoft.Paint_8wekyb3d8bbwe') }) -Force
        $journal | Add-Member -NotePropertyName rebuild -NotePropertyValue ([pscustomobject]@{ rebuilt = $true; signals = @('windows-old'); checkedAt = '2026-10-02T00:00:00Z' }) -Force
        Write-AtlasWindowsTransition $journal
        $script:Writes.Clear()
        $saved = $env:WINDIR
        try {
            $env:WINDIR = $TestDrive
            try { Invoke-PreparationRestore } catch { $thrown = $_.Exception }
        }
        finally { $env:WINDIR = $saved }
        $thrown.Data['reason'] | Should -BeExactly 'feature-install-active'
        @($script:Writes) | Should -BeNullOrEmpty
        Get-AtlasWindowsTransitionRebase | Should -Not -BeNullOrEmpty
    }

    It 'is the install''s closing step, which reports what it left' {
        $lines = @(Complete-AtlasWindowsTransition)
        ($lines -join "`n") | Should -Match 'Left as the replayed choices set them: .*service\.wuauserv'
        Get-Fake $script:Record Journal | Should -BeNullOrEmpty
        Complete-AtlasWindowsTransition | Should -Match 'nothing to put back'
    }
}

Describe 'Install and toggle guards while Windows Update is turned on' {
    BeforeAll {
        $ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $script:AtlasTestScriptsRoot 'Entry\Install-Atlas.ps1'), [ref]$null, [ref]$null)
        $guard = $ast.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Test-AtlasWindowsUpdateInProgress' }, $true)
        . ([scriptblock]::Create($guard.Extent.Text))
    }
    BeforeEach { Reset-Machine; Set-HeldBackUpdate }

    It 'blocks the install while Windows has not reached the target' {
        [void](Save-AtlasWindowsTransitionSnapshot -Kind transition -Source ([pscustomobject]@{ build = 26100 }) `
                -Target ([pscustomobject]@{ release = '26H2'; build = 26300; kb = '5121794' }) -UserSid 'S')
        $result = Test-AtlasWindowsUpdateInProgress -WindowsBuild 26100
        $result.Passed | Should -BeFalse
        $result.Blocking | Should -BeTrue
        $unchecked = Test-AtlasWindowsUpdateInProgress -WindowsBuild 26300
        $unchecked.Passed | Should -BeFalse -Because 'how Windows moved decides the install mode'
        $unchecked.Detail | Should -Match 'not checked how Windows moved'

        $journal = Read-AtlasWindowsTransition
        $journal | Add-Member -NotePropertyName rebuild -NotePropertyValue ([pscustomobject]@{ rebuilt = $false; signals = @('windows-old'); checkedAt = '2026-10-02T00:00:00Z' }) -Force
        Write-AtlasWindowsTransition $journal
        # The install itself changes the Atlas packages, so only the recorded decision counts.
        Mock Get-AtlasInstalledAtlasPackage { @() }
        (Test-AtlasWindowsUpdateInProgress -WindowsBuild 26300).Passed | Should -BeTrue
        $journal.rebuild.signals = @('packages-missing')
        Write-AtlasWindowsTransition $journal
        $lost = Test-AtlasWindowsUpdateInProgress -WindowsBuild 26300
        $lost.Passed | Should -BeFalse
        $lost.Detail | Should -Match 'Atlas packages are gone'
    }

    It 'allows a plain update''s record and blocks an unreadable one' {
        [void](Save-AtlasWindowsTransitionSnapshot -Kind access -Source ([pscustomobject]@{ build = 26200 }) -Target $null -UserSid 'S')
        (Test-AtlasWindowsUpdateInProgress -WindowsBuild 26200).Passed | Should -BeTrue
        Set-Fake $script:Record Journal String '{not json'
        $unreadable = Test-AtlasWindowsUpdateInProgress -WindowsBuild 26200
        $unreadable.Passed | Should -BeFalse
        $unreadable.Detail | Should -Match 'cannot be read'
        Reset-Machine
        (Test-AtlasWindowsUpdateInProgress -WindowsBuild 26200).Passed | Should -BeTrue
    }

    It 'refuses the Windows Update and pause toggles by hand while the record is open, and only those' {
        { Assert-AtlasToggleAllowedDuringTransition -Name ToggleWindowsUpdates } | Should -Not -Throw
        [void](Save-AtlasWindowsTransitionSnapshot -Kind access -Source ([pscustomobject]@{ build = 26200 }) -Target $null -UserSid 'S')
        { Assert-AtlasToggleAllowedDuringTransition -Name ToggleWindowsUpdates } | Should -Throw '*Atlas Manager is updating Windows*'
        { Assert-AtlasToggleAllowedDuringTransition -Name PauseUpdates } | Should -Throw '*Atlas Manager is updating Windows*'
        { Assert-AtlasToggleAllowedDuringTransition -Name AutomaticUpdates } | Should -Not -Throw
    }
}

Describe 'The install''s closing step' {
    BeforeAll {
        . (Join-Path $script:AtlasTestScriptsRoot 'Install\Install-Plan.ps1')
        . (Join-Path $script:AtlasTestScriptsRoot 'Entry\Invoke-AtlasInstall.ps1')
    }

    It 'runs once in <Mode> (OOBE <Oobe>), after the choices are replayed and the pin is written' -TestCases @(
        @{ Mode = 'Fresh'; Oobe = $false }, @{ Mode = 'Fresh'; Oobe = $true }
        @{ Mode = 'Upgrade'; Oobe = $false }, @{ Mode = 'Upgrade'; Oobe = $true }
        @{ Mode = 'Reapply'; Oobe = $false }, @{ Mode = 'Reapply'; Oobe = $true }
    ) {
        param($Mode, $Oobe)
        $plan = @(Get-AtlasInstallPlan -Mode $Mode -IsOobe $Oobe)
        $keys = @($plan.Key)
        $index = [array]::IndexOf($keys, 'Checkpoint/WindowsTransition')
        $index | Should -BeGreaterThan ([array]::IndexOf($keys, 'Defaults'))
        if ($keys -contains 'Tweaks/qol') { $index | Should -BeGreaterThan ([array]::IndexOf($keys, 'Tweaks/qol')) }
        ($plan | Where-Object Key -eq 'Checkpoint/WindowsTransition').Replay | Should -BeExactly 'Once'
    }

    It 'maps to the task that closes the record' {
        $action = Get-AtlasInstallCheckpointAction -Target WindowsTransition -ScriptsRoot $script:AtlasTestScriptsRoot -SourceScriptsRoot $TestDrive
        $action.Path | Should -BeExactly (Join-Path $script:AtlasTestScriptsRoot 'Install\Tasks\Complete-AtlasWindowsTransition.ps1')
        [IO.File]::Exists($action.Path) | Should -BeTrue
    }
}

Describe 'Disk cleanup while a move may need undoing' {
    BeforeAll {
        $previousErrorActionPreference = $ErrorActionPreference
        try { . (Join-Path $script:AtlasTestScriptsRoot 'Install\Tasks\Invoke-DiskCleanup.ps1') -Scope CurrentUser -ExpectedUserSid 'not-a-sid' }
        catch { if ($_.Exception.Message -notlike '*is invalid*') { throw } }
        finally { $ErrorActionPreference = $previousErrorActionPreference }
    }

    It 'keeps setup logs, driver packages and restore points' {
        $script:Flags = @{}
        Mock Get-Process {}
        Mock Test-Path { $true }
        Mock Set-ItemProperty { $script:Flags[(Split-Path -Leaf $LiteralPath)] = $Value }
        Mock Start-Process {}
        Mock Test-AtlasOtherWindowsInstall { $false }
        Mock Invoke-AtlasTempCleanup {}
        Mock Invoke-AtlasSystemShadowCopyCleanup {}
        $tools = Join-Path $TestDrive 'tools'
        [void][IO.Directory]::CreateDirectory($tools)
        foreach ($name in 'cleanmgr.exe', 'vssadmin.exe') { [IO.File]::WriteAllText((Join-Path $tools $name), '') }
        Invoke-AtlasMachineCleanup -SystemRoot $TestDrive -WindowsRoot $TestDrive -CleanMgrPath (Join-Path $tools 'cleanmgr.exe') `
            -VssAdminPath (Join-Path $tools 'vssadmin.exe') -KeepRecovery
        $script:Flags['Setup Log Files'] | Should -Be 0
        $script:Flags['Device Driver Packages'] | Should -Be 0
        $script:Flags['Temporary Sync Files'] | Should -Be 2
        Should -Invoke Invoke-AtlasSystemShadowCopyCleanup -Times 0 -Exactly
    }
}

Describe 'Staging the update worker' {
    BeforeAll { . (Join-Path $script:AtlasTestRepoRoot 'app\resources\prepare\Stage-App.ps1') -FunctionsOnly }

    It 'stages the libraries beside the worker with the same protected permissions' {
        # Unelevated, the folders and files get this user's ownership instead.
        Mock New-AtlasRecoveryDirectory {
            param($Path)
            [void][IO.Directory]::CreateDirectory($Path)
            return [IO.Path]::GetFullPath($Path)
        }
        Mock Get-AtlasRecoveryFileSecurity {
            $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
            $security = New-Object Security.AccessControl.FileSecurity
            $security.SetSecurityDescriptorSddlForm("O:${sid}D:P(A;;FA;;;${sid})")
            return $security
        }
        $root = Join-Path $TestDrive 'Recovery'
        $directory = New-AtlasPreparationJob $root ('c' * 64) '123-456' '# worker' ([byte[]](1)) '# library' '# registry'
        [IO.File]::ReadAllText((Join-Path $directory 'WindowsTransition.ps1')) | Should -BeExactly '# library'
        [IO.File]::ReadAllText((Join-Path $directory 'RegistryFile.ps1')) | Should -BeExactly '# registry'
        Assert-AtlasRecoveryFileSecurity (Join-Path $directory 'WindowsTransition.ps1')
        Assert-AtlasRecoveryFileSecurity (Join-Path $directory 'RegistryFile.ps1')
    }
}

Describe 'What the record keeps of the Atlas install' {
    BeforeEach { Reset-Machine }

    It 'reads an Atlas 0.5.0 install''s choices from what they left, and leaves out what nothing shows' {
        $carry = ConvertTo-AtlasTransitionCarry (New-Atlas050Fact) @('Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~5.0.0.0')
        $carry.atlasVersion | Should -BeExactly '0.5.0'
        $carry.optionSource | Should -BeExactly 'observed'
        @($carry.options) | Should -Be @('defender-disable', 'mitigations-default', 'auto-updates-disable', 'disable-hibernation', 'uninstall-edge', 'remove-snipping-tool',
            'disable-core-isolation', 'install-toolbox', 'install-another-browser', 'browser-brave')
        $carry.browser | Should -BeExactly 'Brave'
        @($carry.toggles).Count | Should -Be 5
        $carry.oneDrive | Should -BeFalse
        Test-AtlasTransitionCarry $carry | Should -BeTrue
    }

    It 'keeps Defender and Edge when they were there, and asks again when no record shows a choice' {
        $facts = New-Atlas050Fact
        $facts.Edge = $true
        $facts.Toggles = @()
        $facts.Appx = @('Microsoft.ScreenSketch_8wekyb3d8bbwe')
        $facts.Toolbox = $false
        $facts.CoreIsolationOff = $false
        $facts.Browser = $null
        $carry = ConvertTo-AtlasTransitionCarry $facts @('Z-Atlas-NoTelemetry-Package~31bf3856ad364e35~amd64~~5.0.0.0')
        @($carry.options) | Should -Be @('defender-enable')
    }

    It 'finds OneDrive another account installed, not only the one running Atlas' {
        $list = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
        Set-Fake "$list\S-1-5-21-1-1001" ProfileImagePath ExpandString 'C:\Users\Alex'
        Set-Fake "$list\S-1-5-21-1-1002" ProfileImagePath ExpandString 'C:\Users\Sam'
        Mock Get-AtlasTransitionProfileSid { @('S-1-5-21-1-1001', 'S-1-5-21-1-1002') }
        $script:Present = @('C:\Users\Sam\AppData\Local\Microsoft\OneDrive\OneDrive.exe')
        Mock Test-AtlasTransitionPath { $script:Present -contains $Path }
        Test-AtlasTransitionOneDrive | Should -BeTrue
        $script:Present = @()
        Test-AtlasTransitionOneDrive | Should -BeFalse
        Should -Invoke Test-AtlasTransitionPath -ParameterFilter { $Path -like 'C:\Users\Alex\*' }
    }

    It 'finds LibreWolf, which Atlas 0.5.0 records as an empty browser name, only when it is the one browser installed' {
        $facts = New-Atlas050Fact
        $facts.Browser = ''
        $facts.Browsers = @('browser-librewolf')
        @(ConvertTo-AtlasTransitionCarry $facts @()).options | Should -Contain 'browser-librewolf'
        $facts.Browsers = @('browser-librewolf', 'browser-firefox')
        @((ConvertTo-AtlasTransitionCarry $facts @()).options | Where-Object { $_ -like '*browser*' }) | Should -BeNullOrEmpty
    }

    It 'reads core isolation from the values Atlas 0.5.0 and Windows leave: <name>' -ForEach @(
        (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures\windows-transition\core-isolation.json') -Raw | ConvertFrom-Json) |
            ForEach-Object { @{ name = $_.name; values = $_.values; off = $_.off } }
    ) {
        $deviceGuard = 'SYSTEM\CurrentControlSet\Control\DeviceGuard'
        if ($null -ne $values.enableVirtualizationBasedSecurity) { Set-Fake $deviceGuard EnableVirtualizationBasedSecurity DWord ([int64]$values.enableVirtualizationBasedSecurity) }
        if ($null -ne $values.hypervisorEnforcedCodeIntegrity) { Set-Fake "$deviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" Enabled DWord ([int64]$values.hypervisorEnforcedCodeIntegrity) }
        if ($null -ne $values.runAsPpl) { Set-Fake 'SYSTEM\CurrentControlSet\Control\Lsa' RunAsPPL DWord ([int64]$values.runAsPpl) }
        Test-AtlasTransitionCoreIsolationOff | Should -Be ([bool]$off)
    }

    It 'takes a recorded install''s options as they are' {
        $facts = New-Atlas050Fact
        $facts.State = [pscustomobject]@{ installedVersion = '0.6.0'; options = @('defender-enable', 'mitigations-disable', 'auto-updates-default') }
        $carry = ConvertTo-AtlasTransitionCarry $facts @()
        $carry.atlasVersion | Should -BeExactly '0.6.0'
        $carry.optionSource | Should -BeExactly 'recorded'
        @($carry.options) | Should -Be @('defender-enable', 'mitigations-disable', 'auto-updates-default')
    }

    It 'accepts the record of a rebuilt Windows the app reads too, and gives the Atlas install its version and choices' {
        $text = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures\windows-transition\journal-rebuilt.json') -Raw
        Set-Fake $script:Record Journal String $text
        $rebase = Get-AtlasWindowsTransitionRebase
        $rebase.AtlasVersion | Should -BeExactly '0.5.0'
        @($rebase.Options) | Should -Contain 'defender-disable'
        $rebase.Rebuild.rebuilt | Should -BeTrue
        $rebase.Carry.browser | Should -BeExactly 'Brave'
    }

    It 'reads the same options as the app for every shared case' {
        $cases = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures\windows-transition\observed-options.json') -Raw | ConvertFrom-Json
        @($cases).Count | Should -BeGreaterThan 0
        foreach ($case in @($cases)) {
            $facts = [pscustomobject]@{
                State = $null; LegacyVersions = @('0.5.0'); Toggles = @($case.facts.toggles)
                Browser = $case.facts.browser; AtlasModules = $true; Edge = $case.facts.edge; OneDrive = $false; Defender = $true
                Appx = @($case.facts.appx); Toolbox = $case.facts.toolbox; CoreIsolationOff = $case.facts.coreIsolationOff; Browsers = @($case.facts.browsers)
            }
            $carry = ConvertTo-AtlasTransitionCarry $facts @($case.packages)
            (@($carry.options) -join ',') | Should -BeExactly (@($case.options) -join ',') -Because $case.name
        }
    }

    It 'keeps no version or choices on a PC without Atlas' {
        $facts = New-Atlas050Fact
        $facts.LegacyVersions = @()
        $carry = ConvertTo-AtlasTransitionCarry $facts @()
        $carry.atlasVersion | Should -BeNullOrEmpty
        @($carry.options) | Should -BeNullOrEmpty
        $carry.optionSource | Should -BeExactly 'none'
    }

    It 'refuses a record whose kept install has <Case>' -TestCases @(
        @{ Case = 'an unknown option shape'; Change = { param($c) $c.options = @('Defender Disable') } }
        @{ Case = 'a toggle name with a path in it'; Change = { param($c) $c.toggles = @([pscustomobject]@{ name = '..\Policies'; state = 0 }) } }
        @{ Case = 'a version that is not one'; Change = { param($c) $c.atlasVersion = '0.5.0; rm' } }
        @{ Case = 'a flag that is not true or false'; Change = { param($c) $c.oneDrive = 'yes' } }
    ) {
        param($Case, $Change)
        $carry = ConvertTo-AtlasTransitionCarry (New-Atlas050Fact) @()
        & $Change $carry
        $journal = Save-AtlasWindowsTransitionSnapshot -Kind transition -Source ([pscustomobject]@{ build = 26100 }) `
            -Target ([pscustomobject]@{ release = '26H2'; build = 26300; kb = '5121794,5129195' }) -UserSid 'S'
        $journal | Add-Member -NotePropertyName carry -NotePropertyValue $carry -Force
        try { Write-AtlasWindowsTransition $journal } catch { $thrown = $_.Exception }
        $thrown.Data['reason'] | Should -BeExactly 'feature-journal' -Because $Case
    }

    It 'keeps it in the record of a move, and in a copy that stands in when the registry record is gone' {
        $journal = Save-AtlasWindowsTransitionSnapshot -Kind transition -Source ([pscustomobject]@{ build = 26100 }) `
            -Target ([pscustomobject]@{ release = '26H2'; build = 26300; kb = '5121794,5129195' }) -UserSid 'S' `
            -Carry (ConvertTo-AtlasTransitionCarry (New-Atlas050Fact) @())
        $journal.carry.atlasVersion | Should -BeExactly '0.5.0'
        $script:Copy | Should -Not -BeNullOrEmpty
        $script:Registry.Remove("$script:Record|Journal")
        (Read-AtlasWindowsTransition).carry.browser | Should -BeExactly 'Brave'
        Remove-AtlasWindowsTransition
        $script:Writes.IndexOf('remove copy') | Should -BeLessThan $script:Writes.IndexOf("remove $script:Record|Journal") -Because 'a copy left behind must never bring back a closed record'
        Read-AtlasWindowsTransition | Should -BeNullOrEmpty
    }

    It 'never trusts a copy someone else owns' {
        $path = Join-Path $TestDrive 'copy\journal.json'
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $path))
        [IO.File]::WriteAllText($path, '{}')
        $owner = [IO.File]::GetAccessControl($path).GetOwner([Security.Principal.SecurityIdentifier]).Value
        if ($owner -in @('S-1-5-18', 'S-1-5-32-544')) { Set-ItResult -Skipped -Because 'this test runs elevated, so its file belongs to Administrators'; return }
        $thrown = & {
            . $script:Library
            function Get-AtlasTransitionCopyPath { $path }
            try { Read-AtlasTransitionCopy } catch { $_.Exception }
        }
        $thrown.Data['reason'] | Should -BeExactly 'feature-journal'
    }

    It 'records the install''s choices only for the first record of a move' {
        $script:Windows.CurrentBuildNumber = '26100'
        Mock Test-PreparationRestart { $false }
        Mock Test-PreparationNetwork { $true }
        Mock Invoke-PreparationWindows { 'reboot' }
        Mock Write-PreparationState {}
        Mock Assert-PreparationContinue {}
        Mock Get-AtlasTransitionCarry { ConvertTo-AtlasTransitionCarry (New-Atlas050Fact) $AtlasPackages }
        Use-TransitionRun
        Invoke-PreparationTransition | Should -Be 'reboot'
        (Read-Journal).carry.atlasVersion | Should -BeExactly '0.5.0'
        Invoke-PreparationTransition | Should -Be 'reboot'
        Should -Invoke Get-AtlasTransitionCarry -Times 1 -Exactly
    }
}

Describe 'Telling a rebuilt Windows from one switched on in place' {
    BeforeAll {
        # The real reader, on folders under the test drive; the harness stands in for it elsewhere.
        $ast = [Management.Automation.Language.Parser]::ParseFile($script:Library, [ref]$null, [ref]$null)
        $reader = $ast.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Get-AtlasTransitionRebuildFact' }, $true)
        . ([scriptblock]::Create($reader.Extent.Text))
    }
    BeforeEach {
        Reset-Machine
        $script:Windows050 = Join-Path $TestDrive 'Drive\Windows'
        Remove-Item -LiteralPath (Join-Path $TestDrive 'Drive') -Recurse -Force -ErrorAction SilentlyContinue
        [void][IO.Directory]::CreateDirectory((Join-Path $script:Windows050 'AtlasModules\Scripts'))
        $script:Since = [DateTime]::UtcNow.AddHours(-1)
        $script:Journal = [pscustomobject]@{
            atlasPackages = @('Z-Atlas-NoTelemetry-Package~31bf3856ad364e35~amd64~~5.0.0.0')
            carry = [pscustomobject]@{ atlasModules = $true }
        }
    }

    It 'is not fooled by the empty Windows.old a cumulative update leaves' {
        [void][IO.Directory]::CreateDirectory((Join-Path $TestDrive 'Drive\Windows.old\Windows'))
        $facts = Get-AtlasTransitionRebuildFact -Since $script:Since -WindowsPath $script:Windows050
        $facts.WindowsOld | Should -BeFalse
        $rebuild = Resolve-AtlasTransitionRebuild $script:Journal $facts @($script:Journal.atlasPackages)
        $rebuild.rebuilt | Should -BeFalse
        $rebuild.setup | Should -BeFalse
    }

    It 'needs Setup''s traces and Atlas''s components gone together' -TestCases @(
        @{ Case = 'Setup ran, Atlas is all there'; Old = $true; Bt = $true; Log = $false; Modules = $true; Packages = $true; Rebuilt = $false; Lost = $false }
        @{ Case = 'Windows.old filled but no Setup trace'; Old = $true; Bt = $false; Log = $false; Modules = $false; Packages = $false; Rebuilt = $false; Lost = $true }
        @{ Case = 'Setup log only, Atlas gone'; Old = $false; Bt = $false; Log = $true; Modules = $false; Packages = $false; Rebuilt = $false; Lost = $true }
        @{ Case = 'a rebuild by Setup'; Old = $true; Bt = $false; Log = $true; Modules = $false; Packages = $false; Rebuilt = $true; Lost = $true }
        @{ Case = 'a rebuild that kept the Atlas folder'; Old = $true; Bt = $true; Log = $false; Modules = $true; Packages = $false; Rebuilt = $true; Lost = $true }
    ) {
        param($Case, $Old, $Bt, $Log, $Modules, $Packages, $Rebuilt, $Lost)
        $drive = Join-Path $TestDrive 'Drive'
        if ($Old) { [void][IO.Directory]::CreateDirectory((Join-Path $drive 'Windows.old\Windows\System32')) }
        if ($Bt) { [void][IO.Directory]::CreateDirectory((Join-Path $drive '$WINDOWS.~BT')) }
        if ($Log) {
            [void][IO.Directory]::CreateDirectory((Join-Path $script:Windows050 'Panther'))
            [IO.File]::WriteAllText((Join-Path $script:Windows050 'Panther\setupact.log'), 'setup')
        }
        if (-not $Modules) { Remove-Item -LiteralPath (Join-Path $script:Windows050 'AtlasModules') -Recurse -Force }
        $present = if ($Packages) { @($script:Journal.atlasPackages) } else { @() }
        $rebuild = Resolve-AtlasTransitionRebuild $script:Journal (Get-AtlasTransitionRebuildFact -Since $script:Since -WindowsPath $script:Windows050) $present
        $rebuild.rebuilt | Should -Be $Rebuilt -Because $Case
        $rebuild.lost | Should -Be $Lost -Because $Case
    }

    It 'ignores a Setup log older than the move' {
        [void][IO.Directory]::CreateDirectory((Join-Path $script:Windows050 'Panther'))
        $log = Join-Path $script:Windows050 'Panther\setupact.log'
        [IO.File]::WriteAllText($log, 'setup')
        [IO.File]::SetLastWriteTimeUtc($log, $script:Since.AddDays(-30))
        (Get-AtlasTransitionRebuildFact -Since $script:Since -WindowsPath $script:Windows050).PantherWritten | Should -BeFalse
    }
}

Describe 'Putting Atlas back on a rebuilt Windows' {
    BeforeEach {
        Reset-Machine
        $script:Win = Join-Path $TestDrive 'Rebuilt\Windows'
        Remove-Item -LiteralPath (Join-Path $TestDrive 'Rebuilt') -Recurse -Force -ErrorAction SilentlyContinue
        [void][IO.Directory]::CreateDirectory((Join-Path $script:Win 'AtlasModules\Other'))
        $script:OldOther = Join-Path $TestDrive 'Rebuilt\Windows.old\Windows\AtlasModules\Other'
        [void][IO.Directory]::CreateDirectory($script:OldOther)
        [IO.File]::WriteAllText((Join-Path $script:OldOther 'winServices.reg'), 'Windows Registry Editor Version 5.00')
    }

    It 'brings back the service backup from Windows.old and keeps one that exists' {
        Copy-AtlasRebaseServiceBackup -Name 'winServices.reg' -WindowsPath $script:Win | Should -Match 'brought back'
        [IO.File]::ReadAllText((Join-Path $script:Win 'AtlasModules\Other\winServices.reg')) | Should -BeExactly 'Windows Registry Editor Version 5.00'
        [IO.File]::WriteAllText((Join-Path $script:OldOther 'winServices.reg'), 'changed')
        Copy-AtlasRebaseServiceBackup -Name 'winServices.reg' -WindowsPath $script:Win | Should -Match 'kept the existing'
        [IO.File]::ReadAllText((Join-Path $script:Win 'AtlasModules\Other\winServices.reg')) | Should -BeExactly 'Windows Registry Editor Version 5.00'
        Copy-AtlasRebaseServiceBackup -Name 'atlasServices.reg' -WindowsPath $script:Win | Should -Match 'no atlasServices.reg'
    }

    It 'never copies through a link' {
        $target = Join-Path $TestDrive 'Elsewhere'
        [void][IO.Directory]::CreateDirectory($target)
        [IO.File]::WriteAllText((Join-Path $target 'atlasServices.reg'), 'planted')
        Remove-Item -LiteralPath $script:OldOther -Recurse -Force
        [void](Microsoft.PowerShell.Management\New-Item -ItemType Junction -Path $script:OldOther -Target $target)
        Copy-AtlasRebaseServiceBackup -Name 'atlasServices.reg' -WindowsPath $script:Win | Should -Match 'is a link'
        [IO.File]::Exists((Join-Path $script:Win 'AtlasModules\Other\atlasServices.reg')) | Should -BeFalse
    }

    It 'brings back the recorded choices only when Windows lost them all' {
        $carry = ConvertTo-AtlasTransitionCarry (New-Atlas050Fact) @()
        $lines = @(Restore-AtlasRebaseChoice $carry)
        $lines[0] | Should -Match 'brought back 5 recorded choices'
        $script:ToggleRecords['AutomaticUpdates'] | Should -Be 0
        (Get-Fake 'SOFTWARE\AtlasOS\SetupOptions' browser).Data | Should -BeExactly 'Brave'
        $script:Writes.Clear()
        $script:ToggleRecords = @{ FileSharing = 1 }
        @(Restore-AtlasRebaseChoice $carry)[0] | Should -Match 'kept the 1 recorded choices'
        @($script:Writes | Where-Object { $_ -like 'toggle *' }) | Should -BeNullOrEmpty
        $script:ToggleRecords['FileSharing'] | Should -Be 1
    }

    It 'repeats only the app removals of apps that were not there before Windows moved' {
        $definitions = @(
            [pscustomobject]@{ Name = 'Microsoft.Paint*'; Option = $null; IgnoreErrors = $false }
            [pscustomobject]@{ Name = 'Microsoft.BingWeather*'; Option = $null; IgnoreErrors = $false }
            [pscustomobject]@{ Name = 'Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe'; Option = 'uninstall-edge'; IgnoreErrors = $true }
        )
        $selection = @(Select-AtlasRebaseAppxRemoval $definitions @('Microsoft.Paint_8wekyb3d8bbwe', 'Microsoft.WindowsCalculator_8wekyb3d8bbwe'))
        @($selection | Where-Object { -not $_.Kept } | ForEach-Object { $_.Definition.Name }) | Should -Be @('Microsoft.BingWeather*', 'Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe')
        @($selection | Where-Object Kept | ForEach-Object { $_.Definition.Name }) | Should -Be @('Microsoft.Paint*')

        # A record without the list removes nothing: any of them may be the user's.
        @(Select-AtlasRebaseAppxRemoval $definitions @() | Where-Object { -not $_.Kept }) | Should -BeNullOrEmpty
    }
}

Describe 'The Rebase install plan' {
    BeforeAll {
        . (Join-Path $script:AtlasTestScriptsRoot 'Install\Install-Plan.ps1')
        . (Join-Path $script:AtlasTestScriptsRoot 'Entry\Invoke-AtlasInstall.ps1')
        Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
        Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Tweaks\Atlas.Tweaks.psd1') -Force -DisableNameChecking
    }

    It 'is the Upgrade plan plus the fresh-install phases a rebuilt Windows undid, OOBE <Oobe>' -TestCases @(@{ Oobe = $false }, @{ Oobe = $true }) {
        param($Oobe)
        $upgrade = @((Get-AtlasInstallPlan -Mode Upgrade -IsOobe $Oobe).Key)
        $rebase = @((Get-AtlasInstallPlan -Mode Rebase -IsOobe $Oobe).Key)
        @($rebase | Where-Object { $upgrade -notcontains $_ }) | Should -Be @('Checkpoint/RebaseRecovery', 'Services', 'Components', 'AppxSupport')
        @($upgrade | Where-Object { $rebase -notcontains $_ }) | Should -BeNullOrEmpty
        $fresh = @((Get-AtlasInstallPlan -Mode Fresh -IsOobe $Oobe).Key)
        @($fresh | Where-Object { $rebase -notcontains $_ }) | Should -Be @('Tweak/qol/set-hidden-settings-pages', 'Tweak/scripts/set-power-settings') -Because 'a rebuild keeps the user''s settings pages and power plan'
        [array]::IndexOf($rebase, 'Checkpoint/RebaseRecovery') | Should -BeLessThan ([array]::IndexOf($rebase, 'Checkpoint/LegacyChoices'))
        [array]::IndexOf($rebase, 'Checkpoint/RebaseRecovery') | Should -BeGreaterThan ([array]::IndexOf($rebase, 'Checkpoint/PayloadReplacement'))
        [array]::IndexOf($rebase, 'Services') | Should -BeLessThan ([array]::IndexOf($rebase, 'Defaults')) -Because 'the replay of recorded choices comes after the phases that set defaults'
    }

    It 'maps the recovery step to its task' {
        $action = Get-AtlasInstallCheckpointAction -Target RebaseRecovery -ScriptsRoot $script:AtlasTestScriptsRoot -SourceScriptsRoot $TestDrive
        $action.Path | Should -BeExactly (Join-Path $script:AtlasTestScriptsRoot 'Install\Tasks\Restore-AtlasRebaseState.ps1')
        [IO.File]::Exists($action.Path) | Should -BeTrue
    }

    It 'repeats exactly the fresh-install tweaks that leave the user''s own settings alone' {
        $rebase = @()
        $fresh = @()
        foreach ($file in Get-ChildItem -LiteralPath (Join-Path $script:AtlasTestScriptsRoot 'Tweaks') -Filter '*.psd1' -Recurse) {
            if ($file.Name -eq 'tweaks.manifest.psd1') { continue }
            $tweak = Import-PowerShellDataFile -LiteralPath $file.FullName
            if ($tweak['OnUpgrade'] -ne 'Skip') { continue }
            $slug = $file.FullName.Substring((Join-Path $script:AtlasTestScriptsRoot 'Tweaks').Length + 1).Replace('\', '/') -replace '\.psd1$', ''
            $fresh += $slug
            $context = [pscustomobject]@{ IsUpgrade = $true; IsRebase = $true; IsOobe = $false; IsArm64 = $true; WindowsBuild = 26300; IsInstallStateBacked = $true; Options = @() }
            if (Test-AtlasTweakApplicable -Tweak $tweak -Context $context) { $rebase += $slug }
            $upgrade = [pscustomobject]@{ IsUpgrade = $true; IsRebase = $false; IsOobe = $false; IsArm64 = $true; WindowsBuild = 26300; IsInstallStateBacked = $true; Options = @() }
            Test-AtlasTweakApplicable -Tweak $tweak -Context $upgrade | Should -BeFalse -Because "$slug stays fresh-only on a plain upgrade"
        }
        @($rebase | Sort-Object) | Should -Be @('misc/delete-windows-specific-files', 'scripts/backup-services', 'scripts/disable-pnp', 'scripts/set-profile-pictures')
        @($fresh | Where-Object { $rebase -notcontains $_ } | Sort-Object) | Should -Be @(
            'qol/appearance/atlas-theme', 'qol/config-start-menu', 'qol/explorer/debloat-send-to',
            'qol/set-hidden-settings-pages', 'qol/taskbar/config-pins', 'scripts/set-file-associations')
    }
}
