BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.State\Atlas.State.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.InstallState\Atlas.InstallState.psd1') -Force -DisableNameChecking

    $script:PlaybookPath = Join-Path $script:AtlasTestRepoRoot 'playbook\playbook.conf'
    $script:SessionScript = Join-Path $script:AtlasTestScriptsRoot 'Install\Invoke-AtlasInstallSession.ps1'
    $script:FrontDoorScript = Join-Path $script:AtlasTestScriptsRoot 'Entry\Install-Atlas.ps1'
    $script:StateScript = Join-Path $script:AtlasTestScriptsRoot 'Entry\Initialize-AtlasInstallState.ps1'
    $script:SecurityCases = Join-Path $script:AtlasTestRepoRoot 'tests\fixtures\front-door\windows-security.json'
    $script:PowerShell51 = Join-Path $PSHOME 'powershell.exe'

    # Lift the functions out of the scripts so they run without their privilege
    # checks and process side effects.
    function Get-ScriptFunctionText {
        param([string]$Path, [string[]]$Names)
        $ast = [Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
        foreach ($name in $Names) {
            $function = $ast.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name }, $true)
            if ($null -eq $function) { throw "Function '$name' is missing from '$Path'." }
            $function.Extent.Text
        }
    }
    foreach ($text in @(Get-ScriptFunctionText -Path $script:SessionScript -Names 'Read-AtlasInstallRequest', 'Assert-AtlasInstallOptionSet') +
        @(Get-ScriptFunctionText -Path $script:FrontDoorScript -Names 'Get-AtlasDeclaredRequirement', 'Test-AtlasDefenderPresent', 'Get-AtlasDefenderSwitch', 'Test-AtlasDefenderPrepared', 'Invoke-AtlasPreparationCheck', 'Test-AtlasPreparationCurrent', 'Get-AtlasPowerStatus', 'Test-AtlasPowerConnected', 'Test-AtlasUserAccountReady', 'Test-AtlasInstallRequirement', 'Copy-AtlasPayloadToStaging', 'Get-AtlasRestartComment', 'New-AtlasProtectedStagingRoot', 'New-AtlasFrontDoorDirectorySecurity', 'Remove-AtlasStagedPackage', 'Remove-AtlasEarlierStagedPackage', 'Invoke-AtlasInstallPhase') +
        @(Get-ScriptFunctionText -Path $script:StateScript -Names 'Find-AtlasInstallUserMarker')) {
        . ([scriptblock]::Create($text))
    }
    $script:Groups = @(Get-AtlasPlaybookOption -PlaybookPath $script:PlaybookPath)
    function Get-AtlasWindowsReleaseStatus { param($Version, $BuildLabEx) throw "Unmocked release query: $Version $BuildLabEx" }
    # The requirement checks default to this process's account. These tests check a
    # local account's; a test about another account type passes -AccountSid itself.
    $PSDefaultParameterValues = @{ 'Test-AtlasInstallRequirement:AccountSid' = 'S-1-5-21-111-222-333-1001' }

    function Get-TestRequirement {
        param([string]$Name, [hashtable]$Arguments = @{})
        Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26200 -EditionId Professional -InstallationType Client @Arguments |
            Where-Object Name -eq $Name
    }
}

Describe 'Protected front-door staging' {
    It 'pins module resolution before entry imports: <Entry>' -TestCases @(
        @{ Entry = 'Initialize-AtlasInstallState.ps1'; Arguments = @('-Operation', 'RecordOption'); Module = 'Atlas.InstallState' }
        @{ Entry = 'Publish-AtlasInstallUser.ps1'; Arguments = @(); Module = 'Atlas.InstallState' }
        @{ Entry = 'Invoke-AtlasResetServices.ps1'; Arguments = @('-Silent'); Module = 'Atlas.Core' }
        @{ Entry = 'Invoke-AtlasTrustedInstallerBroker.ps1'; Arguments = @('-Operation', 'ResetServices', '-RestoreSource', 'ToggleDefaults'); Module = 'Atlas.Core' }
        @{ Entry = 'Restore-AtlasServiceDefaults.ps1'; Arguments = @('-RestoreSource', 'ToggleDefaults'); Module = 'Atlas.Core' }
        @{ Entry = 'Test-TrustedWinget.ps1'; Arguments = @(); Module = 'Atlas.Download' }
    ) {
        param($Entry, $Arguments, $Module)
        $scripts = Join-Path (Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))) 'AtlasModules\Scripts'
        $entryRoot = Join-Path $scripts 'Entry'
        $moduleRoot = Join-Path $scripts 'Modules'
        $stateRoot = Join-Path $moduleRoot $Module
        New-Item -ItemType Directory -Path $entryRoot, $stateRoot -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $script:AtlasTestScriptsRoot "Entry\$Entry") -Destination $entryRoot
        Copy-Item -LiteralPath (Join-Path $script:AtlasTestScriptsRoot 'Initialize-AtlasPowerShell.ps1') -Destination $scripts
        Set-Content -LiteralPath (Join-Path $stateRoot "$Module.psd1") -Value "@{ RootModule = '$Module.psm1'; ModuleVersion = '1.0.0' }"
        Set-Content -LiteralPath (Join-Path $stateRoot "$Module.psm1") -Value @'
