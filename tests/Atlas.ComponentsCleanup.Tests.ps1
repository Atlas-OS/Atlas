[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter',
    '',
    Justification = 'The components-phase harness stubs declare the parameter surface of the commands they shadow.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidOverwritingBuiltInCmdlets',
    '',
    Justification = 'The components-phase harness shadows registry and scheduled-task cmdlets only while executing the phase under test.'
)]
param()

BeforeAll {
    $script:atlasScriptsRoot = Join-Path -Path $PSScriptRoot `
        -ChildPath '..\playbook\Executables\AtlasModules\Scripts'
    $script:componentsPhase = Join-Path -Path $script:atlasScriptsRoot `
        -ChildPath 'Phases\Invoke-ComponentsPhase.ps1'
    $script:oneDriveUserCleanup = Join-Path -Path $script:atlasScriptsRoot `
        -ChildPath 'Internal\Remove-OneDriveCurrentUserData.ps1'
    $script:edgeUserCleanup = Join-Path -Path $script:atlasScriptsRoot `
        -ChildPath 'Internal\Remove-EdgeCurrentUserData.ps1'

    $tokens = $null
    $errors = $null
    $script:oneDriveAst = [Management.Automation.Language.Parser]::ParseFile(
        $script:oneDriveUserCleanup,
        [ref]$tokens,
        [ref]$errors
    )
    if (@($errors).Count -ne 0) {
        throw "The OneDrive exact-user cleanup script has parse errors: $($errors -join '; ')"
    }

    foreach ($functionName in @(
            'ConvertTo-AtlasOneDriveUserSid'
            'Resolve-AtlasOneDriveUserDirectory'
            'Remove-AtlasOneDriveUserEntry'
            'Remove-AtlasOneDriveUserTree'
        )) {
        $functionAst = @($script:oneDriveAst.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                        $node.Name -ceq $functionName
                }, $true))
        if ($functionAst.Count -ne 1) {
            throw "Expected one $functionName definition in the OneDrive cleanup script."
        }
        . ([scriptblock]::Create($functionAst[0].Extent.Text))
    }

    $tokens = $null
    $errors = $null
    $script:edgeAst = [Management.Automation.Language.Parser]::ParseFile(
        $script:edgeUserCleanup,
        [ref]$tokens,
        [ref]$errors
    )
    if (@($errors).Count -ne 0) {
        throw "The Edge exact-user cleanup script has parse errors: $($errors -join '; ')"
    }
    foreach ($functionName in @(
            'Get-AtlasEdgeExecutablePaths'
            'Remove-AtlasOrphanedEdgeAutoLaunch'
        )) {
        $functionAst = @($script:edgeAst.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                        $node.Name -ceq $functionName
                }, $true))
        if ($functionAst.Count -ne 1) {
            throw "Expected one $functionName definition in the Edge cleanup script."
        }
        . ([scriptblock]::Create($functionAst[0].Extent.Text))
    }

    # Execution doubles for the components phase. Functions shadow the real commands so
    # the phase script runs end to end without touching the machine.
    function Reset-PhaseRecording {
        $script:PhaseOptions = @()
        $script:PhaseContext = [pscustomobject]@{
            IsOobe             = $true
            InteractiveUserSid = 'S-1-5-21-1000-2000-3000-1001'
        }
        $script:AsUserExitCode = 0
        $script:AsUserCalls = [Collections.Generic.List[pscustomobject]]::new()
        $script:HiddenProcessCalls = [Collections.Generic.List[pscustomobject]]::new()
        $script:RegisteredTasks = [Collections.Generic.List[pscustomobject]]::new()
        $script:LogCalls = [Collections.Generic.List[pscustomobject]]::new()
        $script:CbsInstallCalls = [Collections.Generic.List[object]]::new()
        $script:RegistryWrites = [Collections.Generic.List[pscustomobject]]::new()
        $script:OneDriveRemovalError = $null
    }

    function Assert-AtlasPrivilege {
        param([switch]$TrustedInstaller)
    }
    function Import-Module {
        param($Name, [switch]$Force, $ErrorAction)
    }
    function Test-AtlasOption {
        param($Name)
        return $script:PhaseOptions -contains $Name
    }
    function Get-AtlasContext {
        return $script:PhaseContext
    }
    function ConvertTo-AtlasWindowsArgumentString {
        param($ArgumentList)
        return (@($ArgumentList) -join ' ')
    }
    function Invoke-AtlasHiddenProcess {
        param($FilePath, $ArgumentList, [switch]$Wait)
        $script:HiddenProcessCalls.Add([pscustomobject]@{
                FilePath     = $FilePath
                ArgumentList = @($ArgumentList)
            })
    }
    function Invoke-AtlasAsUser {
        param($FilePath, $Arguments)
        $script:AsUserCalls.Add([pscustomobject]@{
                FilePath  = $FilePath
                Arguments = $Arguments
            })
        return $script:AsUserExitCode
    }
    function Remove-AtlasOneDrive {
        if ($null -ne $script:OneDriveRemovalError) {
            throw $script:OneDriveRemovalError
        }
    }
    function Write-AtlasLog {
        param($Message, $Level = 'Info', $ErrorRecord)
        $script:LogCalls.Add([pscustomobject]@{
                Level   = $Level
                Message = $Message
            })
    }
    function Stop-AtlasService {
        param($Name)
    }
    function Set-AtlasServiceStartup {
        param($Name, $StartupType, [switch]$AllowMissing)
    }
    function Remove-AtlasScheduledTask {
        param($Path, [switch]$IgnoreMissing)
    }
    function Install-AtlasCbsPackage {
        param($Packages, [switch]$NonInteractive)
        $script:CbsInstallCalls.Add(@($Packages))
    }
    function Uninstall-AtlasCbsPackage {
        param($Packages)
    }
    function New-ScheduledTaskSettingsSet {
        return 'settings'
    }
    function New-ScheduledTaskTrigger {
        return 'trigger'
    }
    function New-ScheduledTaskPrincipal {
        param($UserId, $LogonType, $RunLevel)
        return [pscustomobject]@{ UserId = $UserId; RunLevel = $RunLevel }
    }
    function New-ScheduledTaskAction {
        param($Execute, $Argument)
        return [pscustomobject]@{ Execute = $Execute; Argument = $Argument }
    }
    function Register-ScheduledTask {
        param($TaskName, $Settings, $Trigger, $Principal, $Force, $Action)
        $script:RegisteredTasks.Add([pscustomobject]@{
                TaskName  = $TaskName
                Principal = $Principal
                Action    = $Action
            })
        return $null
    }
    # Registry doubles: the phase writes only HKLM keys, which must never be touched.
    function Test-Path {
        param($LiteralPath, $Path, $PathType)
        return $true
    }
    function New-Item {
        param($Path, $ItemType, [switch]$Force)
        $script:RegistryWrites.Add([pscustomobject]@{
                Operation = 'NewItem'
                Path      = $Path
            })
        return $null
    }
    function Set-ItemProperty {
        param($LiteralPath, $Path, $Name, $Value, $Type, [switch]$Force)
        $script:RegistryWrites.Add([pscustomobject]@{
                Operation = 'SetValue'
                Path      = if ($LiteralPath) { $LiteralPath } else { $Path }
                Name      = $Name
                Value     = $Value
            })
    }
    function Remove-ItemProperty {
        param($LiteralPath, $Path, $Name, [switch]$Force, $ErrorAction)
        $script:RegistryWrites.Add([pscustomobject]@{
                Operation = 'RemoveValue'
                Path      = if ($LiteralPath) { $LiteralPath } else { $Path }
                Name      = $Name
            })
    }

    function Invoke-ComponentsPhaseUnderTest {
        # Dot-source so the recording doubles observe this test file's script scope.
        . $script:componentsPhase
    }
}

