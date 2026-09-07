[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidGlobalVars',
    '',
    Justification = 'Module-scoped mock bodies cannot see test-file variables, so shared fixture state is staged as global variables.'
)]
param()

BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Add-Type -AssemblyName System.ServiceProcess
    Import-Module -Name (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path $script:AtlasTestModulesRoot 'Atlas.Privacy\Atlas.Privacy.psd1') -Force

    # Module-scoped mocks cannot see test-file functions, so the fake service
    # controller factory and the shared call log live in the global scope.
    function global:New-AtlasPrivacyTestService {
        param([string]$Name, [string]$Status)

        $service = [pscustomobject]@{
            Name   = $Name
            Status = [System.ServiceProcess.ServiceControllerStatus]$Status
        }
        $service | Add-Member -MemberType ScriptMethod -Name Refresh -Value {}
        $service | Add-Member -MemberType ScriptMethod -Name Start -Value {
            $global:AtlasPrivacyTestCalls.Add("$($this.Name):Start")
            $this.Status = [System.ServiceProcess.ServiceControllerStatus]::StartPending
        }
        $service | Add-Member -MemberType ScriptMethod -Name Stop -Value {
            $global:AtlasPrivacyTestCalls.Add("$($this.Name):Stop")
            $this.Status = [System.ServiceProcess.ServiceControllerStatus]::StopPending
        }
        $service | Add-Member -MemberType ScriptMethod -Name WaitForStatus -Value {
            param($Desired, $Timeout)
            [void]$Timeout
            $global:AtlasPrivacyTestCalls.Add("$($this.Name):Wait:$Desired")
            $this.Status = $Desired
        }
        $service | Add-Member -MemberType ScriptMethod -Name Dispose -Value {
            $global:AtlasPrivacyTestCalls.Add("$($this.Name):Dispose")
        }
        return $service
    }
}

