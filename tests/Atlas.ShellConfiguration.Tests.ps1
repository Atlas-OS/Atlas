[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidGlobalVars',
    '',
    Justification = 'Extracted new-user functions resolve their script-level state dynamically, so fixtures must be staged as global variables.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter',
    '',
    Justification = 'AST helper parameters are consumed inside FindAll predicates and process doubles declare the surface of the commands they shadow.'
)]
param()

BeforeAll {
    function Import-FunctionUnderTest {
        param(
            [Parameter(Mandatory = $true)][string]$Path,
            [Parameter(Mandatory = $true)][string]$Name
        )

        $tokens = $null
        $errors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile(
            $Path, [ref]$tokens, [ref]$errors
        )
        @($errors).Count | Should -Be 0
        $definition = $ast.Find({
                param($node)
                $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -eq $Name
            }, $true)
        $definition | Should -Not -BeNullOrEmpty
        Set-Item -Path "Function:\global:$Name" -Value $definition.Body.GetScriptBlock()
    }

    $script:taskbarScript = Resolve-Path (Join-Path $PSScriptRoot `
            '..\playbook\Executables\AtlasModules\Scripts\Internal\Set-TaskbarPins.ps1')
    $script:startScript = Resolve-Path (Join-Path $PSScriptRoot `
            '..\playbook\Executables\AtlasModules\Scripts\Internal\Set-StartLayout.ps1')
    $script:newUserScript = Resolve-Path (Join-Path $PSScriptRoot `
            '..\playbook\Executables\AtlasModules\Scripts\Initialize-NewUser.ps1')
    Import-FunctionUnderTest -Path $script:taskbarScript -Name Resolve-AtlasTaskbarBrowser
    Import-FunctionUnderTest -Path $script:taskbarScript -Name Invoke-AtlasTaskbarRegistryWrite
    Import-FunctionUnderTest -Path $script:startScript -Name Test-AtlasStartPinPolicySupported
    Import-FunctionUnderTest -Path $script:newUserScript -Name Get-SetupMarker
    Import-FunctionUnderTest -Path $script:newUserScript -Name Set-SetupMarker
    Import-FunctionUnderTest -Path $script:newUserScript -Name Invoke-AtlasDesktopCommand
    Import-FunctionUnderTest -Path $script:newUserScript -Name Invoke-CurrentSessionExplorerRefresh

    $tokens = $null
    $errors = $null
    $script:newUserAst = [Management.Automation.Language.Parser]::ParseFile(
        $script:newUserScript, [ref]$tokens, [ref]$errors
    )
    @($errors).Count | Should -Be 0
    $tokens = $null
    $errors = $null
    $script:startAst = [Management.Automation.Language.Parser]::ParseFile(
        $script:startScript, [ref]$tokens, [ref]$errors
    )
    @($errors).Count | Should -Be 0

    function Find-CommandAst {
        param(
            [Parameter(Mandatory = $true)]$Ast,
            [Parameter(Mandatory = $true)][string]$Name
        )

        @($Ast.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.CommandAst] -and
                    $node.GetCommandName() -eq $Name
                }, $true))
    }

    function Find-StringConstant {
        param(
            [Parameter(Mandatory = $true)]$Ast,
            [Parameter(Mandatory = $true)][string]$Value
        )

        @($Ast.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.StringConstantExpressionAst] -and
                    $node.Value -eq $Value
                }, $true))
    }

    function Get-AncestorIfCondition {
        param([Parameter(Mandatory = $true)]$Ast)

        for ($node = $Ast.Parent; $null -ne $node; $node = $node.Parent) {
            if ($node -is [Management.Automation.Language.IfStatementAst]) {
                return $node.Clauses[0].Item1.Extent.Text.Trim()
            }
        }
        return $null
    }
}

AfterAll {
    Remove-Item Function:\Resolve-AtlasTaskbarBrowser -ErrorAction SilentlyContinue
    Remove-Item Function:\Invoke-AtlasTaskbarRegistryWrite -ErrorAction SilentlyContinue
    Remove-Item Function:\Test-AtlasStartPinPolicySupported -ErrorAction SilentlyContinue
    Remove-Item Function:\Get-SetupMarker -ErrorAction SilentlyContinue
    Remove-Item Function:\Set-SetupMarker -ErrorAction SilentlyContinue
    Remove-Item Function:\Invoke-AtlasDesktopCommand -ErrorAction SilentlyContinue
    Remove-Item Function:\Invoke-CurrentSessionExplorerRefresh -ErrorAction SilentlyContinue
}

Describe 'Taskbar tweak install resilience' {
    It 'keeps live Taskband seed writes best-effort' {
        $definitionPath = Join-Path $PSScriptRoot `
            '..\playbook\Executables\AtlasModules\Scripts\Tweaks\qol\taskbar\config-pins.psd1'
        $definition = Import-PowerShellDataFile -LiteralPath $definitionPath

        @($definition.Registry).Count | Should -BeGreaterThan 0
        foreach ($entry in @($definition.Registry)) {
            $entry.Path | Should -Match '(?i)\\Explorer\\Taskband(?:\\|$)'
            $entry.IgnoreErrors | Should -BeTrue
        }
    }
}

