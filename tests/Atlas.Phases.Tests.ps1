BeforeAll {
    $script:atlasModulesRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules')).Path
    $script:phasesRoot = Join-Path -Path $script:atlasModulesRoot -ChildPath 'Scripts\Phases'

    function Get-AtlasPhaseAst {
        param([Parameter(Mandatory = $true)][string]$Path)

        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
        return [pscustomobject]@{ Ast = $ast; Errors = $errors }
    }

    function Get-AtlasPrivilegeSwitch {
        param([Parameter(Mandatory = $true)]$Ast)

        $commands = $Ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                $node.GetCommandName() -eq 'Assert-AtlasPrivilege'
            }, $true)

        $switches = foreach ($command in $commands) {
            foreach ($element in $command.CommandElements) {
                if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {
                    $element.ParameterName
                }
            }
        }

        return @($switches)
    }

    function Get-AtlasInProcessHelperInvocation {
        param(
            [Parameter(Mandatory = $true)]$CallerAst,
            [Parameter(Mandatory = $true)][string]$HelperName
        )

        $callOperators = @(
            [System.Management.Automation.Language.TokenKind]::Ampersand,
            [System.Management.Automation.Language.TokenKind]::Dot
        )
        $commands = @($CallerAst.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.CommandAst] -and
                    $callOperators -contains $node.InvocationOperator
                }, $true))

        # Direct calls, including: & (Join-Path ... -ChildPath 'Helper.ps1')
        $invocations = @($commands | Where-Object {
                $_.CommandElements.Count -gt 0 -and
                $_.CommandElements[0].Extent.Text -match [regex]::Escape($HelperName)
            })

        # Variable calls, including: $script = Join-Path ... 'Helper.ps1'; & $script
        $assignments = @($CallerAst.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
                    $node.Left -is [System.Management.Automation.Language.VariableExpressionAst] -and
                    $node.Right.Extent.Text -match [regex]::Escape($HelperName)
                }, $true))
        foreach ($assignment in $assignments) {
            $variableName = $assignment.Left.VariablePath.UserPath
            $scope = $assignment.Parent
            while ($null -ne $scope -and $scope -isnot [System.Management.Automation.Language.ScriptBlockAst]) {
                $scope = $scope.Parent
            }
            if ($null -eq $scope) {
                continue
            }

            $invocations += @($scope.FindAll({
                        param($node)
                        if ($node -isnot [System.Management.Automation.Language.CommandAst] -or
                            $callOperators -notcontains $node.InvocationOperator -or
                            $node.CommandElements.Count -eq 0) {
                            return $false
                        }

                        $target = $node.CommandElements[0]
                        return $target -is [System.Management.Automation.Language.VariableExpressionAst] -and
                            $target.VariablePath.UserPath -eq $variableName
                    }, $true))
        }

        return @($invocations)
    }

    function Get-AtlasPotentialSuccessExitStatement {
        param([Parameter(Mandatory = $true)]$Ast)

        $exitStatements = @($Ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.ExitStatementAst]
                }, $true))
        foreach ($exitStatement in $exitStatements) {
            if ($null -eq $exitStatement.Pipeline) {
                $exitStatement
                continue
            }

            try {
                $exitCode = [int]$exitStatement.Pipeline.SafeGetValue()
                if ($exitCode -eq 0) {
                    $exitStatement
                }
            }
            catch {
                # A dynamic exit expression (for example, $LASTEXITCODE) can be zero.
                $exitStatement
            }
        }
    }
}

