[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter',
    '',
    Justification = 'The servicing doubles declare the parameter surface of the commands they stand in for.'
)]
param()

BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    . (Join-Path $script:AtlasTestScriptsRoot 'Install\Tasks\Set-AtlasDefenderChoice.ps1')

    # Servicing doubles: the task must never install, remove or register anything on the
    # PC that runs the tests. Each records into $script:Events in the order it ran.
    function Install-AtlasCbsPackage {
        param($Packages, [switch]$NonInteractive)
        $script:Events.Add("Install:$(@($Packages) -join '+'):$([bool]$NonInteractive)")
    }
    function Uninstall-AtlasCbsPackage {
        param($Packages)
        $script:Events.Add("Uninstall:$(@($Packages) -join '+')")
        return [pscustomobject]@{ RemovedPackages = @(); FailedPackages = @($script:UninstallFailed); UnmatchedPatterns = @() }
    }
    function Set-AtlasDefenderCoreService {
        param($State)
        $script:Events.Add("CoreService:$State")
    }
    # Stands in for Atlas.Security's reader, so each test's mock answers instead of this PC.
    function Test-AtlasDefenderCoreServiceRemoved { }
    function Write-AtlasLog {
        param($Message, $Level = 'Info', $ErrorRecord)
        $script:Logs.Add([pscustomobject]@{ Level = $Level; Message = $Message })
    }
}

AfterAll {
    foreach ($name in @(
            'Install-AtlasCbsPackage', 'Uninstall-AtlasCbsPackage', 'Set-AtlasDefenderCoreService', 'Write-AtlasLog'
            'Test-AtlasDefenderCoreServiceRemoved'
            'Get-AtlasServicingPackageState', 'Test-AtlasDefenderServicePresent', 'Set-AtlasDefenderChoice'
        )) {
        Microsoft.PowerShell.Management\Remove-Item -LiteralPath "Function:\$name" -ErrorAction SilentlyContinue
    }
}

