BeforeDiscovery {
    $root = Join-Path $PSScriptRoot '..\playbook\Executables\AtlasModules\Scripts'
    $script:IdentifierCases = @(foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object Extension -in @('.ps1', '.psm1')) {
        $ast = [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$null)
        foreach ($attribute in $ast.FindAll({
                param($node)
                $node -is [Management.Automation.Language.AttributeAst] -and
                    $node.TypeName.FullName -eq 'ValidatePattern' -and
                    ($node.Extent.Text.Contains('[A-Za-z') -or $node.Extent.Text.Contains('[a-z0-9'))
            }, $true)) {
            $moduleName = $attribute.Extent.Text.Contains('^Atlas\.')
            $lowercase = $attribute.Extent.Text.Contains('[a-z0-9')
            $valid = if ($moduleName) { 'Atlas.InstallState' } elseif ($lowercase) {
                if ($attribute.Extent.Text.Contains('(/[a-z')) { 'testing/indexing' } else { 'indexing' }
            } else { 'Indexing' }
            @{
                Location = $file.Name + ':' + $attribute.Extent.StartLineNumber
                Attribute = $attribute.Extent.Text
                Valid = $valid
            }
        }
    })

    # Each culture breaks a different assumption: Turkish casing, the Thai Buddhist
    # calendar and comma decimals.
    $script:Cultures = @(
        @{ Culture = 'tr-TR' }
        @{ Culture = 'th-TH' }
        @{ Culture = 'de-DE' }
    )
}

BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    foreach ($name in @('Atlas.State', 'Atlas.InstallState', 'Atlas.Toggles', 'Atlas.Tweaks', 'Atlas.Search')) {
        Import-Module (Join-Path $script:AtlasTestModulesRoot "$name\$name.psd1") -Force
    }
    $script:ToggleRoot = Join-Path $script:AtlasTestScriptsRoot '..\Toggles'
    $script:TweakRoot = Join-Path $script:AtlasTestScriptsRoot 'Tweaks'
    $script:ToggleNames = @(Get-ChildItem -LiteralPath $script:ToggleRoot -Recurse -Filter '*.psd1' -File | Select-Object -ExpandProperty BaseName)

    function Use-Culture {
        param([Parameter(Mandatory = $true)][string]$Name, [Parameter(Mandatory = $true)][scriptblock]$Action)
        $previous = [Threading.Thread]::CurrentThread.CurrentCulture
        try {
            [Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::GetCultureInfo($Name)
            & $Action
        }
        finally { [Threading.Thread]::CurrentThread.CurrentCulture = $previous }
    }
}

Describe 'ASCII identifier parameter binding' {
    It 'accepts ASCII and rejects non-ASCII at <Location>' -TestCases $script:IdentifierCases {
        param($Attribute, $Valid)
        # Exercise the production parameter attribute without running its privileged operation.
        # Case-insensitive matching would let the Turkish dotted I and the Kelvin sign
        # pass for ASCII letters.
        $binding = [scriptblock]::Create('param(' + $Attribute + '[string]$Name) $Name')
        $dotted = $Valid.Replace('I', [string][char]0x0130).Replace('i', [string][char]0x0130)
        $dotless = $Valid.Replace('I', [string][char]0x0131).Replace('i', [string][char]0x0131)
        $kelvin = $Valid + [char]0x212A
        Use-Culture tr-TR {
            (& $binding -Name $Valid) | Should -BeExactly $Valid
            { & $binding -Name $dotted } | Should -Throw
            { & $binding -Name $dotless } | Should -Throw
            { & $binding -Name $kelvin } | Should -Throw
            { & $binding -Name 'bad//name' } | Should -Throw
        }
    }
}

Describe 'Atlas data under other cultures' {
    It 'loads definitions and persists toggle records under <Culture>' -TestCases $script:Cultures {
        param($Culture)
        Use-Culture $Culture {
            $path = Join-Path $TestDrive "$Culture\state.json"
            foreach ($name in $script:ToggleNames) {
                $definition = Get-AtlasToggleDefinition -Name $name -TogglesRoot $script:ToggleRoot
                $definition['Name'] | Should -BeExactly $name
                Set-AtlasStateToggle -Name $name -State 1 -Path $path | Out-Null
            }
            @((Get-AtlasState -Path $path).toggles.PSObject.Properties.Name).Count | Should -Be $script:ToggleNames.Count
            @(Test-AtlasToggleDefinition -Path $script:ToggleRoot).Count | Should -Be 0
            @(Test-AtlasTweakManifest -Path (Join-Path $script:TweakRoot 'tweaks.manifest.psd1')).Count | Should -Be 0
            @(Get-AtlasPlaybookOption -PlaybookPath (Join-Path $script:AtlasTestRepoRoot 'playbook\playbook.conf')).Count | Should -BeGreaterThan 0
        }
    }

    It 'accepts every ASCII drive letter with Unicode folder names and rejects a dotted-I drive' {
        Use-Culture tr-TR {
            foreach ($letter in @(65..90) + @(97..122)) {
                $path = [string][char]$letter + ':\Users\' + [char]0x0130 + 'pek\Desktop'
                (& (Get-Module Atlas.Search) { param($candidate) ConvertTo-AtlasIndexPath -Candidate $candidate } $path) |
                    Should -BeExactly ([IO.Path]::GetFullPath($path))
            }
            { & (Get-Module Atlas.Search) { ConvertTo-AtlasIndexPath -Candidate ([string][char]0x0130 + ':\Users') } } | Should -Throw
        }
    }
}
