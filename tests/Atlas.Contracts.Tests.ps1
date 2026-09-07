BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:PlaybookRoot = Join-Path $script:RepoRoot 'playbook'
    $script:ModulesRoot = Join-Path $script:PlaybookRoot `
        'Executables\AtlasModules\Scripts\Modules'
    $script:TweaksRoot = Join-Path $script:PlaybookRoot `
        'Executables\AtlasModules\Scripts\Tweaks'
    $script:ConfigurationRoot = Join-Path $script:PlaybookRoot 'Configuration'

    Import-Module -Name (Join-Path $script:ModulesRoot `
            'Atlas.Tweaks\Atlas.Tweaks.psd1') -Force

    [xml]$playbook = [IO.File]::ReadAllText((Join-Path $script:PlaybookRoot 'playbook.conf'))
    $script:FeatureOptions = @($playbook.SelectNodes(
            '/Playbook/FeaturePages/*/Options/*/Name'
        ) | ForEach-Object { $_.InnerText } | Sort-Object -Unique)

    . (Join-Path $script:RepoRoot 'tools\build\AtlasBuild\AtlasYamlAction.ps1')
    $script:CustomActions = @(Get-AtlasYamlAction `
            -Path (Join-Path $script:ConfigurationRoot 'custom.yml') `
            -RelativePath 'custom.yml')
}

Describe 'Atlas option handoff contract' {
    It 'keeps FeaturePage, state, YAML, and tweak option sets identical' {
        $recordActions = @($script:CustomActions | Where-Object {
                $_.Type -ceq 'run' -and
                [string]$_.Properties.args -match `
                    ' -Operation RecordOption -Option (?<Option>[a-z0-9-]+)$'
            })
        $yamlOptions = foreach ($action in $recordActions) {
            $match = [regex]::Match(
                [string]$action.Properties.args,
                ' -Operation RecordOption -Option (?<Option>[a-z0-9-]+)$'
            )
            $name = $match.Groups['Option'].Value
            [string]$action.Properties.option | Should -BeExactly $name
            $name
        }

        $statePath = Join-Path $script:PlaybookRoot `
            'Executables\AtlasModules\Scripts\Entry\Initialize-AtlasInstallState.ps1'
        $tokens = $null
        $parseErrors = $null
        $stateAst = [Management.Automation.Language.Parser]::ParseFile(
            $statePath,
            [ref]$tokens,
            [ref]$parseErrors
        )
        $parseErrors | Should -BeNullOrEmpty
        $optionParameter = @($stateAst.ParamBlock.Parameters | Where-Object {
                $_.Name.VariablePath.UserPath -ceq 'Option'
            })
        $optionParameter.Count | Should -Be 1
        $optionValidateSet = @($optionParameter[0].Attributes | Where-Object {
                $_.TypeName.FullName -ceq 'ValidateSet'
            })
        $optionValidateSet.Count | Should -Be 1
        $stateOptions = @($optionValidateSet[0].PositionalArguments | ForEach-Object {
                [string]$_.SafeGetValue()
            } | Sort-Object -Unique)

        $tweakOptions = @(InModuleScope Atlas.Tweaks {
                $script:AtlasKnownOptions
            } | Sort-Object -Unique)

        @($yamlOptions | Sort-Object -Unique) | Should -Be $script:FeatureOptions
        $recordActions.Count | Should -Be $script:FeatureOptions.Count
        $stateOptions | Should -Be $script:FeatureOptions
        $tweakOptions | Should -Be $script:FeatureOptions
    }

    It 'uses only declared FeaturePage options in tweak data and option checks' {
        $referencedOptions = [System.Collections.Generic.List[string]]::new()

        Get-ChildItem -LiteralPath $script:TweaksRoot -Filter '*.psd1' -File -Recurse |
            Where-Object { $_.Name -ne 'tweaks.manifest.psd1' } |
            ForEach-Object {
                $definition = Import-PowerShellDataFile -LiteralPath $_.FullName
                if ($definition.ContainsKey('Option')) {
                    $referencedOptions.Add([string]$definition.Option)
                }
            }

        $literalCallPattern = 'Test-AtlasOption\s+-Name\s+[''"]([^''"]+)[''"]'
        Get-ChildItem -LiteralPath $script:PlaybookRoot `
            -Include '*.ps1','*.psm1' -File -Recurse |
            Select-String -Pattern $literalCallPattern -AllMatches |
            ForEach-Object {
                foreach ($match in $_.Matches) {
                    $referencedOptions.Add($match.Groups[1].Value)
                }
            }

        $unknown = @($referencedOptions | Sort-Object -Unique |
            Where-Object { $script:FeatureOptions -notcontains $_ })
        $unknown | Should -BeNullOrEmpty
    }
}