Describe 'Install phase scripts' {
    BeforeDiscovery {
        $phasesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Phases'
        $script:phaseFiles = Get-ChildItem -Path $phasesRoot -Filter 'Invoke-*Phase.ps1' -File

        # Privilege each phase must assert. Features runs elevated (DISM online servicing);
        # Revert runs as TrustedInstaller (StoreFixer) and is a no-op on fresh installs.
        $script:privilegeExpectations = @{
            'Invoke-PreInstallPhase.ps1'   = 'Administrator'
            'Invoke-EnvironmentPhase.ps1'  = 'Administrator'
            'Invoke-FeaturesPhase.ps1'     = 'Administrator'
            'Invoke-SoftwarePhase.ps1'     = 'Administrator'
            'Invoke-AppxSupportPhase.ps1'  = 'Administrator'
            'Invoke-DefaultsPhase.ps1'     = 'Administrator'
            'Invoke-FinalizePhase.ps1'     = 'Administrator'
            'Invoke-ServicesPhase.ps1'     = 'TrustedInstaller'
            'Invoke-ComponentsPhase.ps1'   = 'TrustedInstaller'
            'Invoke-TweaksPhase.ps1'       = 'TrustedInstaller'
            'Invoke-RevertPhase.ps1'       = 'TrustedInstaller'
        }
    }

    It 'finds every expected phase script' {
        $names = (Get-ChildItem -Path $script:phasesRoot -Filter 'Invoke-*Phase.ps1' -File).Name
        foreach ($expected in @('PreInstall', 'Environment', 'Features', 'Software', 'Services',
                'Components', 'AppxSupport', 'Tweaks', 'Defaults', 'Revert', 'Finalize')) {
            $names | Should -Contain "Invoke-${expected}Phase.ps1"
        }
    }

    It '<Name> parses without errors' -ForEach ($phaseFiles | ForEach-Object { @{ Name = $_.Name; FullName = $_.FullName } }) {
        $parsed = Get-AtlasPhaseAst -Path $FullName
        $parsed.Errors | Should -BeNullOrEmpty
    }

    It '<Name> asserts <Privilege> privilege' -ForEach (
        $privilegeExpectations.GetEnumerator() | ForEach-Object { @{ Name = $_.Key; Privilege = $_.Value } }
    ) {
        $parsed = Get-AtlasPhaseAst -Path (Join-Path -Path $script:phasesRoot -ChildPath $Name)
        $switches = Get-AtlasPrivilegeSwitch -Ast $parsed.Ast
        $switches | Should -Contain $Privilege
    }
}

