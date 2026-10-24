[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidGlobalVars',
    '',
    Justification = 'Extracted handler functions resolve the handler''s script variables dynamically, so fixtures must be staged as global variables.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter',
    '',
    Justification = 'Stand-ins declare the parameters of the handler functions they let Pester mock.'
)]
param()

BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:executablesRoot = Join-Path $script:repositoryRoot 'playbook\Executables'
    $script:terminalHandler = Join-Path $script:executablesRoot `
        'AtlasModules\Scripts\Entry\Open-TerminalHere.ps1'
    $script:takeOwnershipHandler = Join-Path $script:executablesRoot `
        'AtlasModules\Scripts\Entry\Invoke-TakeOwnership.ps1'
    $script:takeOwnershipPayload = Join-Path $script:executablesRoot `
        'AtlasModules\Scripts\Registry\TakeOwnership\add.reg'

    Import-Module -Name (Join-Path $script:AtlasTestModulesRoot 'Atlas.Shell\Atlas.Shell.psd1') -Force

    function Get-ContextMenuCommand {
        param(
            [Parameter(Mandatory)]
            [string]$Path,

            [Parameter(Mandatory)]
            [string]$SelectionToken
        )

        return @(
            ([IO.File]::ReadAllText($Path) -split '\r?\n') |
                Where-Object { $_ -match [regex]::Escape($SelectionToken) }
        )
    }

    # Starts powershell.exe with one .reg command line as Explorer does, with the
    # selection filled in and the handler swapped for a probe that reports what
    # -File bound.
    function Invoke-ContextMenuCommandLine {
        param(
            [Parameter(Mandatory)][string]$RegistryLine,
            [Parameter(Mandatory)][string]$SelectionToken,
            [Parameter(Mandatory)][string]$Selection
        )

        $probe = Join-Path $TestDrive 'Show-HandlerArguments.ps1'
        if (-not (Test-Path -LiteralPath $probe)) {
            Set-Content -LiteralPath $probe -Encoding Ascii -Value @'
param([string]$Terminal, [string]$Verb, [string]$Path, [string]$TargetType, [string]$TargetPath, [switch]$Pause)
[Console]::Out.WriteLine((ConvertTo-Json -Compress -InputObject @{ Path = $Path; TargetPath = $TargetPath; Pause = [bool]$Pause }))
'@
        }

        $value = [regex]::Match($RegistryLine, '^(?:@|"IsolatedCommand")="(?<value>.*)"$').Groups['value'].Value
        $command = [regex]::Replace($value, '\\(["\\])', '$1')
        $command = [regex]::Replace($command, '"%SystemRoot%\\AtlasModules\\Scripts\\Entry\\[^"]+\.ps1"', { '"' + $probe + '"' })
        $command = $command.Replace('%SystemRoot%', $env:SystemRoot).Replace($SelectionToken, $Selection)
        $parts = [regex]::Match($command, '^"(?<file>[^"]+)" (?<arguments>.*)$')

        $startInfo = [Diagnostics.ProcessStartInfo]::new()
        $startInfo.FileName = $parts.Groups['file'].Value
        $startInfo.Arguments = $parts.Groups['arguments'].Value
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardOutput = $true
        $process = [Diagnostics.Process]::Start($startInfo)
        try {
            $output = $process.StandardOutput.ReadToEnd()
            $process.WaitForExit()
        }
        finally {
            $process.Dispose()
        }
        return ($output | ConvertFrom-Json)
    }
}

Describe 'Terminal context-menu .reg files' {
    BeforeDiscovery {
        $root = (Resolve-Path (Join-Path $PSScriptRoot '..\playbook\Executables')).ProviderPath
        $script:terminalPayloadCases = @(
            @{
                Name = 'Scripts enabled'
                Path = Join-Path $root 'AtlasModules\Scripts\Registry\Terminals\enabled.reg'
                IncludesWindowsTerminal = $true
            }
            @{
                Name = 'Scripts minimal'
                Path = Join-Path $root 'AtlasModules\Scripts\Registry\Terminals\minimal.reg'
                IncludesWindowsTerminal = $false
            }
        )
    }

    It '<Name> routes each selected directory through the internal handler' -ForEach $terminalPayloadCases {
        $commands = @(Get-ContextMenuCommand -Path $Path -SelectionToken '%V')
        $terminals = @('CommandPrompt', 'PowerShell')
        if ($IncludesWindowsTerminal) {
            $terminals += 'WindowsTerminal'
        }

        $commands.Count | Should -Be ($terminals.Count * 8)
        foreach ($command in $commands) {
            $command | Should -Match '^@="\\"%SystemRoot%\\\\System32\\\\WindowsPowerShell\\\\v1\.0\\\\powershell\.exe\\" '
            $command | Should -Match ' -File \\"%SystemRoot%\\\\AtlasModules\\\\Scripts\\\\Entry\\\\Open-TerminalHere\.ps1\\" '
            $command | Should -Match ' -Terminal (?:CommandPrompt|PowerShell|WindowsTerminal) -Verb (?:Open|RunAs) -Path \\"%V\.\\""$'
        }

        foreach ($terminal in $terminals) {
            foreach ($verb in @('Open', 'RunAs')) {
                @($commands | Where-Object { $_ -match " -Terminal $terminal -Verb $verb -Path " }).Count |
                    Should -Be 4
            }
        }
    }

    It '<Name> hands a drive root and a folder to the handler as rooted paths' -ForEach $terminalPayloadCases {
        $command = @(Get-ContextMenuCommand -Path $Path -SelectionToken '%V')[0]
        foreach ($selection in @([IO.Path]::GetPathRoot($env:SystemRoot), $env:SystemRoot)) {
            $bound = Invoke-ContextMenuCommandLine -RegistryLine $command -SelectionToken '%V' -Selection $selection

            [IO.Path]::GetFullPath($bound.Path) | Should -BeExactly $selection
        }
    }
}

Describe 'Take Ownership context-menu .reg files' {
    It 'routes files, directories, and drives through the internal handler' {
        $commands = @(Get-ContextMenuCommand -Path $script:takeOwnershipPayload -SelectionToken '%1')

        $commands.Count | Should -Be 6
        foreach ($command in $commands) {
            $command | Should -Match '^(?:@|"IsolatedCommand")="\\"%SystemRoot%\\\\System32\\\\WindowsPowerShell\\\\v1\.0\\\\powershell\.exe\\" '
            $command | Should -Match ' -File \\"%SystemRoot%\\\\AtlasModules\\\\Scripts\\\\Entry\\\\Invoke-TakeOwnership\.ps1\\" '
            $command | Should -Match ' -TargetType (?:(?:File|Directory) -TargetPath \\"%1|Drive -TargetPath \\"%1\.)\\" -Pause"$'
        }

        foreach ($targetType in @('File', 'Directory', 'Drive')) {
            @($commands | Where-Object { $_ -match " -TargetType $targetType -TargetPath " }).Count |
                Should -Be 2
        }
    }

    It 'hands a drive root to the handler as a rooted path, followed by -Pause' {
        $commands = @(Get-ContextMenuCommand -Path $script:takeOwnershipPayload -SelectionToken '%1' |
                Where-Object { $_ -match ' -TargetType Drive ' })
        $driveRoot = [IO.Path]::GetPathRoot($env:SystemRoot)

        foreach ($command in $commands) {
            $bound = Invoke-ContextMenuCommandLine -RegistryLine $command -SelectionToken '%1' -Selection $driveRoot

            [IO.Path]::GetFullPath($bound.TargetPath) | Should -BeExactly $driveRoot
            $bound.Pause | Should -BeTrue
        }
    }
}

Describe 'Shell context-menu handlers' {
    BeforeAll {
        # Pester mocks only a command that already exists. These stand-ins let the
        # mocks below replace the handler's own functions of the same name.
        function global:Start-AtlasTerminalProcess { param($StartInfo) }
        function global:Show-AtlasTerminalFailure { param($ErrorRecord) }
    }
    AfterAll {
        Remove-Item Function:\Start-AtlasTerminalProcess, Function:\Show-AtlasTerminalFailure -ErrorAction SilentlyContinue
    }
    BeforeEach {
        Mock Show-AtlasTerminalFailure {}
        # Throw rather than return, so a regression fails here instead of opening a
        # real terminal, a UAC prompt or an elevated Take Ownership run.
        Mock Start-Process { throw 'Start-Process must not run in handler tests.' }
    }

    It 'opens a command prompt in <Name> exactly' -ForEach @(
        @{ Name = 'terminal & data' }
        @{ Name = 'Movies [2020]' }
        @{ Name = '[Backup]' }
    ) {
        $workingDirectory = Join-Path $TestDrive $Name
        [void][IO.Directory]::CreateDirectory($workingDirectory)
        [AppDomain]::CurrentDomain.SetData('AtlasShellStartInfo', $null)
        Mock Start-AtlasTerminalProcess {
            [AppDomain]::CurrentDomain.SetData('AtlasShellStartInfo', $StartInfo)
            return [pscustomobject]@{ Id = 101 }
        }

        try {
            & $script:terminalHandler -Terminal CommandPrompt -Verb Open -Path $workingDirectory

            Should -Invoke Start-AtlasTerminalProcess -Times 1 -Exactly
            Should -Invoke Show-AtlasTerminalFailure -Times 0 -Exactly
            $start = [AppDomain]::CurrentDomain.GetData('AtlasShellStartInfo')
            $start.FileName | Should -BeExactly (Join-Path ([Environment]::SystemDirectory) 'cmd.exe')
            $start.WorkingDirectory | Should -BeExactly ([IO.Path]::GetFullPath($workingDirectory))
            $start.Verb | Should -BeExactly 'Open'
            $start.UseShellExecute | Should -BeTrue
            $start.Arguments | Should -BeNullOrEmpty
        }
        finally {
            [AppDomain]::CurrentDomain.SetData('AtlasShellStartInfo', $null)
        }
    }

    It 'reports a failed terminal launch to the user and fails' {
        Mock Start-AtlasTerminalProcess { throw 'launch failed' }

        { & $script:terminalHandler -Terminal PowerShell -Verb Open -Path $TestDrive } |
            Should -Throw '*launch failed*'
        Should -Invoke Show-AtlasTerminalFailure -Times 1 -Exactly -ParameterFilter {
            $ErrorRecord.Exception.Message -like '*launch failed*'
        }
    }

    It 'treats a declined UAC prompt as no failure' {
        Mock Start-AtlasTerminalProcess { throw [ComponentModel.Win32Exception]::new(1223) }

        { & $script:terminalHandler -Terminal PowerShell -Verb RunAs -Path $TestDrive } | Should -Not -Throw
        Should -Invoke Show-AtlasTerminalFailure -Times 0 -Exactly
    }

    It 'crosses UAC with the fixed handler path and the target as an argument' {
        $targetPath = Join-Path $TestDrive 'ownership & data.txt'
        [IO.File]::WriteAllText($targetPath, 'test')
        [AppDomain]::CurrentDomain.SetData('AtlasShellStartParameters', $null)
        Mock Start-Process {
            [AppDomain]::CurrentDomain.SetData('AtlasShellStartParameters', @{
                FilePath     = $FilePath
                ArgumentList = $ArgumentList
                Verb         = $Verb
                WindowStyle  = $WindowStyle
                Wait         = $Wait
                PassThru     = $PassThru
            })
            return [pscustomobject]@{ ExitCode = 0 }
        }

        try {
            & $script:takeOwnershipHandler -TargetType File -TargetPath $targetPath -Pause

            Should -Invoke Start-Process -Times 1 -Exactly
            $start = [AppDomain]::CurrentDomain.GetData('AtlasShellStartParameters')
            $start.FilePath | Should -BeExactly (Join-Path `
                ([Environment]::SystemDirectory) 'WindowsPowerShell\v1.0\powershell.exe')
            $start.Verb | Should -BeExactly 'RunAs'
            $start.Wait | Should -BeTrue
            $start.PassThru | Should -BeTrue
            $start.WindowStyle | Should -BeExactly 'Normal'

            $arguments = @($start.ArgumentList)
            $arguments[[Array]::IndexOf($arguments, '-File') + 1] | Should -BeExactly `
                (ConvertTo-AtlasShellWindowsArgument -Value ([IO.Path]::GetFullPath($script:takeOwnershipHandler)))
            $arguments[[Array]::IndexOf($arguments, '-TargetType') + 1] | Should -BeExactly 'File'
            $arguments[[Array]::IndexOf($arguments, '-TargetPath') + 1] | Should -BeExactly `
                (ConvertTo-AtlasShellWindowsArgument -Value ([IO.Path]::GetFullPath($targetPath)))
            $arguments | Should -Contain '-Elevated'
            $arguments | Should -Contain '-Pause'
        }
        finally {
            [AppDomain]::CurrentDomain.SetData('AtlasShellStartParameters', $null)
        }
    }

    It 'reads one localized Yes letter for takeown.exe under StrictMode and Stop' {
        $tokens = $null
        $errors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile(
            $script:takeOwnershipHandler, [ref]$tokens, [ref]$errors
        )
        $definition = $ast.Find({
                param($node)
                $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -eq 'Get-AtlasTakeOwnershipYesChoice'
            }, $true)
        $definition | Should -Not -BeNullOrEmpty
        # The elevated handler runs the probe under these settings.
        $probe = [scriptblock]::Create(
            "Set-StrictMode -Version 3.0`n`$ErrorActionPreference = 'Stop'`n" +
            "function Get-AtlasTakeOwnershipYesChoice $($definition.Body.Extent.Text)`n" +
            "Get-AtlasTakeOwnershipYesChoice -ChoicePath ([IO.Path]::Combine([Environment]::SystemDirectory, 'choice.exe'))"
        )

        $yes = @(& $probe)

        $yes.Count | Should -Be 1
        $yes[0] | Should -BeOfType [string]
        $yes[0].Length | Should -Be 1
        [char]::IsLetter($yes[0][0]) | Should -BeTrue
    }

    It 'rejects relative paths and target-type mismatches before launch' {
        Mock Start-AtlasTerminalProcess { throw 'The terminal was started before validation rejected the target.' }

        { & $script:terminalHandler -Terminal CommandPrompt -Verb Open -Path '.\relative' } |
            Should -Throw '*one absolute path of at most*'
        Should -Invoke Show-AtlasTerminalFailure -Times 1 -Exactly
        Should -Invoke Start-AtlasTerminalProcess -Times 0 -Exactly
        { & $script:takeOwnershipHandler -TargetType File -TargetPath $TestDrive } |
            Should -Throw '*file does not exist*'
        { & $script:takeOwnershipHandler -TargetType Drive -TargetPath $TestDrive } |
            Should -Throw '*not an existing file-system root*'
        Should -Invoke Start-Process -Times 0 -Exactly
    }
}

