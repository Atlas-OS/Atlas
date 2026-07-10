BeforeAll {
    $script:phasesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Phases'

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

Describe 'In-process phase helper control flow' {
    BeforeAll {
        $script:internalRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Internal'
    }

    It '<Helper> returns control to <Phase> instead of exiting its host process' -TestCases @(
        @{
            Helper = 'Set-NotificationState.ps1'
            Phase  = 'Invoke-PreInstallPhase.ps1'
        }
        @{
            Helper = 'Disable-FileSharing.ps1'
            Phase  = 'Invoke-ServicesPhase.ps1'
        }
    ) {
        $helperPath = Join-Path -Path $script:internalRoot -ChildPath $Helper
        $phasePath = Join-Path -Path $script:phasesRoot -ChildPath $Phase
        (Get-Content -LiteralPath $phasePath -Raw) | Should -Match ([regex]::Escape($Helper))

        $parsed = Get-AtlasPhaseAst -Path $helperPath
        $parsed.Errors | Should -BeNullOrEmpty
        $exitStatements = @($parsed.Ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.ExitStatementAst]
                }, $true))

        $exitStatements | Should -BeNullOrEmpty `
            -Because "$Helper is invoked in-process by $Phase and exit would terminate the whole phase"
    }
}