Describe 'Payload module import contracts' {
    BeforeDiscovery {
        $modulesRoot = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\playbook')).ProviderPath 'Executables\AtlasModules\Scripts\Modules'
        $script:PayloadManifests = @(Get-ChildItem -LiteralPath $modulesRoot -Filter 'Atlas.*.psd1' -File -Recurse |
            ForEach-Object { @{ Name = $_.BaseName; FullName = $_.FullName; ModulesRoot = $modulesRoot } })
    }

    BeforeAll {
        $script:ImportHarness = Join-Path $TestDrive 'Test-AtlasModuleImport.ps1'
        @'
param(
    [Parameter(Mandatory = $true)][string]$ManifestPath,
    [Parameter(Mandatory = $true)][string]$ModulesRoot
)

$ErrorActionPreference = 'Stop'
# Resolve modules only from this host's own inbox modules and the payload root, so
# per-user or cross-edition PSModulePath entries cannot shadow the inbox modules.
# Import-PowerShellDataFile itself lives in the inbox Utility module, so this must
# happen before the manifest is read.
$env:PSModulePath = @(
    [IO.Path]::Combine($PSHOME, 'Modules')
    $ModulesRoot
) -join [IO.Path]::PathSeparator

Import-Module Microsoft.PowerShell.Management -ErrorAction Stop
Import-Module Microsoft.PowerShell.Utility -ErrorAction Stop
$null = Get-Command Import-Module,Get-Command
$PSModuleAutoloadingPreference = 'None'

$manifest = Import-PowerShellDataFile -LiteralPath $ManifestPath
$expectedExports = @($manifest.FunctionsToExport)
$moduleName = [IO.Path]::GetFileNameWithoutExtension($ManifestPath)
Import-Module -Name $ManifestPath -Force -ErrorAction Stop
$actualExports = @((Get-Command -Module $moduleName -CommandType Function).Name)

$missing = @($expectedExports | Where-Object { $actualExports -notcontains $_ })
$unexpected = @($actualExports | Where-Object { $expectedExports -notcontains $_ })
if ($missing.Count -gt 0 -or $unexpected.Count -gt 0) {
    throw "Export mismatch. Missing: $($missing -join ', '); unexpected: $($unexpected -join ', ')."
}
'@ | Set-Content -LiteralPath $script:ImportHarness -Encoding UTF8

        $script:CurrentPowerShell = if ($PSVersionTable.PSEdition -eq 'Desktop') {
            Join-Path $PSHOME 'powershell.exe'
        }
        else {
            Join-Path $PSHOME 'pwsh.exe'
        }
    }

    It 'covers every module directory under the payload module root with exactly one manifest' {
        # Same enumeration as the discovery above: every Atlas.* directory must carry
        # exactly one manifest named after it, so a new module cannot escape the import contract.
        $directories = @(Get-ChildItem -LiteralPath $script:ModulesRoot -Directory |
                ForEach-Object { $_.Name } | Sort-Object)
        $manifests = @(Get-ChildItem -LiteralPath $script:ModulesRoot -Filter 'Atlas.*.psd1' -File -Recurse)

        $directories.Count | Should -BeGreaterThan 0
        @($manifests | ForEach-Object { $_.BaseName } | Sort-Object) | Should -Be $directories
        foreach ($manifest in $manifests) {
            $manifest.DirectoryName | Should -BeExactly (Join-Path $script:ModulesRoot $manifest.BaseName)
        }
    }

    It '<Name> imports in a clean process with autoloading disabled and exact exports' -ForEach $PayloadManifests {
        $output = & $script:CurrentPowerShell -NoProfile -ExecutionPolicy Bypass -File $script:ImportHarness `
            -ManifestPath $FullName -ModulesRoot $ModulesRoot 2>&1

        $LASTEXITCODE | Should -Be 0 -Because ($output -join "`n")
    }
}

