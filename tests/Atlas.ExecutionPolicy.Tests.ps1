[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter',
    '',
    Justification = 'The environment-phase harness stubs declare the parameter surface of the commands they shadow.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidOverwritingBuiltInCmdlets',
    '',
    Justification = 'The isolated environment-phase harness shadows Import-Module and Write-Host only while executing the phase under test.'
)]
param()

BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Registry\Atlas.Registry.psd1') -Force

    $script:phasePath = Join-Path -Path $PSScriptRoot -ChildPath `
        '..\playbook\Executables\AtlasModules\Scripts\Install\Phases\Invoke-EnvironmentPhase.ps1'
    $script:testRoot = 'HKCU:\Software\AtlasRewriteTest'
    $script:policySubKey = 'Software\AtlasRewriteTest\ExecutionPolicy\ShellIds\Microsoft.PowerShell'

    function Get-TestExecutionPolicyValue {
        param([Parameter(Mandatory = $true)][Microsoft.Win32.RegistryView]$View)

        $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
            [Microsoft.Win32.RegistryHive]::CurrentUser, $View
        )
        try {
            $key = $baseKey.OpenSubKey($script:policySubKey, $false)
            if ($null -eq $key) {
                return $null
            }
            try {
                return $key.GetValue('ExecutionPolicy', $null)
            }
            finally {
                $key.Dispose()
            }
        }
        finally {
            $baseKey.Dispose()
        }
    }

    function Invoke-AtlasEnvironmentPhaseForTest {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)][string]$Path,
            [Parameter(Mandatory = $true)]$Context,
            [Parameter(Mandatory = $true)]$Calls,
            [Parameter(Mandatory = $true)]$Logs
        )

        & {
            function Assert-AtlasPrivilege {
                [CmdletBinding()]
                param([switch]$TrustedInstaller)
                [void]$TrustedInstaller
                [void]$Calls.Add('Assert-AtlasPrivilege')
            }

            function Import-Module {
                [CmdletBinding()]
                param([string]$Name, [switch]$Force)
                [void]$Force
                [void]$Calls.Add("Import-Module:$(Split-Path -Path $Name -Leaf)")
            }

            function Get-AtlasContext {
                return $Context
            }

            function Set-AtlasWindowsPowerShellExecutionPolicy {
                [void]$Calls.Add('Set-AtlasWindowsPowerShellExecutionPolicy')
            }

            function Write-AtlasLog {
                param(
                    [string]$Level = 'Information',
                    [Parameter(Mandatory = $true)][string]$Message
                )
                [void]$Logs.Add([pscustomobject]@{ Level = $Level; Message = $Message })
                # After logging its execution policy decision the phase NGENs the loaded
                # assemblies and writes a machine environment variable; neither belongs in
                # a test process, so the harness stops the phase at that first log entry.
                throw [OperationCanceledException]::new('environment phase harness stop')
            }

            function Write-Host {
                param([Parameter(ValueFromRemainingArguments = $true)]$Arguments)
                [void]$Arguments
            }

            . $Path
        }
    }
}

AfterAll {
    Remove-Item -Path 'HKCU:\Software\AtlasRewriteTest' -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Set-AtlasWindowsPowerShellExecutionPolicy' {
    BeforeEach {
        Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    AfterEach {
        Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'writes RemoteSigned into every registry view and reads it back' {
        Set-AtlasWindowsPowerShellExecutionPolicy `
            -Hive ([Microsoft.Win32.RegistryHive]::CurrentUser) -SubKey $script:policySubKey

        $views = if ([Environment]::Is64BitOperatingSystem) {
            @([Microsoft.Win32.RegistryView]::Registry64, [Microsoft.Win32.RegistryView]::Registry32)
        }
        else {
            @([Microsoft.Win32.RegistryView]::Default)
        }
        foreach ($view in $views) {
            Get-TestExecutionPolicyValue -View $view | Should -BeExactly 'RemoteSigned'
        }
        (Get-ItemProperty -Path "HKCU:\$script:policySubKey" -Name ExecutionPolicy).ExecutionPolicy |
            Should -BeExactly 'RemoteSigned'
    }

    It 'replaces a different existing policy without touching sibling values' {
        New-Item -Path "HKCU:\$script:policySubKey" -Force | Out-Null
        Set-ItemProperty -Path "HKCU:\$script:policySubKey" -Name ExecutionPolicy -Value 'Restricted'
        Set-ItemProperty -Path "HKCU:\$script:policySubKey" -Name Path `
            -Value 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'

        Set-AtlasWindowsPowerShellExecutionPolicy `
            -Hive ([Microsoft.Win32.RegistryHive]::CurrentUser) -SubKey $script:policySubKey

        $key = Get-ItemProperty -Path "HKCU:\$script:policySubKey"
        $key.ExecutionPolicy | Should -BeExactly 'RemoteSigned'
        $key.Path | Should -BeExactly 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
    }

    It 'throws when the written value does not retain RemoteSigned' {
        Mock -CommandName Get-AtlasWindowsPowerShellExecutionPolicyValue -ModuleName Atlas.Registry -MockWith {
            'Unrestricted'
        }

        {
            Set-AtlasWindowsPowerShellExecutionPolicy `
                -Hive ([Microsoft.Win32.RegistryHive]::CurrentUser) -SubKey $script:policySubKey
        } | Should -Throw '*did not retain RemoteSigned*'
    }

    It 'defaults to the machine Windows PowerShell shell ID key' {
        $command = Get-Command -Name Set-AtlasWindowsPowerShellExecutionPolicy -Module Atlas.Registry
        $command.Parameters['Hive'].ParameterType | Should -Be ([Microsoft.Win32.RegistryHive])
        $command.Parameters['SubKey'].ParameterType | Should -Be ([string])

        $defaults = @{}
        foreach ($parameter in $command.ScriptBlock.Ast.Body.ParamBlock.Parameters) {
            $defaults[$parameter.Name.VariablePath.UserPath] = $parameter.DefaultValue
        }
        $defaults['Hive'].Extent.Text | Should -BeExactly '[Microsoft.Win32.RegistryHive]::LocalMachine'
        $defaults['SubKey'].SafeGetValue() |
            Should -BeExactly 'SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell'
    }
}

Describe 'Environment phase execution policy gate' {
    BeforeEach {
        $script:phaseCalls = New-Object 'Collections.Generic.List[string]'
        $script:phaseLogs = New-Object 'Collections.Generic.List[object]'
    }

    It 'sets RemoteSigned for a fresh install' {
        $context = [pscustomobject]@{ IsUpgrade = $false; IsOobe = $false }

        {
            Invoke-AtlasEnvironmentPhaseForTest -Path $script:phasePath -Context $context `
                -Calls $script:phaseCalls -Logs $script:phaseLogs
        } | Should -Throw 'environment phase harness stop'

        @($script:phaseCalls) | Should -Be @(
            'Assert-AtlasPrivilege',
            'Import-Module:Atlas.Registry.psd1',
            'Set-AtlasWindowsPowerShellExecutionPolicy'
        )
        $script:phaseLogs.Count | Should -Be 1
        $script:phaseLogs[0].Level | Should -BeExactly 'Information'
        $script:phaseLogs[0].Message | Should -BeLike '*RemoteSigned for the fresh install*'
    }

    It 'preserves the existing policy during an upgrade' {
        $context = [pscustomobject]@{ IsUpgrade = $true; IsOobe = $false }

        {
            Invoke-AtlasEnvironmentPhaseForTest -Path $script:phasePath -Context $context `
                -Calls $script:phaseCalls -Logs $script:phaseLogs
        } | Should -Throw 'environment phase harness stop'

        @($script:phaseCalls) | Should -Be @(
            'Assert-AtlasPrivilege',
            'Import-Module:Atlas.Registry.psd1'
        )
        $script:phaseLogs.Count | Should -Be 1
        $script:phaseLogs[0].Message | Should -BeLike '*Preserving the existing Windows PowerShell execution policy*'
    }
}
