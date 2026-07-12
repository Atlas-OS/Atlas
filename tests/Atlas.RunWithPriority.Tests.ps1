BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
    $togglePath = Join-Path $repoRoot `
        'playbook\Executables\AtlasModules\Toggles\Interface\RunWithPriority.ps1'
    $handlerPath = Join-Path $repoRoot `
        'playbook\Executables\AtlasModules\Scripts\Internal\Invoke-AtlasPriorityLaunch.ps1'
    $shellSupportPath = Join-Path $repoRoot `
        'playbook\Executables\AtlasModules\Scripts\Internal\Shell-ContextMenuSupport.ps1'

    $script:definition = & $togglePath
    . $shellSupportPath
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

    function Invoke-PriorityToggleAction {
        param(
            [Parameter(Mandatory = $true)]
            [scriptblock]$Action
        )

        $writes = [Collections.Generic.List[object]]::new()
        $removals = [Collections.Generic.List[string]]::new()
        & {
            param($Action)

            Set-Item -Path Function:\Import-Module -Value { $null = $args }
            Set-Item -Path Function:\Set-AtlasRegistryValue -Value {
                param($Path, $Name, $Type, $Data)
                [void]$writes.Add([pscustomobject]@{
                        Path = $Path
                        Name = $Name
                        Type = $Type
                        Data = $Data
                    })
            }
            Set-Item -Path Function:\Remove-AtlasRegistryKey -Value {
                param($Path)
                [void]$removals.Add($Path)
            }

            & $Action ([pscustomobject]@{
                    ScriptsPath = 'C:\AtlasModules\Scripts'
                    Silent      = $true
                })
        } $Action

        return [pscustomobject]@{
            Writes   = @($writes)
            Removals = @($removals)
        }
    }
}

Describe 'Run with priority' {
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
        $handler = 'C:\Windows\AtlasModules\Scripts\Internal\Invoke-AtlasPriorityLaunch.ps1'
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
        Initialize-AtlasPriorityNative

        'AtlasPriorityLauncherNative' -as [type] | Should -Not -BeNullOrEmpty
        { [AtlasPriorityLauncherNative]::Start(
                $null,
                '"C:\missing.exe"',
                'C:\',
                [uint32]0x20
            ) } | Should -Throw '*application path is required*'
    }

    It 'writes one machine cascade with the six visible menu entries' {
        $result = Invoke-PriorityToggleAction `
            -Action $script:definition.States.Add.Action
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
        $script:definition.States.Add.ReplayScope | Should -BeExactly 'Machine'
    }

    It 'keeps every selected executable as one argument to the fixed internal script' {
        $result = Invoke-PriorityToggleAction `
            -Action $script:definition.States.Add.Action
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
                '%SystemRoot%\AtlasModules\Scripts\Internal\Invoke-AtlasPriorityLaunch.ps1'
            $parsed[11] | Should -BeExactly $priorities[$index]
            $parsed[13] | Should -BeExactly $target
        }
    }

    It 'removes only the machine cascade root' {
        $result = Invoke-PriorityToggleAction `
            -Action $script:definition.States.Remove.Action

        $result.Writes | Should -BeNullOrEmpty
        $result.Removals | Should -Be @(
            'HKLM:\SOFTWARE\Classes\exefile\Shell\Priority'
        )
        $script:definition.States.Remove.ReplayScope | Should -BeExactly 'Machine'
    }
}
