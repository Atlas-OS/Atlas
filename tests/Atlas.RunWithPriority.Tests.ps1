BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $repoRoot = $script:AtlasTestRepoRoot
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force
    $handlerPath = Join-Path $repoRoot `
        'playbook\Executables\AtlasModules\Scripts\Operations\Invoke-AtlasPriorityLaunch.ps1'

    $script:definition = Get-AtlasToggleDefinition -Name RunWithPriority `
        -TogglesRoot (Join-Path $repoRoot 'playbook\Executables\AtlasModules\Toggles')
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Shell\Atlas.Shell.psd1') -Force
    . $handlerPath -Priority Normal -TargetPath 'C:\not-used.exe'

    if (-not ('AtlasPriorityTestCommandLine' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

public static class AtlasPriorityTestCommandLine
{
    [DllImport("shell32.dll", SetLastError = true)]
    private static extern IntPtr CommandLineToArgvW(
        [MarshalAs(UnmanagedType.LPWStr)] string commandLine,
        out int argumentCount);

    [DllImport("kernel32.dll")]
    private static extern IntPtr LocalFree(IntPtr memory);

    public static string[] Split(string commandLine)
    {
        int count;
        IntPtr arguments = CommandLineToArgvW(commandLine, out count);
        if (arguments == IntPtr.Zero)
            throw new Win32Exception(Marshal.GetLastWin32Error());

        try
        {
            string[] result = new string[count];
            for (int index = 0; index < count; index++)
                result[index] = Marshal.PtrToStringUni(
                    Marshal.ReadIntPtr(arguments, index * IntPtr.Size));
            return result;
        }
        finally
        {
            LocalFree(arguments);
        }
    }
}
'@ -ErrorAction Stop
    }

    # Runs one companion function through the engine's own runner (module scope, strict
    # mode) with the Atlas.Registry writes captured by the module-scoped mocks declared
    # in the Describe's BeforeEach.
    function Invoke-PriorityToggleAction {
        param(
            [Parameter(Mandatory = $true)]
            [string]$FunctionName
        )

        $script:priorityWrites = [Collections.Generic.List[object]]::new()
        $script:priorityRemovals = [Collections.Generic.List[string]]::new()
        $toggle = [pscustomobject]@{
            Name           = 'RunWithPriority'
            State          = 'Add'
            StateValue     = 1
            Silent         = $true
            OperationsPath = 'C:\AtlasModules\Scripts\Operations'
        }
        InModuleScope Atlas.Toggles {
            Invoke-AtlasToggleFunction -Definition $d -FunctionName $f -Toggle $t -Label 'test'
        } -Parameters @{ d = $script:definition; f = $FunctionName; t = $toggle }

        return [pscustomobject]@{
            Writes   = @($script:priorityWrites)
            Removals = @($script:priorityRemovals)
        }
    }
}

