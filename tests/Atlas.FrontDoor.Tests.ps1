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
    foreach ($text in @(Get-ScriptFunctionText -Path $script:SessionScript -Names 'Read-AtlasInstallRequest', 'Assert-AtlasInstallOptionSet', 'Invoke-AtlasInstallCapture') +
        @(Get-ScriptFunctionText -Path $script:FrontDoorScript -Names 'Get-AtlasDeclaredRequirement', 'Test-AtlasDefenderPresent', 'Get-AtlasDefenderSwitch', 'Test-AtlasDefenderPrepared', 'Invoke-AtlasPreparationCheck', 'Test-AtlasPreparationCurrent', 'Get-AtlasPowerStatus', 'Test-AtlasPowerConnected', 'Test-AtlasUserAccountReady', 'Test-AtlasInstallRequirement', 'Copy-AtlasPayloadToStaging', 'Get-AtlasRestartComment', 'New-AtlasProtectedStagingRoot', 'New-AtlasFrontDoorDirectorySecurity', 'Remove-AtlasStagedPackage', 'Remove-AtlasEarlierStagedPackage', 'Invoke-AtlasInstallPhase', 'New-AtlasInstallRequest', 'Format-AtlasTakenChoice', 'Get-AtlasInstallProbe', 'Read-AtlasCapturedOption') +
        @(Get-ScriptFunctionText -Path $script:StateScript -Names 'Find-AtlasInstallUserMarker', 'Start-AtlasWizardInstallState')) {
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
        $request = Read-AtlasInstallRequest -PayloadRoot $payload
        @($request.Options) | Should -Be @('defender-enable')
        $request.Choices | Should -BeExactly 'Keep' -Because 'a request without the field keeps the choices'

        Set-Content -LiteralPath (Join-Path $payload 'request.json') -Value '{"options":[],"mode":"Fresh"}'
        { Read-AtlasInstallRequest -PayloadRoot $payload } | Should -Throw "*unknown field 'mode'*"
        Set-Content -LiteralPath (Join-Path $payload 'request.json') -Value '{"options":[],"windowsSetup":true}'
        { Read-AtlasInstallRequest -PayloadRoot $payload } | Should -Throw "*unknown field 'windowsSetup'*"

        # Valid JSON on both sides of the 64 KiB limit, so only the size check can refuse it.
        $atLimit = '{"options":["' + ('a' * (65536 - 16)) + '"]}'
        [IO.File]::WriteAllText((Join-Path $payload 'request.json'), $atLimit)
        @((Read-AtlasInstallRequest -PayloadRoot $payload).Options) | Should -HaveCount 1
        [IO.File]::WriteAllText((Join-Path $payload 'request.json'), $atLimit.Replace('"a', '"aa'))
        { Read-AtlasInstallRequest -PayloadRoot $payload } | Should -Throw '*exceeds its size limit*'

        Remove-Item -LiteralPath (Join-Path $payload 'request.json')
        { Read-AtlasInstallRequest -PayloadRoot $payload } | Should -Throw '*missing*'
    }

    It 'reads how an update treats the choices, accepting only Keep and ChooseAgain' {
        $payload = Join-Path $TestDrive 'choices-payload'
        New-Item -Path $payload -ItemType Directory -Force | Out-Null
        foreach ($choices in @('Keep', 'ChooseAgain')) {
            Set-Content -LiteralPath (Join-Path $payload 'request.json') -Value "{""options"":[""defender-enable""],""choices"":""$choices""}"
            (Read-AtlasInstallRequest -PayloadRoot $payload).Choices | Should -BeExactly $choices
        }
        foreach ($value in @('"chooseagain"', '"Rebase"', '""', 'null', 'true', '["Keep"]')) {
            Set-Content -LiteralPath (Join-Path $payload 'request.json') -Value "{""options"":[],""choices"":$value}"
            { Read-AtlasInstallRequest -PayloadRoot $payload } | Should -Throw "*choices must be 'Keep' or 'ChooseAgain'*" -Because $value
        }
    }

    It 'writes the request Capture reads, ChooseAgain only with -ChooseAgain' {
        $payload = Join-Path $TestDrive 'written-payload'
        New-Item -Path $payload -ItemType Directory -Force | Out-Null
        foreach ($case in @(@{ ChooseAgain = $false; Choices = 'Keep' }, @{ ChooseAgain = $true; Choices = 'ChooseAgain' })) {
            [IO.File]::WriteAllText((Join-Path $payload 'request.json'), (New-AtlasInstallRequest -Option @('mitigations-default', 'defender-enable', 'defender-enable') -ChooseAgain:$case.ChooseAgain))
            $request = Read-AtlasInstallRequest -PayloadRoot $payload
            @($request.Options) | Should -Be @('defender-enable', 'mitigations-default')
            $request.Choices | Should -BeExactly $case.Choices
        }
        # One option is still an array.
        New-AtlasInstallRequest -Option 'defender-enable' | Should -BeExactly '{"options":["defender-enable"],"choices":"Keep"}'
    }

    It 'names each choice Capture took from the PC, and nothing when it took none' {
        Format-AtlasTakenChoice -Requested @('defender-enable', 'disable-hibernation', 'mitigations-disable') `
            -Recorded @('defender-disable', 'mitigations-default') |
            Should -BeExactly 'Choices taken from this PC instead of the request: defender-disable (Microsoft Defender), mitigations-default (Processor protections), disable-hibernation left out (Turn off hibernation).'
        # A repeated option is the same request.
        Format-AtlasTakenChoice -Requested @('defender-enable', 'defender-enable') -Recorded @('defender-enable') | Should -BeNullOrEmpty
    }

    Context 'after Capture' {
        BeforeEach {
            Mock Write-Warning {}
        }

        It 'names the choices Capture took from the PC and the options a resume must give' {
            Mock Get-AtlasInstallState { [pscustomobject]@{ options = @('defender-disable', 'mitigations-default') } }
            $captured = Read-AtlasCapturedOption -Option @('defender-enable', 'mitigations-default')
            $captured.Line | Should -BeExactly 'Choices taken from this PC instead of the request: defender-disable (Microsoft Defender).'
            @($captured.ResumeOptions) | Should -Be @('defender-disable', 'mitigations-default')
        }

        It 'gives nothing when Capture recorded the request' {
            Mock Get-AtlasInstallState { [pscustomobject]@{ options = @('mitigations-default', 'defender-enable') } }
            $captured = Read-AtlasCapturedOption -Option @('defender-enable', 'mitigations-default')
            $captured.Line | Should -BeNullOrEmpty
            $null -eq $captured.ResumeOptions | Should -BeTrue
        }

        It 'only warns when the recorded choices can''t be read' {
            Mock Get-AtlasInstallState { throw 'state locked' }
            $captured = Read-AtlasCapturedOption -Option @('defender-enable')
            $captured.Line | Should -BeNullOrEmpty
            $null -eq $captured.ResumeOptions | Should -BeTrue
            Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter { $Message -eq "The recorded choices couldn't be read: state locked" }
        }
    }
}

Describe 'Front door probe before the requirements' {
    BeforeAll {
        # Defined by WindowsTransition.ps1, which the front door loads.
        function Get-AtlasInstalledAtlasPackage { throw 'Unmocked package read' }
        $script:Probe = @{ TargetVersion = '0.6.0'; WindowsPath = 'C:\Windows'; Option = @('defender-enable', 'mitigations-default') }
    }
    BeforeEach {
        Mock Resolve-AtlasInstallMode { 'Upgrade' }
        Mock Resolve-AtlasInstallChoices { [pscustomobject]@{ Choices = $Requested; Summary = ''; Note = $null; ResumedOptions = $null } }
        Mock Get-AtlasInstalledAtlasPackage { 'Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~5.0.0.0' }
    }

    It 'reads the mode, the way this installation treats the choices and Atlas''s packages' {
        $probe = Get-AtlasInstallProbe @script:Probe -ChooseAgain
        $probe.Mode | Should -BeExactly 'Upgrade'
        $probe.Choices | Should -BeExactly 'ChooseAgain'
        @($probe.AtlasPackages) | Should -Be @('Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~5.0.0.0')
        $null -eq $probe.ResumeOptions | Should -BeTrue
        Should -Invoke Resolve-AtlasInstallChoices -Times 1 -Exactly -ParameterFilter { $Mode -eq 'Upgrade' -and $Requested -eq 'ChooseAgain' -and $TargetVersion -eq '0.6.0' }
    }

    It 'takes the way an unfinished installation began, not the switch' {
        Mock Resolve-AtlasInstallChoices { [pscustomobject]@{ Choices = 'Keep'; Summary = ''; Note = 'Continuing'; ResumedOptions = @('mitigations-default', 'defender-enable') } }
        $probe = Get-AtlasInstallProbe @script:Probe -ChooseAgain
        $probe.Choices | Should -BeExactly 'Keep'
        $null -eq $probe.ResumeOptions | Should -BeTrue -Because 'the options given are the ones it began with'
    }

    It 'names the options an unfinished installation began with when they aren''t the ones given' {
        Mock Resolve-AtlasInstallChoices { [pscustomobject]@{ Choices = 'Keep'; Summary = ''; Note = $null; ResumedOptions = @('defender-disable', 'mitigations-default') } }
        @((Get-AtlasInstallProbe @script:Probe).ResumeOptions) | Should -Be @('defender-disable', 'mitigations-default')
    }

    It 'leaves out what it can''t read, and still reads the rest: <Case>' -TestCases @(
        @{ Case = 'no mode'; Failing = 'Resolve-AtlasInstallMode'; Mode = $null; Choices = $null; Packages = $true }
        @{ Case = 'a refused way'; Failing = 'Resolve-AtlasInstallChoices'; Mode = 'Upgrade'; Choices = $null; Packages = $true }
        @{ Case = 'no packages'; Failing = 'Get-AtlasInstalledAtlasPackage'; Mode = 'Upgrade'; Choices = 'Keep'; Packages = $false }
    ) {
        param($Case, $Failing, $Mode, $Choices, $Packages)
        Mock $Failing { throw 'unreadable' }
        $probe = Get-AtlasInstallProbe @script:Probe
        $probe.Mode | Should -Be $Mode -Because $Case
        $probe.Choices | Should -Be $Choices -Because $Case
        ($null -ne $probe.AtlasPackages) | Should -Be $Packages -Because $Case
    }

    It 'tells no packages apart from packages it couldn''t read' {
        Mock Get-AtlasInstalledAtlasPackage { }
        $probe = Get-AtlasInstallProbe @script:Probe
        $null -eq $probe.AtlasPackages | Should -BeFalse
        @($probe.AtlasPackages) | Should -HaveCount 0
    }
}

Describe 'Install capture' {
    BeforeAll {
        $script:Target = Get-AtlasPlaybookVersion -PlaybookPath $script:PlaybookPath
        $script:Asked = @('auto-updates-disable', 'defender-enable', 'keyboard-shortcuts', 'mitigations-default')
        # What the PC shows: Atlas's NoDefender package is installed.
        $script:Shown = @('auto-updates-disable', 'defender-disable', 'keyboard-shortcuts', 'mitigations-default')
        function Write-AtlasSessionLog { param([string]$Message) $script:SessionLines.Add($Message) }
        function Invoke-TestCapture {
            param([string]$Choices)
            $payload = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            New-Item -Path $payload -ItemType Directory -Force | Out-Null
            [IO.File]::WriteAllText((Join-Path $payload 'request.json'), (@{ options = $script:Asked; choices = $Choices } | ConvertTo-Json -Compress))
            Invoke-AtlasInstallCapture -PlaybookPath $script:PlaybookPath -PayloadRoot $payload
        }
        function ConvertTo-TestCall {
            param([string[]]$Calls)
            @($Calls | ForEach-Object { $_.Replace('<asked>', ($script:Asked -join ',')).Replace('<shown>', ($script:Shown -join ',')) })
        }
    }
    BeforeEach {
        $script:SessionLines = New-Object 'Collections.Generic.List[string]'
        $script:CaptureCalls = New-Object 'Collections.Generic.List[string]'
        $script:ActiveState = $null
        $script:CaptureMode = 'Upgrade'
        $script:KeptOptions = $script:Shown
        # The real Resolve-AtlasInstallChoices reads this.
        Mock Get-AtlasInstallState -ModuleName Atlas.InstallState { $script:ActiveState }
        Mock Resolve-AtlasInstallMode { $script:CaptureMode }
        Mock Get-AtlasInstalledVersion { '0.5.0' }
        Mock Repair-AtlasToolboxRecord {
            $script:CaptureCalls.Add("Repair:$InstalledVersion")
            "Removed the 'Mitigations' record (state 2): only the old Atlas Toolbox wrote it, and its choices never reached this PC."
        }
        Mock Resolve-AtlasKeptOption {
            $script:CaptureCalls.Add("Kept:$(@($Requested) -join ',')")
            [pscustomobject]@{
                Options  = $script:KeptOptions
                Changes  = @([pscustomobject]@{ Message = "Kept 'defender-disable' for Microsoft Defender instead of the requested 'defender-enable'." })
                Warnings = @('A reading failed.')
            }
        }
        Mock Start-AtlasInstallState { $script:CaptureCalls.Add("Start:${Mode}:$Choices"); [pscustomobject]@{} }
        Mock Set-AtlasInstallOptions { $script:CaptureCalls.Add("Options:$(@($Options) -join ',')") }
    }

    It 'captures <Case>' -TestCases @(
        @{ Case = 'an upgrade keeping the choices, migrating the old records before reading the PC'; Mode = 'Upgrade'; Choices = 'Keep'
            Calls = @('Repair:0.5.0', 'Kept:<asked>', 'Start:Upgrade:Keep', 'Options:<shown>'); Summary = 'Upgrade, keeping your choices'; Recorded = 'shown' }
        @{ Case = 'an upgrade choosing again'; Mode = 'Upgrade'; Choices = 'ChooseAgain'
            Calls = @('Repair:0.5.0', 'Start:Upgrade:ChooseAgain', 'Options:<asked>'); Summary = 'Upgrade, choosing again'; Recorded = 'asked' }
        @{ Case = 'a reinstall keeping the choices'; Mode = 'Reapply'; Choices = 'Keep'
            Calls = @('Repair:0.5.0', 'Kept:<asked>', 'Start:Reapply:Keep', 'Options:<shown>'); Summary = 'Reapply, keeping your choices'; Recorded = 'shown' }
        @{ Case = 'a reinstall choosing again'; Mode = 'Reapply'; Choices = 'ChooseAgain'
            Calls = @('Repair:0.5.0', 'Start:Reapply:ChooseAgain', 'Options:<asked>'); Summary = 'Reapply, choosing again'; Recorded = 'asked' }
        @{ Case = 'a Rebase, whose choices the PC no longer shows'; Mode = 'Rebase'; Choices = 'Keep'
            Calls = @('Repair:0.5.0', 'Start:Rebase:Keep', 'Options:<asked>'); Summary = 'Rebase, keeping your choices'; Recorded = 'asked' }
        @{ Case = 'a first installation asked to choose again'; Mode = 'Fresh'; Choices = 'ChooseAgain'
            Calls = @('Start:Fresh:Keep', 'Options:<asked>'); Summary = 'Fresh'; Recorded = 'asked' }
    ) {
        param($Case, $Mode, $Choices, $Calls, $Summary, $Recorded)
        $script:CaptureMode = $Mode
        $message = Invoke-TestCapture -Choices $Choices

        $script:CaptureCalls.ToArray() | Should -Be (ConvertTo-TestCall $Calls) -Because $Case
        $script:SessionLines[0] | Should -BeExactly "Install mode: $Summary."
        $options = if ($Recorded -eq 'shown') { $script:Shown } else { $script:Asked }
        $message | Should -BeExactly "Atlas install state ready for $Mode of $script:Target with options: $($options -join ', ')."
        if ($Calls -contains 'Repair:0.5.0') {
            $script:SessionLines | Should -Contain "Removed the 'Mitigations' record (state 2): only the old Atlas Toolbox wrote it, and its choices never reached this PC."
        }
        if ($Calls -contains 'Kept:<asked>') {
            $script:SessionLines | Should -Contain 'WARNING: A reading failed.'
            $script:SessionLines | Should -Contain "Kept 'defender-disable' for Microsoft Defender instead of the requested 'defender-enable'."
        }
        if ($Mode -eq 'Fresh') {
            $script:SessionLines | Should -Contain 'A first installation applies every choice, so -ChooseAgain changes nothing.'
        }
    }

    It 'refuses to choose again on a Rebase before it changes anything' {
        $script:CaptureMode = 'Rebase'
        { Invoke-TestCapture -Choices ChooseAgain } | Should -Throw '*Run it again without -ChooseAgain*'
        $script:CaptureCalls.ToArray() | Should -HaveCount 0
    }

    It 'continues a run whose steps began as it began, without migrating or reading the PC again: <Case>' -TestCases @(
        @{ Case = 'an upgrade from Atlas 0.5.0 that keeps the choices'; Mode = 'Upgrade'; Began = 'Keep'; Asked = 'Keep'; Note = $null }
        @{ Case = 'a reinstall that began choosing again'; Mode = 'Reapply'; Began = 'ChooseAgain'; Asked = 'Keep'
            Note = "Continuing the unfinished installation as it began, choosing again; its choices can't change now." }
    ) {
        param($Case, $Mode, $Began, $Asked, $Note)
        $script:CaptureMode = $Mode
        $script:ActiveState = [pscustomobject]@{
            targetVersion = $script:Target; status = 'Running'; mode = $Mode; completedSteps = @('Environment', 'LegacyChoices')
            options = $script:Asked; choices = $Began
        }
        Invoke-TestCapture -Choices $Asked | Out-Null

        $script:CaptureCalls.ToArray() | Should -Be (ConvertTo-TestCall @("Start:${Mode}:$Began", 'Options:<asked>')) -Because $Case
        Should -Invoke Repair-AtlasToolboxRecord -Times 0 -Exactly
        Should -Invoke Resolve-AtlasKeptOption -Times 0 -Exactly
        if ($Note) { $script:SessionLines | Should -Contain $Note }
    }

    It 'is what the Capture phase runs' {
        $ast = [Management.Automation.Language.Parser]::ParseFile($script:SessionScript, [ref]$null, [ref]$null)
        $switch = $ast.Find({ param($node) $node -is [Management.Automation.Language.SwitchStatementAst] }, $true)
        $capture = @($switch.Clauses | Where-Object { $_.Item1.Extent.Text -ceq "'Capture'" })
        $capture.Count | Should -Be 1
        @($capture[0].Item2.Statements)[0].Extent.Text |
            Should -BeExactly '$message = Invoke-AtlasInstallCapture -PlaybookPath $playbookPath -PayloadRoot $payloadRoot'
    }

    It 'checks the choices taken from the PC against the package before recording them' {
        $script:CaptureMode = 'Reapply'
        $script:KeptOptions = @('auto-updates-disable', 'defender-disable', 'defender-enable', 'keyboard-shortcuts', 'mitigations-default')
        { Invoke-TestCapture -Choices Keep } | Should -Throw '*Exactly one of defender-*'
        Should -Invoke Start-AtlasInstallState -Times 0 -Exactly
    }
}

Describe 'AME Wizard''s start of an install' {
    BeforeAll {
        $script:Target = Get-AtlasPlaybookVersion -PlaybookPath $script:PlaybookPath
        $script:Repaired = "Removed the 'Mitigations' record (state 2): only the old Atlas Toolbox wrote it, and its choices never reached this PC."
    }
    BeforeEach {
        $script:WizardCalls = New-Object 'Collections.Generic.List[string]'
        $script:ActiveState = $null
        # The real Resolve-AtlasInstallChoices reads this.
        Mock Get-AtlasInstallState -ModuleName Atlas.InstallState { $script:ActiveState }
        Mock Get-AtlasPlaybookVersion { $script:Target }
        Mock Get-AtlasInstalledVersion { '0.5.0' }
        Mock Repair-AtlasToolboxRecord { $script:WizardCalls.Add("Repair:$InstalledVersion"); $script:Repaired }
        Mock Start-AtlasInstallState { $script:WizardCalls.Add("Start:$Mode"); [pscustomobject]@{ mode = $Mode; isOobe = $IsOobe } }
    }

    It 'repairs records before an AME <Mode>, as Capture does' -TestCases @(
        @{ Mode = 'Upgrade' }, @{ Mode = 'Reapply' }
    ) {
        param($Mode)
        $lines = @(Start-AtlasWizardInstallState -Mode $Mode -IsOobe $true)

        $script:WizardCalls.ToArray() | Should -Be @("Start:$Mode", 'Repair:0.5.0')
        $lines | Should -Be @($script:Repaired, "Atlas install state ready for $Mode (OOBE=True).")
    }

    It 'leaves the records alone for <Case>' -TestCases @(
        @{ Case = 'a first installation'; Mode = 'Fresh'; Active = $null }
        @{ Case = 'an update whose steps began, which has rewritten them already'; Mode = 'Upgrade'
            Active = @{ status = 'Running'; mode = 'Upgrade'; completedSteps = @('Checkpoint/LegacyChoices'); options = @('defender-enable') } }
        @{ Case = 'an update stopped after its first steps'; Mode = 'Upgrade'
            Active = @{ status = 'Capturing'; mode = 'Upgrade'; completedSteps = @('Checkpoint/DefaultHiveLoad'); options = @('defender-enable') } }
    ) {
        param($Case, $Mode, $Active)
        if ($null -ne $Active) { $script:ActiveState = [pscustomobject]($Active + @{ targetVersion = $script:Target }) }
        $lines = @(Start-AtlasWizardInstallState -Mode $Mode -IsOobe $false)

        Should -Invoke Repair-AtlasToolboxRecord -Times 0 -Exactly -Because $Case
        $lines | Should -Be @("Atlas install state ready for $Mode (OOBE=False).")
    }

    It 'changes no record when another install holds the PC' {
        Mock Start-AtlasInstallState { throw "An install state for target '0.6.1' is already active." }
        { Start-AtlasWizardInstallState -Mode Upgrade -IsOobe $false } | Should -Throw '*already active*'
        Should -Invoke Repair-AtlasToolboxRecord -Times 0 -Exactly
    }

    It 'is what Begin runs' {
        $ast = [Management.Automation.Language.Parser]::ParseFile($script:StateScript, [ref]$null, [ref]$null)
        $switch = $ast.Find({ param($node) $node -is [Management.Automation.Language.SwitchStatementAst] }, $true)
        $begin = @($switch.Clauses | Where-Object { $_.Item1.Extent.Text -ceq "'Begin'" })
        $begin.Count | Should -Be 1
        @($begin[0].Item2.Statements)[-1].Extent.Text | Should -BeExactly 'Start-AtlasWizardInstallState -Mode $Mode -IsOobe ([bool]$Oobe)'
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

    Context 'Windows Security without Microsoft Defender' {
        BeforeAll {
            $script:NoDefender = 'Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~5.0.0.0'
            $script:NoTelemetry = 'Z-Atlas-NoTelemetry-Package~31bf3856ad364e35~amd64~~5.0.0.0'
        }
        BeforeEach {
            Mock Test-Path { $false }
            Mock Test-AtlasDefenderPresent { $false }
            # The switches belong to the Defender service, so they are never read without it.
            Mock Get-AtlasDefenderSwitch { throw "Cannot find path 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Features' because it does not exist." }
        }

        It 'says truthfully what this installation does with it: <Case>' -TestCases @(
            @{ Case = 'restored on a fresh installation'; Packages = @('NoDefender'); Option = 'defender-enable'; Mode = 'Fresh'; ChooseAgain = $false
                Passed = $true; Blocking = $true; Detail = "Microsoft Defender was removed by Atlas's NoDefender package; this installation takes that package off, so Defender is back after the restart. There is nothing to turn off now" }
            @{ Case = 'restored on a Rebase'; Packages = @('NoDefender', 'NoTelemetry'); Option = 'defender-enable'; Mode = 'Rebase'; ChooseAgain = $false
                Passed = $true; Blocking = $true; Detail = "Microsoft Defender was removed by Atlas's NoDefender package; this installation takes that package off*" }
            @{ Case = 'restored choosing again'; Packages = @('NoDefender'); Option = 'defender-enable'; Mode = 'Reapply'; ChooseAgain = $true
                Passed = $true; Blocking = $true; Detail = "Microsoft Defender was removed by Atlas's NoDefender package; this installation takes that package off*" }
            @{ Case = 'kept removed, keeping the choices'; Packages = @('NoDefender'); Option = 'defender-enable'; Mode = 'Upgrade'; ChooseAgain = $false
                Passed = $false; Blocking = $false; Detail = "Microsoft Defender was removed by Atlas's NoDefender package, and keeping your choices leaves it removed, so this installation records it as removed. To bring it back, run again with -ChooseAgain, or use Toggle Defender in the Atlas folder afterwards" }
            @{ Case = 'removed, as chosen'; Packages = @('NoDefender'); Option = 'defender-disable'; Mode = 'Reapply'; ChooseAgain = $false
                Passed = $true; Blocking = $true; Detail = "Microsoft Defender was removed by Atlas's NoDefender package, so there is nothing to turn off" }
            @{ Case = 'missing, though kept'; Packages = @('NoTelemetry'); Option = 'defender-enable'; Mode = 'Reapply'; ChooseAgain = $true
                Passed = $false; Blocking = $false; Detail = "Microsoft Defender isn't on this PC, and no Atlas package removed it, so this installation can't bring it back. Install another antivirus app, or repair Windows to get Defender back" }
            @{ Case = 'missing on a fresh installation'; Packages = @(); Option = 'defender-enable'; Mode = 'Fresh'; ChooseAgain = $false
                Passed = $false; Blocking = $false; Detail = "Microsoft Defender isn't on this PC, and no Atlas package removed it*" }
            @{ Case = 'missing, and removal chosen'; Packages = @(); Option = 'defender-disable'; Mode = 'Fresh'; ChooseAgain = $false
                Passed = $true; Blocking = $true; Detail = "Microsoft Defender isn't on this PC, so there is nothing to turn off" }
            # The mode couldn't be probed, so nothing is said about this installation.
            @{ Case = 'removed by Atlas, mode unknown'; Packages = @('NoDefender'); Option = 'defender-enable'; Mode = $null; ChooseAgain = $false
                Passed = $true; Blocking = $true; Detail = "Microsoft Defender was removed by Atlas's NoDefender package, so there is nothing to turn off" }
            @{ Case = 'missing, mode unknown'; Packages = @(); Option = 'defender-enable'; Mode = $null; ChooseAgain = $true
                Passed = $true; Blocking = $true; Detail = "Microsoft Defender isn't on this PC, so there is nothing to turn off" }
            # Nor when Atlas's packages couldn't be read.
            @{ Case = 'missing, packages unread'; Packages = $null; Option = 'defender-enable'; Mode = 'Upgrade'; ChooseAgain = $false
                Passed = $true; Blocking = $true; Detail = "Microsoft Defender isn't on this PC, so there is nothing to turn off" }
        ) {
            param($Case, $Packages, $Option, $Mode, $ChooseAgain, $Passed, $Blocking, $Detail)
            $installed = $null
            if ($null -ne $Packages) {
                $installed = @($Packages | ForEach-Object { if ($_ -eq 'NoDefender') { $script:NoDefender } else { $script:NoTelemetry } })
            }
            $result = Get-TestRequirement -Name 'Windows Security' -Arguments @{
                DeclaredRequirements = @('DefenderToggled'); Option = @($Option, 'mitigations-default'); Mode = $Mode
                ChooseAgain = $ChooseAgain; AtlasPackages = $installed
            }
            $result.Passed | Should -Be $Passed -Because $Case
            $result.Blocking | Should -Be $Blocking -Because $Case
            $result.Detail | Should -BeLike $Detail -Because $Case
            $result.Detail | Should -Not -BeLike '*earlier Atlas install*'
            Should -Invoke Get-AtlasDefenderSwitch -Times 0
        }
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
        try { Invoke-AtlasInstallPhase -Phase $Phase -PayloadRoot $payload -TimeoutSeconds 60 -MachineLogRoot (Join-Path $TestDrive 'no-machine-logs') }
        catch { $thrown = $_.Exception.Message }
        $thrown | Should -BeLike $Message
        $thrown | Should -BeLike "*disallowed code 1. Output: the end of the phase log The full log is '$payload\AtlasModules\Logs\$Log'. Re-run this script with the same options to $Next"
        Should -Invoke Invoke-AtlasTrustedInstaller -Times 1 -Exactly -ParameterFilter {
            $Operation -eq 'Install' -and $InstallPhase -eq $Phase -and $PayloadRoot -eq $payload -and $TimeoutSeconds -eq 60
        }
    }

    It 'names the copy of the phase log the machine keeps, never an older one' {
        $logs = Join-Path $TestDrive "machine-logs-$([guid]::NewGuid().ToString('N'))"
        New-Item -Path $logs -ItemType Directory -Force | Out-Null
        $older = Join-Path $logs '20260101-000000-install-run.log'
        Set-Content -LiteralPath $older -Value 'an earlier install'
        [IO.File]::SetLastWriteTimeUtc($older, [DateTime]::UtcNow.AddHours(-1))
        $script:CopyPath = Join-Path $logs '20261031-120000-install-run.log'
        Mock Invoke-AtlasTrustedInstaller { Set-Content -LiteralPath $script:CopyPath -Value 'this run'; throw 'phase failed.' }

        { Invoke-AtlasInstallPhase -Phase Run -PayloadRoot 'C:\Staging\Executables' -TimeoutSeconds 60 -MachineLogRoot $logs } |
            Should -Throw "The install plan failed: phase failed. The full log is '$script:CopyPath'. Re-run this script with the same options to resume."

        # A phase that left no copy of its own names the staged log, not an earlier install's.
        Remove-Item -LiteralPath $script:CopyPath
        Mock Invoke-AtlasTrustedInstaller { throw 'phase failed.' }
        { Invoke-AtlasInstallPhase -Phase Run -PayloadRoot 'C:\Staging\Executables' -TimeoutSeconds 60 -MachineLogRoot $logs } |
            Should -Throw "*The full log is 'C:\Staging\Executables\AtlasModules\Logs\install-run.log'.*"
    }

    It 'says how to resume: <Case>' -TestCases @(
        @{ Case = 'choosing again'; Phase = 'Run'; Arguments = @{ ChooseAgain = $true }; Next = 'Re-run this script with the same options and -ChooseAgain to resume.' }
        @{ Case = 'with the choices taken from the PC'; Phase = 'Run'; Arguments = @{ ResumeOptions = @('defender-disable', 'mitigations-default') }
            Next = 'Re-run this script with the options it recorded, -Option defender-disable,mitigations-default, to resume.' }
        # An unfinished installation's option lock refuses the options given.
        @{ Case = 'with the options an unfinished installation started with'; Phase = 'Capture'; Arguments = @{ ResumeOptions = @('defender-disable', 'mitigations-default') }
            Next = 'Re-run this script with the options it started with, -Option defender-disable,mitigations-default, to try again.' }
    ) {
        param($Case, $Phase, $Arguments, $Next)
        Mock Invoke-AtlasTrustedInstaller { throw 'phase failed.' }
        $call = @{ Phase = $Phase; PayloadRoot = 'C:\Staging\Executables'; TimeoutSeconds = 60; MachineLogRoot = (Join-Path $TestDrive 'none') } + $Arguments
        $thrown = $null
        try { Invoke-AtlasInstallPhase @call }
        catch { $thrown = $_.Exception.Message }
        $thrown | Should -BeLike "*. $Next" -Because $Case
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
        function Get-BodyCommandCall {
            param([string]$Name)
            @(Get-ScriptCommandCall -Ast $script:FrontDoorAst -Name $Name | Where-Object { -not (Test-InScriptFunction -Ast $_) })
        }
        # The text a call gives a parameter, as -Name:value or -Name value.
        function Get-CallArgument {
            param([Management.Automation.Language.CommandAst]$Call, [string]$Parameter)
            $elements = @($Call.CommandElements)
            for ($index = 0; $index -lt $elements.Count; $index++) {
                $element = $elements[$index]
                if ($element -isnot [Management.Automation.Language.CommandParameterAst] -or $element.ParameterName -ne $Parameter) { continue }
                if ($null -ne $element.Argument) { return $element.Argument.Extent.Text }
                return $elements[$index + 1].Extent.Text
            }
            return $null
        }
        # The variable a call's result is assigned to.
        function Get-CallTarget {
            param([Management.Automation.Language.CommandAst]$Call)
            $assignment = $Call.Parent.Parent
            if ($assignment -is [Management.Automation.Language.AssignmentStatementAst]) { return $assignment.Left.Extent.Text }
            return $null
        }
    }

    It 'probes before the requirements and words Windows Security from the probe, not the switch' {
        $probe = @(Get-BodyCommandCall 'Get-AtlasInstallProbe')
        $requirements = @(Get-BodyCommandCall 'Test-AtlasInstallRequirement')
        $probe.Count | Should -Be 1
        $requirements.Count | Should -Be 1
        Get-CallTarget $probe[0] | Should -BeExactly '$probe'
        $probe[0].Extent.StartOffset | Should -BeLessThan $requirements[0].Extent.StartOffset
        Get-CallArgument $requirements[0] 'Mode' | Should -BeExactly '$probe.Mode'
        Get-CallArgument $requirements[0] 'AtlasPackages' | Should -BeExactly '$probe.AtlasPackages'
        Get-CallArgument $requirements[0] 'ChooseAgain' | Should -BeExactly "(`$probe.Choices -ceq 'ChooseAgain')"
    }

    It 'resolves the update path before anything is copied, and names it' {
        $path = @(Get-BodyCommandCall 'Resolve-AtlasInstallChoices')
        $path.Count | Should -Be 1
        Get-CallTarget $path[0] | Should -BeExactly '$updatePath'
        $path[0].Extent.StartOffset | Should -BeLessThan @(Get-BodyCommandCall 'New-AtlasProtectedStagingRoot')[0].Extent.StartOffset
        @(Get-BodyCommandCall 'Write-AtlasInstallStep' | Where-Object { $_.CommandElements[1].Extent.Text -ceq '"Install mode: $($updatePath.Summary)."' }) |
            Should -HaveCount 1
    }

    It 'tells each phase''s retry the options it must give' {
        $phases = @(Get-BodyCommandCall 'Invoke-AtlasInstallPhase')
        $capture = @($phases | Where-Object { (Get-CallArgument $_ 'Phase') -ceq 'Capture' })
        $run = @($phases | Where-Object { (Get-CallArgument $_ 'Phase') -ceq 'Run' })
        $capture.Count | Should -Be 1
        $run.Count | Should -Be 1
        Get-CallArgument $capture[0] 'ResumeOptions' | Should -BeExactly '$probe.ResumeOptions'
        Get-CallArgument $run[0] 'ResumeOptions' | Should -BeExactly '$captured.ResumeOptions'
        $read = @(Get-BodyCommandCall 'Read-AtlasCapturedOption')
        $read.Count | Should -Be 1
        Get-CallTarget $read[0] | Should -BeExactly '$captured'
        $read[0].Extent.StartOffset | Should -BeGreaterThan $capture[0].Extent.StartOffset
        $read[0].Extent.StartOffset | Should -BeLessThan $run[0].Extent.StartOffset
        @(Get-BodyCommandCall 'Write-AtlasInstallStep' | Where-Object { $_.CommandElements[1].Extent.Text -ceq '$captured.Line' }) |
            Should -HaveCount 1
    }

    It 'forwards -<Switch> to <Command>' -TestCases @(
        @{ Switch = 'WindowsSecurityConfirmed'; Command = 'Test-AtlasInstallRequirement'; Forwarded = 1 }
        @{ Switch = 'ChooseAgain'; Command = 'Get-AtlasInstallProbe'; Forwarded = 1 }
        @{ Switch = 'ChooseAgain'; Command = 'New-AtlasInstallRequest'; Forwarded = 1 }
        # Only the Run phase is resumed, so only its failure says to choose again.
        @{ Switch = 'ChooseAgain'; Command = 'Invoke-AtlasInstallPhase'; Forwarded = 1 }
    ) {
        param($Switch, $Command, $Forwarded)
        $commands = @(Get-ScriptCommandCall -Ast $script:FrontDoorAst -Name $Command | Where-Object { -not (Test-InScriptFunction -Ast $_) })
        $forwarding = @($commands | Where-Object {
                $parameter = @($_.CommandElements | Where-Object {
                        $_ -is [Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq $Switch
                    })
                $parameter.Count -eq 1 -and $parameter[0].Argument -is [Management.Automation.Language.VariableExpressionAst] -and
                    $parameter[0].Argument.VariablePath.UserPath -eq $Switch
            })
        $forwarding.Count | Should -Be $Forwarded
    }

    It 'declares -ChooseAgain as a switch' {
        $parameter = @($script:FrontDoorAst.ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'ChooseAgain' })
        $parameter.Count | Should -Be 1
        $parameter[0].StaticType | Should -Be ([switch])
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