Describe 'Taskbar pin fallback' {
    BeforeEach {
        $script:shortcutTable = @{
            'Selected'       = @{ Path = 'C:\Selected\browser.exe' }
            'Microsoft Edge' = @{ Path = 'C:\Edge\msedge.exe' }
            'File Explorer'  = @{ Path = 'C:\Windows\explorer.exe' }
        }
    }

    It 'keeps an installed selected browser' {
        Mock Test-Path { $LiteralPath -eq 'C:\Selected\browser.exe' }

        Resolve-AtlasTaskbarBrowser -RequestedBrowser Selected `
            -ShortcutTable $script:shortcutTable -EdgeName 'Microsoft Edge' `
            -ExplorerName 'File Explorer' | Should -BeExactly 'Selected'
    }

    It 'warns and falls back to Edge when the selected browser is missing' {
        Mock Test-Path { $LiteralPath -eq 'C:\Edge\msedge.exe' }

        $warnings = @()
        $result = Resolve-AtlasTaskbarBrowser -RequestedBrowser Selected `
            -ShortcutTable $script:shortcutTable -EdgeName 'Microsoft Edge' `
            -ExplorerName 'File Explorer' -WarningVariable warnings

        $result | Should -BeExactly 'Microsoft Edge'
        @($warnings).Count | Should -Be 1
        [string]$warnings[0] | Should -Match 'Selected.*not installed'
    }

    It 'warns and falls back to File Explorer when no browser is installed' {
        Mock Test-Path { $false }

        $warnings = @()
        $result = Resolve-AtlasTaskbarBrowser -RequestedBrowser Selected `
            -ShortcutTable $script:shortcutTable -EdgeName 'Microsoft Edge' `
            -ExplorerName 'File Explorer' -WarningVariable warnings

        $result | Should -BeExactly 'File Explorer'
        @($warnings).Count | Should -Be 2
    }
}

