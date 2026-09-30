BeforeDiscovery {
    $cultureMap = @{
        'de' = 'de-DE'; 'en-GB' = 'en-GB'; 'en-US' = 'en-US'; 'es' = 'es-ES'; 'fr' = 'fr-FR'
        'hi' = 'hi-IN'; 'id' = 'id-ID'; 'ja' = 'ja-JP'; 'pl' = 'pl-PL'; 'pt-BR' = 'pt-BR'
        'ru' = 'ru-RU'; 'th' = 'th-TH'; 'tr' = 'tr-TR'; 'zh-Hans' = 'zh-CN'; 'zh-Hant' = 'zh-TW'
    }
    $cultures = @(foreach ($directory in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot '..\app\i18n') -Directory) {
        if (-not $cultureMap.ContainsKey($directory.Name)) { throw "No culture test for locale '$($directory.Name)'." }
        @{ Locale = $directory.Name; Culture = $cultureMap[$directory.Name] }
    })
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
            foreach ($culture in $cultures) {
                @{
                    Location = $file.Name + ':' + $attribute.Extent.StartLineNumber
                    Attribute = $attribute.Extent.Text
                    Valid = $valid
                    Invalid = $valid.Replace('I', [string][char]0x0130).Replace('i', [string][char]0x0130)
                    Culture = $culture.Culture
                }
            }
        }
    })
}

Describe 'ASCII identifier parameter binding' {
    It 'accepts ASCII and rejects non-ASCII at <Location> under <Culture>' -TestCases $script:IdentifierCases {
        param($Attribute, $Valid, $Invalid, $Culture)
        # Exercise the production parameter attribute without running its privileged operation.
        $binding = [scriptblock]::Create('param(' + $Attribute + '[string]$Name) $Name')
        $invalidValue = [string]$Invalid
        $dotlessValue = $Valid.Replace('I', [string][char]0x0131).Replace('i', [string][char]0x0131)
        $previous = [Threading.Thread]::CurrentThread.CurrentCulture
        try {
            [Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::GetCultureInfo($Culture)
            (& $binding -Name $Valid) | Should -BeExactly $Valid
            { & $binding -Name $invalidValue } | Should -Throw
            { & $binding -Name $dotlessValue } | Should -Throw
            { & $binding -Name 'bad//name' } | Should -Throw
        }
        finally { [Threading.Thread]::CurrentThread.CurrentCulture = $previous }
    }
}

BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    foreach ($name in @('Atlas.State', 'Atlas.InstallState', 'Atlas.Toggles', 'Atlas.Tweaks', 'Atlas.Search')) {
        Import-Module (Join-Path $script:AtlasTestModulesRoot "$name\$name.psd1") -Force
    }
    $script:ToggleRoot = Join-Path $script:AtlasTestScriptsRoot '..\Toggles'
    $script:TweakRoot = Join-Path $script:AtlasTestScriptsRoot 'Tweaks'
    $script:ToggleNames = @(Get-ChildItem -LiteralPath $script:ToggleRoot -Recurse -Filter '*.psd1' -File | Select-Object -ExpandProperty BaseName)
}

Describe 'Payload data across supported languages' {
    It 'loads definitions and persists toggle records in <Locale> (<Culture>)' -TestCases $cultures {
        param($Locale, $Culture)
        $previous = [Threading.Thread]::CurrentThread.CurrentCulture
        try {
            [Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::GetCultureInfo($Culture)
            $path = Join-Path $TestDrive "$Locale\state.json"
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
        finally { [Threading.Thread]::CurrentThread.CurrentCulture = $previous }
    }

    It 'accepts every ASCII drive letter and Unicode folder names in <Locale> (<Culture>)' -TestCases $cultures {
        param($Culture)
        $previous = [Threading.Thread]::CurrentThread.CurrentCulture
        try {
            [Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::GetCultureInfo($Culture)
            foreach ($letter in @(65..90) + @(97..122)) {
                $path = [string][char]$letter + ':\Users\' + [char]0x0130 + 'pek\Desktop'
                (& (Get-Module Atlas.Search) { param($candidate) ConvertTo-AtlasIndexPath -Candidate $candidate } $path) |
                    Should -BeExactly ([IO.Path]::GetFullPath($path))
            }
            { & (Get-Module Atlas.Search) { ConvertTo-AtlasIndexPath -Candidate ([string][char]0x0130 + ':\Users') } } | Should -Throw
        }
        finally { [Threading.Thread]::CurrentThread.CurrentCulture = $previous }
    }
}