[Console]::Out.WriteLine('PINNED:' + $env:PSModulePath)
throw 'Stopped before install-state access.'
'@
        $previousModulePath = $env:PSModulePath
        $previousPreference = $ErrorActionPreference
        try {
            $env:PSModulePath = Join-Path $TestDrive 'untrusted-inherited-modules'
            $ErrorActionPreference = 'Continue'
            $output = & $script:PowerShell51 -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $entryRoot $Entry) @Arguments 2>&1
            $code = $LASTEXITCODE
        }
        finally {
            $env:PSModulePath = $previousModulePath
            $ErrorActionPreference = $previousPreference
        }
        $code | Should -Not -Be 0
        ($output -join "`n") | Should -Match 'Stopped before install-state access'
        $expectedPath = $moduleRoot + [IO.Path]::PathSeparator + (Join-Path $PSHOME 'Modules')
        ($output -join "`n") | Should -Match ([regex]::Escape("PINNED:$expectedPath"))
    }

    It 'allows users to read shared state but keeps staging private and both non-writable' {
        $users = [Security.Principal.SecurityIdentifier]::new('S-1-5-32-545')
        $stateAcl = New-AtlasFrontDoorDirectorySecurity -ReadableState
        $userRules = @($stateAcl.GetAccessRules($true, $true, $users.GetType()) | Where-Object { $_.IdentityReference -eq $users })
        $userRules | Should -HaveCount 1
        ($userRules[0].FileSystemRights -band [Security.AccessControl.FileSystemRights]::ReadData) | Should -Not -Be 0
        ($userRules[0].FileSystemRights -band [Security.AccessControl.FileSystemRights]::WriteData) | Should -Be 0
        ($userRules[0].InheritanceFlags -band [Security.AccessControl.InheritanceFlags]::ObjectInherit) | Should -Not -Be 0
        ($userRules[0].InheritanceFlags -band [Security.AccessControl.InheritanceFlags]::ContainerInherit) | Should -Not -Be 0
        $stagingAcl = New-AtlasFrontDoorDirectorySecurity
        $stagingAcl.AreAccessRulesProtected | Should -BeTrue
        @($stagingAcl.GetAccessRules($true, $true, $users.GetType()) | Where-Object { $_.IdentityReference -eq $users }) | Should -HaveCount 0
        foreach ($acl in @($stateAcl, $stagingAcl)) {
            $acl.GetOwner($users.GetType()).Value | Should -Be 'S-1-5-32-544'
            $writers = @($acl.GetAccessRules($true, $true, $users.GetType()) | Where-Object { ($_.FileSystemRights -band [Security.AccessControl.FileSystemRights]::WriteData) -ne 0 })
            @($writers | ForEach-Object { $_.IdentityReference.Value } | Sort-Object) | Should -Be @('S-1-5-18', 'S-1-5-32-544')
        }
    }
}
Describe 'Package manifest readers' {
    It 'read the version, supported builds and option groups from playbook.conf' {
        $fixture = Join-Path $TestDrive 'readers-playbook.conf'
        Set-Content -LiteralPath $fixture -Value @'
<Playbook>
	<Version>1.2.3-rc.1</Version>
	<SupportedBuilds>
		<!-- A comment between builds, as the real file has. -->
		<string>26200</string>
		<string>26300</string>
	</SupportedBuilds>
	<FeaturePages>
		<RadioPage IsRequired="true" DefaultOption="radio-b">
			<TopLine Text="Page text the reader skips."/>
			<Options>
				<RadioOption><Text>A</Text><Name>radio-a</Name></RadioOption>
				<RadioOption><Text>B</Text><Name>radio-b</Name></RadioOption>
			</Options>
		</RadioPage>
		<CheckboxPage>
			<Options>
				<CheckboxOption><Text>C</Text><Name>check-c</Name></CheckboxOption>
				<CheckboxOption><Text>D</Text><Name>check-d</Name></CheckboxOption>
			</Options>
		</CheckboxPage>
		<!-- A comment between pages. -->
		<RadioImagePage DependsOn="check-d" DefaultOption="image-e">
			<Options>
				<RadioImageOption><Text>E</Text><Name>image-e</Name><FileName>e</FileName></RadioImageOption>
				<RadioImageOption><Text>F</Text><Name>image-f</Name><FileName>f</FileName></RadioImageOption>
			</Options>
		</RadioImagePage>
	</FeaturePages>
</Playbook>
'@
        Get-AtlasPlaybookVersion -PlaybookPath $fixture | Should -BeExactly '1.2.3-rc.1'
        @(Get-AtlasPlaybookSupportedBuild -PlaybookPath $fixture) | Should -Be @(26200, 26300)

        $groups = @(Get-AtlasPlaybookOption -PlaybookPath $fixture)
        $groups | Should -HaveCount 3
        @($groups[0].Options) | Should -Be @('radio-a', 'radio-b')
        @($groups[1].Options) | Should -Be @('check-c', 'check-d')
        @($groups[2].Options) | Should -Be @('image-e', 'image-f')
        @($groups.ExactlyOne) | Should -Be @($true, $false, $true)
        $groups[0].DependsOn | Should -BeNullOrEmpty
        $groups[1].DependsOn | Should -BeNullOrEmpty
        $groups[2].DependsOn | Should -BeExactly 'check-d'
        $groups[0].Default | Should -BeExactly 'radio-b'
    }
}

Describe 'Resolve-AtlasInstallMode' {
    BeforeEach {
        Mock Get-ItemProperty -ModuleName Atlas.InstallState { $null }
        Mock Get-AtlasWindowsTransitionRebase -ModuleName Atlas.InstallState { $null }
    }
    It 'resumes an interrupted fresh transaction after the files have been copied' {
        $windows = Join-Path $TestDrive 'Interrupted'
        New-Item -Path (Join-Path $windows 'AtlasModules\Scripts') -ItemType Directory -Force | Out-Null
        $path = Join-Path $windows 'AtlasOS\Install\active.json'
        Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Fresh | Out-Null
        Commit-AtlasInstallState -StatePath $path | Out-Null
        Resolve-AtlasInstallMode -TargetVersion '0.6.0' -WindowsPath $windows | Should -Be 'Fresh'
        { Resolve-AtlasInstallMode -TargetVersion '0.7.0' -WindowsPath $windows } | Should -Throw '*already active*'
    }
    It 'accepts declared legacy OEM versions' -TestCases @(
        @{ Version = '0.4.1' }, @{ Version = '0.5.0' }
    ) {
        param($Version)
        $script:LegacyVersion = $Version
        Mock Get-ItemProperty -ModuleName Atlas.InstallState { [pscustomobject]@{ Model = "Atlas Playbook $script:LegacyVersion"; RegisteredOrganization = "Atlas Playbook $script:LegacyVersion" } }
        Resolve-AtlasInstallMode -TargetVersion '0.6.0' -WindowsPath (Join-Path $TestDrive 'Legacy') | Should -Be 'Upgrade'
    }

    It 'rejects undeclared recorded source versions' -TestCases @(
        @{ Version = '0.3.2' }, @{ Version = '0.5.1' }, @{ Version = '0.7.0' }
    ) {
        param($Version)
        $windows = Join-Path $TestDrive 'Unsupported'
        $install = [pscustomobject]@{ targetVersion = $Version; mode = 'Fresh'; isOobe = $false; options = @(); transactionId = 'x' }
        Set-AtlasStateInstall -InstallState $install -Path (Join-Path $windows 'AtlasOS\state.json') | Out-Null
        { Resolve-AtlasInstallMode -TargetVersion '0.6.0' -WindowsPath $windows } | Should -Throw '*not a declared upgrade source*'
    }
    It 'is Fresh on a machine with no Atlas, Upgrade for another version, Reapply for the same version' {
        $windows = Join-Path $TestDrive 'Windows'
        New-Item -Path $windows -ItemType Directory -Force | Out-Null
        Resolve-AtlasInstallMode -TargetVersion '0.6.0' -WindowsPath $windows | Should -Be 'Fresh'

        $install = [pscustomobject]@{ targetVersion = '0.5.0'; mode = 'Fresh'; isOobe = $false; options = @(); transactionId = 'x' }
        Set-AtlasStateInstall -InstallState $install -Path (Join-Path $windows 'AtlasOS\state.json') | Out-Null
        Resolve-AtlasInstallMode -TargetVersion '0.6.0' -WindowsPath $windows | Should -Be 'Upgrade'
        Resolve-AtlasInstallMode -TargetVersion '0.5.0' -WindowsPath $windows | Should -Be 'Reapply'
    }

    It 'rejects installed Atlas files without version evidence' {
        $windows = Join-Path $TestDrive 'LegacyWindows'
        New-Item -Path (Join-Path $windows 'AtlasModules\Scripts') -ItemType Directory -Force | Out-Null
        { Resolve-AtlasInstallMode -TargetVersion '0.6.0' -WindowsPath $windows } | Should -Throw '*version could not be established*'
    }

    It 'is Rebase after Windows rebuilt itself while Atlas Manager moved it, with or without the markers' {
        Mock Get-AtlasWindowsTransitionRebase -ModuleName Atlas.InstallState { [pscustomobject]@{ AtlasVersion = '0.5.0'; Options = @('defender-disable') } }
        Mock Get-ItemProperty -ModuleName Atlas.InstallState { [pscustomobject]@{ Model = 'Atlas Playbook v0.5.0'; RegisteredOrganization = 'Atlas Playbook v0.5.0' } }
        $windows = Join-Path $TestDrive 'Rebuilt'
        New-Item -Path $windows -ItemType Directory -Force | Out-Null
        Resolve-AtlasInstallMode -TargetVersion '0.6.0' -WindowsPath $windows | Should -Be 'Rebase'
        Mock Get-ItemProperty -ModuleName Atlas.InstallState { $null }
        Resolve-AtlasInstallMode -TargetVersion '0.6.0' -WindowsPath $windows | Should -Be 'Rebase' -Because 'the record of the move keeps the version when the markers are gone'
    }

    It 'is Rebase for the same version and still refuses an undeclared one' {
        Mock Get-AtlasWindowsTransitionRebase -ModuleName Atlas.InstallState { [pscustomobject]@{ AtlasVersion = '0.6.0'; Options = @() } }
        $windows = Join-Path $TestDrive 'RebuiltSame'
        New-Item -Path $windows -ItemType Directory -Force | Out-Null
        Resolve-AtlasInstallMode -TargetVersion '0.6.0' -WindowsPath $windows | Should -Be 'Rebase'
        Mock Get-AtlasWindowsTransitionRebase -ModuleName Atlas.InstallState { [pscustomobject]@{ AtlasVersion = '0.3.2'; Options = @() } }
        { Resolve-AtlasInstallMode -TargetVersion '0.6.0' -WindowsPath $windows } | Should -Throw '*not a declared upgrade source*'
    }
}

