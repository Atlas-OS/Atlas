BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.State\Atlas.State.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.InstallState\Atlas.InstallState.psd1') -Force -DisableNameChecking

    $script:PlaybookPath = Join-Path $script:AtlasTestRepoRoot 'playbook\playbook.conf'
    $script:SessionScript = Join-Path $script:AtlasTestScriptsRoot 'Install\Invoke-AtlasInstallSession.ps1'
    $script:FrontDoorScript = Join-Path $script:AtlasTestScriptsRoot 'Entry\Install-Atlas.ps1'
    $script:BrokerScript = Join-Path $script:AtlasTestScriptsRoot 'Entry\Invoke-AtlasTrustedInstallerBroker.ps1'
    $script:PowerShell51 = Join-Path $PSHOME 'powershell.exe'

    # Lift the pure functions out of the two entry scripts so they run without their
    # privilege checks and process side effects. Dot-sourcing happens here, in the
    # BeforeAll scope, so the functions are visible to every test.
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
        @(Get-ScriptFunctionText -Path $script:FrontDoorScript -Names 'Get-AtlasDeclaredRequirement', 'Test-AtlasDefenderPrepared', 'Invoke-AtlasPreparationCheck', 'Get-AtlasPowerStatus', 'Test-AtlasPowerConnected', 'Test-AtlasInstallRequirement', 'Copy-AtlasPayloadToStaging', 'Get-AtlasRestartComment', 'New-AtlasProtectedStagingRoot', 'New-AtlasFrontDoorDirectorySecurity')) {
        . ([scriptblock]::Create($text))
    }
    $script:Groups = @(Get-AtlasPlaybookOption -PlaybookPath $script:PlaybookPath)
    function Get-AtlasWindowsReleaseStatus { param($Version, $BuildLabEx) throw "Unmocked release query: $Version $BuildLabEx" }
}

