BeforeAll {
    $script:ModulesRoot = Join-Path -Path $PSScriptRoot `
        -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path -Path $script:ModulesRoot `
            -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    $script:CoreModule = Get-Module -Name Atlas.Core
    $script:WindowsPath = [Environment]::GetFolderPath('Windows')
    $script:PowerShellPath = [IO.Path]::Combine(
        $script:WindowsPath,
        'System32',
        'WindowsPowerShell',
        'v1.0',
        'powershell.exe'
    )

    & $script:CoreModule { Initialize-AtlasRunAsUserType }

    function New-TestUserContext {
        param(
            [string]$Sid = 'S-1-5-21-111-222-333-1001',
            [object]$SessionId = 7,
            [bool]$IsOobe = $false
        )

        [pscustomobject]@{
            WinDir                      = $script:WindowsPath
            IsOobe                     = $IsOobe
            InteractiveUserSid          = $Sid
            InteractiveUserSessionId    = $SessionId
        }
    }

    function Invoke-TestUserProcess {
        param(
            $Context = (New-TestUserContext),
            [int]$ExitCode = 0,
            [Collections.Generic.List[object]]$Calls =
                (New-Object Collections.Generic.List[object]),
            [string]$FilePath = $script:PowerShellPath,
            [string]$Arguments = '-NoLogo -File "C:\Atlas Files\setup.ps1" "one two"'
        )

        & $script:CoreModule {
            param($Context, $ExitCode, $Calls, $FilePath, $Arguments)
            $testContext = $Context
            $testExitCode = $ExitCode
            $testCalls = $Calls
            $contextReader = { $testContext }.GetNewClosure()
            $launcher = {
                param($ApplicationPath, $CommandLine, $WorkingDirectory,
                    $TimeoutMilliseconds, $UserSid, $UserSessionId)
                $testCalls.Add([pscustomobject]@{
                        ApplicationPath     = $ApplicationPath
                        CommandLine         = $CommandLine
                        WorkingDirectory    = $WorkingDirectory
                        TimeoutMilliseconds = $TimeoutMilliseconds
                        UserSid             = $UserSid
                        UserSessionId       = $UserSessionId
                    })
                return $testExitCode
            }.GetNewClosure()

            Invoke-AtlasBoundUserProcess -FilePath $FilePath -Arguments $Arguments `
                -ContextReader $contextReader -ProcessLauncher $launcher
        } $Context $ExitCode $Calls $FilePath $Arguments
    }
}

Describe 'Atlas installing-user process boundary' {
    It 'keeps the exported caller-facing command surface' {
        $command = Get-Command -Name Invoke-AtlasAsUser

        $command.Parameters.Keys | Should -Contain 'FilePath'
        $command.Parameters.Keys | Should -Contain 'Arguments'
        $command.Parameters.Keys | Should -Contain 'WorkingDirectory'
        $command.Parameters.Keys | Should -Contain 'Wait'
        $command.Parameters.Keys | Should -Contain 'TimeoutSeconds'
        $command.Parameters.Keys | Should -Not -Contain 'Elevated'
    }

    It 'passes the captured SID and session to one exact System32 PowerShell launch' {
        $calls = New-Object Collections.Generic.List[object]

        $result = Invoke-TestUserProcess -Calls $calls -ExitCode 37

        $result | Should -Be 37
        $calls.Count | Should -Be 1
        $calls[0].ApplicationPath | Should -BeExactly $script:PowerShellPath
        $calls[0].UserSid | Should -BeExactly 'S-1-5-21-111-222-333-1001'
        $calls[0].UserSessionId | Should -Be 7
        $calls[0].TimeoutMilliseconds | Should -Be 900000
    }

    It 'preserves the serialized child arguments in the Windows command line' {
        $calls = New-Object Collections.Generic.List[object]
        $arguments = '-NoLogo -File "C:\Atlas Files\setup.ps1" "one two"'

        Invoke-TestUserProcess -Calls $calls -Arguments $arguments | Out-Null

        $calls[0].CommandLine | Should -BeExactly `
            ('"{0}" {1}' -f $script:PowerShellPath, $arguments)
    }

    It 'returns a nonzero child exit code unchanged' {
        Invoke-TestUserProcess -ExitCode 23 | Should -Be 23
    }

    It 'skips the launch during OOBE' {
        $calls = New-Object Collections.Generic.List[object]
        $context = New-TestUserContext -Sid '' -SessionId $null -IsOobe $true

        Invoke-TestUserProcess -Context $context -Calls $calls | Should -Be 0

        $calls.Count | Should -Be 0
    }

    It 'rejects missing or invalid captured identity before launch' -TestCases @(
        @{ Sid = 'S-1-5-18'; Session = 7 }
        @{ Sid = 'S-1-5-21-111-222-333-1001'; Session = 0 }
        @{ Sid = 'S-1-5-21-111-222-333-1001'; Session = '7' }
    ) {
        param($Sid, $Session)
        $calls = New-Object Collections.Generic.List[object]
        $context = New-TestUserContext -Sid $Sid -SessionId $Session

        { Invoke-TestUserProcess -Context $context -Calls $calls } | Should -Throw
        $calls.Count | Should -Be 0
    }

    It 'rejects any executable other than inbox System32 Windows PowerShell' {
        $calls = New-Object Collections.Generic.List[object]

        {
            Invoke-TestUserProcess -Calls $calls `
                -FilePath (Join-Path -Path $script:WindowsPath -ChildPath 'explorer.exe')
        } | Should -Throw -ExpectedMessage '*inbox Windows PowerShell*'
        $calls.Count | Should -Be 0
    }

    It 'accepts matching token evidence and rejects SID or session changes' {
        {
            [Atlas.UserProcess]::ValidateIdentity(
                'S-1-5-21-111-222-333-1001', 7,
                'S-1-5-21-111-222-333-1001', 7, 1)
        } | Should -Not -Throw

        {
            [Atlas.UserProcess]::ValidateIdentity(
                'S-1-5-21-111-222-333-1001', 7,
                'S-1-5-21-111-222-333-1002', 7, 1)
        } | Should -Throw

        {
            [Atlas.UserProcess]::ValidateIdentity(
                'S-1-5-21-111-222-333-1001', 7,
                'S-1-5-21-111-222-333-1001', 8, 1)
        } | Should -Throw
    }
}