Describe 'Install request validation' {
    It 'accepts a complete option set and rejects unknown, repeated and incomplete sets' {
        $good = @('defender-enable', 'mitigations-default', 'auto-updates-disable', 'keyboard-shortcuts', 'install-another-browser', 'browser-brave')
        @(Assert-AtlasInstallOptionSet -Options $good -Groups $script:Groups) | Should -Be $good

        { Assert-AtlasInstallOptionSet -Options ($good + 'not-an-option') -Groups $script:Groups } | Should -Throw '*not declared*'
        { Assert-AtlasInstallOptionSet -Options ($good + 'defender-enable') -Groups $script:Groups } | Should -Throw '*repeats*'
        { Assert-AtlasInstallOptionSet -Options @('defender-enable', 'defender-disable', 'mitigations-default', 'auto-updates-disable') -Groups $script:Groups } |
            Should -Throw '*Exactly one of*'
        { Assert-AtlasInstallOptionSet -Options @('defender-enable', 'mitigations-default') -Groups $script:Groups } |
            Should -Throw '*Exactly one of auto-updates*'
        { Assert-AtlasInstallOptionSet -Options @('defender-enable', 'mitigations-default', 'auto-updates-disable', 'keyboard-shortcuts', 'browser-brave') -Groups $script:Groups } |
            Should -Throw "*require 'install-another-browser'*"
        { Assert-AtlasInstallOptionSet -Options @('defender-enable', 'mitigations-default', 'auto-updates-disable') -Groups $script:Groups } |
            Should -Throw '*Exactly one of keyboard-*'
        { Assert-AtlasInstallOptionSet -Options ($good + 'keyboard-single') -Groups $script:Groups } |
            Should -Throw '*Exactly one of keyboard-*'
        { Assert-AtlasInstallOptionSet -Options ($good + 'browser-firefox') -Groups $script:Groups } |
            Should -Throw '*Exactly one of browser-*'
    }

    It 'resumes an install begun before a required group with the options it began with' {
        # An RC without the keyboard page recorded these; the resume must keep them.
        $began = @('defender-enable', 'mitigations-default', 'auto-updates-disable')
        @(Assert-AtlasInstallOptionSet -Options $began -Groups $script:Groups -ResumedOptions $began) | Should -Be $began

        { Assert-AtlasInstallOptionSet -Options @('defender-enable', 'mitigations-default') -Groups $script:Groups -ResumedOptions ($began + 'keyboard-single') } |
            Should -Throw '*Exactly one of auto-updates*'
        { Assert-AtlasInstallOptionSet -Options ($began + 'keyboard-single' + 'keyboard-shortcuts') -Groups $script:Groups -ResumedOptions $began } |
            Should -Throw '*Exactly one of keyboard-*'
    }

    It 'reads only a size-limited request.json with an options array' {
        $payload = Join-Path $TestDrive 'payload'
        New-Item -Path $payload -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $payload 'request.json') -Value '{"options":["defender-enable"]}'
        @(Read-AtlasInstallRequest -PayloadRoot $payload) | Should -Be @('defender-enable')

        Set-Content -LiteralPath (Join-Path $payload 'request.json') -Value '{"options":[],"mode":"Fresh"}'
        { Read-AtlasInstallRequest -PayloadRoot $payload } | Should -Throw "*unknown field 'mode'*"
        Set-Content -LiteralPath (Join-Path $payload 'request.json') -Value '{"options":[],"windowsSetup":true}'
        { Read-AtlasInstallRequest -PayloadRoot $payload } | Should -Throw "*unknown field 'windowsSetup'*"

        # Valid JSON on both sides of the 64 KiB limit, so only the size check can refuse it.
        $atLimit = '{"options":["' + ('a' * (65536 - 16)) + '"]}'
        [IO.File]::WriteAllText((Join-Path $payload 'request.json'), $atLimit)
        @(Read-AtlasInstallRequest -PayloadRoot $payload) | Should -HaveCount 1
        [IO.File]::WriteAllText((Join-Path $payload 'request.json'), $atLimit.Replace('"a', '"aa'))
        { Read-AtlasInstallRequest -PayloadRoot $payload } | Should -Throw '*exceeds its size limit*'

        Remove-Item -LiteralPath (Join-Path $payload 'request.json')
        { Read-AtlasInstallRequest -PayloadRoot $payload } | Should -Throw '*missing*'
    }
}

Describe 'Front door power status' {
    It 'interprets AC and battery status without treating 255 as no battery' -TestCases @(
        @{ Battery = 128; Line = 'Unknown'; Connected = $true }
        @{ Battery = 1; Line = 'Online'; Connected = $true }
        @{ Battery = 1; Line = 'Offline'; Connected = $false }
        @{ Battery = 255; Line = 'Online'; Connected = $true }
        @{ Battery = 255; Line = 'Unknown'; Connected = $null }
    ) {
        param($Battery, $Line, $Connected)
        $script:FixturePowerStatus = [pscustomobject]@{ BatteryChargeStatus = $Battery; PowerLineStatus = $Line }
        Mock Get-AtlasPowerStatus { $script:FixturePowerStatus }
        if ($null -eq $Connected) {
            { Test-AtlasPowerConnected } | Should -Throw '*could not determine*'
        }
        else {
            Test-AtlasPowerConnected | Should -Be $Connected
        }
    }
}

