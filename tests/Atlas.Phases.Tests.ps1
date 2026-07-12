[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter',
    '',
    Justification = 'The software-phase harness parameters are consumed through its isolated child-scope command stubs.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidOverwritingBuiltInCmdlets',
    '',
    Justification = 'The isolated software-phase harness shadows Import-Module only while executing the phase under test.'
)]
param()

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

    function Invoke-AtlasSoftwarePhaseForTest {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)][string]$Path,
            [Parameter(Mandatory = $true)]$Context,
            [Parameter(Mandatory = $true)][hashtable]$Options,
            [Parameter(Mandatory = $true)][hashtable]$ComponentOutcomes,
            [Parameter(Mandatory = $true)]$Attempts,
            [Parameter(Mandatory = $true)]$Logs,
            [Parameter(Mandatory = $true)]$UserIntegrationState,
            [int]$UserIntegrationExitCode = 0
        )

        & {
            function Assert-AtlasPrivilege {
                [CmdletBinding()]
                param([switch]$TrustedInstaller)
                [void]$TrustedInstaller
            }

            function Import-Module {
                [CmdletBinding()]
                param([string]$Name, [switch]$Force)
                [void]$Name
                [void]$Force
            }

            function Get-AtlasContext {
                return $Context
            }

            function Test-AtlasOption {
                param([Parameter(Mandatory = $true)][string]$Name)
                return $Options.ContainsKey($Name) -and [bool]$Options[$Name]
            }

            function Install-AtlasSoftware {
                param([Parameter(Mandatory = $true)][string[]]$Component)
                $name = [string]$Component[0]
                [void]$Attempts.Add($name)
                if (-not $ComponentOutcomes.ContainsKey($name)) {
                    return $true
                }
                $outcome = $ComponentOutcomes[$name]
                if ($outcome -is [Exception]) {
                    throw $outcome
                }
                return [bool]$outcome
            }

            function Invoke-AtlasAsUser {
                param(
                    [Parameter(Mandatory = $true)][string]$FilePath,
                    [Parameter(Mandatory = $true)][string]$Arguments
                )
                [void]$FilePath
                [void]$Arguments
                $UserIntegrationState.Count++
                return $UserIntegrationExitCode
            }

            function Write-AtlasLog {
                param(
                    [string]$Level = 'Information',
                    [Parameter(Mandatory = $true)][string]$Message
                )
                [void]$Logs.Add([pscustomobject]@{ Level = $Level; Message = $Message })
            }

            . $Path
        }
    }
}

