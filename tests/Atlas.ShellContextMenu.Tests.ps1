BeforeAll {
    $script:repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:executablesRoot = Join-Path $script:repositoryRoot 'playbook\Executables'
    $script:terminalHandler = Join-Path $script:executablesRoot `
        'AtlasModules\Scripts\Internal\Open-TerminalHere.ps1'
    $script:takeOwnershipHandler = Join-Path $script:executablesRoot `
        'AtlasModules\Scripts\Internal\Invoke-TakeOwnership.ps1'
    $script:shellSupport = Join-Path $script:executablesRoot `
        'AtlasModules\Scripts\Internal\Shell-ContextMenuSupport.ps1'
    $script:takeOwnershipPayload = Join-Path $script:executablesRoot `
        'AtlasModules\Scripts\Registry\TakeOwnership\add.reg'

    . $script:shellSupport

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
}

Describe 'Terminal context-menu payloads' {
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
            @{
                Name = 'Toolbox enabled'
                Path = Join-Path $root `
                    'AtlasModules\Toolbox\ConfigurationServices\ContextMenuTerminals\ContextMenuTerminals_1.reg'
                IncludesWindowsTerminal = $true
            }
            @{
                Name = 'Toolbox minimal'
                Path = Join-Path $root `
                    'AtlasModules\Toolbox\ConfigurationServices\ContextMenuTerminals\ContextMenuTerminals_2.reg'
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
            $command | Should -Match ' -File \\"%SystemRoot%\\\\AtlasModules\\\\Scripts\\\\Internal\\\\Open-TerminalHere\.ps1\\" '
            $command | Should -Match ' -Terminal (?:CommandPrompt|PowerShell|WindowsTerminal) -Verb (?:Open|RunAs) -Path \\"%V\\""$'
        }

        foreach ($terminal in $terminals) {
            foreach ($verb in @('Open', 'RunAs')) {
                @($commands | Where-Object { $_ -match " -Terminal $terminal -Verb $verb -Path " }).Count |
                    Should -Be 4
            }
        }
    }
}

Describe 'Take Ownership context-menu payload' {
    It 'routes files, directories, and drives through the internal handler' {
        $commands = @(Get-ContextMenuCommand -Path $script:takeOwnershipPayload -SelectionToken '%1')

        $commands.Count | Should -Be 6
        foreach ($command in $commands) {
            $command | Should -Match '^(?:@|"IsolatedCommand")="\\"%SystemRoot%\\\\System32\\\\WindowsPowerShell\\\\v1\.0\\\\powershell\.exe\\" '
            $command | Should -Match ' -File \\"%SystemRoot%\\\\AtlasModules\\\\Scripts\\\\Internal\\\\Invoke-TakeOwnership\.ps1\\" '
            $command | Should -Match ' -TargetType (?:File|Directory|Drive) -TargetPath \\"%1\\" -Pause"$'
        }

        foreach ($targetType in @('File', 'Directory', 'Drive')) {
            @($commands | Where-Object { $_ -match " -TargetType $targetType -TargetPath " }).Count |
                Should -Be 2
        }
    }
}

Describe 'Shell context-menu handlers' {
    It 'opens a command prompt with the selected path as its working directory' {
        $workingDirectory = Join-Path $TestDrive 'terminal & data'
        [void][IO.Directory]::CreateDirectory($workingDirectory)
        [AppDomain]::CurrentDomain.SetData('AtlasShellStartParameters', $null)
        Mock Start-Process {
            [AppDomain]::CurrentDomain.SetData('AtlasShellStartParameters', @{
                FilePath         = $FilePath
                ArgumentList     = $ArgumentList
                WorkingDirectory = $WorkingDirectory
                Verb             = $Verb
                PassThru         = $PassThru
            })
            return [pscustomobject]@{ Id = 101 }
        }

        try {
            & $script:terminalHandler -Terminal CommandPrompt -Verb Open -Path $workingDirectory

            Should -Invoke Start-Process -Times 1 -Exactly
            $start = [AppDomain]::CurrentDomain.GetData('AtlasShellStartParameters')
            $start.FilePath | Should -BeExactly (Join-Path ([Environment]::SystemDirectory) 'cmd.exe')
            $start.WorkingDirectory | Should -BeExactly ([IO.Path]::GetFullPath($workingDirectory))
            $start.Verb | Should -BeExactly 'Open'
            $start.ArgumentList | Should -BeNullOrEmpty
        }
        finally {
            [AppDomain]::CurrentDomain.SetData('AtlasShellStartParameters', $null)
        }
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

    It 'rejects relative paths and target-type mismatches before launch' {
        { & $script:terminalHandler -Terminal CommandPrompt -Verb Open -Path '.\relative' } |
            Should -Throw '*bounded absolute path*'
        { & $script:takeOwnershipHandler -TargetType File -TargetPath $TestDrive } |
            Should -Throw '*file does not exist*'
        { & $script:takeOwnershipHandler -TargetType Drive -TargetPath $TestDrive } |
            Should -Throw '*not an existing file-system root*'
    }
}

Describe 'Shell context-menu argument helpers' {
    It 'quotes <Name> using Windows argv rules' -TestCases @(
        @{ Name = 'an empty value'; Value = ''; Expected = '""' }
        @{ Name = 'a drive root'; Value = 'C:\'; Expected = '"C:\\"' }
        @{ Name = 'a UNC root'; Value = '\\server\share\'; Expected = '"\\server\share\\"' }
        @{
            Name = 'spaces and a trailing separator'
            Value = 'C:\folder with spaces\'
            Expected = '"C:\folder with spaces\\"'
        }
        @{
            Name = 'an embedded quote'
            Value = 'synthetic\value"with-quote\'
            Expected = '"synthetic\value\"with-quote\\"'
        }
    ) {
        ConvertTo-AtlasShellWindowsArgument -Value $Value | Should -BeExactly $Expected
    }

    It 'builds non-recursive and recursive native ownership arguments' {
        $file = Get-AtlasTakeOwnershipArgumentPlan `
            -TargetType File `
            -TargetPath 'C:\file.txt'
        $directory = Get-AtlasTakeOwnershipArgumentPlan `
            -TargetType Directory `
            -TargetPath 'C:\directory' `
            -YesChoice 'Y'
        $drive = Get-AtlasTakeOwnershipArgumentPlan `
            -TargetType Drive `
            -TargetPath 'C:\' `
            -YesChoice 'Y'

        $file.TakeOwnArguments | Should -Not -Contain '/r'
        $file.IcaclsArguments | Should -Contain '/l'
        foreach ($plan in @($directory, $drive)) {
            $plan.TakeOwnArguments | Should -Contain '/r'
            $plan.TakeOwnArguments | Should -Contain '/SKIPSL'
            $plan.IcaclsArguments | Should -Contain '/l'
        }
        $directory.IcaclsArguments | Should -Contain '/q'
        $drive.IcaclsArguments | Should -Not -Contain '/q'
    }

    It 'rejects a descendant junction without traversing it' {
        $root = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'ownership-tree')
        $target = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'junction-target')
        $junctionPath = Join-Path $root.FullName 'junction'
        [void](New-Item -ItemType Junction -Path $junctionPath -Target $target.FullName)

        try {
            { Assert-AtlasTakeOwnershipTree -RootPath $root.FullName } |
                Should -Throw '*descendant reparse point*'
        }
        finally {
            Remove-Item -LiteralPath $junctionPath -Force
        }
    }
}