Describe 'Front door provider completion' {
    It 'requires this verification process to succeed for the installing account' -TestCases @(
        @{ Status='complete'; ExitCode=0; WrongUser=$false; Passes=$true }
        @{ Status='failed'; ExitCode=0; WrongUser=$false; Passes=$false }
        @{ Status='complete'; ExitCode=1; WrongUser=$false; Passes=$false }
        @{ Status='complete'; ExitCode=0; WrongUser=$true; Passes=$false }
    ) {
        param($Status, $ExitCode, $WrongUser, $Passes)
        $payload = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $workerRoot = Join-Path $payload 'AtlasModules\Scripts\Preparation'
        [void][IO.Directory]::CreateDirectory($workerRoot)
        @{ status=$Status; exitCode=$ExitCode; wrongUser=$WrongUser } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $workerRoot 'fixture.json')
        $stub = @'
param([string]$JobPath, [switch]$VerifyOnly)
if (-not $VerifyOnly) { exit 7 }
$fixture = Get-Content (Join-Path $PSScriptRoot 'fixture.json') -Raw | ConvertFrom-Json
$sid = if ($fixture.wrongUser) { 'S-1-5-18' } else { [Security.Principal.WindowsIdentity]::GetCurrent().User.Value }
@{schema=1;status=$fixture.status;userSid=$sid} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $JobPath 'state.json')
exit $fixture.exitCode
'@
        Set-Content -LiteralPath (Join-Path $workerRoot 'Update-Windows.ps1') -Value $stub
        $job = Join-Path $payload 'Verification'
        if ($Passes) {
            { Invoke-AtlasPreparationCheck -PayloadRoot $payload -JobPath $job } | Should -Not -Throw
        }
        else {
            { Invoke-AtlasPreparationCheck -PayloadRoot $payload -JobPath $job } | Should -Throw
        }
        # The entry exits with its own code when this is false, so the app can
        # send the user back to preparation rather than report a failed install.
        Test-AtlasPreparationCurrent -PayloadRoot $payload -JobPath $job | Should -Be $Passes
    }
}

Describe 'User account policy preflight' {
    It 'rejects disabled UAC before loading the user-token helper' {
        Mock Get-ItemProperty { [pscustomobject]@{ EnableLUA = 0 } }
        Mock Initialize-AtlasNativeType { throw 'must not load a token helper with disabled UAC' }
        Test-AtlasUserAccountReady | Should -BeFalse
        Should -Invoke Initialize-AtlasNativeType -Times 0 -Exactly
        Should -Invoke Get-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $LiteralPath -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -and $Name -eq 'EnableLUA'
        }
    }

    It 'does not treat an unreadable UAC policy as enabled' {
        Mock Get-ItemProperty { Write-Error 'UAC policy access denied' }
        $ready = try { Test-AtlasUserAccountReady } catch { $false }
        $ready | Should -BeFalse
    }
}