Describe 'Install phase scripts' {
    BeforeDiscovery {
        $phasesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Phases'
        $script:phaseFiles = Get-ChildItem -Path $phasesRoot -Filter 'Invoke-*Phase.ps1' -File

        # Every install phase is rooted in one strict TrustedInstaller identity. Genuine
        # user work drops through the install-state-bound exact-user launcher inside it.
        $script:privilegeExpectations = @{
            'Invoke-PreInstallPhase.ps1'   = 'TrustedInstaller'
            'Invoke-ShellRefreshPhase.ps1' = 'TrustedInstaller'
            'Invoke-EnvironmentPhase.ps1'  = 'TrustedInstaller'
            'Invoke-FeaturesPhase.ps1'     = 'TrustedInstaller'
            'Invoke-SoftwarePhase.ps1'     = 'TrustedInstaller'
            'Invoke-AppxSupportPhase.ps1'  = 'TrustedInstaller'
            'Invoke-DefaultsPhase.ps1'     = 'TrustedInstaller'
            'Invoke-ServicesPhase.ps1'     = 'TrustedInstaller'
            'Invoke-ComponentsPhase.ps1'   = 'TrustedInstaller'
            'Invoke-TweaksPhase.ps1'       = 'TrustedInstaller'
            'Invoke-RevertPhase.ps1'       = 'TrustedInstaller'
        }
    }

    It 'finds every expected phase script' {
        $names = (Get-ChildItem -Path $script:phasesRoot -Filter 'Invoke-*Phase.ps1' -File).Name
        foreach ($expected in @('PreInstall', 'ShellRefresh', 'Environment', 'Features', 'Software', 'Services',
                'Components', 'AppxSupport', 'Tweaks', 'Defaults', 'Revert')) {
            $names | Should -Contain "Invoke-${expected}Phase.ps1"
        }
    }

    It '<Name> parses without errors' -ForEach ($phaseFiles | ForEach-Object { @{ Name = $_.Name; FullName = $_.FullName } }) {
        $parsed = Get-AtlasPhaseAst -Path $FullName
        $parsed.Errors | Should -BeNullOrEmpty
    }

    It '<Name> returns or throws without exiting the install dispatcher host' -ForEach (
        $phaseFiles | ForEach-Object { @{ Name = $_.Name; FullName = $_.FullName } }
    ) {
        $parsed = Get-AtlasPhaseAst -Path $FullName
        $exitStatements = @($parsed.Ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.ExitStatementAst]
                }, $true))

        $exitStatements | Should -BeNullOrEmpty `
            -Because "$Name must return or throw so Invoke-AtlasInstall can durably complete or fail its phase"
    }

    It '<Name> asserts <Privilege> privilege' -ForEach (
        $privilegeExpectations.GetEnumerator() | ForEach-Object { @{ Name = $_.Key; Privilege = $_.Value } }
    ) {
        $parsed = Get-AtlasPhaseAst -Path (Join-Path -Path $script:phasesRoot -ChildPath $Name)
        $switches = Get-AtlasPrivilegeSwitch -Ast $parsed.Ast
        $switches | Should -Contain $Privilege
    }
}

Describe 'Software phase outcome aggregation' {
    BeforeEach {
        $script:softwarePhasePath = Join-Path -Path $script:phasesRoot `
            -ChildPath 'Invoke-SoftwarePhase.ps1'
        $script:softwareAttempts = New-Object 'Collections.Generic.List[string]'
        $script:softwareLogs = New-Object 'Collections.Generic.List[object]'
        $script:userIntegrationState = [pscustomobject]@{ Count = 0 }
    }

    It 'attempts every selected component before throwing one aggregate for false and thrown outcomes' {
        $context = [pscustomobject]@{
            IsUpgrade = $false
            IsOobe = $true
            InteractiveUserSid = $null
        }
        $options = @{
            'install-toolbox' = $true
            'browser-brave' = $true
            'browser-firefox' = $true
            'browser-librewolf' = $true
            'browser-chrome' = $true
        }
        $outcomes = @{
            SevenZip = $false
            DirectX = $false
            Firefox = [InvalidOperationException]::new('simulated Firefox failure')
        }

        $failure = $null
        try {
            Invoke-AtlasSoftwarePhaseForTest `
                -Path $script:softwarePhasePath `
                -Context $context `
                -Options $options `
                -ComponentOutcomes $outcomes `
                -Attempts $script:softwareAttempts `
                -Logs $script:softwareLogs `
                -UserIntegrationState $script:userIntegrationState
        }
        catch {
            $failure = $_
        }

        $failure | Should -Not -BeNullOrEmpty
        $failure.Exception.Message | Should -BeExactly `
            'Software phase failed for components: SevenZip, Firefox.'
        @($script:softwareAttempts) | Should -Be @(
            'VCRedist', 'SevenZip', 'DirectX', 'Toolbox',
            'Brave', 'Firefox', 'LibreWolf', 'Chrome'
        )
        $script:softwareLogs.Count | Should -Be 3
        @($script:softwareLogs | Where-Object {
                $_.Message -match 'Optional legacy DirectX runtime was not installed; continuing'
            }).Count | Should -Be 1
    }

    It 'counts failed exact-user LibreWolf integration and still attempts later browsers' {
        $context = [pscustomobject]@{
            IsUpgrade = $true
            IsOobe = $false
            InteractiveUserSid = 'S-1-5-21-1000-1001-1002-1003'
        }
        $options = @{
            'browser-librewolf' = $true
            'browser-chrome' = $true
        }

        $failure = $null
        try {
            Invoke-AtlasSoftwarePhaseForTest `
                -Path $script:softwarePhasePath `
                -Context $context `
                -Options $options `
                -ComponentOutcomes @{} `
                -Attempts $script:softwareAttempts `
                -Logs $script:softwareLogs `
                -UserIntegrationState $script:userIntegrationState `
                -UserIntegrationExitCode 37
        }
        catch {
            $failure = $_
        }

        $failure | Should -Not -BeNullOrEmpty
        $failure.Exception.Message | Should -BeExactly `
            'Software phase failed for components: LibreWolf.'
        @($script:softwareAttempts) | Should -Be @('LibreWolf', 'Chrome')
        $script:userIntegrationState.Count | Should -Be 1
        $script:softwareLogs.Count | Should -Be 1
        $script:softwareLogs[0].Message | Should -Match `
            'Exact-user LibreWolf integration failed with exit code 37'
    }
}
