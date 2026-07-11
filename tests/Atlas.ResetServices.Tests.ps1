BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
    $script:scriptsRoot = Join-Path -Path $script:repoRoot `
        -ChildPath 'playbook\Executables\AtlasModules\Scripts'
    $script:internalResetPath = Join-Path -Path $script:scriptsRoot `
        -ChildPath 'Internal\Invoke-AtlasResetServices.ps1'
    $script:serviceForwarderPath = Join-Path -Path $script:scriptsRoot `
        -ChildPath 'Internal\Set-ServiceStartup.ps1'
    $script:publicResetPath = Join-Path -Path $script:scriptsRoot `
        -ChildPath 'Invoke-AtlasResetServices.ps1'
    $script:startupDomainPath = Join-Path -Path $script:scriptsRoot `
        -ChildPath 'Modules\Atlas.Services\Domain\Startup.ps1'
    $script:wrapperPaths = @(
        (Join-Path -Path $script:repoRoot `
            -ChildPath 'playbook\Executables\AtlasDesktop\9. Troubleshooting\Set services to defaults.cmd')
        (Join-Path -Path $script:repoRoot `
            -ChildPath 'playbook\Executables\AtlasModules\Toolbox\Scripts\setServicesToDefaults.cmd')
        (Join-Path -Path $script:repoRoot `
            -ChildPath 'playbook\Executables\AtlasModules\Toolbox\Scripts\Troubleshooting\Set services to defaults.cmd')
    )

    $script:parsedScripts = @{}
    foreach ($path in @(
            $script:internalResetPath
            $script:serviceForwarderPath
            $script:publicResetPath
        )) {
        $tokens = $null
        $errors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile(
            $path,
            [ref]$tokens,
            [ref]$errors
        )
        $script:parsedScripts[$path] = [pscustomobject]@{
            Ast    = $ast
            Errors = @($errors)
            Source = Get-Content -LiteralPath $path -Raw
        }
    }

    function Invoke-AtlasTrustedInstaller {
        [CmdletBinding()]
        param(
            [string]$Operation,
            [string]$RestoreSource
        )

        $null = $Operation, $RestoreSource
    }

    $script:serviceContractModuleName = 'Atlas.ResetServices.ServiceContract.Test'
    $serviceContractModule = New-Module `
        -Name $script:serviceContractModuleName `
        -ArgumentList $script:startupDomainPath `
        -ScriptBlock {
            param([string]$StartupDomainPath)

            function Write-AtlasLog {
                param(
                    [string]$Level,
                    [string]$Message
                )

                $null = $Level, $Message
            }

            . $StartupDomainPath
            Export-ModuleMember -Function Set-AtlasServiceStartup
        }
    Import-Module -ModuleInfo $serviceContractModule -Force
}

AfterAll {
    Remove-Module -Name $script:serviceContractModuleName -Force -ErrorAction SilentlyContinue
}

Describe 'Reset Services PowerShell entry points' {
    It 'parses every migrated PowerShell entry point without errors' {
        foreach ($parsed in $script:parsedScripts.Values) {
            $parsed.Errors.Count | Should -Be 0
        }
    }

    It 'keeps the broker operation closed and runs fixed defaults before an optional snapshot' {
        $parsed = $script:parsedScripts[$script:internalResetPath]
        $parameters = @($parsed.Ast.ParamBlock.Parameters | ForEach-Object {
                $_.Name.VariablePath.UserPath
            })
        $parameters | Should -Be @('RestoreSource')
        $parsed.Source | Should -Match `
            "ValidateSet\('ToggleDefaults',\s*'WindowsBackup',\s*'AtlasBackup'\)"
        $parsed.Source | Should -Match 'Assert-AtlasPrivilege\s+-TrustedInstaller'
        $parsed.Source | Should -Match `
            '(?s)\$validRestoreSources\s*=\s*@\(''ToggleDefaults'',\s*''WindowsBackup'',\s*''AtlasBackup''\).+?\$validRestoreSources\s+-cnotcontains\s+\$RestoreSource'
        $parsed.Source | Should -Not -Match `
            '(?i)RunAsTI|cmd\.exe|ComSpec|Invoke-AtlasToggle\b|Start-Process'

        $commands = @($parsed.Ast.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.CommandAst]
                }, $true))
        $defaultsCall = @($commands | Where-Object {
                $_.GetCommandName() -ceq 'Invoke-AtlasServiceDefaultsReset'
            })
        $snapshotCall = @($commands | Where-Object {
                $_.Extent.Text -match '^&\s+\$regExe\s+import\s+\$snapshot$'
            })
        $defaultsCall.Count | Should -Be 1
        $snapshotCall.Count | Should -Be 1
        $defaultsCall[0].Extent.StartOffset | Should -BeLessThan $snapshotCall[0].Extent.StartOffset

        $defaultsConditionalAncestors = @()
        $ancestor = $defaultsCall[0].Parent
        while ($null -ne $ancestor -and $ancestor -ne $parsed.Ast) {
            if ($ancestor -is [Management.Automation.Language.IfStatementAst]) {
                $defaultsConditionalAncestors += $ancestor
            }
            $ancestor = $ancestor.Parent
        }
        $defaultsConditionalAncestors.Count | Should -Be 0

        $parsed.Source | Should -Match `
            'if\s*\(\$RestoreSource\s+-ceq\s+''WindowsBackup''\)\s*\{\s*''winServices\.reg''\s*\}\s*else\s*\{\s*''atlasServices\.reg'''
        $parsed.Source | Should -Match `
            'Join-Path\s+-Path\s+\$context\.WinDir\s+-ChildPath\s+''System32\\reg\.exe'''
        $parsed.Source | Should -Match `
            '(?s)if\s*\(\$snapshot\).+?&\s+\$regExe\s+import\s+\$snapshot.+?\$LASTEXITCODE\s+-ne\s+0'
    }

    It 'rejects noncanonical restore-source casing before privileged setup' {
        { & $script:internalResetPath -RestoreSource 'toggledefaults' } |
            Should -Throw -ExpectedMessage '*exact canonical casing*'
        { & $script:internalResetPath -RestoreSource 'windowsbackup' } |
            Should -Throw -ExpectedMessage '*exact canonical casing*'
        { & $script:internalResetPath -RestoreSource 'atlasbackup' } |
            Should -Throw -ExpectedMessage '*exact canonical casing*'
    }

    It 'keeps the compatibility forwarder on the typed Atlas.Services boundary' {
        $parsed = $script:parsedScripts[$script:serviceForwarderPath]
        $parameters = @($parsed.Ast.ParamBlock.Parameters | ForEach-Object {
                $_.Name.VariablePath.UserPath
            })
        $parameters | Should -Be @('Name', 'Start')
        $parsed.Source | Should -Match `
            "\.\.\\Modules\\Atlas\.Services\\Atlas\.Services\.psd1'"
        $parsed.Source | Should -Match `
            'Import-Module\s+-Name\s+\$servicesManifest\s+-Force\s+-ErrorAction\s+Stop'
        $parsed.Source | Should -Match `
            'Set-AtlasServiceStartup\s+-Name\s+\$Name\s+-StartupType\s+\$Start'
        $parsed.Source | Should -Not -Match `
            '(?i)CurrentControlSet\\Services|Set-ItemProperty|reg(?:\.exe)?\s+add'
    }

    It 'routes silent calls through only the typed ResetServices operation' {
        Mock -CommandName Import-Module -MockWith {}
        Mock -CommandName Write-Host -MockWith {}
        Mock -CommandName Invoke-AtlasTrustedInstaller -MockWith {
            [pscustomobject]@{
                status         = 'Completed'
                exitCodeUInt32 = [uint64]0
                error          = $null
            }
        }

        { & $script:publicResetPath -Silent } | Should -Not -Throw

        Should -Invoke -CommandName Invoke-AtlasTrustedInstaller -Times 1 -Exactly `
            -ParameterFilter {
                $Operation -ceq 'ResetServices' -and
                    $RestoreSource -ceq 'ToggleDefaults'
            }
        Should -Invoke -CommandName Import-Module -Times 1 -Exactly -ParameterFilter {
            [string]$Name -like '*\Modules\Atlas.Core\Atlas.Core.psd1' -and $Force
        }
    }

    It 'surfaces broker failure and nonzero target exits without attempting a restart' {
        Mock -CommandName Import-Module -MockWith {}
        Mock -CommandName Write-Host -MockWith {}
        Mock -CommandName Invoke-AtlasTrustedInstaller -MockWith {
            [pscustomobject]@{
                status         = 'CompletionUnknown'
                exitCodeUInt32 = [uint64]0
                error          = 'test broker failure'
            }
        }

        { & $script:publicResetPath -Silent } |
            Should -Throw -ExpectedMessage "*CompletionUnknown*test broker failure*"

        Mock -CommandName Invoke-AtlasTrustedInstaller -MockWith {
            [pscustomobject]@{
                status         = 'Completed'
                exitCodeUInt32 = [uint64]5
                error          = $null
            }
        }
        { & $script:publicResetPath -Silent } |
            Should -Throw -ExpectedMessage '*exited with code 5*'
    }

    It 'rejects a completed broker result without an exit-code field' {
        Mock -CommandName Import-Module -MockWith {}
        Mock -CommandName Invoke-AtlasTrustedInstaller -MockWith {
            [pscustomobject]@{
                status = 'Completed'
                error  = $null
            }
        }

        { & $script:publicResetPath -Silent } |
            Should -Throw -ExpectedMessage '*completed without an exit code*'
    }
}