Describe 'Front door Windows Security readings' {
    It 'reads every shared case as Atlas Manager does' {
        # Windows PowerShell 5.1 passes a JSON array on as one object.
        $cases = @(Get-Content -LiteralPath $script:SecurityCases -Raw | ConvertFrom-Json | ForEach-Object { $_ })
        $cases.Count | Should -BeGreaterThan 1
        $states = @{ off = 'Off'; on = 'On'; unreadable = 'Unknown' }
        foreach ($case in $cases) {
            # A key the case leaves out is missing; a JSON string stands for a value
            # that isn't a DWORD, and {"qword": n} for a REG_QWORD, which .NET reads as a [long].
            $registry = @{}
            foreach ($key in $case.registry.PSObject.Properties) {
                $values = @{}
                foreach ($value in $key.Value.PSObject.Properties) {
                    $qword = if ($null -ne $value.Value) { $value.Value.PSObject.Properties['qword'] }
                    $values[$value.Name] = if ($null -ne $qword) { [long]$qword.Value } else { $value.Value }
                }
                $registry[$key.Name] = $values
            }
            $switches = Get-AtlasDefenderSwitch -Registry $registry
            @($switches.TamperProtection, $switches.RealTimeProtection, $switches.CloudDelivered, $switches.SampleSubmission) |
                Should -Be @(
                    $states[$case.switches.tamperProtection], $states[$case.switches.realTimeProtection],
                    $states[$case.switches.cloudDelivered], $states[$case.switches.sampleSubmission]
                ) -Because $case.name
            foreach ($name in 'RealTimeProtection', 'CloudDelivered', 'SampleSubmission', 'TamperProtection') {
                $switches.Reasons.Contains($name) | Should -Be ($switches.$name -eq 'Unknown') -Because "$($case.name): $name"
            }
        }
    }

    It 'reads the registry key types as the shared cases describe them: <Name>' -ForEach @(
        @{
            Name     = 'DWORDs'
            Tamper   = @{ Data = 4; Kind = 'DWord' }
            RealTime = @{ Data = 1; Kind = 'DWord' }
            Expected = @('Off', 'Off', 'Unknown', 'Unknown')
        }
        @{
            Name     = 'a QWORD that fits and a string'
            Tamper   = @{ Data = [long]4; Kind = 'QWord' }
            RealTime = @{ Data = '1'; Kind = 'String' }
            Expected = @('Off', 'On', 'Unknown', 'Unknown')
        }
        @{
            Name     = "a QWORD that doesn't fit"
            Tamper   = @{ Data = [long]0x100000004; Kind = 'QWord' }
            RealTime = @{ Data = 0; Kind = 'DWord' }
            Expected = @('Unknown', 'On', 'Unknown', 'Unknown')
        }
    ) {
        # SpyNet is left out, as a PC that never had it.
        $subKey = "Software\AtlasRewriteTest\$([Guid]::NewGuid().ToString('N'))"
        try {
            foreach ($entry in @(
                    @{ Key = 'Features'; Name = 'TamperProtection'; Value = $Tamper }
                    @{ Key = 'Real-Time Protection'; Name = 'DisableRealtimeMonitoring'; Value = $RealTime }
                )) {
                $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey("$subKey\$($entry.Key)")
                try { $key.SetValue($entry.Name, $entry.Value.Data, [Microsoft.Win32.RegistryValueKind]$entry.Value.Kind) }
                finally { $key.Dispose() }
            }

            $switches = Get-AtlasDefenderSwitch -Root ([Microsoft.Win32.Registry]::CurrentUser) -SubKey $subKey

            @($switches.TamperProtection, $switches.RealTimeProtection, $switches.CloudDelivered, $switches.SampleSubmission) |
                Should -Be $Expected
            $switches.Reasons['CloudDelivered'] | Should -Be 'SpyNet key missing'
        }
        finally {
            [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree($subKey, $false)
        }
    }

    It 'reads a QWORD that fits in 32 bits as Atlas Manager does, and leaves a larger one unread' {
        $switches = Get-AtlasDefenderSwitch -Registry @{
            'Features'             = @{ TamperProtection = [long]4 }
            'Real-Time Protection' = @{ DisableRealtimeMonitoring = [long]1 }
            'SpyNet'               = @{ SpyNetReporting = [long]0; SubmitSamplesConsent = [long]2 }
        }
        @($switches.TamperProtection, $switches.RealTimeProtection, $switches.CloudDelivered, $switches.SampleSubmission) |
            Should -Be @('Off', 'Off', 'Off', 'Off')
        Test-AtlasDefenderPrepared -Switch $switches | Should -BeTrue

        $tooLarge = [long][uint32]::MaxValue + 1
        $switches = Get-AtlasDefenderSwitch -Registry @{
            'Features'             = @{ TamperProtection = $tooLarge }
            'Real-Time Protection' = @{ DisableRealtimeMonitoring = $tooLarge }
            'SpyNet'               = @{ SpyNetReporting = $tooLarge; SubmitSamplesConsent = $tooLarge }
        }
        # Real-time protection reads on, as in the app: its key is there and the value isn't 1.
        @($switches.TamperProtection, $switches.RealTimeProtection, $switches.CloudDelivered, $switches.SampleSubmission) |
            Should -Be @('Unknown', 'On', 'Unknown', 'Unknown')
        $switches.Reasons.TamperProtection | Should -Be "Features\TamperProtection is a QWORD that doesn't fit in 32 bits"
    }
}

Describe 'Front door requirements and staging' {
    BeforeEach {
        Mock Get-AtlasWindowsReleaseStatus { 'Released' }
        Mock Test-AtlasUserAccountReady { $true }
        Mock Get-ItemProperty { [pscustomobject]@{} }
        Mock Test-AtlasPowerConnected { $true }
        # Keep the host's Security Center out of every requirement check.
        Mock Get-CimInstance { @() }
    }

    It 'blocks an account without a limited token and explains how to recover' {
        Mock Test-Path { $false }
        Mock Test-AtlasUserAccountReady { $false }
        $result = Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26200 -EditionId Professional -InstallationType Client | Where-Object Name -eq 'User account'
        $result.Passed | Should -BeFalse
        $result.Blocking | Should -BeTrue
        $result.Detail | Should -BeLike '*UAC*restart*'
    }

    It 'fails closed when account verification cannot run' {
        Mock Test-Path { $false }
        Mock Test-AtlasUserAccountReady { throw 'token query failed' }
        $result = Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26200 -EditionId Professional -InstallationType Client | Where-Object Name -eq 'User account'
        $result.Passed | Should -BeFalse
        $result.Blocking | Should -BeTrue
        $result.Detail | Should -BeLike '*token query failed*'
    }

    It 'refuses a work or school (Microsoft Entra ID) account before anything is copied' {
        Mock Test-Path { $false }
        $result = Get-TestRequirement -Name 'User account' -Arguments @{ AccountSid = 'S-1-12-1-2933642503-1247987907-1399130510-4207851353' }
        $result.Passed | Should -BeFalse
        $result.Blocking | Should -BeTrue
        $result.Detail | Should -BeLike "Atlas can't be installed from a work or school (Microsoft Entra ID) account.*"
        Should -Invoke Test-AtlasUserAccountReady -Times 0 -Exactly
    }

    It 'goes on to the UAC check for a local or Microsoft account' {
        Mock Test-Path { $false }
        $result = Get-TestRequirement -Name 'User account' -Arguments @{ AccountSid = 'S-1-5-21-111-222-333-1001' }
        $result.Passed | Should -BeTrue
        Should -Invoke Test-AtlasUserAccountReady -Times 1 -Exactly
    }

    It 'blocks unsupported builds, pending restart and declared prerequisites' {
        Mock Test-Path { $true }
        Mock Test-AtlasPowerConnected { $false }
        Mock Get-CimInstance { @([pscustomobject]@{ displayName = 'Contoso Shield' }) }

        $results = @(Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 22631 -EditionId Professional -InstallationType Client -DeclaredRequirements @('NoAntivirus', 'PluggedIn'))
        ($results | Where-Object { $_.Name -eq 'Windows build' }).Passed | Should -BeFalse
        ($results | Where-Object { $_.Name -eq 'Windows build' }).Blocking | Should -BeTrue
        @($results | Where-Object { -not $_.Passed -and $_.Blocking }).Count | Should -Be 4
        ($results | Where-Object { $_.Name -eq 'Windows edition' }).Passed | Should -BeTrue

        Mock Test-Path { $false }
        Mock Test-AtlasPowerConnected { $true }
        Mock Get-CimInstance { @() }
        $results = @(Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26200 -EditionId Professional -InstallationType Client -DeclaredRequirements @('NoAntivirus', 'PluggedIn'))
        @($results | Where-Object { -not $_.Passed }).Count | Should -Be 0
    }

    It 'does not report unavailable antivirus or power providers as satisfied' {
        Mock Test-Path { $false }
        Mock Get-CimInstance { throw 'provider unavailable' }
        Mock Test-AtlasPowerConnected { throw 'power unknown' }
        $results = @(Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26200 -EditionId Professional -InstallationType Client -DeclaredRequirements @('NoAntivirus', 'PluggedIn'))
        foreach ($name in @('Plugged in', 'No third-party antivirus')) {
            $result = $results | Where-Object Name -eq $name
            $result.Passed | Should -BeFalse
            $result.Blocking | Should -BeTrue
            $result.Detail | Should -Match 'could not be checked'
        }
    }

    It 'ignores an antivirus registration whose executable is gone' {
        Mock Test-Path { $false }
        Mock Get-CimInstance { @([pscustomobject]@{ displayName = 'Malwarebytes'; pathToSignedProductExe = 'C:\Program Files\Malwarebytes\Anti-Malware\mbam.exe' }) }
        $result = Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26200 -EditionId Professional -InstallationType Client -DeclaredRequirements @('NoAntivirus') | Where-Object Name -eq 'No third-party antivirus'
        $result.Passed | Should -BeTrue
        $result.Detail | Should -Match 'leftover registration for Malwarebytes'

        # The same registration with its executable present is an installed product.
        Mock Test-Path { $LiteralPath -like '*mbam.exe' }
        $result = Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26200 -EditionId Professional -InstallationType Client -DeclaredRequirements @('NoAntivirus') | Where-Object Name -eq 'No third-party antivirus'
        $result.Passed | Should -BeFalse
        $result.Detail | Should -Match 'found: Malwarebytes'
    }

    It 'counts an antivirus registration without a drive or UNC path as installed' {
        # A URI or an unexpanded %variable% path can't be checked on disk, so, as in the app, it counts as installed.
        Mock Test-Path { $false }
        Mock Get-CimInstance {
            @(
                [pscustomobject]@{ displayName = 'Contoso Link'; pathToSignedProductExe = 'contoso://' }
                [pscustomobject]@{ displayName = 'Contoso'; pathToSignedProductExe = '%ProgramFiles%\Contoso\av.exe' }
            )
        }
        $result = Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26200 -EditionId Professional -InstallationType Client -DeclaredRequirements @('NoAntivirus') | Where-Object Name -eq 'No third-party antivirus'
        $result.Passed | Should -BeFalse
        $result.Detail | Should -Match 'found: Contoso Link, Contoso'
    }

    It 'leaves undeclared antivirus and power checks advisory' {
        Mock Test-Path { $false }
        Mock Get-CimInstance { @([pscustomobject]@{ displayName = 'Contoso Shield' }) }
        Mock Test-AtlasPowerConnected { $false }
        $results = @(Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26200 -EditionId Professional -InstallationType Client)
        @($results | Where-Object { -not $_.Passed -and -not $_.Blocking }).Count | Should -Be 2
    }

    It 'accepts a development manifest without Requirements while retaining platform and reboot gates' {
        Set-StrictMode -Version 3.0
        [xml]$manifest = '<Playbook><Version>0.6.0</Version><SupportedBuilds><string>26200</string></SupportedBuilds></Playbook>'
        $declared = @(Get-AtlasDeclaredRequirement -Playbook $manifest)
        $declared | Should -HaveCount 0
        Mock Test-Path { $true }
        $results = @(Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26100 -EditionId Core -InstallationType Client -DeclaredRequirements $declared)
        foreach ($name in @('Windows build', 'Windows edition', 'No pending reboot')) {
            $result = $results | Where-Object Name -eq $name
            $result.Passed | Should -BeFalse
            $result.Blocking | Should -BeTrue
        }
    }

    It 'reads declared prerequisite names from a production manifest' {
        Set-StrictMode -Version 3.0
        [xml]$manifest = '<Playbook><Requirements><Requirement>NoAntivirus</Requirement><Requirement>PluggedIn</Requirement></Requirements></Playbook>'
        @(Get-AtlasDeclaredRequirement -Playbook $manifest) | Should -Be @('NoAntivirus', 'PluggedIn')
    }

    It 'passes the Windows Security requirement when an earlier install removed Defender' {
        Mock Test-Path { $false }
        Mock Test-AtlasDefenderPresent { $false }
        Mock Get-AtlasDefenderSwitch { throw "Cannot find path 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Features' because it does not exist." }
        $result = Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26200 -EditionId Professional -InstallationType Client -DeclaredRequirements @('DefenderToggled') | Where-Object Name -eq 'Windows Security'
        $result.Passed | Should -BeTrue
        $result.Detail | Should -Match 'not installed'
        Should -Invoke Get-AtlasDefenderSwitch -Times 0
    }

    Context 'the Windows Security switches' {
        BeforeEach {
            Mock Test-Path { $false }
            Mock Test-AtlasDefenderPresent { $true }
        }

        It 'accepts switches it could not read only once the user confirmed them' {
            Mock Get-AtlasDefenderSwitch { [pscustomobject][ordered]@{ RealTimeProtection = 'Off'; CloudDelivered = 'Off'; SampleSubmission = 'Unknown'; TamperProtection = 'Off' } }
            $refused = Get-TestRequirement -Name 'Windows Security' -Arguments @{ DeclaredRequirements = @('DefenderToggled') }
            $refused.Passed | Should -BeFalse
            $refused.Blocking | Should -BeTrue
            $refused.Detail | Should -BeLike "*couldn't be read: automatic sample submission*-WindowsSecurityConfirmed*"

            $confirmed = Get-TestRequirement -Name 'Windows Security' -Arguments @{ DeclaredRequirements = @('DefenderToggled'); WindowsSecurityConfirmed = $true }
            $confirmed.Passed | Should -BeTrue
            $confirmed.Detail | Should -BeLike '*confirmed*automatic sample submission'
        }

        It 'names why a switch could not be read' {
            # Inside the mock, $Registry is the mocked call's own unset parameter, so
            # the mock returns a reading taken here.
            $reading = Get-AtlasDefenderSwitch -Registry @{
                'Features'             = @{ TamperProtection = 4 }
                'Real-Time Protection' = @{ DisableRealtimeMonitoring = 1 }
                'SpyNet'               = @{ SpyNetReporting = 0 }
            }
            $reading.Reasons.SampleSubmission | Should -Be 'SpyNet\SubmitSamplesConsent missing'
            Mock Get-AtlasDefenderSwitch { $reading }

            $refused = Get-TestRequirement -Name 'Windows Security' -Arguments @{ DeclaredRequirements = @('DefenderToggled') }
            $refused.Passed | Should -BeFalse
            $refused.Detail | Should -BeLike "*couldn't be read: automatic sample submission (SpyNet\SubmitSamplesConsent missing).*"

            $confirmed = Get-TestRequirement -Name 'Windows Security' -Arguments @{ DeclaredRequirements = @('DefenderToggled'); WindowsSecurityConfirmed = $true }
            $confirmed.Passed | Should -BeTrue
            $confirmed.Detail | Should -BeLike '*confirmed*: automatic sample submission (SpyNet\SubmitSamplesConsent missing)'
        }

        It 'still blocks a switch that reads on when the user confirmed the rest' {
            Mock Get-AtlasDefenderSwitch { [pscustomobject][ordered]@{ RealTimeProtection = 'Off'; CloudDelivered = 'On'; SampleSubmission = 'Unknown'; TamperProtection = 'Unknown' } }
            $result = Get-TestRequirement -Name 'Windows Security' -Arguments @{ DeclaredRequirements = @('DefenderToggled'); WindowsSecurityConfirmed = $true }
            $result.Passed | Should -BeFalse
            $result.Detail | Should -BeLike "*on: cloud-delivered protection; couldn't be read: automatic sample submission, Tamper Protection"
        }

        It 'passes every switch off without asking for confirmation' {
            Mock Get-AtlasDefenderSwitch { [pscustomobject][ordered]@{ RealTimeProtection = 'Off'; CloudDelivered = 'Off'; SampleSubmission = 'Off'; TamperProtection = 'Off' } }
            (Get-TestRequirement -Name 'Windows Security' -Arguments @{ DeclaredRequirements = @('DefenderToggled') }).Passed | Should -BeTrue
        }

        It 'fails closed when reading the switches throws, confirmed or not' {
            Mock Get-AtlasDefenderSwitch { throw 'Access denied' }
            $result = Get-TestRequirement -Name 'Windows Security' -Arguments @{ DeclaredRequirements = @('DefenderToggled'); WindowsSecurityConfirmed = $true }
            $result.Passed | Should -BeFalse
            $result.Blocking | Should -BeTrue
            $result.Detail | Should -BeLike '*could not be checked: Access denied'
        }
    }

    It 'rejects an unknown declared requirement instead of silently bypassing it' {
        { Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26200 -EditionId Professional -InstallationType Client -DeclaredRequirements @('FutureRequirement') } | Should -Throw '*cannot verify*'
    }

    It 'blocks preview, unlisted and unverifiable Windows releases independently of the base build' -TestCases @(
        @{ Release='Preview'; Detail='*Insider or preview*' }
        @{ Release='Unlisted'; Detail="*build 26200.5551 is not in Microsoft's list*" }
        @{ Release='Unknown'; Detail='*could not be verified*' }
    ) {
        param($Release, $Detail)
        $script:ReleaseFixture = $Release
        Mock Get-AtlasWindowsReleaseStatus { $script:ReleaseFixture }
        Mock Test-Path { $false }
        $result = Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26200 -WindowsRevision 5551 -BuildLabEx 'rs_prerelease' -EditionId Professional -InstallationType Client | Where-Object Name -eq 'Windows release'
        $result.Passed | Should -BeFalse
        $result.Blocking | Should -BeTrue
        $result.Detail | Should -BeLike $Detail
        Should -Invoke Get-AtlasWindowsReleaseStatus -Times 1 -Exactly -ParameterFilter { $Version -eq [version]'10.0.26200.5551' -and $BuildLabEx -eq 'rs_prerelease' }
    }

    It 'only notes pending file replacements when neither restart flag is set' {
        # The printer driver replacements a cumulative update left after its own
        # restart, with no restart flag.
        Mock Test-Path { $false }
        $script:Renames = foreach ($file in @('MXDWDRV.DLL', 'PJLMON.DLL', 'PS5UI.DLL', 'PSCRIPT5.DLL', 'UNIDRV.DLL')) {
            "*1\??\C:\Windows\System32\spool\drivers\x64\3\New\$file"
            "\??\C:\Windows\System32\spool\drivers\x64\3\$file"
        }
        Mock Get-ItemProperty { [pscustomobject]@{ PendingFileRenameOperations = @($script:Renames) } }
        $results = Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26200 -EditionId Professional -InstallationType Client
        ($results | Where-Object Name -eq 'No pending reboot').Passed | Should -BeTrue
        $files = $results | Where-Object Name -eq 'No pending file replacements'
        $files.Passed | Should -BeTrue -Because 'without a restart flag nothing needs the user'
        $files.Blocking | Should -BeFalse
        $files.Detail | Should -BeLike '*C:\Windows\System32\spool\drivers\x64\3\New\MXDWDRV.DLL*'
    }

    It 'does not treat an unreadable reboot marker as absent' {
        Mock Test-Path { Write-Error 'registry access denied'; $false }
        { Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26200 -EditionId Professional -InstallationType Client } | Should -Throw '*registry access denied*'
    }

    It 'enforces the supported client edition contract independently of build' -TestCases @(
        @{ Edition = 'Professional'; Type = 'Client'; Passed = $true }
        @{ Edition = 'ProfessionalWorkstation'; Type = 'Client'; Passed = $true }
        @{ Edition = 'Enterprise'; Type = 'Client'; Passed = $true }
        @{ Edition = 'Education'; Type = 'Client'; Passed = $true }
        @{ Edition = 'ProfessionalN'; Type = 'Client'; Passed = $true }
        @{ Edition = 'Core'; Type = 'Client'; Passed = $false }
        @{ Edition = 'EnterpriseS'; Type = 'Client'; Passed = $false }
        @{ Edition = 'IoTEnterpriseS'; Type = 'Client'; Passed = $false }
        @{ Edition = 'ServerStandard'; Type = 'Server'; Passed = $false }
        @{ Edition = ''; Type = ''; Passed = $false }
    ) {
        param($Edition, $Type, $Passed)
        Mock Test-Path { $false }
        $requirements = @(Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26200 -EditionId $Edition -InstallationType $Type)
        $result = $requirements | Where-Object Name -eq 'Windows edition'
        $result.Passed | Should -Be $Passed
        $result.Blocking | Should -BeTrue
    }

    It 'copies playbook.conf and the Executables tree and refuses a package containing a reparse point' {
        $extracted = Join-Path $TestDrive 'extracted'
        New-Item -Path (Join-Path $extracted 'Executables\AtlasModules') -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $extracted 'playbook.conf') -Value '<Playbook/>'
        Set-Content -LiteralPath (Join-Path $extracted 'Executables\AtlasModules\x.txt') -Value 'x'
        $staging = Join-Path $TestDrive 'staging'
        New-Item -Path $staging -ItemType Directory -Force | Out-Null

        $payloadRoot = Copy-AtlasPayloadToStaging -ExtractedRoot $extracted -StagingRoot $staging
        $payloadRoot | Should -Be (Join-Path $staging 'Executables')
        Join-Path $staging 'playbook.conf' | Should -Exist
        Join-Path $payloadRoot 'AtlasModules\x.txt' | Should -Exist

        $junctionTarget = Join-Path $TestDrive 'elsewhere'
        New-Item -Path $junctionTarget -ItemType Directory -Force | Out-Null
        try {
            New-Item -Path (Join-Path $extracted 'Executables\Link') -ItemType Junction -Value $junctionTarget -ErrorAction Stop | Out-Null
        }
        catch {
            Set-ItResult -Skipped -Because 'this host cannot create junctions'
            return
        }
        { Copy-AtlasPayloadToStaging -ExtractedRoot $extracted -StagingRoot (Join-Path $TestDrive 'staging2') } |
            Should -Throw '*link or junction*'
    }

    It 'copies a reparse point that holds its own data and refuses one that is a <LinkType>' -TestCases @(
        @{ LinkType = 'SymbolicLink' }
        @{ LinkType = 'Junction' }
    ) {
        param($LinkType)
        # A OneDrive Files On-Demand placeholder is a reparse point with no link type.
        $extracted = Join-Path $TestDrive 'placeholder-pkg'
        $staging = Join-Path $TestDrive 'placeholder-staging'
        $script:ReparseLinkType = $null
        Mock Get-ChildItem -ParameterFilter { $Recurse } {
            [pscustomobject]@{
                FullName   = (Join-Path $extracted 'Executables\placeholder.txt')
                Attributes = [IO.FileAttributes]'Archive, ReparsePoint'
                LinkType   = $script:ReparseLinkType
            }
        }
        Mock Copy-Item {}
        { Copy-AtlasPayloadToStaging -ExtractedRoot $extracted -StagingRoot $staging } | Should -Not -Throw
        Should -Invoke Copy-Item -Times 2 -Exactly

        $script:ReparseLinkType = $LinkType
        { Copy-AtlasPayloadToStaging -ExtractedRoot $extracted -StagingRoot $staging } | Should -Throw '*link or junction*'
        Should -Invoke Copy-Item -Times 2 -Exactly
    }
}