Describe 'Payload variable definition contract' {
    # Initialize-NewUser once read a $windir it never assigned, so every account setup
    # died on its first use. Nothing in the parse gate or the linter catches that.
    It 'never reads a variable the script does not define' {
        $automatic = @(
            '_', 'args', 'error', 'false', 'true', 'null', 'input', 'this', 'psitem', 'pscmdlet',
            'psscriptroot', 'pscommandpath', 'psboundparameters', 'myinvocation', 'host', 'home',
            'pid', 'pwd', 'profile', 'shellid', 'stacktrace', 'lastexitcode', '?', '^', '$',
            'executioncontext', 'psversiontable', 'pshome', 'matches', 'nestedpromptlevel',
            'erroractionpreference', 'verbosepreference', 'debugpreference', 'warningpreference',
            'progresspreference', 'informationpreference', 'confirmpreference', 'whatifpreference',
            'psdefaultparametervalues', 'psemailserver', 'psmoduleautoloadingpreference',
            'outputencoding', 'formatenumerationlimit', 'maximumhistorycount', 'psculture',
            'psuiculture', 'iscoreclr', 'iswindows', 'islinux', 'ismacos', 'consolefilename',
            'switch', 'foreach', 'sender', 'eventargs', 'event', 'eventsubscriber', 'reason'
        )
        $scopedDrives = @('env', 'using', 'script', 'global', 'local', 'private', 'variable', 'function')

        $undefined = @()
        $payloadScripts = @(Get-ChildItem -LiteralPath $script:PlaybookRoot -Recurse -File |
                Where-Object { $_.Extension -cin @('.ps1', '.psm1') })
        foreach ($file in $payloadScripts) {
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
            @($errors).Count | Should -Be 0 -Because "$($file.Name) must parse"

            $defined = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
            foreach ($assignment in $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.AssignmentStatementAst] }, $true)) {
                foreach ($target in $assignment.Left.FindAll({ $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true)) {
                    [void]$defined.Add($target.VariablePath.UserPath)
                }
            }
            foreach ($parameter in $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ParameterAst] }, $true)) {
                [void]$defined.Add($parameter.Name.VariablePath.UserPath)
            }
            foreach ($loop in $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ForEachStatementAst] }, $true)) {
                [void]$defined.Add($loop.Variable.VariablePath.UserPath)
            }
            foreach ($dataStatement in $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.DataStatementAst] }, $true)) {
                if ($dataStatement.Variable) { [void]$defined.Add($dataStatement.Variable) }
            }

            foreach ($use in $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true)) {
                $path = $use.VariablePath
                if ($path.IsGlobal -or $path.IsScript -or $path.DriveName -in $scopedDrives) { continue }
                if ($automatic -contains $path.UserPath.ToLowerInvariant()) { continue }
                if ($defined.Contains($path.UserPath)) { continue }
                $undefined += "$($file.Name):$($use.Extent.StartLineNumber) `$$($path.UserPath)"
            }
        }

        $undefined | Should -BeNullOrEmpty
    }
}