Describe 'Reset Services optional-service behavior' {
    BeforeEach {
        Mock -CommandName Test-Path -ModuleName $script:serviceContractModuleName `
            -MockWith { $false }
        Mock -CommandName Write-AtlasLog -ModuleName $script:serviceContractModuleName `
            -MockWith {}
        Mock -CommandName Set-ItemProperty -ModuleName $script:serviceContractModuleName `
            -MockWith { throw 'Set-ItemProperty must not run for a missing optional service.' }
    }

    It 'warns and succeeds when an edition-specific service is absent' {
        $fakeServicesRoot = Join-Path -Path $TestDrive -ChildPath 'Services'

        {
            Set-AtlasServiceStartup `
                -Name 'AtlasResetTestMissingOptionalService' `
                -StartupType 4 `
                -ServicesRoot $fakeServicesRoot
        } | Should -Not -Throw

        Should -Invoke -CommandName Write-AtlasLog `
            -ModuleName $script:serviceContractModuleName `
            -Times 1 `
            -Exactly `
            -ParameterFilter {
                $Level -ceq 'Warning' -and
                    $Message -like '*AtlasResetTestMissingOptionalService*'
            }
        Should -Not -Invoke -CommandName Set-ItemProperty `
            -ModuleName $script:serviceContractModuleName
    }
}

Describe 'Reset Services CMD wrappers' {
    It 'keeps all three copies byte-for-byte equivalent' {
        $contents = @($script:wrapperPaths | ForEach-Object {
                Get-Content -LiteralPath $_ -Raw
            })
        $contents.Count | Should -Be 3
        $contents[1] | Should -BeExactly $contents[0]
        $contents[2] | Should -BeExactly $contents[0]
    }

    It 'accepts only optional slash-silent and invokes the protected exact launcher' {
        foreach ($path in $script:wrapperPaths) {
            $source = Get-Content -LiteralPath $path -Raw
            $source | Should -Match `
                '(?m)^if not "%~2"=="" exit /b 87\r?$'
            $source | Should -Match `
                '(?m)^if /i "%~1"=="/silent" \(\r?$'
            $source | Should -Match `
                '(?m)^\s*set "AtlasResetSilent=-Silent"\r?$'
            $source | Should -Match `
                '(?m)^"%AtlasNativePowerShell%" -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%AtlasWindowsRoot%\\AtlasModules\\Scripts\\Invoke-AtlasResetServices\.ps1" %AtlasResetSilent%\r?$'
            $source | Should -Not -Match `
                '(?i)%\*|%~[3-9]|RunAsTI|whoami|\bstart\b|\breg(?:\.exe)?\s+import|\bfor\s+/f\b'

            $helperIndex = $source.IndexOf('call "%launcherEnvironment%"')
            $launcherIndex = $source.IndexOf('"%AtlasNativePowerShell%"')
            $helperIndex | Should -BeGreaterOrEqual 0
            $launcherIndex | Should -BeGreaterThan $helperIndex
        }
    }

    It 'normalizes signed launcher failures while preserving ordinary nonzero exits' {
        foreach ($path in $script:wrapperPaths) {
            $source = Get-Content -LiteralPath $path -Raw
            $source | Should -Match `
                '(?s)"%AtlasNativePowerShell%".+?if errorlevel 0 \(\s*if errorlevel 1 exit /b\s*\) else \(\s*exit /b 1\s*\)\s*exit /b 0'
            $source | Should -Not -Match '(?i)%ERRORLEVEL%'
        }
    }
}