Describe 'Restart notice text' {
    It 'defaults to the English notice and otherwise keeps the caller''s text within shutdown.exe limits' {
        Get-AtlasRestartComment -Comment $null | Should -Be 'Atlas installation complete.'
        Get-AtlasRestartComment -Comment '   ' | Should -Be 'Atlas installation complete.'
        $translated = 'Neustart: Atlas ist f' + [char]0x00FC + 'r Sie fertig ' + [char]0x2713
        Get-AtlasRestartComment -Comment "  $translated " | Should -BeExactly $translated
        Get-AtlasRestartComment -Comment "a`tb`r`nc`0d" | Should -Be 'a b  c d'
        (Get-AtlasRestartComment -Comment ('x' * 600)).Length | Should -Be 512
    }
}

Describe 'Install-user marker' {
    BeforeAll {
        # Stands in for HKEY_USERS: one subkey per loaded hive, named by its SID.
        function New-TestMarker {
            param([string]$Sid)
            $marker = $script:Users.CreateSubKey("$Sid\Software\AtlasOS\InstallSession")
            try {
                $marker.SetValue('Nonce', $script:Nonce, [Microsoft.Win32.RegistryValueKind]::String)
                $marker.SetValue('UserSid', $Sid, [Microsoft.Win32.RegistryValueKind]::String)
                $marker.SetValue('SessionId', 1, [Microsoft.Win32.RegistryValueKind]::DWord)
            }
            finally { $marker.Dispose() }
        }
    }

    BeforeEach {
        $script:UsersPath = "Software\AtlasRewriteTest\InstallUserMarker-$([guid]::NewGuid().ToString('N'))"
        $script:Users = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($script:UsersPath)
        $script:Nonce = [guid]::NewGuid().ToString('D')
    }

    AfterEach {
        $script:Users.Dispose()
        [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree($script:UsersPath, $false)
    }

    It 'names the work or school account whose hive holds the marker' {
        New-TestMarker -Sid 'S-1-12-1-2933642503-1247987907-1399130510-4207851353'
        $script:Users.CreateSubKey('S-1-5-21-111-222-333-1001\Software').Dispose()
        { Find-AtlasInstallUserMarker -Nonce $script:Nonce -UsersRoot $script:Users } |
            Should -Throw '*work or school (Microsoft Entra ID) account (S-1-12-1-2933642503-1247987907-1399130510-4207851353)*sign in with a local account*'
    }

    It 'finds the marker in a local or Microsoft account''s hive' {
        New-TestMarker -Sid 'S-1-12-1-2933642503-1247987907-1399130510-4207851353'
        New-TestMarker -Sid 'S-1-5-21-111-222-333-1001'
        $found = Find-AtlasInstallUserMarker -Nonce $script:Nonce -UsersRoot $script:Users
        $found.Sid | Should -Be 'S-1-5-21-111-222-333-1001'
        $found.SessionId | Should -Be 1
    }
}

Describe 'Front door staging copies' {
    BeforeAll {
        function New-TestStagingCopy {
            param([string]$Root)
            foreach ($file in @(
                    'playbook.conf'
                    'Executables\request.json'
                    'Executables\AtlasModules\Logs\install-run.log'
                    'Executables\AtlasModules\Scripts\Entry\Install-Atlas.ps1'
                    'Executables\AtlasModules\Packages\x.cab'
                    'Executables\AtlasDesktop\readme.txt'
                    'Preparation\worker.log'
                    'Preparation\state.json'
                )) {
                $path = Join-Path $Root $file
                [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path))
                Set-Content -LiteralPath $path -Value 'x'
            }
        }
        function Get-TestStagedFile {
            param([string]$Root)
            @(Get-ChildItem -LiteralPath $Root -Recurse -File -Force | ForEach-Object { $_.FullName.Substring($Root.Length + 1) } | Sort-Object)
        }
        $script:Evidence = @(
            'Executables\AtlasModules\Logs\install-run.log'
            'Executables\request.json'
            'Preparation\state.json'
            'Preparation\worker.log'
        )
    }

    It 'keeps only what diagnostics export when it removes a copy''s package files' {
        $copy = Join-Path $TestDrive 'Staging\one'
        New-TestStagingCopy -Root $copy
        Remove-AtlasStagedPackage -StagingRoot $copy
        Get-TestStagedFile -Root $copy | Should -Be $script:Evidence
        { Remove-AtlasStagedPackage -StagingRoot $copy } | Should -Not -Throw
        { Remove-AtlasStagedPackage -StagingRoot (Join-Path $TestDrive 'Staging\missing') } | Should -Not -Throw
    }

    It 'tidies only the copies that earlier attempts left' {
        $staging = Join-Path $TestDrive 'Tidy'
        $now = [DateTime]::UtcNow
        foreach ($copy in @(@{ Name = 'earlier'; Age = 60 }, @{ Name = 'current'; Age = 10 }, @{ Name = 'later'; Age = 0 })) {
            $root = Join-Path $staging $copy.Name
            New-TestStagingCopy -Root $root
            [IO.Directory]::SetCreationTimeUtc($root, $now.AddMinutes(-$copy.Age))
        }
        $all = Get-TestStagedFile -Root (Join-Path $staging 'current')

        Remove-AtlasEarlierStagedPackage -StagingRoot (Join-Path $staging 'current')
        Get-TestStagedFile -Root (Join-Path $staging 'earlier') | Should -Be $script:Evidence
        Get-TestStagedFile -Root (Join-Path $staging 'current') | Should -Be $all
        Get-TestStagedFile -Root (Join-Path $staging 'later') | Should -Be $all -Because 'another run may still be using a newer copy'
    }
}