Describe 'Protected front-door staging' {
    It 'pins module resolution before entry imports: <Entry>' -TestCases @(
        @{ Entry = 'Initialize-AtlasInstallState.ps1'; Arguments = @('-Operation', 'RecordOption'); Module = 'Atlas.InstallState' }
        @{ Entry = 'Publish-AtlasInstallUser.ps1'; Arguments = @(); Module = 'Atlas.InstallState' }
        @{ Entry = 'Invoke-AtlasResetServices.ps1'; Arguments = @('-Silent'); Module = 'Atlas.Core' }
        @{ Entry = 'Invoke-AtlasTrustedInstaller.ps1'; Arguments = @('-Operation', 'ResetServices', '-RestoreSource', 'ToggleDefaults'); Module = 'Atlas.Core' }
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
Describe 'Playbook readers' {
    It 'read the version, supported builds and option groups from playbook.conf' {
        Get-AtlasPlaybookVersion -PlaybookPath $script:PlaybookPath | Should -Match '^\d+\.\d+\.\d+'
        @(Get-AtlasPlaybookSupportedBuild -PlaybookPath $script:PlaybookPath) | Should -Be @(26200)
        $radio = @($script:Groups | Where-Object { $_.ExactlyOne })
        $radio.Count | Should -BeGreaterThan 2
        @($script:Groups | ForEach-Object { $_.Options }) | Should -Contain 'defender-enable'
        ($script:Groups | Where-Object { $_.Options -contains 'browser-brave' }).DependsOn | Should -Be 'install-another-browser'
    }

    It 'agree with the option set the AME handoff and the tweak schema know' {
        $tweaksModule = Join-Path $script:AtlasTestModulesRoot 'Atlas.Tweaks\Atlas.Tweaks.psd1'
        Import-Module $tweaksModule -Force
        $known = & (Get-Module Atlas.Tweaks) { $script:AtlasKnownOptions }
        @($script:Groups | ForEach-Object { $_.Options } | Sort-Object) | Should -Be @($known | Sort-Object)
    }
}

Describe 'Resolve-AtlasInstallMode' {
    BeforeEach { Mock Get-ItemProperty -ModuleName Atlas.InstallState { $null } }
    It 'resumes an interrupted fresh transaction after the payload has been copied' {
        $windows = Join-Path $TestDrive 'Interrupted'
        New-Item -Path (Join-Path $windows 'AtlasModules\Scripts') -ItemType Directory -Force | Out-Null
        $path = Join-Path $windows 'AtlasOS\Install\active.json'
        Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Fresh | Out-Null
        Commit-AtlasInstallState -StatePath $path | Out-Null
        Resolve-AtlasInstallMode -TargetVersion '0.6.0' -WindowsPath $windows | Should -Be 'Fresh'
        { Resolve-AtlasInstallMode -TargetVersion '0.7.0' -WindowsPath $windows } | Should -Throw '*already active*'
    }
    It 'accepts declared legacy OEM versions' -TestCases @(
        @{ Version = '0.4.1' }, @{ Version = '0.5.0' }, @{ Version = '0.5.1' }
    ) {
        param($Version)
        $script:LegacyVersion = $Version
        Mock Get-ItemProperty -ModuleName Atlas.InstallState { [pscustomobject]@{ Model = "Atlas Playbook $script:LegacyVersion"; RegisteredOrganization = "Atlas Playbook $script:LegacyVersion" } }
        Resolve-AtlasInstallMode -TargetVersion '0.6.0' -WindowsPath (Join-Path $TestDrive 'Legacy') | Should -Be 'Upgrade'
    }

    It 'rejects undeclared durable source versions' -TestCases @(
        @{ Version = '0.3.2' }, @{ Version = '0.7.0' }
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

    It 'rejects an installed payload without version evidence' {
        $windows = Join-Path $TestDrive 'LegacyWindows'
        New-Item -Path (Join-Path $windows 'AtlasModules\Scripts') -ItemType Directory -Force | Out-Null
        { Resolve-AtlasInstallMode -TargetVersion '0.6.0' -WindowsPath $windows } | Should -Throw '*version could not be established*'
    }
}

Describe 'Install request validation' {
    It 'accepts a complete option set and rejects unknown, repeated and incomplete sets' {
        $good = @('defender-enable', 'mitigations-default', 'auto-updates-disable', 'install-another-browser', 'browser-brave')
        @(Assert-AtlasInstallOptionSet -Options $good -Groups $script:Groups) | Should -Be $good

        { Assert-AtlasInstallOptionSet -Options ($good + 'not-an-option') -Groups $script:Groups } | Should -Throw '*not declared*'
        { Assert-AtlasInstallOptionSet -Options ($good + 'defender-enable') -Groups $script:Groups } | Should -Throw '*repeats*'
        { Assert-AtlasInstallOptionSet -Options @('defender-enable', 'defender-disable', 'mitigations-default', 'auto-updates-disable') -Groups $script:Groups } |
            Should -Throw '*Exactly one of*'
        { Assert-AtlasInstallOptionSet -Options @('defender-enable', 'mitigations-default') -Groups $script:Groups } |
            Should -Throw '*Exactly one of auto-updates*'
        { Assert-AtlasInstallOptionSet -Options @('defender-enable', 'mitigations-default', 'auto-updates-disable', 'browser-brave') -Groups $script:Groups } |
            Should -Throw "*require 'install-another-browser'*"
    }

    It 'reads only a bounded request.json with an options array' {
        $payload = Join-Path $TestDrive 'payload'
        New-Item -Path $payload -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $payload 'request.json') -Value '{"options":["defender-enable"]}'
        @(Read-AtlasInstallRequest -PayloadRoot $payload) | Should -Be @('defender-enable')

        Set-Content -LiteralPath (Join-Path $payload 'request.json') -Value '{"options":[],"mode":"Fresh"}'
        { Read-AtlasInstallRequest -PayloadRoot $payload } | Should -Throw "*unknown field 'mode'*"

        Remove-Item -LiteralPath (Join-Path $payload 'request.json')
        { Read-AtlasInstallRequest -PayloadRoot $payload } | Should -Throw '*missing*'
    }

    It 'preserves the interactive default and rejects a non-Boolean setup mode' {
        $payload = Join-Path $TestDrive 'setup-request'
        New-Item -Path $payload -ItemType Directory -Force | Out-Null
        $requestPath = Join-Path $payload 'request.json'
        Set-Content -LiteralPath $requestPath -Value '{"options":["defender-enable"]}'
        (Read-AtlasInstallRequest -PayloadRoot $payload -WithMode).windowsSetup | Should -BeFalse
        Set-Content -LiteralPath $requestPath -Value '{"options":[],"windowsSetup":"true"}'
        { Read-AtlasInstallRequest -PayloadRoot $payload -WithMode } | Should -Throw '*Boolean*'
    }

    It 'refuses setup mode outside Windows Setup' {
        Mock Get-ItemPropertyValue { 0 }
        $payload = Join-Path $TestDrive 'not-setup'
        New-Item -Path $payload -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $payload 'request.json') -Value '{"options":[],"windowsSetup":true}'
        { Read-AtlasInstallRequest -PayloadRoot $payload -WithMode } | Should -Throw '*Windows Setup is not running*'
    }

    It 'carries setup mode through the validated request during Setup' {
        Mock Get-ItemPropertyValue { 1 }
        $payload = Join-Path $TestDrive 'during-setup'
        New-Item -Path $payload -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $payload 'request.json') -Value '{"options":["defender-enable"],"windowsSetup":true}'
        $request = Read-AtlasInstallRequest -PayloadRoot $payload -WithMode
        $request.windowsSetup | Should -BeTrue
        @($request.options) | Should -Be @('defender-enable')
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
    }
}