Describe 'Set-AtlasDefenderChoice' {
    BeforeEach {
        $script:Events = [Collections.Generic.List[string]]::new()
        $script:Logs = [Collections.Generic.List[pscustomobject]]::new()
        $script:UninstallFailed = @()
        $script:PackageStates = @{}
        $script:DefenderPresent = $true
        # MDCoreSvc already off, or Atlas's task waiting to turn it off.
        $script:CoreServiceRemoved = $true
        Mock Get-AtlasServicingPackageState { $script:PackageStates[$Name] }
        Mock Test-AtlasDefenderServicePresent { $script:DefenderPresent }
        Mock Test-AtlasDefenderCoreServiceRemoved { $script:CoreServiceRemoved }
    }

    Context 'choosing again on an update' {
        It 'removes a Defender that is present: NoTelemetry <Telemetry>' -ForEach @(
            @{ Telemetry = 'missing'; TelemetryState = $null; Install = 'Install:*Z-Atlas-NoDefender-Package*+*Z-Atlas-NoTelemetry-Package*:True' }
            @{ Telemetry = 'installed'; TelemetryState = 'Installed'; Install = 'Install:*Z-Atlas-NoDefender-Package*:True' }
            @{ Telemetry = 'waiting for the restart'; TelemetryState = 'InstallPending'; Install = 'Install:*Z-Atlas-NoDefender-Package*:True' }
        ) {
            $script:PackageStates['Z-Atlas-NoTelemetry-Package'] = $TelemetryState

            Set-AtlasDefenderChoice -State Disable | Should -BeTrue

            @($script:Events) | Should -Be @($Install, 'CoreService:Removed')
        }

        It 'brings back a Defender Atlas removed, putting its core service back first: NoTelemetry <Telemetry>' -ForEach @(
            @{ Telemetry = 'missing'; TelemetryState = $null; Expected = @('CoreService:Restored', 'Uninstall:*Z-Atlas-NoDefender-Package*', 'Install:*Z-Atlas-NoTelemetry-Package*:True') }
            @{ Telemetry = 'installed'; TelemetryState = 'Installed'; Expected = @('CoreService:Restored', 'Uninstall:*Z-Atlas-NoDefender-Package*') }
        ) {
            $script:PackageStates['Z-Atlas-NoDefender-Package'] = 'Installed'
            $script:PackageStates['Z-Atlas-NoTelemetry-Package'] = $TelemetryState

            Set-AtlasDefenderChoice -State Enable | Should -BeTrue

            @($script:Events) | Should -Be $Expected
        }

        It 'fails when Atlas''s package can''t be taken off, so the install never reports a Defender it lacks' {
            $script:PackageStates['Z-Atlas-NoDefender-Package'] = 'Installed'
            $script:PackageStates['Z-Atlas-NoTelemetry-Package'] = 'Installed'
            $script:UninstallFailed = @('Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~5.0.0.0')

            { Set-AtlasDefenderChoice -State Enable } |
                Should -Throw "Microsoft Defender couldn't be restored: Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~5.0.0.0"
        }

        It 'changes nothing when the PC already matches: <Case>' -ForEach @(
            @{ Case = 'Defender removed by Atlas, Remove chosen'; State = 'Disable'; Defender = 'Installed' }
            @{ Case = 'removal waiting for the restart, Remove chosen'; State = 'Disable'; Defender = 'InstallPending' }
            @{ Case = 'Defender present, Keep chosen'; State = 'Enable'; Defender = $null }
            @{ Case = 'restore waiting for the restart, Keep chosen'; State = 'Enable'; Defender = 'UninstallPending' }
        ) {
            $script:PackageStates['Z-Atlas-NoDefender-Package'] = $Defender

            Set-AtlasDefenderChoice -State $State | Should -BeFalse

            $script:Events | Should -BeNullOrEmpty
            @($script:Logs | Where-Object Level -eq 'Warning') | Should -BeNullOrEmpty
        }

        It 'turns the core service off when Defender was removed but the service never was: <Defender>' -ForEach @(
            @{ Defender = 'Installed' }
            @{ Defender = 'InstallPending' }
        ) {
            # A run that stopped after the package went on, or an earlier Atlas that never
            # turned the service off.
            $script:PackageStates['Z-Atlas-NoDefender-Package'] = $Defender
            $script:CoreServiceRemoved = $false

            Set-AtlasDefenderChoice -State Disable | Should -BeFalse

            @($script:Events) | Should -Be @('CoreService:Removed')
        }

        It 'warns, and changes nothing, when Defender is missing and no Atlas package removed it' {
            $script:DefenderPresent = $false

            Set-AtlasDefenderChoice -State Enable | Should -BeFalse

            $script:Events | Should -BeNullOrEmpty
            @($script:Logs | Where-Object Level -eq 'Warning' | ForEach-Object Message) |
                Should -Be @("Microsoft Defender isn't on this PC and no Atlas package removed it, so Atlas can't bring it back.")
        }

        It 'fails, and changes nothing, when Keep is chosen while Atlas''s removal still waits for a restart' {
            $script:PackageStates['Z-Atlas-NoDefender-Package'] = 'InstallPending'

            { Set-AtlasDefenderChoice -State Enable } |
                Should -Throw "Microsoft Defender couldn't be restored: Atlas's NoDefender package is still waiting for a restart to finish installing.*"

            $script:Events | Should -BeNullOrEmpty
        }

        It 'warns, and changes nothing, when Remove is chosen while Atlas''s restore still waits for a restart: -Fresh <Fresh>' -ForEach @(
            @{ Fresh = $false }
            @{ Fresh = $true }
        ) {
            $script:PackageStates['Z-Atlas-NoDefender-Package'] = 'UninstallPending'
            $script:PackageStates['Z-Atlas-NoTelemetry-Package'] = 'Installed'
            $script:CoreServiceRemoved = $false

            Set-AtlasDefenderChoice -State Disable -Fresh:$Fresh | Should -BeFalse

            $script:Events | Should -BeNullOrEmpty
            @($script:Logs | Where-Object Level -eq 'Warning' | ForEach-Object Message) |
                Should -BeLike "Atlas's NoDefender package is still waiting for a restart to come off*Toggle Defender*"
        }

        It 'redoes nothing on a second run once the first has removed Defender' {
            Set-AtlasDefenderChoice -State Disable | Should -BeTrue
            $script:PackageStates['Z-Atlas-NoDefender-Package'] = 'InstallPending'
            $script:PackageStates['Z-Atlas-NoTelemetry-Package'] = 'InstallPending'
            $script:Events.Clear()

            Set-AtlasDefenderChoice -State Disable | Should -BeFalse

            $script:Events | Should -BeNullOrEmpty
        }
    }

    Context 'a first installation (-Fresh)' {
        It 'puts NoTelemetry on with Keep chosen and nothing else to do' {
            Set-AtlasDefenderChoice -State Enable -Fresh | Should -BeFalse

            @($script:Events) | Should -Be @('Install:*Z-Atlas-NoTelemetry-Package*:True')
        }

        It 'sets the core service up for removal even when Defender was already removed: <Defender>' -ForEach @(
            @{ Defender = 'Installed' }
            @{ Defender = 'InstallPending' }
        ) {
            $script:PackageStates['Z-Atlas-NoDefender-Package'] = $Defender

            Set-AtlasDefenderChoice -State Disable -Fresh | Should -BeFalse

            @($script:Events) | Should -Be @('CoreService:Removed', 'Install:*Z-Atlas-NoTelemetry-Package*:True')
            # As the first installation always has, whatever the service reads.
            Should -Invoke Test-AtlasDefenderCoreServiceRemoved -Times 0 -Exactly
        }

        It 'installs NoTelemetry once when it goes on with the Defender change' {
            Set-AtlasDefenderChoice -State Disable -Fresh | Should -BeTrue

            @($script:Events) | Should -Be @(
                'Install:*Z-Atlas-NoDefender-Package*+*Z-Atlas-NoTelemetry-Package*:True'
                'CoreService:Removed'
            )
        }

        It 'never installs NoTelemetry again when it is already installed' {
            $script:PackageStates['Z-Atlas-NoTelemetry-Package'] = 'Installed'

            Set-AtlasDefenderChoice -State Enable -Fresh | Should -BeFalse

            $script:Events | Should -BeNullOrEmpty
        }
    }
}