AfterAll {
    foreach ($shadow in @(
            'Assert-AtlasPrivilege', 'Import-Module', 'Test-AtlasOption', 'Get-AtlasContext'
            'ConvertTo-AtlasWindowsArgumentString', 'Invoke-AtlasHiddenProcess'
            'Invoke-AtlasAsUser', 'Remove-AtlasOneDrive', 'Write-AtlasLog'
            'Stop-AtlasService', 'Set-AtlasServiceStartup', 'Remove-AtlasScheduledTask'
            'Install-AtlasCbsPackage', 'Uninstall-AtlasCbsPackage'
            'New-ScheduledTaskSettingsSet', 'New-ScheduledTaskTrigger'
            'New-ScheduledTaskPrincipal', 'New-ScheduledTaskAction', 'Register-ScheduledTask'
            'Test-Path', 'New-Item', 'Set-ItemProperty', 'Remove-ItemProperty'
            'Get-AtlasEdgeExecutablePaths', 'Remove-AtlasOrphanedEdgeAutoLaunch'
        )) {
        Microsoft.PowerShell.Management\Remove-Item -LiteralPath "Function:\$shadow" `
            -ErrorAction SilentlyContinue
    }
}

Describe 'Components phase deferred and exact-user cleanup behavior' {
    BeforeEach {
        Reset-PhaseRecording
    }

    It 'parses in Windows PowerShell syntax' {
        $tokens = $null
        $errors = $null
        [Management.Automation.Language.Parser]::ParseFile(
            $script:componentsPhase,
            [ref]$tokens,
            [ref]$errors
        ) | Out-Null

        @($errors) | Should -BeNullOrEmpty
    }

    It 'defers MDCoreSvc disable to a SYSTEM task that records state before self-deleting' {
        $script:PhaseOptions = @('defender-disable')

        Invoke-ComponentsPhaseUnderTest

        @($script:RegisteredTasks).Count | Should -Be 1
        $task = $script:RegisteredTasks[0]
        $task.Principal.UserId | Should -BeExactly 'SYSTEM'
        $task.Action.Execute | Should -BeExactly 'cmd'

        $argument = [string]$task.Action.Argument
        $regAddIndex = $argument.IndexOf(
            'reg add "HKLM\SYSTEM\CurrentControlSet\Services\MDCoreSvc"',
            [StringComparison]::Ordinal
        )
        $deleteIndex = $argument.IndexOf(
            "schtasks /delete /tn `"$($task.TaskName)`"",
            [StringComparison]::Ordinal
        )
        $regAddIndex | Should -BeGreaterThan -1
        $deleteIndex | Should -BeGreaterThan $regAddIndex
        $argument.Substring($regAddIndex, $deleteIndex - $regAddIndex) | Should -Match '&&'
    }

    It 'dispatches OneDrive profile cleanup through the exact-user launcher' {
        $script:PhaseContext.IsOobe = $false

        Invoke-ComponentsPhaseUnderTest

        $oneDriveCalls = @($script:AsUserCalls | Where-Object {
                $_.Arguments -like '*Remove-OneDriveCurrentUserData.ps1*'
            })
        $oneDriveCalls.Count | Should -Be 1
        $oneDriveCalls[0].FilePath | Should -Match 'powershell\.exe$'
        $oneDriveCalls[0].Arguments | Should -Match `
        ('-ExpectedUserSid ' + [regex]::Escape($script:PhaseContext.InteractiveUserSid))
    }

    It 'warns and continues when the exact-user OneDrive cleanup exits nonzero' {
        $script:PhaseContext.IsOobe = $false
        $script:AsUserExitCode = 23

        { Invoke-ComponentsPhaseUnderTest } | Should -Not -Throw

        $warnings = @($script:LogCalls | Where-Object { $_.Level -eq 'Warning' })
        @($warnings | Where-Object {
                $_.Message -like '*Exact-user OneDrive leftover cleanup exited with code 23*'
            }).Count | Should -Be 1
    }

    It 'requires the install-state user SID for non-OOBE OneDrive cleanup' {
        $script:PhaseContext.IsOobe = $false
        $script:PhaseContext.InteractiveUserSid = ''

        { Invoke-ComponentsPhaseUnderTest } | Should -Throw '*install-state user SID*'
    }

    It 'skips the exact-user cleanup process entirely during OOBE' {
        Invoke-ComponentsPhaseUnderTest

        @($script:AsUserCalls).Count | Should -Be 0
    }

    It 'rethrows unconfirmed OneDrive process containment instead of continuing' {
        $containmentError = New-Object Exception 'vendor uninstall failed'
        $containmentError.Data['AtlasProcessMayStillBeRunning'] = $true
        $script:OneDriveRemovalError = $containmentError

        { Invoke-ComponentsPhaseUnderTest } | Should -Throw '*vendor uninstall failed*'
    }

    It 'logs a warning and completes when confirmed-contained OneDrive removal fails' {
        $script:OneDriveRemovalError = New-Object Exception 'ordinary removal failure'

        { Invoke-ComponentsPhaseUnderTest } | Should -Not -Throw

        @($script:LogCalls | Where-Object {
                $_.Level -eq 'Warning' -and
                $_.Message -like '*Removing OneDrive failed: ordinary removal failure*'
            }).Count | Should -Be 1
    }
}

Describe 'OneDrive exact-user cleanup boundary' {
    It 'refuses to run for a token that does not match the install-state SID' {
        # A structurally valid account SID that cannot match the current test token.
        $foreignSid = 'S-1-5-21-1-2-3-500'
        $savedModulePath = $env:PSModulePath
        try {
            { & $script:oneDriveUserCleanup -ExpectedUserSid $foreignSid } |
                Should -Throw '*does not match install-state SID*'
        }
        finally {
            $env:PSModulePath = $savedModulePath
        }
    }

    It 'canonicalizes account SIDs and rejects invalid or non-account SIDs' {
        ConvertTo-AtlasOneDriveUserSid -Sid 'S-1-5-21-1000-2000-3000-1001' |
            Should -BeExactly 'S-1-5-21-1000-2000-3000-1001'
        { ConvertTo-AtlasOneDriveUserSid -Sid 'not-a-sid' } |
            Should -Throw '*is invalid*'
        { ConvertTo-AtlasOneDriveUserSid -Sid 'S-1-5-18' } |
            Should -Throw '*not a local or domain account SID*'
    }

    It 'resolves cleanup paths only inside an existing normal root' {
        $root = Join-Path $TestDrive 'ProfileRoot'
        [void][IO.Directory]::CreateDirectory($root)

        Resolve-AtlasOneDriveUserDirectory -Root $root -ChildPath 'Microsoft\OneDrive' |
            Should -BeExactly ([IO.Path]::Combine([IO.Path]::GetFullPath($root), 'Microsoft\OneDrive'))
        { Resolve-AtlasOneDriveUserDirectory -Root ' ' -ChildPath 'x' } |
            Should -Throw '*is unavailable*'
        { Resolve-AtlasOneDriveUserDirectory -Root (Join-Path $TestDrive 'Missing') -ChildPath 'x' } |
            Should -Throw '*is unavailable*'
        { Resolve-AtlasOneDriveUserDirectory -Root $root -ChildPath '..\Escape' } |
            Should -Throw '*escaped exact-user root*'
    }

    It 'rejects a reparse-point root and reparse-point path components' {
        $outside = Join-Path $TestDrive 'OutsideRoot'
        $linkRoot = Join-Path $TestDrive 'LinkRoot'
        [void][IO.Directory]::CreateDirectory($outside)
        try {
            Microsoft.PowerShell.Management\New-Item -Path $linkRoot -ItemType Junction `
                -Target $outside -ErrorAction Stop | Out-Null
        }
        catch {
            Set-ItResult -Skipped -Because "Directory junctions are unavailable: $($_.Exception.Message)"
            return
        }

        { Resolve-AtlasOneDriveUserDirectory -Root $linkRoot -ChildPath 'x' } |
            Should -Throw '*is a reparse point*'

        $normalRoot = Join-Path $TestDrive 'NormalRoot'
        $linkChild = Join-Path $normalRoot 'Linked'
        [void][IO.Directory]::CreateDirectory($normalRoot)
        Microsoft.PowerShell.Management\New-Item -Path $linkChild -ItemType Junction `
            -Target $outside | Out-Null
        { Resolve-AtlasOneDriveUserDirectory -Root $normalRoot -ChildPath 'Linked\Deeper' } |
            Should -Throw '*is a reparse point*'
    }

    It 'deletes a junction inside the tree without traversing into its target' {
        $tree = Join-Path $TestDrive 'CacheTree'
        $outside = Join-Path $TestDrive 'JunctionTarget'
        [void][IO.Directory]::CreateDirectory((Join-Path $tree 'Nested'))
        [void][IO.Directory]::CreateDirectory($outside)
        $sentinel = Join-Path $outside 'sentinel.txt'
        [IO.File]::WriteAllText($sentinel, 'keep')
        $readOnly = Join-Path $tree 'Nested\readonly.dat'
        [IO.File]::WriteAllText($readOnly, 'x')
        [IO.File]::SetAttributes($readOnly, [IO.FileAttributes]::ReadOnly)
        try {
            Microsoft.PowerShell.Management\New-Item -Path (Join-Path $tree 'Linked') `
                -ItemType Junction -Target $outside -ErrorAction Stop | Out-Null
        }
        catch {
            Set-ItResult -Skipped -Because "Directory junctions are unavailable: $($_.Exception.Message)"
            return
        }

        Remove-AtlasOneDriveUserTree -Path $tree

        [IO.Directory]::Exists($tree) | Should -BeFalse
        [IO.File]::Exists($sentinel) | Should -BeTrue
    }

    It 'treats a missing cleanup tree as already removed' {
        { Remove-AtlasOneDriveUserTree -Path (Join-Path $TestDrive 'NeverExisted') } |
            Should -Not -Throw
    }

    It 'uses only the current-user registry provider and never enumerates HKEY_USERS' {
        $registryLiterals = @($script:oneDriveAst.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.StringConstantExpressionAst] -and
                        $node.Value -match '^(HK|Registry::)'
                }, $true) | ForEach-Object { $_.Value })

        @($registryLiterals).Count | Should -BeGreaterThan 0
        foreach ($literal in $registryLiterals) {
            $literal | Should -Match '^HKCU:'
        }
    }
}