Describe 'In-process payload helper control flow' {
    It '<Helper> returns control to <Caller> instead of exiting its host process' -TestCases @(
        @{
            Helper = 'Scripts\Internal\Set-NotificationState.ps1'
            Caller = 'Scripts\Phases\Invoke-PreInstallPhase.ps1'
        }
        @{
            Helper = 'Scripts\Internal\Disable-FileSharing.ps1'
            Caller = 'Scripts\Phases\Invoke-ServicesPhase.ps1'
        }
        @{
            Helper = 'Scripts\Internal\Disable-PowerSaving.ps1'
            Caller = 'Toggles\General\PowerSaving.ps1'
        }
        @{
            Helper = 'Scripts\Internal\Set-DefaultPowerSaving.ps1'
            Caller = 'Toggles\General\PowerSaving.ps1'
        }
        @{
            Helper = 'Scripts\Internal\Enable-FileSharing.ps1'
            Caller = 'Toggles\General\FileSharing.ps1'
        }
        @{
            Helper = 'Scripts\Internal\Set-SendToContextMenu.ps1'
            Caller = 'Toggles\Services\Bluetooth.ps1'
        }
        @{
            Helper = 'Scripts\Internal\Set-DefenderState.ps1'
            Caller = 'Toggles\Security\ToggleDefender.ps1'
        }
        @{
            Helper = 'Scripts\Internal\Remove-TelemetryComponents.ps1'
            Caller = 'Toggles\Troubleshooting\TelemetryComponents.ps1'
        }
    ) {
        $helperPath = Join-Path -Path $script:atlasModulesRoot -ChildPath $Helper
        $callerPath = Join-Path -Path $script:atlasModulesRoot -ChildPath $Caller

        $callerParse = Get-AtlasPhaseAst -Path $callerPath
        $callerParse.Errors | Should -BeNullOrEmpty
        $helperName = Split-Path -Path $Helper -Leaf
        @(Get-AtlasInProcessHelperInvocation -CallerAst $callerParse.Ast -HelperName $helperName).Count | Should -BeGreaterThan 0 `
            -Because "$Caller must invoke $Helper in-process for this host-control contract to apply"

        $parsed = Get-AtlasPhaseAst -Path $helperPath
        $parsed.Errors | Should -BeNullOrEmpty
        $exitStatements = @(Get-AtlasPotentialSuccessExitStatement -Ast $parsed.Ast)

        $exitStatements | Should -BeNullOrEmpty `
            -Because "$Helper is invoked in-process by $Caller and a successful exit would terminate the toggle or phase host with code 0"
    }

    It '<Helper> isolates Install-AtlasPackage exits in a child Windows PowerShell host' -TestCases @(
        @{ Helper = 'Scripts\Internal\Set-DefenderState.ps1' }
        @{ Helper = 'Scripts\Internal\Remove-TelemetryComponents.ps1' }
    ) {
        $helperPath = Join-Path -Path $script:atlasModulesRoot -ChildPath $Helper
        $parsed = Get-AtlasPhaseAst -Path $helperPath
        $parsed.Errors | Should -BeNullOrEmpty

        @(Get-AtlasInProcessHelperInvocation -CallerAst $parsed.Ast -HelperName 'Install-AtlasPackage.ps1').Count | Should -Be 0 `
            -Because 'the package shell has a standalone exit-code contract and must not run inside a reusable helper host'

        $childProcessCalls = @($parsed.Ast.FindAll({
                    param($node)
                    if ($node -isnot [System.Management.Automation.Language.CommandAst] -or
                        $node.InvocationOperator -ne [System.Management.Automation.Language.TokenKind]::Ampersand -or
                        $node.CommandElements.Count -eq 0) {
                        return $false
                    }

                    $target = $node.CommandElements[0]
                    return $target -is [System.Management.Automation.Language.VariableExpressionAst] -and
                        $target.VariablePath.UserPath -eq 'packagePowerShell' -and
                        $node.Extent.Text -match '(?i)-File\s+\$packageInstall\s+-(?:Install|Uninstall)Packages'
                }, $true))
        $childProcessCalls.Count | Should -Be 2
    }

    It 'classifies every remaining potentially successful exit reachable through an in-process helper call' {
        # These exits are unreachable on the listed in-process route. Keep the exceptions
        # explicit so a new reusable script containing `exit` cannot bypass this contract.
        $contextBoundExitPairs = [ordered]@{
            'Scripts\Internal\Remove-Edge.ps1|Toggles\Software\RemoveEdge.ps1' =
                'The Admin toggle does not reach self-elevation, does not pass NonInteractive, and Write-Status exits only on failure.'
            'Scripts\Internal\Repair-RegistryPaths.ps1|Scripts\Phases\Invoke-FinalizePhase.ps1' =
                'The phase asserts Administrator before the helper self-elevation branch.'
            'Scripts\Internal\Set-VbsConfiguration.ps1|Toggles\Security\ConfigVBS.ps1' =
                'The toggle calls the interactive parameterless route; parameterized routes run in a child PowerShell process.'
            'Scripts\Internal\Update-Drivers.ps1|Toggles\General\UpdateDrivers.ps1' =
                'The Admin toggle makes the helper self-elevation branch unreachable.'
        }

        $payloadFiles = @(Get-ChildItem -LiteralPath $script:atlasModulesRoot -Recurse -File | Where-Object {
                $_.Extension -in @('.ps1', '.psm1', '.psd1')
            })
        $sources = @{}
        foreach ($file in $payloadFiles) {
            $sources[$file.FullName] = [System.IO.File]::ReadAllText($file.FullName)
        }

        $potentialExitHelpers = foreach ($file in $payloadFiles) {
            if ($sources[$file.FullName] -notmatch '(?im)^\s*exit(?:\s|$)') {
                continue
            }

            $parsed = Get-AtlasPhaseAst -Path $file.FullName
            if (@(Get-AtlasPotentialSuccessExitStatement -Ast $parsed.Ast).Count -gt 0) {
                $file
            }
        }

        $discoveredPairs = foreach ($helper in $potentialExitHelpers) {
            foreach ($caller in $payloadFiles) {
                if ($caller.FullName -eq $helper.FullName -or
                    $sources[$caller.FullName].IndexOf($helper.Name, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
                    continue
                }

                $callerParse = Get-AtlasPhaseAst -Path $caller.FullName
                if (@(Get-AtlasInProcessHelperInvocation -CallerAst $callerParse.Ast -HelperName $helper.Name).Count -eq 0) {
                    continue
                }

                $helperRelative = $helper.FullName.Substring($script:atlasModulesRoot.Length + 1)
                $callerRelative = $caller.FullName.Substring($script:atlasModulesRoot.Length + 1)
                "$helperRelative|$callerRelative"
            }
        }
        $discoveredPairs = @($discoveredPairs | Sort-Object -Unique)

        $unclassified = @($discoveredPairs | Where-Object { -not $contextBoundExitPairs.Contains($_) })
        $unclassified | Should -BeNullOrEmpty `
            -Because 'every in-process helper exit that can report success must be removed or proven unreachable for that caller'
        foreach ($knownPair in $contextBoundExitPairs.Keys) {
            $discoveredPairs | Should -Contain $knownPair `
                -Because "the context-bound exception must not outlive its call graph: $($contextBoundExitPairs[$knownPair])"
        }
    }
}