Describe 'Front door requirements and staging' {
    BeforeEach {
        Mock Get-AtlasWindowsReleaseStatus { 'Released' }
        Mock Get-ItemProperty { [pscustomobject]@{} }
        Mock Test-AtlasPowerConnected { $true }
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
        Mock Get-CimInstance { @() }
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

    It 'blocks enabled or unreadable required Windows Security settings' {
        Mock Test-Path { $false }
        Mock Get-CimInstance { @() }
        Mock Test-AtlasDefenderPrepared { $false }
        $result = Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26200 -EditionId Professional -InstallationType Client -DeclaredRequirements @('DefenderToggled') | Where-Object Name -eq 'Windows Security'
        $result.Passed | Should -BeFalse
        $result.Blocking | Should -BeTrue
        Mock Test-AtlasDefenderPrepared { throw 'Access denied' }
        $result = Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26200 -EditionId Professional -InstallationType Client -DeclaredRequirements @('DefenderToggled') | Where-Object Name -eq 'Windows Security'
        $result.Passed | Should -BeFalse
        $result.Detail | Should -Match 'could not be checked'
    }

    It 'rejects an unknown declared requirement instead of silently bypassing it' {
        { Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26200 -EditionId Professional -InstallationType Client -DeclaredRequirements @('FutureRequirement') } | Should -Throw '*cannot verify*'
    }

    It 'blocks preview and unverifiable Windows releases independently of the base build' -TestCases @(
        @{ Release='Preview' }, @{ Release='Unknown' }
    ) {
        param($Release)
        $script:ReleaseFixture = $Release
        Mock Get-AtlasWindowsReleaseStatus { $script:ReleaseFixture }
        Mock Test-Path { $false }
        Mock Get-CimInstance { @() }
        $result = Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26200 -WindowsRevision 5551 -BuildLabEx 'rs_prerelease' -EditionId Professional -InstallationType Client | Where-Object Name -eq 'Windows release'
        $result.Passed | Should -BeFalse
        $result.Blocking | Should -BeTrue
        Should -Invoke Get-AtlasWindowsReleaseStatus -Times 1 -Exactly -ParameterFilter { $Version -eq [version]'10.0.26200.5551' -and $BuildLabEx -eq 'rs_prerelease' }
    }

    It 'requires a restart for pending file renames even without update markers' {
        Mock Test-Path { $false }
        Mock Get-CimInstance { @() }
        Mock Get-ItemProperty { [pscustomobject]@{ PendingFileRenameOperations = @('\??\C:\old', '\??\C:\new') } }
        $result = Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26200 -EditionId Professional -InstallationType Client | Where-Object Name -eq 'No pending reboot'
        $result.Passed | Should -BeFalse
        $result.Blocking | Should -BeTrue
    }

    It 'does not treat an unreadable reboot marker as absent' {
        Mock Test-Path { throw 'registry access denied' }
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
        Mock Get-CimInstance { @() }
        $requirements = @(Test-AtlasInstallRequirement -SupportedBuilds @(26200) -WindowsBuild 26200 -EditionId $Edition -InstallationType $Type)
        $result = $requirements | Where-Object Name -eq 'Windows edition'
        $result.Passed | Should -Be $Passed
        $result.Blocking | Should -BeTrue
    }

    It 'copies playbook.conf and the Executables tree and refuses a payload containing a reparse point' {
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
            Should -Throw '*reparse point*'
    }
}

Describe 'Restart notice text' {
    It 'defaults to the English notice and otherwise keeps the caller''s text within shutdown.exe limits' {
        Get-AtlasRestartComment -Comment $null | Should -Be 'Atlas installation complete.'
        Get-AtlasRestartComment -Comment '   ' | Should -Be 'Atlas installation complete.'
        Get-AtlasRestartComment -Comment "  Neustart: Atlas ist fertig `u{2713} " | Should -Be "Neustart: Atlas ist fertig `u{2713}"
        Get-AtlasRestartComment -Comment "a`tb`r`nc`0d" | Should -Be 'a b  c d'
        (Get-AtlasRestartComment -Comment ('x' * 600)).Length | Should -Be 512
    }

    It 'is declared by the front door so the app can pass it' {
        $ast = [Management.Automation.Language.Parser]::ParseFile($script:FrontDoorScript, [ref]$null, [ref]$null)
        @($ast.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath }) | Should -Contain 'RestartComment'
    }
}

