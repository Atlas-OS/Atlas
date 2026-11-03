[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter',
    '',
    Justification = 'The phase doubles declare the parameter surface of the commands they stand in for.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidOverwritingBuiltInCmdlets',
    '',
    Justification = 'The phase harness shadows Import-Module only while the phase under test runs.'
)]
param()

BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    . (Join-Path $script:AtlasTestScriptsRoot 'Install\Tasks\Choices.ps1')
    $script:ChoicesPhase = Join-Path $script:AtlasTestScriptsRoot 'Install\Phases\Invoke-ChoicesPhase.ps1'
    $script:DefaultsPhase = Join-Path $script:AtlasTestScriptsRoot 'Install\Phases\Invoke-DefaultsPhase.ps1'
    $script:TogglesRoot = Join-Path (Split-Path -Parent $script:AtlasTestScriptsRoot) 'Toggles'

    # Each choice toggle's StateValue by state name, from the definitions Atlas installs.
    $script:StateValues = @{}
    foreach ($name in @(Get-AtlasChoiceToggleName)) {
        $file = @(Get-ChildItem -LiteralPath $script:TogglesRoot -Filter "$name.psd1" -Recurse -File)
        if ($file.Count -ne 1) { throw "Expected one definition file for '$name'." }
        $values = @{}
        foreach ($state in @((Import-PowerShellDataFile -LiteralPath $file[0].FullName).States)) {
            $values[[string]$state.Name] = [int]$state.StateValue
        }
        $script:StateValues[$name] = $values
    }

    # The AppX removal list the phase picks from, lifted from Removal.ps1 so the choice
    # gates are the real ones.
    $tokens = $null
    $errors = $null
    $removalAst = [Management.Automation.Language.Parser]::ParseFile(
        (Join-Path $script:AtlasTestModulesRoot 'Atlas.Appx\Domain\Removal.ps1'), [ref]$tokens, [ref]$errors)
    $definitionAst = $removalAst.Find({
            param($node)
            $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Get-AtlasAppxRemovalDefinition'
        }, $true)
    . ([scriptblock]::Create($definitionAst.Extent.Text))

    $script:UserSid = 'S-1-5-21-1000-2000-3000-1001'
    $script:EdgeFamily = 'Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe'
    $script:SnippingFamily = 'Microsoft.ScreenSketch_8wekyb3d8bbwe'

    # A PC the doubles below read and change, so a second run sees what the first did.
    # Each PC has its own Windows folder, which holds the install's work.
    function Reset-ChoicesPc {
        param([string[]]$Options = @())
        $script:Context = [pscustomobject]@{
            IsChoosingAgain = $true; IsOobe = $false; Mode = 'Reapply'; IsUpgrade = $true
            InteractiveUserSid = $script:UserSid; Options = @($Options)
            WinDir = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            TransactionId = [guid]::NewGuid().ToString('D')
        }
        $script:Pc = @{
            Records = @{}
            Edge = $false
            Defender = $true
            DefenderPackage = $null
            TelemetryPackage = 'Installed'
            CoreServiceRemoved = $true
            Appx = @('Microsoft.WindowsCalculator_8wekyb3d8bbwe', 'MSTeams_8wekyb3d8bbwe')
            # Families Windows provisions for new accounts.
            Provisioned = @('Microsoft.WindowsCalculator_8wekyb3d8bbwe')
            ProvisionedReads = 0
            CoreIsolationOff = $false
        }
        $script:Events = [Collections.Generic.List[string]]::new()
        $script:Logs = [Collections.Generic.List[pscustomobject]]::new()
        $script:Imports = [Collections.Generic.List[string]]::new()
        $script:EdgeCalls = [Collections.Generic.List[pscustomobject]]::new()
        $script:VbsChecks = [Collections.Generic.List[string]]::new()
        $script:FactReads = [Collections.Generic.List[string]]::new()
        $script:UninstallFailed = @()
        $script:CbsInstallFails = $false
        $script:EdgeRemovalFails = $false
        $script:AppxPlanFails = $false
        $script:DeprovisionFails = $false
        $script:ToggleFailures = @()
        $script:VbsRefusal = $null
    }

    # Starts another attempt or run on the same PC, as a resume or a later update would.
    function Reset-ChoicesRun {
        $script:Events.Clear()
        $script:Logs.Clear()
        $script:VbsChecks.Clear()
    }

    function Get-ChoicesWarning { @($script:Logs | Where-Object Level -eq 'Warning' | ForEach-Object Message) }
    function Get-ChoicesInfo { @($script:Logs | Where-Object Level -eq 'Info' | ForEach-Object Message) }
    function Get-ChoicesRecordFile { Join-Path $script:Context.WinDir 'AtlasOS\Install\work\choices.json' }

    # Doubles for the commands the phase gets from Atlas's modules, which it imports.
    function Assert-AtlasPrivilege { param([switch]$TrustedInstaller) }
    function Import-Module { param($Name, [switch]$Force, $ErrorAction) $script:Imports.Add([string]$Name) }
    function Get-AtlasContext { $script:Context }
    function Write-AtlasLog {
        param($Message, $Level = 'Info', $ErrorRecord)
        $script:Logs.Add([pscustomobject]@{ Level = $Level; Message = $Message })
    }
    function Install-AtlasCbsPackage {
        param($Packages, [switch]$NonInteractive)
        $script:Events.Add("Install:$(@($Packages) -join '+')")
        if ($script:CbsInstallFails) { throw 'simulated servicing failure' }
        foreach ($package in @($Packages)) {
            if ($package -like '*NoDefender*') { $script:Pc.DefenderPackage = 'InstallPending' }
            if ($package -like '*NoTelemetry*') { $script:Pc.TelemetryPackage = 'InstallPending' }
        }
    }
    function Uninstall-AtlasCbsPackage {
        param($Packages)
        $script:Events.Add("Uninstall:$(@($Packages) -join '+')")
        if (@($script:UninstallFailed).Count -eq 0) { $script:Pc.DefenderPackage = 'UninstallPending' }
        return [pscustomobject]@{ RemovedPackages = @(); FailedPackages = @($script:UninstallFailed); UnmatchedPatterns = @() }
    }
    function Set-AtlasDefenderCoreService {
        param($State)
        $script:Events.Add("CoreService:$State")
        if ($State -ceq 'Removed') { $script:Pc.CoreServiceRemoved = $true }
    }
    function Test-AtlasDefenderCoreServiceRemoved { $script:Pc.CoreServiceRemoved }
    function Save-AtlasAppxSnapshot { $script:Events.Add('AppxSnapshot') }
    function Invoke-AtlasAppxRemovalPlan {
        param($Definition)
        $names = @($Definition | ForEach-Object { [string]$_.Name })
        $script:Events.Add("AppxRemoval:$($names -join '+')")
        if ($script:AppxPlanFails) { throw 'simulated AppX failure' }
        $script:Pc.Appx = @($script:Pc.Appx | Where-Object { $family = $_; @($names | Where-Object { $family -like $_ }).Count -eq 0 })
        $script:Pc.Provisioned = @($script:Pc.Provisioned | Where-Object { $family = $_; @($names | Where-Object { $family -like $_ }).Count -eq 0 })
    }
    function Get-AtlasAppxProvisionedFamily {
        $script:Pc.ProvisionedReads++
        if ($null -eq $script:Pc.Provisioned) { throw 'simulated provisioning read failure' }
        @($script:Pc.Provisioned)
    }
    function Set-AtlasAppxDeprovisioned {
        $script:Events.Add('AppxDeprovision')
        if ($script:DeprovisionFails) { throw 'simulated deprovisioning failure' }
    }
    function Test-AtlasVbsChange {
        param($State)
        $script:VbsChecks.Add([string]$State)
        return $script:VbsRefusal
    }
    function Invoke-AtlasToggleMachineState {
        param($Name, $State, $StateRoot, $TogglesRoot)
        $script:Events.Add("Toggle:$Name=$State")
        if (-not $script:StateValues.ContainsKey($Name) -or -not $script:StateValues[$Name].ContainsKey($State)) {
            throw "Toggle '$Name' does not define exact state '$State'."
        }
        if ($script:ToggleFailures -contains $Name) { throw "simulated $Name failure" }
        $script:Pc.Records[$Name] = $script:StateValues[$Name][$State]
        if ($Name -ceq 'VbsState') { $script:Pc.CoreIsolationOff = $State -ceq 'Disable' }
    }
    # Stand in for what the phase dot-sources, so each test's mocks answer instead of
    # this PC; the mocks win over the definitions the phase loads.
    function Get-AtlasTransitionMachineFact { param([string]$UserSid, [switch]$MachineOnly) }
    function Get-AtlasServicingPackageState { param($Name) }
    function Test-AtlasDefenderServicePresent { }
    function Invoke-AtlasEdgeRemoval { param($ScriptsRoot, $Context) }

    function Invoke-ChoicesPhaseUnderTest {
        # Under the orchestrator's strict mode, and dot-sourced, so the doubles above are
        # what it calls.
        Set-StrictMode -Version 3.0
        . $script:ChoicesPhase
    }

    # Runs the Defaults phase on the PC's install context and returns the calls it made.
    function Invoke-DefaultsPhaseForTest {
        param([bool]$IsUpgrade = $true, [bool]$IsChoosingAgain = $true)

        $context = [pscustomobject]@{
            IsUpgrade = $IsUpgrade; IsChoosingAgain = $IsChoosingAgain
            WinDir = $script:Context.WinDir; TransactionId = $script:Context.TransactionId
        }
        $calls = [Collections.Generic.List[string]]::new()
        $null = & {
            Set-StrictMode -Version 3.0
            function Assert-AtlasPrivilege { param([switch]$TrustedInstaller) }
            function Import-Module { param($Name, [switch]$Force, $ErrorAction) }
            function Get-AtlasContext { $context }
            function Invoke-AtlasToggleReapply {
                param([string[]]$Exclude)
                $calls.Add("Reapply:$(@($Exclude | Sort-Object) -join ',')")
            }
            function Test-AtlasToggleDrift { param($Scope) @() }
            function Initialize-AtlasToggleStateStore { $calls.Add('Initialize') }
            # The phase runs on its own, so it must load the record's reader itself; its
            # own load replaces this one.
            function Get-AtlasChoicesRecord { throw 'Defaults must load Choices.ps1 itself.' }
            . $script:DefaultsPhase
        }
        return @($calls)
    }

    function Get-MachineEvent { @($script:Events) }
}