Describe 'Exact-user operation failure reporting' {
    BeforeAll {
        # The child runs in the user's session, so its output never reaches the install
        # console. The task reads the user's own transcript to explain a failure.
        $taskPath = Join-Path $script:PlaybookRoot `
            'Executables\AtlasModules\Scripts\Install\Tasks\Get-AtlasUserFailureDetail.ps1'
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($taskPath, [ref]$tokens, [ref]$errors)
        $function = $ast.Find({
                $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                $args[0].Name -eq 'Get-AtlasUserFailureDetail'
            }, $true)
        $function | Should -Not -BeNullOrEmpty
        . ([scriptblock]::Create($function.Extent.Text))
    }

    It 'returns the tail of the newest user transcript' {
        $profileRoot = Join-Path $TestDrive 'Profile'
        $logs = Join-Path $profileRoot 'AppData\Local\AtlasOS\Logs'
        New-Item -Path $logs -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $logs '20260101-000000-new-user-setup-1.log') -Value 'older run'
        $newest = Join-Path $logs '20260102-000000-new-user-setup-2.log'
        Set-Content -LiteralPath $newest -Value @('line one', 'Cannot bind argument to parameter Path')
        (Get-Item -LiteralPath $newest).LastWriteTimeUtc = (Get-Date).ToUniversalTime()

        Mock Get-ItemProperty { [pscustomobject]@{ ProfileImagePath = $profileRoot } }

        $detail = Get-AtlasUserFailureDetail -UserSid 'S-1-5-21-1-2-3-1001' -TranscriptPattern '*-new-user-setup-*.log'
        $detail | Should -Match 'Cannot bind argument to parameter Path'
        $detail | Should -Match ([regex]::Escape($newest))
    }

    It 'selects only the requested operation from this invocation' {
        $profileRoot = Join-Path $TestDrive 'OperationProfile'
        $logs = Join-Path $profileRoot 'AppData\Local\AtlasOS\Logs'
        New-Item -Path $logs -ItemType Directory -Force | Out-Null
        $old = Join-Path $logs 'old-onedrive-cleanup-1.log'
        Set-Content -LiteralPath $old -Value 'stale failure'
        (Get-Item -LiteralPath $old).LastWriteTimeUtc = [datetime]::UtcNow.AddMinutes(-5)
        $started = [datetime]::UtcNow.AddSeconds(-1)
        Set-Content -LiteralPath (Join-Path $logs 'new-new-user-setup-2.log') -Value 'different operation'
        Mock Get-ItemProperty { [pscustomobject]@{ ProfileImagePath = $profileRoot } }

        Get-AtlasUserFailureDetail -UserSid 'S-1-5-21-1-2-3-1001' `
            -TranscriptPattern '*-onedrive-cleanup-*.log' -NotBefore $started | Should -BeNullOrEmpty

        Set-Content -LiteralPath (Join-Path $logs 'new-onedrive-cleanup-3.log') -Value 'locked cache file'
        $detail = Get-AtlasUserFailureDetail -UserSid 'S-1-5-21-1-2-3-1001' `
            -TranscriptPattern '*-onedrive-cleanup-*.log' -NotBefore $started
        $detail | Should -Match 'locked cache file'
        $detail | Should -Not -Match 'stale failure|different operation'
    }

    It 'stays silent when the user has no transcript' {
        $profileRoot = Join-Path $TestDrive 'EmptyProfile'
        New-Item -Path $profileRoot -ItemType Directory -Force | Out-Null
        Mock Get-ItemProperty { [pscustomobject]@{ ProfileImagePath = $profileRoot } }

        Get-AtlasUserFailureDetail -UserSid 'S-1-5-21-1-2-3-1001' -TranscriptPattern '*-new-user-setup-*.log' | Should -BeNullOrEmpty
    }

    It 'never replaces the failure it describes when diagnostics fail' {
        Mock Get-ItemProperty { throw 'profile list unavailable' }

        Get-AtlasUserFailureDetail -UserSid 'S-1-5-21-1-2-3-1001' -TranscriptPattern '*-new-user-setup-*.log' |
            Should -Match 'transcript could not be read: profile list unavailable'
    }
}