Describe 'Edge exact-user startup cleanup boundary' {
    BeforeEach {
        $script:edgeRegistryRoot = 'Software\AtlasRewriteTest\EdgeCleanup'
        $script:edgeRunSubKey = "$script:edgeRegistryRoot\Run"
        $script:edgeApprovedSubKey = "$script:edgeRegistryRoot\StartupApproved"
        $script:missingEdgePath = Join-Path $TestDrive `
            'Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
        $runKey = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey(
            $script:edgeRunSubKey
        )
        $approvedKey = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey(
            $script:edgeApprovedSubKey
        )
        $script:edgeRunKey = $runKey
        $script:edgeApprovedKey = $approvedKey
    }

    AfterEach {
        if ($null -ne $script:edgeRunKey) {
            $script:edgeRunKey.Dispose()
        }
        if ($null -ne $script:edgeApprovedKey) {
            $script:edgeApprovedKey.Dispose()
        }
        [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree(
            $script:edgeRegistryRoot,
            $false
        )
    }

    It 'removes only a canonical orphaned Edge auto-launch registration' {
        $edgeValueName = 'MicrosoftEdgeAutoLaunch_3C32DD8DCCCF754B3FFB51F344CC4011'
        $edgeCommand = '"{0}" --no-startup-window --win-session-start' -f `
            $script:missingEdgePath
        $script:edgeRunKey.SetValue(
            $edgeValueName,
            $edgeCommand,
            [Microsoft.Win32.RegistryValueKind]::String
        )
        $script:edgeApprovedKey.SetValue(
            $edgeValueName,
            [byte[]](2, 0, 0, 0),
            [Microsoft.Win32.RegistryValueKind]::Binary
        )

        $removed = @(Remove-AtlasOrphanedEdgeAutoLaunch `
                -RunSubKey $script:edgeRunSubKey `
                -StartupApprovedSubKeys @($script:edgeApprovedSubKey) `
                -KnownEdgeExecutablePaths @($script:missingEdgePath))

        $removed | Should -Be @($edgeValueName)
        $script:edgeRunKey.GetValueNames() | Should -Not -Contain $edgeValueName
        $script:edgeApprovedKey.GetValueNames() | Should -Not -Contain $edgeValueName
    }

    It 'preserves unrelated, malformed, and still-installed startup entries' {
        $orphanedEdgeName = 'MicrosoftEdgeAutoLaunch_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        $installedEdgeName = 'MicrosoftEdgeAutoLaunch_BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
        $malformedEdgeName = 'MicrosoftEdgeAutoLaunch_CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'
        $unrelatedName = 'MyStartupItem'
        $installedEdgePath = Join-Path $TestDrive `
            'Installed\Microsoft\Edge\Application\msedge.exe'
        $null = [IO.Directory]::CreateDirectory(
            [IO.Path]::GetDirectoryName($installedEdgePath)
        )
        [IO.File]::WriteAllText($installedEdgePath, 'not-an-executable')

        $script:edgeRunKey.SetValue(
            $orphanedEdgeName,
            '"C:\Other\msedge.exe" --no-startup-window --win-session-start'
        )
        $script:edgeRunKey.SetValue(
            $installedEdgeName,
            ('"{0}" --no-startup-window --win-session-start' -f $installedEdgePath)
        )
        $script:edgeRunKey.SetValue(
            $malformedEdgeName,
            ('"{0}" --win-session-start' -f $script:missingEdgePath)
        )
        $script:edgeRunKey.SetValue($unrelatedName, '"C:\Tools\tool.exe"')

        $removed = @(Remove-AtlasOrphanedEdgeAutoLaunch `
                -RunSubKey $script:edgeRunSubKey `
                -StartupApprovedSubKeys @($script:edgeApprovedSubKey) `
                -KnownEdgeExecutablePaths @(
                    $script:missingEdgePath
                    $installedEdgePath
                ))

        $removed | Should -BeNullOrEmpty
        $script:edgeRunKey.GetValueNames() | Should -Contain $orphanedEdgeName
        $script:edgeRunKey.GetValueNames() | Should -Contain $installedEdgeName
        $script:edgeRunKey.GetValueNames() | Should -Contain $malformedEdgeName
        $script:edgeRunKey.GetValueNames() | Should -Contain $unrelatedName
    }

    It 'removes an approved-only Edge auto-launch orphan' {
        $edgeValueName = 'MicrosoftEdgeAutoLaunch_DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD'
        $script:edgeApprovedKey.SetValue(
            $edgeValueName,
            [byte[]](2, 0, 0, 0),
            [Microsoft.Win32.RegistryValueKind]::Binary
        )

        $removed = @(Remove-AtlasOrphanedEdgeAutoLaunch `
                -RunSubKey $script:edgeRunSubKey `
                -StartupApprovedSubKeys @($script:edgeApprovedSubKey) `
                -KnownEdgeExecutablePaths @($script:missingEdgePath))

        $removed | Should -Be @($edgeValueName)
        $script:edgeApprovedKey.GetValueNames() | Should -Not -Contain $edgeValueName
    }

    It 'preserves an approved record while its startup command still exists' {
        $edgeValueName = 'MicrosoftEdgeAutoLaunch_EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE'
        $script:edgeRunKey.SetValue(
            $edgeValueName,
            '"C:\Custom\msedge.exe" --no-startup-window --win-session-start'
        )
        $script:edgeApprovedKey.SetValue(
            $edgeValueName,
            [byte[]](2, 0, 0, 0),
            [Microsoft.Win32.RegistryValueKind]::Binary
        )

        $removed = @(Remove-AtlasOrphanedEdgeAutoLaunch `
                -RunSubKey $script:edgeRunSubKey `
                -StartupApprovedSubKeys @($script:edgeApprovedSubKey) `
                -KnownEdgeExecutablePaths @($script:missingEdgePath))

        $removed | Should -BeNullOrEmpty
        $script:edgeApprovedKey.GetValueNames() | Should -Contain $edgeValueName
    }
}