AfterAll {
    foreach ($name in @(
            'Assert-AtlasPrivilege', 'Import-Module', 'Get-AtlasContext', 'Write-AtlasLog'
            'Install-AtlasCbsPackage', 'Uninstall-AtlasCbsPackage', 'Set-AtlasDefenderCoreService'
            'Test-AtlasDefenderCoreServiceRemoved', 'Save-AtlasAppxSnapshot', 'Invoke-AtlasAppxRemovalPlan'
            'Get-AtlasAppxProvisionedFamily', 'Set-AtlasAppxDeprovisioned', 'Test-AtlasVbsChange', 'Invoke-AtlasToggleMachineState'
            'Get-AtlasTransitionMachineFact', 'Get-AtlasServicingPackageState', 'Test-AtlasDefenderServicePresent'
            'Invoke-AtlasEdgeRemoval', 'Get-AtlasAppxRemovalDefinition', 'Get-AtlasChoiceToggleName'
            'Get-AtlasChoiceToggleTarget', 'Get-AtlasChoicesRecordPath', 'Get-AtlasChoicesRecord', 'Save-AtlasChoicesRecord'
        )) {
        Microsoft.PowerShell.Management\Remove-Item -LiteralPath "Function:\$name" -ErrorAction SilentlyContinue
    }
}

Describe 'Get-AtlasChoiceToggleName' {
    It 'names the six toggles the install choices own, power saving first' {
        Get-AtlasChoiceToggleName | Should -Be @(
            'PowerSaving', 'Hibernation', 'Mitigations', 'AutomaticUpdates', 'VbsState', 'KeyboardShortcuts'
        )
    }
}