Describe 'Front door phase failures' {
    It 'keeps the broker''s message and ends with what to do next' -TestCases @(
        @{ Phase = 'Capture'; Message = 'Install capture failed: *'; Log = 'install-capture.log'; Next = 'try again.' }
        @{ Phase = 'Run'; Message = 'The install plan failed: *'; Log = 'install-run.log'; Next = 'resume.' }
    ) {
        param($Phase, $Message, $Log, $Next)
        Mock Invoke-AtlasTrustedInstaller { throw "'powershell.exe' exited with disallowed code 1. Output: the end of the phase log" }
        $payload = 'C:\Windows\AtlasOS\Staging\0123\Executables'
        $thrown = $null
        try { Invoke-AtlasInstallPhase -Phase $Phase -PayloadRoot $payload -TimeoutSeconds 60 }
        catch { $thrown = $_.Exception.Message }
        $thrown | Should -BeLike $Message
        $thrown | Should -BeLike "*disallowed code 1. Output: the end of the phase log The full log is '$payload\AtlasModules\Logs\$Log'. Re-run this script with the same options to $Next"
        Should -Invoke Invoke-AtlasTrustedInstaller -Times 1 -Exactly -ParameterFilter {
            $Operation -eq 'Install' -and $InstallPhase -eq $Phase -and $PayloadRoot -eq $payload -and $TimeoutSeconds -eq 60
        }
    }

    It 'returns nothing when the broker succeeds' {
        Mock Invoke-AtlasTrustedInstaller { [pscustomobject]@{ ExitCode = 0; StandardOutput = 'done'; StandardError = '' } }
        Invoke-AtlasInstallPhase -Phase Run -PayloadRoot 'C:\Windows\AtlasOS\Staging\0123\Executables' -TimeoutSeconds 60 | Should -BeNullOrEmpty
    }
}