Describe 'Run with priority' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Toggles
        Mock Set-AtlasRegistryValue -ModuleName Atlas.Toggles {
            $script:priorityWrites.Add([pscustomobject]@{
                    Path = $Path
                    Name = $Name
                    Type = $Type
                    Data = $Data
                })
        }
        Mock Remove-AtlasRegistryKey -ModuleName Atlas.Toggles {
            $script:priorityRemovals.Add($Path)
        }
    }

    It 'maps the six menu labels to the documented Windows priority classes' {
        $expected = [ordered]@{
            Low         = [uint32]0x00000040
            BelowNormal = [uint32]0x00004000
            Normal      = [uint32]0x00000020
            AboveNormal = [uint32]0x00008000
            High        = [uint32]0x00000080
            Realtime    = [uint32]0x00000100
        }

        foreach ($entry in $expected.GetEnumerator()) {
            Get-AtlasPriorityClass -Name $entry.Key | Should -Be $entry.Value
        }
        { Get-AtlasPriorityClass -Name 'TimeCritical' } | Should -Throw
    }

    It 'accepts an existing local executable and rejects invalid targets' {
        $target = Join-Path $TestDrive `
            ('Atlas priority {0} tool.exe' -f [char]0x03A9)
        Copy-Item -LiteralPath (Join-Path ([Environment]::SystemDirectory) 'where.exe') `
            -Destination $target

        Resolve-AtlasPriorityTarget -Path $target |
            Should -BeExactly ([IO.Path]::GetFullPath($target))
        { Resolve-AtlasPriorityTarget -Path '.\relative.exe' } |
            Should -Throw '*absolute path*'
        { Resolve-AtlasPriorityTarget -Path '\\server\share\tool.exe' } |
            Should -Throw '*absolute path*'
        { Resolve-AtlasPriorityTarget -Path ($target + '.txt') } |
            Should -Throw '*executable file*'
        { Resolve-AtlasPriorityTarget -Path (Join-Path $TestDrive 'missing.exe') } |
            Should -Throw '*does not exist*'
    }

    It 'round-trips the fixed handler and selected target through Realtime UAC arguments' {
        $handler = 'C:\Windows\AtlasModules\Scripts\Operations\Invoke-AtlasPriorityLaunch.ps1'
        $target = 'C:\Program Files\Atlas & games\Unicode {0} app.exe' -f [char]0x03A9
        $arguments = @(Get-AtlasPriorityRelaunchArgumentList `
                -HandlerPath $handler -ExecutablePath $target)
        $parsed = [AtlasPriorityTestCommandLine]::Split($arguments -join ' ')

        $parsed.Count | Should -Be 12
        $parsed[6] | Should -BeExactly $handler
        $parsed[8] | Should -BeExactly 'Realtime'
        $parsed[10] | Should -BeExactly $target
        $parsed[11] | Should -BeExactly '-Elevated'
    }

    It 'loads the native launcher and rejects invalid calls before creating a process' {
        Initialize-AtlasNativeType

        'Atlas.Native.PriorityLauncher' -as [type] | Should -Not -BeNullOrEmpty
        { [Atlas.Native.PriorityLauncher]::Start(
                $null,
                '"C:\missing.exe"',
                'C:\',
                [uint32]0x20
            ) } | Should -Throw '*application path is required*'
    }

    It 'writes one machine cascade with the six visible menu entries' {
        $add = $script:definition.States['Add']
        $add['MachineAction'] | Should -BeExactly 'Add-AtlasRunWithPriorityContextMenu'
        $add['StateValue'] | Should -Be 1
        $result = Invoke-PriorityToggleAction -FunctionName $add['MachineAction']
        $root = 'HKLM:\SOFTWARE\Classes\exefile\Shell\Priority'

        $result.Removals | Should -Be @($root)
        $result.Writes.Count | Should -Be 14
        @($result.Writes | Where-Object {
                $_.Path -eq $root -and $_.Name -eq 'MUIVerb' -and
                $_.Type -eq 'String' -and $_.Data -eq 'Run with priority'
            }).Count | Should -Be 1
        @($result.Writes | Where-Object {
                $_.Path -eq $root -and $_.Name -eq 'MultiSelectModel' -and
                $_.Type -eq 'String' -and $_.Data -eq 'Single'
            }).Count | Should -Be 1

        $labels = @($result.Writes | Where-Object {
                $_.Name -eq 'MUIVerb' -and $_.Path -ne $root
            } | ForEach-Object Data)
        $labels | Should -Be @(
            'Realtime', 'High', 'Above normal', 'Normal', 'Below normal', 'Low'
        )
        $work = Get-AtlasToggleStateWork -Definition $script:definition -StateEntry $add
        $work.Machine | Should -BeTrue
        $work.User | Should -BeFalse
    }

    It 'keeps every selected executable as one argument to the fixed internal script' {
        $result = Invoke-PriorityToggleAction `
            -FunctionName $script:definition.States['Add']['MachineAction']
        $commands = @($result.Writes | Where-Object {
                $_.Name -eq '' -and $_.Type -eq 'ExpandString'
            })
        $target = 'C:\Program Files\Atlas & games\Unicode {0} app.exe' -f [char]0x03A9
        $priorities = @('Realtime', 'High', 'AboveNormal', 'Normal', 'BelowNormal', 'Low')

        $commands.Count | Should -Be 6
        for ($index = 0; $index -lt $commands.Count; $index++) {
            $parsed = [AtlasPriorityTestCommandLine]::Split(
                $commands[$index].Data.Replace('%1', $target)
            )
            $parsed.Count | Should -Be 14
            $parsed[0] | Should -BeExactly `
                '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe'
            $parsed[9] | Should -BeExactly `
                '%SystemRoot%\AtlasModules\Scripts\Operations\Invoke-AtlasPriorityLaunch.ps1'
            $parsed[11] | Should -BeExactly $priorities[$index]
            $parsed[13] | Should -BeExactly $target
        }
    }

    It 'removes only the machine cascade root' {
        # The Remove state is declarative: one DeleteKey entry, no companion function.
        $remove = $script:definition.States['Remove']
        $registry = @($remove['Registry'])

        $registry | Should -HaveCount 1
        $registry[0].Path | Should -BeExactly 'HKLM:\SOFTWARE\Classes\exefile\Shell\Priority'
        $registry[0].Operation | Should -BeExactly 'DeleteKey'
        $remove.Contains('MachineAction') | Should -BeFalse
        $remove.Contains('UserAction') | Should -BeFalse
        $remove['StateValue'] | Should -Be 0

        $work = Get-AtlasToggleStateWork -Definition $script:definition -StateEntry $remove
        $work.Machine | Should -BeTrue
        $work.User | Should -BeFalse
    }
}