Describe 'Install operation through the broker' {
    It 'builds a typed Install request for the fixed broker and nothing else' {
        Mock Assert-AtlasPrivilege -ModuleName Atlas.Core
        Mock Get-AtlasContext -ModuleName Atlas.Core { [pscustomobject]@{ WinDir = 'C:\Windows'; AtlasModulesPath = 'C:\Windows\AtlasModules' } }
        Mock Invoke-AtlasHiddenProcess -ModuleName Atlas.Core { [pscustomobject]@{ ExitCode = 0; ArgumentList = $ArgumentList } }

        $result = Invoke-AtlasTrustedInstaller -Operation Install -InstallPhase Capture -PayloadRoot 'C:\Windows\AtlasOS\Staging\abc\Executables' -TimeoutSeconds 60

        $joined = $result.ArgumentList -join ' '
        $joined | Should -Match 'Invoke-AtlasTrustedInstallerBroker\.ps1'
        $joined | Should -Match '-Operation Install'
        $joined | Should -Match '-InstallPhase Capture'
        $joined | Should -Match '-PayloadRoot C:\\Windows\\AtlasOS\\Staging\\abc\\Executables'
        { Invoke-AtlasTrustedInstaller -Operation Install -InstallPhase Run -PayloadRoot 'relative\path' } | Should -Throw '*absolute*'
        { Invoke-AtlasTrustedInstaller -Operation Install -Name 'X' -InstallPhase Run -PayloadRoot 'C:\x' } | Should -Throw "*does not accept*"
        { Invoke-AtlasTrustedInstaller -Operation Toggle -Name 'X' -State 'On' -InstallPhase Run } | Should -Throw "*does not accept*"
    }

    It 'is rejected by the broker script when the payload root is outside the protected staging root' {
        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $output = & $script:PowerShell51 -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $script:BrokerScript `
                -Operation Install -InstallPhase Capture -PayloadRoot (Join-Path $TestDrive 'not-staging') 2>&1
        }
        finally {
            $ErrorActionPreference = $previousPreference
        }
        $LASTEXITCODE | Should -Be 1
        ($output | Out-String) | Should -Match 'protected staging root|Administrator'
    }

    It 'exposes the Install request fields in the native launcher' {
        Initialize-AtlasNativeType
        $properties = [Atlas.Native.TrustedInstallerLaunchRequest].GetProperties().Name
        $properties | Should -Contain 'InstallPhase'
        $properties | Should -Contain 'PayloadRoot'
    }
}