Describe 'Front door script body' {
    BeforeAll {
        # The lifted functions can't show what the script body does with them.
        $script:FrontDoorAst = [Management.Automation.Language.Parser]::ParseFile($script:FrontDoorScript, [ref]$null, [ref]$null)
        function Get-ScriptCommandCall {
            param([Management.Automation.Language.Ast]$Ast, [string]$Name)
            foreach ($command in $Ast.FindAll({ param($node) $node -is [Management.Automation.Language.CommandAst] }, $true)) {
                if ($command.GetCommandName() -eq $Name) { $command }
            }
        }
        function Test-InScriptFunction {
            param([Management.Automation.Language.Ast]$Ast)
            for ($parent = $Ast.Parent; $null -ne $parent; $parent = $parent.Parent) {
                if ($parent -is [Management.Automation.Language.FunctionDefinitionAst]) { return $true }
            }
            return $false
        }
    }

    It 'forwards -WindowsSecurityConfirmed to the requirement check' {
        $calls = @(Get-ScriptCommandCall -Ast $script:FrontDoorAst -Name 'Test-AtlasInstallRequirement' | Where-Object { -not (Test-InScriptFunction -Ast $_) })
        $calls.Count | Should -Be 1
        $parameter = @($calls[0].CommandElements | Where-Object {
                $_ -is [Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq 'WindowsSecurityConfirmed'
            })
        $parameter.Count | Should -Be 1
        $parameter[0].Argument | Should -BeOfType [Management.Automation.Language.VariableExpressionAst]
        $parameter[0].Argument.VariablePath.UserPath | Should -Be 'WindowsSecurityConfirmed'
    }

    It 'strips the staging copy before exit 5 and in the catch before the broker starts' {
        $exitFive = $script:FrontDoorAst.Find({
                param($node)
                $node -is [Management.Automation.Language.ExitStatementAst] -and "$($node.Pipeline)" -eq '5'
            }, $true)
        @(Get-ScriptCommandCall -Ast $exitFive.Parent -Name 'Remove-AtlasStagedPackage').Count | Should -Be 1
        $try = @($script:FrontDoorAst.EndBlock.Statements | Where-Object { $_ -is [Management.Automation.Language.TryStatementAst] })
        $try.Count | Should -Be 1
        @(Get-ScriptCommandCall -Ast $try[0].CatchClauses[0].Body -Name 'Remove-AtlasStagedPackage').Count | Should -Be 1
    }
}