Describe 'Get-AtlasServicingPackageState' {
    BeforeAll {
        $script:CbsPath = 'Software\AtlasRewriteTest\Cbs\Packages'

        function Set-TestPackage {
            param([string]$Key, $CurrentState, [Microsoft.Win32.RegistryValueKind]$Kind = 'DWord')
            $package = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey("$script:CbsPath\$Key")
            try { $package.SetValue('CurrentState', $CurrentState, $Kind) }
            finally { $package.Dispose() }
        }

        function Get-TestPackageState {
            Get-AtlasServicingPackageState -Name 'Z-Atlas-NoDefender-Package' `
                -BaseKey ([Microsoft.Win32.Registry]::CurrentUser) -PackagesPath $script:CbsPath
        }
    }

    BeforeEach {
        [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree('Software\AtlasRewriteTest\Cbs', $false)
    }

    AfterAll {
        [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree('Software\AtlasRewriteTest\Cbs', $false)
    }

    It 'reads CurrentState <Value> as <Expected>' -ForEach @(
        @{ Value = 112; Expected = 'Installed' }
        @{ Value = 96; Expected = 'InstallPending' }
        @{ Value = 5; Expected = 'UninstallPending' }
        @{ Value = 64; Expected = $null }
        @{ Value = 0; Expected = $null }
    ) {
        Set-TestPackage -Key 'Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~5.0.0.0' -CurrentState $Value

        Get-TestPackageState | Should -Be $Expected
    }

    It 'gives the strongest state of several versions' {
        Set-TestPackage -Key 'Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~1.0.0.0' -CurrentState 5
        Set-TestPackage -Key 'Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~5.0.0.0' -CurrentState 96
        Get-TestPackageState | Should -BeExactly 'InstallPending'

        Set-TestPackage -Key 'Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~6.0.0.0' -CurrentState 112
        Get-TestPackageState | Should -BeExactly 'Installed'
    }

    It 'ignores other packages and a CurrentState that isn''t a DWORD' {
        Set-TestPackage -Key 'Z-Atlas-NoTelemetry-Package~31bf3856ad364e35~amd64~~5.0.0.0' -CurrentState 112
        Set-TestPackage -Key 'Z-Atlas-NoDefender-PackageExtra~31bf3856ad364e35~amd64~~5.0.0.0' -CurrentState 112
        Set-TestPackage -Key 'Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~5.0.0.0' -CurrentState '112' -Kind String

        Get-TestPackageState | Should -BeNullOrEmpty
    }

    It 'reads no packages at all as absent' {
        Get-TestPackageState | Should -BeNullOrEmpty
    }
}