Describe 'Taskbar registry writes' {
    It 'turns a native reg.exe failure into a terminating error' {
        $fakeReg = Join-Path $TestDrive 'reg-failure.cmd'
        Set-Content -LiteralPath $fakeReg -Value '@exit /b 5'

        {
            Invoke-AtlasTaskbarRegistryWrite -RegExe $fakeReg -RegistryKey 'HKCU\Test' `
                -Name Favorites -Data '00'
        } | Should -Throw '*exit code 5*'
    }

    It 'uses System32 reg.exe and guarantees temporary-directory cleanup' {
        $source = Get-Content -LiteralPath $script:taskbarScript -Raw
        $source | Should -Match "ChildPath 'System32\\reg\.exe'"
        $source | Should -Match 'finally\s*\{[\s\S]*Remove-Item -LiteralPath \$tmp\.FullName'
    }

    It 'stamps the canonical Explorer AppUserModelID onto the generated pin' {
        $source = Get-Content -LiteralPath $script:taskbarScript -Raw

        $source | Should -Match `
            "-AppUserModelId 'Microsoft\.Windows\.Explorer'"
    }
}

Describe 'Installing-user setup marker state' {
    BeforeEach {
        $global:markerSubKey = 'Software\AtlasRewriteTest\UserSetup'
        $global:markerPath = "HKCU:\$global:markerSubKey"
        $global:sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    }

    AfterEach {
        Remove-Item -Path 'HKCU:\Software\AtlasRewriteTest' -Recurse -Force `
            -ErrorAction SilentlyContinue
        Remove-Variable -Name markerSubKey, markerPath, sid -Scope Global `
            -ErrorAction SilentlyContinue
    }

    It 'reports an unconfigured account as stage zero' {
        Get-SetupMarker | Should -Be 0
    }

    It 'round-trips the per-SID setup stages' {
        Set-SetupMarker -Value 1
        Get-SetupMarker | Should -Be 1

        Set-SetupMarker -Value 2
        Get-SetupMarker | Should -Be 2
    }

    It 'accepts only the two defined setup stages' {
        { Set-SetupMarker -Value 3 } | Should -Throw
        { Set-SetupMarker -Value 0 } | Should -Throw
    }

    It 'ignores markers of the wrong type or belonging to another SID' {
        $null = New-Item -Path $global:markerPath -Force
        Set-ItemProperty -Path $global:markerPath -Name $global:sid -Value '2' `
            -Type String -Force
        Get-SetupMarker | Should -Be 0

        Remove-ItemProperty -Path $global:markerPath -Name $global:sid -Force
        Set-ItemProperty -Path $global:markerPath -Name 'S-1-5-21-1-2-3-1001' -Value 2 `
            -Type DWord -Force
        Get-SetupMarker | Should -Be 0
    }
}

Describe 'Installing-user desktop command and Explorer refresh' {
    BeforeEach {
        $global:atlasDesktop = Join-Path $TestDrive 'AtlasDesktop'
        $null = New-Item -Path $global:atlasDesktop -ItemType Directory -Force
    }

    AfterEach {
        Remove-Variable -Name atlasDesktop -Scope Global -ErrorAction SilentlyContinue
    }

    It 'runs an Atlas desktop command silently and accepts a zero exit code' {
        $probe = Join-Path $global:atlasDesktop 'probe.cmd'
        $argumentLog = Join-Path $TestDrive 'desktop-command-args.txt'
        Set-Content -LiteralPath $probe -Value "@echo %*> `"$argumentLog`"`r`n@exit /b 0" `
            -Encoding Ascii

        { Invoke-AtlasDesktopCommand -RelativePath 'probe.cmd' } | Should -Not -Throw
        (Get-Content -LiteralPath $argumentLog -Raw).Trim() | Should -BeExactly '/silent'
    }

    It 'fails loudly when a desktop command exits nonzero or is missing' {
        $failing = Join-Path $global:atlasDesktop 'failing.cmd'
        Set-Content -LiteralPath $failing -Value '@exit /b 5' -Encoding Ascii

        { Invoke-AtlasDesktopCommand -RelativePath 'failing.cmd' } |
            Should -Throw '*exited with code 5*'
        { Invoke-AtlasDesktopCommand -RelativePath 'missing.cmd' } |
            Should -Throw '*was not found*'
    }

    It 'restarts only Explorer processes in the current session' {
        # Loosely-typed doubles: the real Stop-Process cannot bind fake process
        # objects, and the refresh must never touch this session's real Explorer.
        $currentSessionId = [Diagnostics.Process]::GetCurrentProcess().SessionId
        $global:explorerRefreshFakes = @(
            [pscustomobject]@{ SessionId = $currentSessionId; Name = 'explorer'; Id = 101 }
            [pscustomobject]@{ SessionId = $currentSessionId + 7; Name = 'explorer'; Id = 202 }
        )
        $global:explorerRefreshStopped = [Collections.Generic.List[object]]::new()
        function global:Get-Process {
            param($Name, $ErrorAction)
            return $global:explorerRefreshFakes
        }
        function global:Stop-Process {
            param($InputObject, [switch]$Force, $ErrorAction)
            $global:explorerRefreshStopped.Add($InputObject)
        }

        try {
            Invoke-CurrentSessionExplorerRefresh
        }
        finally {
            Remove-Item Function:\Get-Process -ErrorAction SilentlyContinue
            Remove-Item Function:\Stop-Process -ErrorAction SilentlyContinue
        }

        @($global:explorerRefreshStopped).Count | Should -Be 1
        $global:explorerRefreshStopped[0].Id | Should -Be 101
        Remove-Variable -Name explorerRefreshFakes, explorerRefreshStopped -Scope Global `
            -ErrorAction SilentlyContinue
    }
}

Describe 'Installing-user shell completion flow' {
    It 'explicitly imports every module used directly by new-user setup' {
        $importLoops = @($script:newUserAst.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.ForEachStatementAst] -and
                    @($node.Body.FindAll({
                                param($child)
                                $child -is [Management.Automation.Language.CommandAst] -and
                                $child.GetCommandName() -eq 'Import-Module'
                            }, $true)).Count -gt 0
                }, $true))

        $importLoops.Count | Should -Be 1
        $moduleNames = @($importLoops[0].Condition.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.StringConstantExpressionAst]
                }, $true) | ForEach-Object { $_.Value })
        $moduleNames | Should -Be @('Atlas.Shortcuts', 'Atlas.Themes', 'Atlas.Toggles')

        $importCommand = @($importLoops[0].Body.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.CommandAst] -and
                    $node.GetCommandName() -eq 'Import-Module'
                }, $true))[0]
        $parameterNames = @($importCommand.CommandElements | Where-Object {
                $_ -is [Management.Automation.Language.CommandParameterAst]
            } | ForEach-Object { $_.ParameterName })
        $parameterNames | Should -Contain 'Force'
        $parameterNames | Should -Contain 'ErrorAction'
        $importCommand.Extent.Text | Should -Match '-ErrorAction Stop'
    }

    It 'creates the current user Atlas desktop shortcut with the Atlas folder icon' {
        $shortcutCommands = Find-CommandAst -Ast $script:newUserAst -Name 'New-AtlasShortcut'

        $shortcutCommands.Count | Should -Be 1
        $parameterNames = @($shortcutCommands[0].CommandElements | Where-Object {
                $_ -is [Management.Automation.Language.CommandParameterAst]
            } | ForEach-Object { $_.ParameterName })
        $parameterNames | Should -Contain 'Source'
        $parameterNames | Should -Contain 'Destination'
        $parameterNames | Should -Contain 'Icon'

        (Find-StringConstant -Ast $script:newUserAst -Value 'Atlas.lnk').Count |
            Should -Be 1
        (Find-StringConstant -Ast $script:newUserAst -Value 'Other\atlas-folder.ico').Count |
            Should -Be 1
        (Find-StringConstant -Ast $script:newUserAst -Value 'DesktopDirectory').Count |
            Should -Be 1
    }

    It 'refreshes the installing user Explorer session after committing shell state' {
        $fromInstallCompletion = $script:newUserAst.Find({
                param($node)
                $node -is [Management.Automation.Language.IfStatementAst] -and
                $node.Clauses[0].Item1.Extent.Text.Trim() -eq '$FromInstall' -and
                $node.Clauses[0].Item2.Extent.Text -match 'Set-SetupMarker'
            }, $true)

        $fromInstallCompletion | Should -Not -BeNullOrEmpty
        $completionBody = $fromInstallCompletion.Clauses[0].Item2
        $marker = @(Find-CommandAst -Ast $completionBody -Name 'Set-SetupMarker')
        $refresh = @(Find-CommandAst -Ast $completionBody `
                -Name 'Invoke-CurrentSessionExplorerRefresh')

        $marker.Count | Should -Be 1
        $marker[0].Extent.Text | Should -Match '-Value 2'
        $refresh.Count | Should -Be 1
        $refresh[0].Extent.StartOffset | Should -BeGreaterThan $marker[0].Extent.EndOffset
        @($completionBody.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.ReturnStatementAst]
                }, $true)).Count | Should -Be 1
    }

    It 'runs safe exact-user OneDrive cleanup for later non-install accounts' {
        $cleanupStrings = Find-StringConstant -Ast $script:newUserAst `
            -Value 'Scripts\Internal\Remove-OneDriveCurrentUserData.ps1'
        $cleanupStrings.Count | Should -Be 1

        # The launch is '& (Join-Path ...) -ExpectedUserSid $sid'; take the outermost
        # command, not the nested Join-Path.
        $cleanupCommand = $null
        for ($node = $cleanupStrings[0].Parent; $null -ne $node; $node = $node.Parent) {
            if ($node -is [Management.Automation.Language.CommandAst]) {
                $cleanupCommand = $node
            }
        }
        $cleanupCommand | Should -Not -BeNullOrEmpty
        $cleanupCommand.Extent.Text | Should -Match '-ExpectedUserSid \$sid'
        Get-AncestorIfCondition -Ast $cleanupCommand | Should -Be '-not $FromInstall'
    }

    It 'runs option-gated exact-user Edge cleanup for later non-install accounts' {
        $cleanupStrings = Find-StringConstant -Ast $script:newUserAst `
            -Value 'Scripts\Internal\Remove-EdgeCurrentUserData.ps1'
        $cleanupStrings.Count | Should -Be 1

        $cleanupCommand = $null
        for ($node = $cleanupStrings[0].Parent; $null -ne $node; $node = $node.Parent) {
            if ($node -is [Management.Automation.Language.CommandAst]) {
                $cleanupCommand = $node
            }
        }
        $cleanupCommand | Should -Not -BeNullOrEmpty
        $cleanupCommand.Extent.Text | Should -Match '-ExpectedUserSid \$sid'

        $ifConditions = [Collections.Generic.List[string]]::new()
        for ($node = $cleanupCommand.Parent; $null -ne $node; $node = $node.Parent) {
            if ($node -is [Management.Automation.Language.IfStatementAst]) {
                $ifConditions.Add($node.Clauses[0].Item1.Extent.Text.Trim())
            }
        }
        $ifConditions | Should -Contain '-not $FromInstall'
        $ifConditions | Should -Contain `
            'Test-Path -LiteralPath $uninstallEdgeFlag -PathType Leaf'
    }

    It 'removes the successful RunOnce retry before restarting Explorer' {
        $endStatements = $script:newUserAst.EndBlock
        $markers = @(Find-CommandAst -Ast $endStatements -Name 'Set-SetupMarker' |
                Where-Object { $_.Extent.Text -match '-Value 2' })
        $markers.Count | Should -Be 2
        $finalMarker = $markers | Sort-Object { $_.Extent.StartOffset } |
            Select-Object -Last 1

        $retryRemoval = @(Find-CommandAst -Ast $endStatements -Name 'Remove-ItemProperty' |
                Where-Object {
                    $_.Extent.Text -match '\$runOncePath' -and
                    $_.Extent.StartOffset -gt $finalMarker.Extent.EndOffset
                })
        $retryRemoval.Count | Should -Be 1

        $laterRefresh = @(
            Find-CommandAst -Ast $endStatements -Name 'Invoke-CurrentSessionExplorerRefresh' |
                Where-Object { $_.Extent.StartOffset -gt $retryRemoval[0].Extent.EndOffset }
        )
        $laterRefresh.Count | Should -Be 1
    }

    It 'logs only substantive setup stages and announces readiness after final refresh' {
        $transcriptStarts = @(Find-CommandAst -Ast $script:newUserAst -Name 'Start-Transcript')
        $transcriptStarts.Count | Should -Be 1
        Get-AncestorIfCondition -Ast $transcriptStarts[0] | Should -Be '-not $FinalizeSearch'

        $readyMessages = Find-StringConstant -Ast $script:newUserAst `
            -Value 'Your account is ready to use.'
        $readyMessages.Count | Should -Be 1

        $finalizer = $script:newUserAst.Find({
                param($node)
                $node -is [Management.Automation.Language.IfStatementAst] -and
                $node.Clauses[0].Item1.Extent.Text.Trim() -eq '$FinalizeSearch'
            }, $true)
        $finalizer | Should -Not -BeNullOrEmpty
        $finalizerBody = $finalizer.Clauses[0].Item2
        $readyMessages[0].Extent.StartOffset |
            Should -BeGreaterThan $finalizerBody.Extent.StartOffset
        $readyMessages[0].Extent.EndOffset |
            Should -BeLessThan $finalizerBody.Extent.EndOffset

        $finalRefresh = @(Find-CommandAst -Ast $finalizerBody `
                -Name 'Invoke-CurrentSessionExplorerRefresh')
        $finalRefresh.Count | Should -Be 1
        $readyMessages[0].Extent.StartOffset |
            Should -BeGreaterThan $finalRefresh[0].Extent.EndOffset
    }
}

Describe 'Start pin policy support' {
    It 'requires the servicing revision that introduced the 24H2 GPO' {
        Test-AtlasStartPinPolicySupported -Build 26100 -Revision 4769 | Should -BeFalse
        Test-AtlasStartPinPolicySupported -Build 26100 -Revision 4770 | Should -BeTrue
        Test-AtlasStartPinPolicySupported -Build 26100 -Revision 9000 | Should -BeTrue
    }

    It 'accepts later Windows build families' {
        Test-AtlasStartPinPolicySupported -Build 26200 -Revision 1 | Should -BeTrue
    }

    It 'names the exact enforced build boundary in the prerequisite diagnostic' {
        $supportFunction = $script:startAst.Find({
                param($node)
                $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -eq 'Test-AtlasStartPinPolicySupported'
            }, $true)
        $supportFunction | Should -Not -BeNullOrEmpty
        $boundaryConstants = @($supportFunction.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.ConstantExpressionAst] -and
                    $node.Value -is [int]
                }, $true) | ForEach-Object { $_.Value } | Sort-Object -Unique)
        $boundaryConstants.Count | Should -Be 2
        $enforcedBoundary = '{0}.{1}' -f $boundaryConstants[1], $boundaryConstants[0]

        # The boundary the function enforces must round-trip into the user-facing
        # diagnostic, so the message cannot drift from the check.
        Test-AtlasStartPinPolicySupported -Build $boundaryConstants[1] `
            -Revision $boundaryConstants[0] | Should -BeTrue
        Test-AtlasStartPinPolicySupported -Build $boundaryConstants[1] `
            -Revision ($boundaryConstants[0] - 1) | Should -BeFalse

        $diagnostics = @($script:startAst.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.StringConstantExpressionAst] -and
                    $node.Value -match 'KB\d{7}'
                }, $true))
        $diagnostics.Count | Should -BeGreaterThan 0
        @($diagnostics | Where-Object { $_.Value -like "*$enforcedBoundary*" }).Count |
            Should -BeGreaterThan 0
    }
}