Describe 'Get-AtlasChoiceToggleTarget' {
    BeforeAll {
        # Name=State per target, with * where Atlas's record already has it.
        function Format-Target {
            param([string[]]$Options, [hashtable]$Records, $CoreIsolationOff)
            Set-StrictMode -Version 3.0
            @(Get-AtlasChoiceToggleTarget -Options $Options -Records $Records -CoreIsolationOff $CoreIsolationOff |
                    ForEach-Object { "$($_.Name)=$($_.State)$(if ($_.Matches) { '*' })" })
        }
    }

    It '<Case>' -ForEach @(
        @{
            Case = 'a ticked box or a disable answer gives Disable, recorded or not'
            Options = @('disable-power-saving', 'disable-hibernation', 'mitigations-disable', 'auto-updates-disable', 'disable-core-isolation', 'keyboard-shortcuts')
            Records = @{}; CoreIsolationOff = $false
            Expected = @('PowerSaving=Disable', 'Hibernation=Disable', 'Mitigations=Disable', 'AutomaticUpdates=Disable', 'VbsState=Disable', 'KeyboardShortcuts=Enable')
        }
        @{
            Case = 'a default answer without a record changes nothing, so a plan or setting the user made stays'
            Options = @('mitigations-default', 'auto-updates-default', 'keyboard-selector')
            Records = @{}; CoreIsolationOff = $false
            Expected = @('KeyboardShortcuts=Disable')
        }
        @{
            Case = 'a cleared box or a default answer undoes Atlas''s own Disable'
            Options = @('mitigations-default', 'auto-updates-default', 'keyboard-single')
            Records = @{ PowerSaving = 0; Hibernation = 0; Mitigations = 0; AutomaticUpdates = 0; VbsState = 0 }; CoreIsolationOff = $true
            Expected = @('PowerSaving=Enable', 'Hibernation=Enable', 'Mitigations=WindowsDefault', 'AutomaticUpdates=Enable', 'VbsState=Enable', 'KeyboardShortcuts=Disable')
        }
        @{
            Case = 'a default answer over Atlas''s Enable records already matches'
            Options = @('mitigations-default', 'auto-updates-default', 'keyboard-selector')
            Records = @{ PowerSaving = 1; Hibernation = 1; Mitigations = 1; AutomaticUpdates = 1; VbsState = 1; KeyboardShortcuts = 0 }; CoreIsolationOff = $false
            Expected = @('PowerSaving=Enable*', 'Hibernation=Enable*', 'Mitigations=WindowsDefault*', 'AutomaticUpdates=Enable*', 'VbsState=Enable*', 'KeyboardShortcuts=Disable*')
        }
        @{
            Case = 'processor protections all on stay all on with the default answer'
            Options = @('mitigations-default'); Records = @{ Mitigations = 2 }; CoreIsolationOff = $false
            Expected = @('Mitigations=Enable*')
        }
        @{
            Case = 'processor protections all on are turned off with the disable answer'
            Options = @('mitigations-disable'); Records = @{ Mitigations = 2 }; CoreIsolationOff = $false
            Expected = @('Mitigations=Disable')
        }
        @{
            Case = 'a disable answer over its own record already matches'
            Options = @('mitigations-disable', 'auto-updates-disable', 'disable-power-saving', 'disable-hibernation', 'keyboard-shortcuts')
            Records = @{ Mitigations = 0; AutomaticUpdates = 0; PowerSaving = 0; Hibernation = 0; KeyboardShortcuts = 1 }; CoreIsolationOff = $false
            Expected = @('PowerSaving=Disable*', 'Hibernation=Disable*', 'Mitigations=Disable*', 'AutomaticUpdates=Disable*', 'KeyboardShortcuts=Enable*')
        }
        @{
            Case = 'records Atlas never writes give nothing'
            Options = @('mitigations-default', 'auto-updates-default')
            Records = @{ PowerSaving = 5; Hibernation = 2; Mitigations = 7; AutomaticUpdates = 3; Sleep = 0 }; CoreIsolationOff = $false
            Expected = @()
        }
        @{
            Case = 'clearing Turn off VBS turns VBS back on when it is off, recorded or not'
            Options = @(); Records = @{}; CoreIsolationOff = $true
            Expected = @('VbsState=Enable')
        }
        @{
            Case = 'a VBS record of Enable while VBS is off doesn''t match'
            Options = @(); Records = @{ VbsState = 1 }; CoreIsolationOff = $true
            Expected = @('VbsState=Enable')
        }
        @{
            Case = 'a VBS record of Disable while VBS is on doesn''t match'
            Options = @('disable-core-isolation'); Records = @{ VbsState = 0 }; CoreIsolationOff = $false
            Expected = @('VbsState=Disable')
        }
        @{
            Case = 'a VBS record of Disable while VBS is off matches'
            Options = @('disable-core-isolation'); Records = @{ VbsState = 0 }; CoreIsolationOff = $true
            Expected = @('VbsState=Disable*')
        }
        @{
            Case = 'VBS values that weren''t read leave the record to decide'
            Options = @('disable-core-isolation'); Records = @{ VbsState = 0 }; CoreIsolationOff = $null
            Expected = @('VbsState=Disable*')
        }
        @{
            Case = 'clearing Turn off VBS changes nothing without a record while VBS is on or unread'
            Options = @(); Records = @{}; CoreIsolationOff = $null
            Expected = @()
        }
        @{
            Case = 'the language selector over shortcuts that are on turns them off'
            Options = @('keyboard-selector'); Records = @{ KeyboardShortcuts = 1 }; CoreIsolationOff = $false
            Expected = @('KeyboardShortcuts=Disable')
        }
        @{
            Case = 'shortcuts over shortcuts already on match'
            Options = @('keyboard-shortcuts'); Records = @{ KeyboardShortcuts = 1 }; CoreIsolationOff = $false
            Expected = @('KeyboardShortcuts=Enable*')
        }
    ) {
        $actual = @(Format-Target -Options $Options -Records $Records -CoreIsolationOff $CoreIsolationOff)

        ($actual -join ' | ') | Should -BeExactly ($Expected -join ' | ')
    }

    It 'names the option each state comes from, and whether it was chosen' {
        $targets = @(Get-AtlasChoiceToggleTarget -Options @('disable-hibernation', 'keyboard-single') `
                -Records @{ PowerSaving = 0 } -CoreIsolationOff $true)

        @($targets | ForEach-Object { "$($_.Name):$($_.Option):$($_.Chosen)" }) | Should -Be @(
            'PowerSaving:disable-power-saving:False'
            'Hibernation:disable-hibernation:True'
            'VbsState:disable-core-isolation:False'
            'KeyboardShortcuts:keyboard-single:True'
        )
    }

    It 'says why processor protections all on are left on' {
        $target = @(Get-AtlasChoiceToggleTarget -Options @('mitigations-default') -Records @{ Mitigations = 2 })

        $target.Count | Should -Be 1
        $target[0].Note | Should -BeExactly 'all processor protections are turned on, and keeping protections leaves them all on'
    }

    It 'reads no records when none are given' {
        @(Get-AtlasChoiceToggleTarget -Options @('mitigations-default') -Records $null) | Should -BeNullOrEmpty
    }

    It 'gives <Name> state <State> with the StateValue its definition declares' -ForEach @(
        @{ Name = 'PowerSaving'; State = 'Disable'; Options = @('disable-power-saving') }
        @{ Name = 'PowerSaving'; State = 'Enable'; Options = @() }
        @{ Name = 'Hibernation'; State = 'Disable'; Options = @('disable-hibernation') }
        @{ Name = 'Hibernation'; State = 'Enable'; Options = @() }
        @{ Name = 'Mitigations'; State = 'Disable'; Options = @('mitigations-disable') }
        @{ Name = 'Mitigations'; State = 'WindowsDefault'; Options = @('mitigations-default') }
        @{ Name = 'Mitigations'; State = 'Enable'; Options = @('mitigations-default') }
        @{ Name = 'AutomaticUpdates'; State = 'Disable'; Options = @('auto-updates-disable') }
        @{ Name = 'AutomaticUpdates'; State = 'Enable'; Options = @('auto-updates-default') }
        @{ Name = 'VbsState'; State = 'Disable'; Options = @('disable-core-isolation') }
        @{ Name = 'VbsState'; State = 'Enable'; Options = @() }
        @{ Name = 'KeyboardShortcuts'; State = 'Enable'; Options = @('keyboard-shortcuts') }
        @{ Name = 'KeyboardShortcuts'; State = 'Disable'; Options = @('keyboard-selector') }
    ) {
        $script:StateValues[$Name].ContainsKey($State) | Should -BeTrue -Because "the $Name definition declares a $State state"
        $value = $script:StateValues[$Name][$State]

        $target = @(Get-AtlasChoiceToggleTarget -Options $Options -Records @{ $Name = $value } |
                Where-Object Name -ceq $Name)

        $target.Count | Should -Be 1
        $target[0].State | Should -BeExactly $State
        $target[0].Matches | Should -BeTrue -Because 'a record of the state''s own value is the state'
    }
}

Describe 'The Choices step''s record' {
    BeforeEach {
        Reset-ChoicesPc
        $script:RecordPath = Get-ChoicesRecordFile
    }

    It 'keeps the install''s work, where only completion removes it' {
        Get-AtlasChoicesRecordPath | Should -BeExactly $script:RecordPath
    }

    It 'gives nothing when nothing is recorded' {
        $record = Get-AtlasChoicesRecord

        @($record.Applied).Count | Should -Be 0
        @($record.Unfinished).Count | Should -Be 0
        Get-ChoicesWarning | Should -BeNullOrEmpty
    }

    It 'reads back what was saved, and replaces it on the next save' {
        Save-AtlasChoicesRecord -Applied @('Mitigations', 'AutomaticUpdates') -Unfinished @('Edge')
        $first = Get-AtlasChoicesRecord
        Save-AtlasChoicesRecord -Applied @('Mitigations') -Unfinished @()
        $second = Get-AtlasChoicesRecord

        @($first.Applied) | Should -Be @('AutomaticUpdates', 'Mitigations')
        @($first.Unfinished) | Should -Be @('Edge')
        @($second.Applied) | Should -Be @('Mitigations')
        @($second.Unfinished).Count | Should -Be 0
        Test-Path -LiteralPath "$script:RecordPath.tmp" | Should -BeFalse
    }

    It 'ignores a record another installation left, so every toggle is replayed' {
        Save-AtlasChoicesRecord -Applied @('Mitigations') -Unfinished @('Edge') -TransactionId ([guid]::NewGuid().ToString('D'))

        $record = Get-AtlasChoicesRecord

        @($record.Applied).Count | Should -Be 0
        @($record.Unfinished).Count | Should -Be 0
        Get-ChoicesWarning | Should -BeNullOrEmpty
        Get-ChoicesInfo | Should -Be @("Ignoring the Choices step's record '$script:RecordPath', which another installation left.")
        Invoke-DefaultsPhaseForTest | Should -Be @('Reapply:')
    }

    It 'ignores a record it can''t read, with a warning, so every toggle is replayed: <Case>' -ForEach @(
        @{ Case = 'not JSON'; Text = 'not json'; Reason = '*' }
        @{ Case = 'empty'; Text = ''; Reason = 'it is empty.' }
        @{ Case = 'without its installation'; Text = '{"applied":[],"unfinished":[]}'; Reason = "it has no 'transactionId'." }
        @{ Case = 'without the toggles'; Text = '{"transactionId":"<txn>","unfinished":[]}'; Reason = "it has no 'applied'." }
        @{ Case = 'without the removals'; Text = '{"transactionId":"<txn>","applied":[]}'; Reason = "it has no 'unfinished'." }
        @{ Case = 'not an object'; Text = '"Mitigations"'; Reason = "it has no 'transactionId'." }
        @{ Case = 'a toggle no choice owns'; Text = '{"transactionId":"<txn>","applied":["Sleep"],"unfinished":[]}'; Reason = "'Sleep' isn't a choice toggle." }
        @{ Case = 'a toggle in another case'; Text = '{"transactionId":"<txn>","applied":["mitigations"],"unfinished":[]}'; Reason = "'mitigations' isn't a choice toggle." }
        @{ Case = 'a removal it doesn''t make'; Text = '{"transactionId":"<txn>","applied":[],"unfinished":["OneDrive"]}'; Reason = "'OneDrive' isn't a removal the Choices step makes." }
        @{ Case = 'a number'; Text = '{"transactionId":"<txn>","applied":[1],"unfinished":[]}'; Reason = "'1' isn't a choice toggle." }
    ) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $script:RecordPath) -Force | Out-Null
        [IO.File]::WriteAllText($script:RecordPath, $Text.Replace('<txn>', $script:Context.TransactionId))

        $record = Get-AtlasChoicesRecord

        @($record.Applied).Count | Should -Be 0
        @($record.Unfinished).Count | Should -Be 0
        $warnings = @(Get-ChoicesWarning)
        $warnings | Should -HaveCount 1
        $prefix = "Ignoring the Choices step's record '$script:RecordPath', which can't be read: "
        $warnings[0].StartsWith($prefix, [StringComparison]::Ordinal) | Should -BeTrue
        $warnings[0].Substring($prefix.Length) | Should -BeLike $Reason
    }
}

Describe 'Choices phase' {
    BeforeEach {
        Reset-ChoicesPc
        Mock Get-AtlasTransitionMachineFact {
            $script:FactReads.Add($UserSid)
            [pscustomobject]@{
                Toggles = @(foreach ($name in @($script:Pc.Records.Keys)) { [pscustomobject]@{ name = $name; state = [int64]$script:Pc.Records[$name] } })
                Edge = $script:Pc.Edge
                Defender = $script:Pc.Defender
                DefenderPackage = $script:Pc.DefenderPackage
                Appx = @($script:Pc.Appx)
                CoreIsolationOff = $script:Pc.CoreIsolationOff
            }
        }
        Mock Get-AtlasServicingPackageState {
            if ($Name -ceq 'Z-Atlas-NoDefender-Package') { $script:Pc.DefenderPackage } else { $script:Pc.TelemetryPackage }
        }
        Mock Test-AtlasDefenderServicePresent { $script:Pc.Defender }
        Mock Invoke-AtlasEdgeRemoval {
            $script:EdgeCalls.Add([pscustomobject]@{ ScriptsRoot = $ScriptsRoot; Context = $Context })
            $script:Events.Add('EdgeRemoval')
            # msedge.exe goes first, so a failure after it leaves Edge gone.
            $script:Pc.Edge = $false
            if ($script:EdgeRemovalFails) { throw 'simulated Edge failure' }
        }
    }

    It 'refuses to run unless the update chooses again, before reading the PC' {
        $script:Context.IsChoosingAgain = $false

        { Invoke-ChoicesPhaseUnderTest } | Should -Throw 'The Choices step runs only when an update chooses again.'
        $script:FactReads | Should -BeNullOrEmpty
        Get-MachineEvent | Should -BeNullOrEmpty
    }

    It 'imports modules that exist in the installed layout and reads the installing user''s PC facts' {
        Reset-ChoicesPc -Options @('defender-enable', 'mitigations-default', 'auto-updates-default', 'keyboard-shortcuts')

        Invoke-ChoicesPhaseUnderTest

        $script:Imports.Count | Should -BeGreaterThan 0
        foreach ($import in $script:Imports) {
            $import | Should -Exist -Because 'the phase must find its modules where Atlas installs them'
        }
        @($script:FactReads) | Should -Be @($script:UserSid)
    }

    It 'applies auto-updates-disable and mitigations-disable chosen again instead of the Enable records Atlas replayed (e9d7a85f)' {
        # Defender removed by Atlas's package, Edge gone, VBS off, and the records the
        # replay kept applying while the options said otherwise.
        Reset-ChoicesPc -Options @(
            'auto-updates-disable', 'defender-enable', 'disable-core-isolation', 'disable-power-saving'
            'install-toolbox', 'keyboard-single', 'mitigations-disable', 'uninstall-edge'
        )
        $script:Pc.Records = @{ AutomaticUpdates = 1; Mitigations = 2; VbsState = 0 }
        $script:Pc.Defender = $false
        $script:Pc.DefenderPackage = 'Installed'
        $script:Pc.CoreIsolationOff = $true
        $script:Pc.Appx = @($script:Pc.Appx + $script:SnippingFamily)

        Invoke-ChoicesPhaseUnderTest

        Get-MachineEvent | Should -Be @(
            'CoreService:Restored'
            'Uninstall:*Z-Atlas-NoDefender-Package*'
            'Toggle:PowerSaving=Disable'
            'Toggle:Mitigations=Disable'
            'Toggle:AutomaticUpdates=Disable'
            'Toggle:KeyboardShortcuts=Disable'
        )
        $script:Pc.Records.Mitigations | Should -Be 0
        $script:Pc.Records.AutomaticUpdates | Should -Be 0
        $info = Get-ChoicesInfo
        $info | Should -Contain "Applied choice 'mitigations-disable': Mitigations set to Disable."
        $info | Should -Contain "Applied choice 'auto-updates-disable': AutomaticUpdates set to Disable."
        $info | Should -Contain "Applied choice 'defender-enable': Microsoft Defender comes back at the restart."
        $info | Should -Contain "Choice 'disable-core-isolation': VbsState is already recorded as Disable."
        $info | Should -Contain "Choice 'uninstall-edge' already matches this PC."
        Get-ChoicesWarning | Should -BeNullOrEmpty
        # Snipping Tool isn't chosen, so it stays.
        $script:Pc.Appx | Should -Contain $script:SnippingFamily
        # Defaults leaves the four it set out of its replay, so neither Enable record comes
        # back, and replays the VBS record that already matched.
        Invoke-DefaultsPhaseForTest | Should -Be @('Reapply:AutomaticUpdates,KeyboardShortcuts,Mitigations,PowerSaving')

        # Defender comes back at the restart, which already counts on the next run.
        Reset-ChoicesRun
        Invoke-ChoicesPhaseUnderTest

        Get-MachineEvent | Should -BeNullOrEmpty
        Get-ChoicesInfo | Should -Contain "Choice 'defender-enable' already matches this PC."
        Get-ChoicesWarning | Should -BeNullOrEmpty
    }

    It 'changes what differs, then nothing on a second run' {
        Reset-ChoicesPc -Options @(
            'defender-disable', 'uninstall-edge', 'remove-snipping-tool', 'mitigations-default'
            'auto-updates-default', 'keyboard-shortcuts'
        )
        $script:Pc.Records = @{ PowerSaving = 0; Hibernation = 0; Mitigations = 0; AutomaticUpdates = 0; KeyboardShortcuts = 0 }
        $script:Pc.Edge = $true
        $script:Pc.TelemetryPackage = $null
        $script:Pc.CoreServiceRemoved = $false
        $script:Pc.CoreIsolationOff = $true
        $script:Pc.Appx = @($script:Pc.Appx + $script:EdgeFamily + $script:SnippingFamily)

        Invoke-ChoicesPhaseUnderTest

        Get-MachineEvent | Should -Be @(
            'Install:*Z-Atlas-NoDefender-Package*+*Z-Atlas-NoTelemetry-Package*'
            'CoreService:Removed'
            'EdgeRemoval'
            'AppxSnapshot'
            "AppxRemoval:$script:EdgeFamily+Microsoft.ScreenSketch*"
            'AppxDeprovision'
            'Toggle:PowerSaving=Enable'
            'Toggle:Hibernation=Enable'
            'Toggle:Mitigations=WindowsDefault'
            'Toggle:AutomaticUpdates=Enable'
            'Toggle:VbsState=Enable'
            'Toggle:KeyboardShortcuts=Enable'
        )
        @($script:VbsChecks) | Should -Be @('Enable')
        $info = Get-ChoicesInfo
        $info | Should -Contain "Applied choice 'uninstall-edge': Microsoft Edge removed."
        $info | Should -Contain "Applied choice 'remove-snipping-tool': Snipping Tool removed for every account."
        $info | Should -Contain "Applied choice 'disable-hibernation' left out: Hibernation set to Enable."
        $info | Should -Contain "Applied choice 'defender-disable': Microsoft Defender is removed at the restart."
        $record = Get-AtlasChoicesRecord
        @($record.Applied) | Should -Be @(Get-AtlasChoiceToggleName | Sort-Object)
        @($record.Unfinished).Count | Should -Be 0

        Reset-ChoicesRun
        Invoke-ChoicesPhaseUnderTest

        Get-MachineEvent | Should -BeNullOrEmpty
        $script:VbsChecks | Should -BeNullOrEmpty
        Get-ChoicesWarning | Should -BeNullOrEmpty
        @(Get-ChoicesInfo) | Should -Be @(
            "Choice 'defender-disable' already matches this PC."
            "Choice 'uninstall-edge' already matches this PC."
            "Choice 'remove-snipping-tool' already matches this PC."
            "Choice 'disable-power-saving' left out: PowerSaving is already recorded as Enable."
            "Choice 'disable-hibernation' left out: Hibernation is already recorded as Enable."
            "Choice 'mitigations-default': Mitigations is already recorded as WindowsDefault."
            "Choice 'auto-updates-default': AutomaticUpdates is already recorded as Enable."
            "Choice 'disable-core-isolation' left out: VbsState is already recorded as Enable."
            "Choice 'keyboard-shortcuts': KeyboardShortcuts is already recorded as Enable."
        )
    }

    It 'leaves the choice toggles that already matched to the replay, as keeping choices does' {
        Reset-ChoicesPc -Options @('defender-enable', 'disable-hibernation', 'mitigations-disable')
        $script:Pc.Records = @{ Hibernation = 0; Mitigations = 2 }

        Invoke-ChoicesPhaseUnderTest

        Get-MachineEvent | Should -Be @('Toggle:Mitigations=Disable')
        Get-ChoicesInfo | Should -Contain "Choice 'disable-hibernation': Hibernation is already recorded as Disable."
        # Hibernation's record is replayed with the others, so this build's Disable runs.
        Invoke-DefaultsPhaseForTest | Should -Be @('Reapply:Mitigations')
    }

    It 'leaves processor protections all on with the default answer, and says so' {
        Reset-ChoicesPc -Options @('defender-enable', 'mitigations-default')
        $script:Pc.Records = @{ Mitigations = 2 }

        Invoke-ChoicesPhaseUnderTest

        Get-MachineEvent | Should -BeNullOrEmpty
        Get-ChoicesInfo | Should -Contain "Choice 'mitigations-default': Mitigations is already recorded as Enable; all processor protections are turned on, and keeping protections leaves them all on."
        # The replay applies the record of 2 again as Enable, which keeps every protection on.
        Invoke-DefaultsPhaseForTest | Should -Be @('Reapply:')
    }

    It 'leaves VBS as it is, unrecorded, when policy or a lock refuses the change, and applies the rest' {
        Reset-ChoicesPc -Options @('defender-enable', 'mitigations-disable')
        $script:Pc.Records = @{ VbsState = 0 }
        $script:Pc.CoreIsolationOff = $true
        $script:VbsRefusal = "policy under 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard' controls it (EnableVirtualizationBasedSecurity = 0)"

        { Invoke-ChoicesPhaseUnderTest } | Should -Not -Throw

        @($script:VbsChecks) | Should -Be @('Enable')
        Get-MachineEvent | Should -Be @('Toggle:Mitigations=Disable')
        $script:Pc.Records.VbsState | Should -Be 0
        Get-ChoicesWarning | Should -Be @(
            "Left VBS as it is: policy under 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard' controls it (EnableVirtualizationBasedSecurity = 0)."
        )
        # The VBS record is replayed, where its own replay check decides, as when keeping.
        Invoke-DefaultsPhaseForTest | Should -Be @('Reapply:Mitigations')
    }

    It 'brings Defender back by putting its core service back first, and fails at once when it can''t' {
        Reset-ChoicesPc -Options @('defender-enable', 'mitigations-disable', 'uninstall-edge')
        $script:Pc.Defender = $false
        $script:Pc.DefenderPackage = 'Installed'
        $script:Pc.Edge = $true
        $script:UninstallFailed = @('Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~5.0.0.0')

        { Invoke-ChoicesPhaseUnderTest } | Should -Throw "Microsoft Defender couldn't be restored: Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~5.0.0.0"

        Get-MachineEvent | Should -Be @('CoreService:Restored', 'Uninstall:*Z-Atlas-NoDefender-Package*')
    }

    It 'stops at once when Atlas''s package can''t be installed, as a first installation does' {
        Reset-ChoicesPc -Options @('defender-disable', 'mitigations-disable', 'uninstall-edge', 'remove-snipping-tool')
        $script:Pc.Edge = $true
        $script:Pc.Appx = @($script:Pc.Appx + $script:SnippingFamily)
        $script:CbsInstallFails = $true

        { Invoke-ChoicesPhaseUnderTest } | Should -Throw 'simulated servicing failure'

        Get-MachineEvent | Should -Be @('Install:*Z-Atlas-NoDefender-Package*')
    }

    It 'removes Defender with only the packages it lacks and sets its core service up for removal' {
        Reset-ChoicesPc -Options @('defender-disable')

        Invoke-ChoicesPhaseUnderTest

        Get-MachineEvent | Should -Be @('Install:*Z-Atlas-NoDefender-Package*', 'CoreService:Removed')
    }

    It 'says so when Defender is already removed and only its core service is turned off' {
        Reset-ChoicesPc -Options @('defender-disable')
        $script:Pc.Defender = $false
        $script:Pc.DefenderPackage = 'Installed'
        $script:Pc.CoreServiceRemoved = $false

        Invoke-ChoicesPhaseUnderTest

        Get-MachineEvent | Should -Be @('CoreService:Removed')
        @(Get-ChoicesInfo) | Should -Contain "Applied choice 'defender-disable': Atlas's NoDefender package already removes Microsoft Defender, and its core service is turned off at the next startup."
        @(Get-ChoicesInfo | Where-Object { $_ -like "*'defender-disable' already matches*" }) | Should -BeNullOrEmpty
    }

    It 'warns, and claims no match, when Defender is missing and no Atlas package removed it' {
        Reset-ChoicesPc -Options @('defender-enable')
        $script:Pc.Defender = $false

        Invoke-ChoicesPhaseUnderTest

        Get-MachineEvent | Should -BeNullOrEmpty
        Get-ChoicesWarning | Should -Be @("Microsoft Defender isn't on this PC and no Atlas package removed it, so Atlas can't bring it back.")
        @(Get-ChoicesInfo | Where-Object { $_ -like "*'defender-enable'*" }) | Should -BeNullOrEmpty
    }

    It 'collects toggle and AppX failures, applies everything else, then throws them together, and the next attempt finishes them' {
        Reset-ChoicesPc -Options @('defender-enable', 'remove-snipping-tool', 'disable-power-saving', 'mitigations-disable', 'auto-updates-disable', 'keyboard-single')
        $script:Pc.Appx = @($script:Pc.Appx + $script:SnippingFamily)
        $script:AppxPlanFails = $true
        $script:ToggleFailures = @('Mitigations')

        $failure = $null
        try { Invoke-ChoicesPhaseUnderTest }
        catch { $failure = $_ }

        $failure | Should -Not -BeNullOrEmpty
        $failure.Exception.Message | Should -BeExactly (
            "The Choices phase failed for 2 choice(s): AppX removal: simulated AppX failure | " +
            "Applying choice 'mitigations-disable' (Mitigations Disable) failed: simulated Mitigations failure")
        Get-MachineEvent | Should -Be @(
            'AppxSnapshot'
            'AppxRemoval:Microsoft.ScreenSketch*'
            'AppxDeprovision'
            'Toggle:PowerSaving=Disable'
            'Toggle:Mitigations=Disable'
            'Toggle:AutomaticUpdates=Disable'
            'Toggle:KeyboardShortcuts=Disable'
        )
        $script:Pc.Records.ContainsKey('Mitigations') | Should -BeFalse -Because 'a state is recorded only after its machine work succeeds'
        @(Get-ChoicesInfo | Where-Object { $_ -like "Applied choice 'remove-snipping-tool'*" }) | Should -BeNullOrEmpty
        # What this attempt set is recorded before the failure is thrown.
        $record = Get-AtlasChoicesRecord
        @($record.Applied) | Should -Be @('AutomaticUpdates', 'KeyboardShortcuts', 'PowerSaving')
        @($record.Unfinished) | Should -Be @('Appx')

        Reset-ChoicesRun
        $script:AppxPlanFails = $false
        $script:ToggleFailures = @()
        Invoke-ChoicesPhaseUnderTest

        Get-MachineEvent | Should -Be @('AppxSnapshot', 'AppxRemoval:Microsoft.ScreenSketch*', 'AppxDeprovision', 'Toggle:Mitigations=Disable')
        $record = Get-AtlasChoicesRecord
        @($record.Applied) | Should -Be @('AutomaticUpdates', 'KeyboardShortcuts', 'Mitigations', 'PowerSaving')
        @($record.Unfinished).Count | Should -Be 0
        # Defaults then leaves out what both attempts set.
        Invoke-DefaultsPhaseForTest | Should -Be @('Reapply:AutomaticUpdates,KeyboardShortcuts,Mitigations,PowerSaving')
    }

    It 'collects a deprovisioning failure, and the next attempt deprovisions what the first removed' {
        Reset-ChoicesPc -Options @('defender-enable', 'remove-snipping-tool', 'mitigations-disable')
        $script:Pc.Appx = @($script:Pc.Appx + $script:SnippingFamily)
        $script:DeprovisionFails = $true

        { Invoke-ChoicesPhaseUnderTest } | Should -Throw (
            'The Choices phase failed for 1 choice(s): Deprovisioning removed AppX packages failed: simulated deprovisioning failure')

        Get-MachineEvent | Should -Be @('AppxSnapshot', 'AppxRemoval:Microsoft.ScreenSketch*', 'AppxDeprovision', 'Toggle:Mitigations=Disable')
        @(Get-ChoicesInfo | Where-Object { $_ -like "Applied choice 'remove-snipping-tool'*" }) | Should -BeNullOrEmpty
        @((Get-AtlasChoicesRecord).Unfinished) | Should -Be @('Appx')

        # Snipping Tool is gone now, so only the record says the removal isn't finished.
        Reset-ChoicesRun
        $script:DeprovisionFails = $false
        Invoke-ChoicesPhaseUnderTest

        Get-MachineEvent | Should -Be @('AppxSnapshot', 'AppxDeprovision')
        Get-ChoicesInfo | Should -Contain 'Finishing the app removal an interrupted attempt of this installation began.'
        @((Get-AtlasChoicesRecord).Unfinished).Count | Should -Be 0

        Reset-ChoicesRun
        Invoke-ChoicesPhaseUnderTest

        Get-MachineEvent | Should -BeNullOrEmpty
    }

    It 'finishes the app removal an attempt stopped part way, after its apps were gone' {
        # As an attempt stopped between the removal and the deprovisioning leaves it.
        Reset-ChoicesPc -Options @('defender-enable', 'remove-snipping-tool')
        Save-AtlasChoicesRecord -Applied @() -Unfinished @('Appx')

        Invoke-ChoicesPhaseUnderTest

        Get-MachineEvent | Should -Be @('AppxSnapshot', 'AppxDeprovision')
        @((Get-AtlasChoicesRecord).Unfinished).Count | Should -Be 0
    }

    It 'removes nothing, and records the failure, when the AppX snapshot fails' {
        Reset-ChoicesPc -Options @('defender-enable', 'remove-snipping-tool')
        $script:Pc.Appx = @($script:Pc.Appx + $script:SnippingFamily)
        Mock Save-AtlasAppxSnapshot { $script:Events.Add('AppxSnapshot'); throw 'simulated snapshot failure' }

        { Invoke-ChoicesPhaseUnderTest } | Should -Throw "*The AppX snapshot failed, so no app was removed: simulated snapshot failure*"

        Get-MachineEvent | Should -Be @('AppxSnapshot')
    }

    It 'stops at once when Edge''s removal fails, and the next attempt finishes it once msedge.exe is gone' {
        Reset-ChoicesPc -Options @('defender-enable', 'uninstall-edge', 'mitigations-disable')
        $script:Pc.Edge = $true
        $script:EdgeRemovalFails = $true

        { Invoke-ChoicesPhaseUnderTest } | Should -Throw 'simulated Edge failure'

        Get-MachineEvent | Should -Be @('EdgeRemoval')
        @((Get-AtlasChoicesRecord).Unfinished) | Should -Be @('Edge')

        Reset-ChoicesRun
        $script:EdgeRemovalFails = $false
        Invoke-ChoicesPhaseUnderTest

        Get-MachineEvent | Should -Be @('EdgeRemoval', 'Toggle:Mitigations=Disable')
        Get-ChoicesInfo | Should -Contain "Applied choice 'uninstall-edge': Microsoft Edge removed."
        @((Get-AtlasChoicesRecord).Unfinished).Count | Should -Be 0

        Reset-ChoicesRun
        Invoke-ChoicesPhaseUnderTest

        Get-MachineEvent | Should -BeNullOrEmpty
        Get-ChoicesInfo | Should -Contain "Choice 'uninstall-edge' already matches this PC."
    }

    It 'removes Edge and Snipping Tool only when ticked and on this PC, and never another app' {
        Reset-ChoicesPc -Options @('defender-enable')
        $script:Pc.Edge = $true
        $script:Pc.Appx = @($script:Pc.Appx + $script:EdgeFamily + $script:SnippingFamily)

        Invoke-ChoicesPhaseUnderTest

        Get-MachineEvent | Should -BeNullOrEmpty

        Reset-ChoicesPc -Options @('defender-enable', 'uninstall-edge')
        $script:Pc.Appx = @($script:Pc.Appx + $script:SnippingFamily + 'Microsoft.Edge.GameAssist_8wekyb3d8bbwe')

        Invoke-ChoicesPhaseUnderTest

        # msedge.exe is gone, but an app Edge's removal covers is still there.
        Get-MachineEvent | Should -Be @('AppxSnapshot', 'AppxRemoval:Microsoft.Edge.GameAssist*', 'AppxDeprovision')
        Get-ChoicesInfo | Should -Contain "Applied choice 'uninstall-edge': Microsoft Edge's remaining apps removed."
    }

    It 'removes a chosen app no account has while Windows still provisions it, as a first installation does' {
        # Each account uninstalled Snipping Tool itself, and new accounts still get it.
        Reset-ChoicesPc -Options @('defender-enable', 'remove-snipping-tool')
        $script:Pc.Provisioned = @($script:Pc.Provisioned + $script:SnippingFamily)

        Invoke-ChoicesPhaseUnderTest

        Get-MachineEvent | Should -Be @('AppxSnapshot', 'AppxRemoval:Microsoft.ScreenSketch*', 'AppxDeprovision')
        Get-ChoicesInfo | Should -Contain "Applied choice 'remove-snipping-tool': Snipping Tool removed for every account."

        Reset-ChoicesRun
        Invoke-ChoicesPhaseUnderTest

        Get-MachineEvent | Should -BeNullOrEmpty
        Get-ChoicesInfo | Should -Contain "Choice 'remove-snipping-tool' already matches this PC."
    }

    It 'reads what Windows provisions only once, and only for a chosen app no account has' {
        Reset-ChoicesPc -Options @('defender-enable', 'mitigations-disable')
        Invoke-ChoicesPhaseUnderTest
        $script:Pc.ProvisionedReads | Should -Be 0 -Because 'no app removal is chosen'

        Reset-ChoicesPc -Options @('defender-enable', 'uninstall-edge', 'remove-snipping-tool')
        $script:Pc.Appx = @($script:Pc.Appx + $script:SnippingFamily + $script:EdgeFamily +
            'Microsoft.MicrosoftEdge_8wekyb3d8bbwe' + 'Microsoft.Edge.GameAssist_8wekyb3d8bbwe')
        Invoke-ChoicesPhaseUnderTest
        $script:Pc.ProvisionedReads | Should -Be 0 -Because 'every chosen app is installed for an account'

        Reset-ChoicesPc -Options @('defender-enable', 'uninstall-edge', 'remove-snipping-tool')
        Invoke-ChoicesPhaseUnderTest
        $script:Pc.ProvisionedReads | Should -Be 1
        Get-MachineEvent | Should -BeNullOrEmpty
    }

    It 'lets the removal plan look for a chosen app when what Windows provisions couldn''t be listed' {
        Reset-ChoicesPc -Options @('defender-enable', 'remove-snipping-tool')
        $script:Pc.Provisioned = $null

        Invoke-ChoicesPhaseUnderTest

        Get-MachineEvent | Should -Be @('AppxSnapshot', 'AppxRemoval:Microsoft.ScreenSketch*', 'AppxDeprovision')
        Get-ChoicesWarning | Should -Be @(
            "Couldn't list the apps Windows provisions for new accounts, so the app removal looks for the chosen ones itself: simulated provisioning read failure"
        )
    }

    It 'passes Edge''s removal the scripts root and the install context' {
        Reset-ChoicesPc -Options @('defender-enable', 'uninstall-edge')
        $script:Pc.Edge = $true

        Invoke-ChoicesPhaseUnderTest

        $script:EdgeCalls.Count | Should -Be 1
        $script:EdgeCalls[0].ScriptsRoot | Should -Be (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $script:ChoicesPhase)))
        $script:EdgeCalls[0].Context.InteractiveUserSid | Should -BeExactly $script:UserSid
    }

    It 'lets the removal plan look for every chosen app when the app list couldn''t be read' {
        Reset-ChoicesPc -Options @('defender-enable', 'uninstall-edge', 'remove-snipping-tool')
        $script:Pc.Appx = @()

        Invoke-ChoicesPhaseUnderTest

        Get-MachineEvent | Should -Be @(
            'AppxSnapshot'
            'AppxRemoval:Microsoft.MicrosoftEdge_8wekyb3d8bbwe+Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe+Microsoft.Edge.GameAssist*+Microsoft.ScreenSketch*'
            'AppxDeprovision'
        )
    }
}

Describe 'Defaults phase' {
    BeforeEach {
        Reset-ChoicesPc
    }

    It 'leaves out of the replay only the toggles the Choices step recorded that it set' {
        Save-AtlasChoicesRecord -Applied @('Mitigations', 'AutomaticUpdates') -Unfinished @()

        Invoke-DefaultsPhaseForTest | Should -Be @('Reapply:AutomaticUpdates,Mitigations')
    }

    It 'replays every record when choosing again set none' {
        Invoke-DefaultsPhaseForTest | Should -Be @('Reapply:')
        Get-ChoicesWarning | Should -BeNullOrEmpty
    }

    It 'replays every record when keeping choices, whatever is recorded' {
        Save-AtlasChoicesRecord -Applied @('Mitigations') -Unfinished @()

        Invoke-DefaultsPhaseForTest -IsChoosingAgain $false | Should -Be @('Reapply:')
    }

    It 'only initialises the store on a first installation' {
        Invoke-DefaultsPhaseForTest -IsUpgrade $false -IsChoosingAgain $false | Should -Be @('Initialize')
    }
}