AfterAll {
    Remove-Item -Path 'Function:\global:New-AtlasPrivacyTestService' -ErrorAction SilentlyContinue
    Remove-Variable -Name AtlasPrivacyTestCalls, AtlasPrivacyTestStatus, AtlasPrivacyTestChoices `
        -Scope Global -ErrorAction SilentlyContinue
}

Describe 'Set-AtlasLocationMachineState' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Privacy
        Mock Test-AtlasTrustedInstaller -ModuleName Atlas.Privacy { $false }
        Mock Assert-AtlasPrivilege -ModuleName Atlas.Privacy {}
        $global:AtlasPrivacyTestCalls = New-Object 'System.Collections.Generic.List[string]'
        $global:AtlasPrivacyTestStatus = @{ lfsvc = 'Running'; MapsBroker = 'Running' }
        Mock Set-AtlasServiceStartup -ModuleName Atlas.Privacy { throw 'Location must configure SCM before a runtime transition.' }
        Mock Set-Service -ModuleName Atlas.Privacy {
            $global:AtlasPrivacyTestCalls.Add("$($Name):Start=$StartupType")
        }
        Mock Get-AtlasLocationServiceController -ModuleName Atlas.Privacy {
            New-AtlasPrivacyTestService -Name $Name -Status $global:AtlasPrivacyTestStatus[$Name]
        }
        Mock Set-AtlasRegistryValue -ModuleName Atlas.Privacy {
            $global:AtlasPrivacyTestCalls.Add("registry:$Name=$Data")
        }
        Mock Set-AtlasLocationSettingsPageVisibility -ModuleName Atlas.Privacy {
            $global:AtlasPrivacyTestCalls.Add("settings:$($Operation):$Page")
        }
    }

    It 'disables both services, locks Find My Device and hides both settings pages in order' {
        Set-AtlasLocationMachineState -State Disable

        @($global:AtlasPrivacyTestCalls) | Should -Be @(
            'lfsvc:Start=Disabled'
            'lfsvc:Stop'
            'lfsvc:Wait:Stopped'
            'lfsvc:Dispose'
            'MapsBroker:Start=Disabled'
            'MapsBroker:Stop'
            'MapsBroker:Wait:Stopped'
            'MapsBroker:Dispose'
            'registry:AllowFindMyDevice=0'
            'registry:LocationSyncEnabled=0'
            'settings:hide:privacy-location'
            'settings:hide:findmydevice'
        )
        Should -Invoke Set-AtlasRegistryValue -ModuleName Atlas.Privacy -Times 2 -Exactly -ParameterFilter {
            $Path -eq 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice' -and $Type -eq 'DWord'
        }
    }

    It 'enables both services and reveals only the location page, leaving Find My Device locked' {
        $global:AtlasPrivacyTestStatus = @{ lfsvc = 'Stopped'; MapsBroker = 'Stopped' }

        Set-AtlasLocationMachineState -State Enable

        @($global:AtlasPrivacyTestCalls) | Should -Be @(
            'lfsvc:Start=Manual'
            'lfsvc:Start'
            'lfsvc:Wait:Running'
            'lfsvc:Dispose'
            'MapsBroker:Start=Automatic'
            'MapsBroker:Start'
            'MapsBroker:Wait:Running'
            'MapsBroker:Dispose'
            'settings:unhide:privacy-location'
        )
        Should -Invoke Set-AtlasRegistryValue -ModuleName Atlas.Privacy -Times 0
    }

    It 'leaves a service alone when it already has the requested status' {
        $global:AtlasPrivacyTestStatus = @{ lfsvc = 'Stopped'; MapsBroker = 'Running' }

        Set-AtlasLocationMachineState -State Disable

        @($global:AtlasPrivacyTestCalls | Where-Object { $_ -like 'lfsvc:*' }) | Should -Be @(
            'lfsvc:Start=Disabled'
            'lfsvc:Dispose'
        )
        @($global:AtlasPrivacyTestCalls) | Should -Contain 'MapsBroker:Stop'
    }

    It 'does not start a service or report enabled settings when SCM rejects the startup change' {
        Mock Set-Service -ModuleName Atlas.Privacy { throw 'SCM configuration denied' }

        { Set-AtlasLocationMachineState -State Enable } | Should -Throw '*SCM configuration denied*'
        Should -Invoke Get-AtlasLocationServiceController -ModuleName Atlas.Privacy -Times 0
        Should -Invoke Set-AtlasLocationSettingsPageVisibility -ModuleName Atlas.Privacy -Times 0
        Should -Invoke Set-Service -ModuleName Atlas.Privacy -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'lfsvc' -and $StartupType -eq 'Manual' -and $ErrorAction -eq 'Stop'
        }
    }

    It 'asserts TrustedInstaller when running as TrustedInstaller and Administrator otherwise' {
        Set-AtlasLocationMachineState -State Enable
        Should -Invoke Assert-AtlasPrivilege -ModuleName Atlas.Privacy -Times 1 -Exactly -ParameterFilter { $Administrator }

        Mock Test-AtlasTrustedInstaller -ModuleName Atlas.Privacy { $true }
        Set-AtlasLocationMachineState -State Enable
        Should -Invoke Assert-AtlasPrivilege -ModuleName Atlas.Privacy -Times 1 -Exactly -ParameterFilter { $TrustedInstaller }
    }

    It 'stops before touching the registry when a service change fails' {
        Mock Set-Service -ModuleName Atlas.Privacy {
            if ($Name -eq 'MapsBroker') { throw 'MapsBroker is protected' }
            $global:AtlasPrivacyTestCalls.Add("$($Name):Start=$StartupType")
        }

        { Set-AtlasLocationMachineState -State Disable } | Should -Throw '*MapsBroker is protected*'
        Should -Invoke Set-AtlasRegistryValue -ModuleName Atlas.Privacy -Times 0
        Should -Invoke Set-AtlasLocationSettingsPageVisibility -ModuleName Atlas.Privacy -Times 0
    }
}

Describe 'Clear-AtlasTelemetryLogFiles' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Privacy
        Mock Assert-AtlasPrivilege -ModuleName Atlas.Privacy {}
        Mock Get-AtlasContext -ModuleName Atlas.Privacy {
            [pscustomobject]@{ IsInstallStateBacked = $true }
        }

        $script:programData = Join-Path $TestDrive 'ProgramData'
        $script:etlRoot = Join-Path $script:programData 'Microsoft\Diagnosis\ETLLogs'
        New-Item -Path (Join-Path $script:etlRoot 'AutoLogger') -ItemType Directory -Force | Out-Null
        foreach ($name in @('DiagTrack-Listener.etl', 'DiagTrack-Listener.etl.000', 'Other.etl')) {
            Set-Content -LiteralPath (Join-Path $script:etlRoot "AutoLogger\$name") -Value 'x' -Encoding ASCII
        }
    }

    It 'removes only DiagTrack files from the two fixed log directories' {
        New-Item -Path (Join-Path $script:etlRoot 'ShutdownLogger') -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $script:etlRoot 'ShutdownLogger\DiagTrack-Shutdown.etl') -Value 'x' -Encoding ASCII
        New-Item -Path (Join-Path $script:etlRoot 'Unrelated') -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $script:etlRoot 'Unrelated\DiagTrack-Keep.etl') -Value 'x' -Encoding ASCII

        Clear-AtlasTelemetryLogFiles -ProgramDataPath $script:programData

        @((Get-ChildItem -LiteralPath (Join-Path $script:etlRoot 'AutoLogger')).Name) | Should -Be @('Other.etl')
        @(Get-ChildItem -LiteralPath (Join-Path $script:etlRoot 'ShutdownLogger')).Count | Should -Be 0
        Test-Path -LiteralPath (Join-Path $script:etlRoot 'Unrelated\DiagTrack-Keep.etl') | Should -BeTrue
        Should -Invoke Assert-AtlasPrivilege -ModuleName Atlas.Privacy -Times 1 -Exactly -ParameterFilter { $TrustedInstaller }
    }

    It 'tolerates a missing log directory' {
        Remove-Item -LiteralPath (Join-Path $script:etlRoot 'AutoLogger') -Recurse -Force

        { Clear-AtlasTelemetryLogFiles -ProgramDataPath $script:programData } | Should -Not -Throw
    }

    It 'requires active install state and a rooted common application-data directory' {
        Mock Get-AtlasContext -ModuleName Atlas.Privacy {
            [pscustomobject]@{ IsInstallStateBacked = $false }
        }
        { Clear-AtlasTelemetryLogFiles -ProgramDataPath $script:programData } |
            Should -Throw '*requires active Atlas install state*'

        Mock Get-AtlasContext -ModuleName Atlas.Privacy {
            [pscustomobject]@{ IsInstallStateBacked = $true }
        }
        { Clear-AtlasTelemetryLogFiles -ProgramDataPath 'relative\ProgramData' } |
            Should -Throw '*rooted common application-data directory*'
        Test-Path -LiteralPath (Join-Path $script:etlRoot 'AutoLogger\DiagTrack-Listener.etl') | Should -BeTrue
    }

    It 'refuses a reparse-point log directory' {
        $target = Join-Path $TestDrive 'Elsewhere'
        New-Item -Path $target -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $target 'DiagTrack-Linked.etl') -Value 'x' -Encoding ASCII
        $junction = Join-Path $script:etlRoot 'ShutdownLogger'
        try {
            New-Item -Path $junction -ItemType Junction -Value $target -ErrorAction Stop | Out-Null
        }
        catch {
            Set-ItResult -Skipped -Because 'this host cannot create a directory junction'
            return
        }

        try {
            { Clear-AtlasTelemetryLogFiles -ProgramDataPath $script:programData } |
                Should -Throw '*is a reparse point*'
            Test-Path -LiteralPath (Join-Path $target 'DiagTrack-Linked.etl') | Should -BeTrue
        }
        finally {
            [IO.Directory]::Delete($junction)
        }
    }
}

Describe 'Remove-AtlasTelemetryComponents' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Privacy
        Mock Write-AtlasNote -ModuleName Atlas.Privacy
        Mock Write-AtlasStep -ModuleName Atlas.Privacy
        Mock Write-Host -ModuleName Atlas.Privacy
        $global:AtlasPrivacyTestCalls = New-Object 'System.Collections.Generic.List[string]'
        Mock Read-AtlasChoice -ModuleName Atlas.Privacy { throw 'the menu was shown without a scripted answer' }
        Mock Invoke-AtlasTelemetryPackageOperation -ModuleName Atlas.Privacy {
            $global:AtlasPrivacyTestCalls.Add("package:${Action}:$([bool]$NoInteraction)")
        }
    }

    It 'adds the package when it is absent and marks removal as the current choice' {
        Mock Get-AtlasTelemetryPackageInstalled -ModuleName Atlas.Privacy { $false }
        Mock Read-AtlasChoice -ModuleName Atlas.Privacy { 1 } -ParameterFilter { $CurrentIndex -eq 2 }

        Remove-AtlasTelemetryComponents

        @($global:AtlasPrivacyTestCalls) | Should -Be @('package:Install:False')
        Should -Invoke Read-AtlasChoice -ModuleName Atlas.Privacy -Times 1 -Exactly
    }

    It 'removes the package when it is present' {
        Mock Get-AtlasTelemetryPackageInstalled -ModuleName Atlas.Privacy { $true }
        Mock Read-AtlasChoice -ModuleName Atlas.Privacy { 2 } -ParameterFilter { $CurrentIndex -eq 1 }

        Remove-AtlasTelemetryComponents

        @($global:AtlasPrivacyTestCalls) | Should -Be @('package:Uninstall:False')
    }

    It 'applies a chosen state silently without the installer restart prompt' {
        Set-AtlasTelemetryPackageState -State Installed -Silent
        Set-AtlasTelemetryPackageState -State Removed -Silent

        @($global:AtlasPrivacyTestCalls) | Should -Be @('package:Install:True', 'package:Uninstall:True')
        Should -Invoke Read-AtlasChoice -ModuleName Atlas.Privacy -Times 0 -Exactly
    }

    It 'propagates a failed package operation' {
        Mock Get-AtlasTelemetryPackageInstalled -ModuleName Atlas.Privacy { $false }
        Mock Invoke-AtlasTelemetryPackageOperation -ModuleName Atlas.Privacy { throw 'Package installation failed with exit code 3.' }
        Mock Read-AtlasChoice -ModuleName Atlas.Privacy { 1 }

        { Remove-AtlasTelemetryComponents } | Should -Throw '*exit code 3*'
    }

    It 'detects the NoTelemetry package by name and wraps enumeration failures' {
        Mock Get-WindowsPackage -ModuleName Atlas.Privacy {
            @(
                [pscustomobject]@{ PackageName = 'Microsoft-Windows-Something' }
                [pscustomobject]@{ PackageName = 'Z-Atlas-NoTelemetry-Package~31bf3856ad364e35~amd64~~10.0.0.0' }
            )
        }
        InModuleScope Atlas.Privacy { Get-AtlasTelemetryPackageInstalled } | Should -BeTrue

        Mock Get-WindowsPackage -ModuleName Atlas.Privacy { @([pscustomobject]@{ PackageName = 'Other' }) }
        InModuleScope Atlas.Privacy { Get-AtlasTelemetryPackageInstalled } | Should -BeFalse

        Mock Get-WindowsPackage -ModuleName Atlas.Privacy { throw 'DISM offline' }
        { InModuleScope Atlas.Privacy { Get-AtlasTelemetryPackageInstalled } } | Should -Throw '*Failed to get packages! DISM offline*'
    }
}