Describe 'Open-TerminalHere launch and failure report' {
    BeforeAll {
        # Show-AtlasTerminalFailure logs through Atlas.Core, which Pester can mock only
        # once it is loaded here.
        Import-Module -Name (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1')
        $tokens = $null
        $errors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile(
            $script:terminalHandler, [ref]$tokens, [ref]$errors
        )
        @($errors).Count | Should -Be 0
        foreach ($name in @('Start-AtlasTerminalProcess', 'Show-AtlasTerminalFailure')) {
            $definition = $ast.Find({
                    param($node)
                    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq $name
                }, $true)
            $definition | Should -Not -BeNullOrEmpty
            Set-Item -Path "Function:\global:$name" -Value $definition.Body.GetScriptBlock()
        }
    }
    AfterAll {
        Remove-Item Function:\Start-AtlasTerminalProcess, Function:\Show-AtlasTerminalFailure -ErrorAction SilentlyContinue
    }

    Context 'Show-AtlasTerminalFailure' {
        BeforeEach {
            # The handler's own script variables, which the extracted function reads.
            $global:Terminal = 'PowerShell'
            $global:Path = Join-Path $TestDrive 'target'
            $global:scriptsRoot = Join-Path $TestDrive 'Scripts'
            $script:toastPath = Join-Path $global:scriptsRoot 'Operations\Show-AtlasToast.ps1'
            $script:toastRecord = Join-Path $TestDrive 'toast.txt'
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $script:toastPath))
            Remove-Item -LiteralPath $script:toastRecord -Force -ErrorAction SilentlyContinue
            Set-Content -LiteralPath $script:toastPath -Encoding Ascii -Value @"
param([string]`$Title, [string]`$Message)
[IO.File]::WriteAllText('$script:toastRecord', `$Message)
"@
            try { throw 'launch failed' } catch { $script:launchError = $_ }
            Mock Write-AtlasLog {}
        }
        AfterEach {
            Remove-Variable Terminal, Path, scriptsRoot -Scope Global -ErrorAction SilentlyContinue
        }

        It 'logs the original error and tells the user why no terminal opened' {
            & {
                Set-StrictMode -Version 3.0
                $ErrorActionPreference = 'Stop'
                Show-AtlasTerminalFailure -ErrorRecord $script:launchError
            }

            Should -Invoke Write-AtlasLog -Times 1 -Exactly -ParameterFilter {
                $Level -eq 'Error' -and [object]::ReferenceEquals($ErrorRecord, $script:launchError) -and
                $Message -like "*PowerShell*$($global:Path)*launch failed*"
            }
            [IO.File]::ReadAllText($script:toastRecord) | Should -BeLike '*launch failed*'
        }

        It 'still tells the user when logging fails' {
            Mock Write-AtlasLog { throw 'log failed' }

            {
                Set-StrictMode -Version 3.0
                $ErrorActionPreference = 'Stop'
                Show-AtlasTerminalFailure -ErrorRecord $script:launchError
            } | Should -Not -Throw
            [IO.File]::ReadAllText($script:toastRecord) | Should -BeLike '*launch failed*'
        }

        It 'returns without throwing when the toast fails' {
            Set-Content -LiteralPath $script:toastPath -Encoding Ascii -Value "throw 'toast failed'"

            {
                Set-StrictMode -Version 3.0
                $ErrorActionPreference = 'Stop'
                Show-AtlasTerminalFailure -ErrorRecord $script:launchError
            } | Should -Not -Throw
            Should -Invoke Write-AtlasLog -Times 1 -Exactly -ParameterFilter { $Level -eq 'Error' }
        }
    }

    It 'starts the terminal in a bracketed folder, not a sibling its name matches as a wildcard' {
        $workingDirectory = Join-Path $TestDrive 'name [x]'
        [void][IO.Directory]::CreateDirectory($workingDirectory)
        [void][IO.Directory]::CreateDirectory((Join-Path $TestDrive 'name x'))
        $startInfo = [Diagnostics.ProcessStartInfo]::new()
        $startInfo.FileName = Join-Path ([Environment]::SystemDirectory) 'cmd.exe'
        $startInfo.Arguments = '/d /c cd > where.txt'
        $startInfo.WorkingDirectory = $workingDirectory
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true

        $process = Start-AtlasTerminalProcess -StartInfo $startInfo
        try {
            $process.WaitForExit()
        }
        finally {
            $process.Dispose()
        }

        [IO.File]::ReadAllText((Join-Path $workingDirectory 'where.txt')).Trim() |
            Should -BeExactly ([IO.Path]::GetFullPath($workingDirectory))
        Test-Path -LiteralPath (Join-Path $TestDrive 'name x\where.txt') | Should -BeFalse
    }
}
