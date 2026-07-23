[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter',
    '',
    Justification = 'The feature-update harness stubs declare the parameter surface of the commands they shadow.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidOverwritingBuiltInCmdlets',
    '',
    Justification = 'The harness shadows registry and CIM cmdlets only while executing the task script under test.'
)]
param()

BeforeAll {
    $script:targetScript = Join-Path -Path $PSScriptRoot -ChildPath `
        '..\playbook\Executables\AtlasModules\Scripts\Tasks\Set-FeatureUpdateTarget.ps1'
    $script:policyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'

    # Execution doubles: the script targets live HKLM policy state, which the tests
    # must never touch.
    function Reset-FeatureUpdateRecording {
        $script:OsCaption = 'Microsoft Windows 11 Pro'
        $script:DisplayVersion = '24H2'
        $script:PolicyKeyExists = $true
        $script:RegistryWriteError = $null
        $script:CreatedKeys = [Collections.Generic.List[string]]::new()
        $script:ValueWrites = [Collections.Generic.List[pscustomobject]]::new()
    }

    function Get-CimInstance {
        param($ClassName, $ErrorAction)
        return [pscustomobject]@{ Caption = $script:OsCaption }
    }
    function Test-Path {
        param($LiteralPath, $Path, $PathType)
        return $script:PolicyKeyExists
    }
    function New-Item {
        param($Path, $ItemType, [switch]$Force)
        $script:CreatedKeys.Add([string]$Path)
        return $null
    }
    function Get-ItemProperty {
        param($Path, $LiteralPath, $Name, $ErrorAction)
        return [pscustomobject]@{ DisplayVersion = $script:DisplayVersion }
    }
    function New-ItemProperty {
        param($Path, $LiteralPath, $Name, $Value, $PropertyType, [switch]$Force)
        if ($null -ne $script:RegistryWriteError) {
            throw $script:RegistryWriteError
        }
        $script:ValueWrites.Add([pscustomobject]@{
                Path         = if ($LiteralPath) { $LiteralPath } else { $Path }
                Name         = $Name
                Value        = $Value
                PropertyType = $PropertyType
            })
        return $null
    }

    function Invoke-FeatureUpdateTarget {
        # Dot-source so the recording doubles observe this test file's script scope.
        . $script:targetScript
    }
}

AfterAll {
    foreach ($shadow in @(
            'Get-CimInstance', 'Test-Path', 'New-Item', 'Get-ItemProperty', 'New-ItemProperty'
        )) {
        Microsoft.PowerShell.Management\Remove-Item -LiteralPath "Function:\$shadow" `
            -ErrorAction SilentlyContinue
    }
}

Describe 'Feature update target pinning' {
    BeforeEach {
        Reset-FeatureUpdateRecording
    }

    It 'parses in Windows PowerShell syntax' {
        $tokens = $null
        $errors = $null
        [Management.Automation.Language.Parser]::ParseFile(
            $script:targetScript,
            [ref]$tokens,
            [ref]$errors
        ) | Out-Null

        @($errors) | Should -BeNullOrEmpty
    }

    It 'pins the running feature release through the Windows Update for Business policy values' {
        Invoke-FeatureUpdateTarget

        @($script:ValueWrites).Count | Should -Be 3
        foreach ($write in $script:ValueWrites) {
            $write.Path | Should -BeExactly $script:policyPath
        }

        $enable = @($script:ValueWrites | Where-Object { $_.Name -ceq 'TargetReleaseVersion' })
        $enable.Count | Should -Be 1
        $enable[0].Value | Should -Be 1
        $enable[0].PropertyType | Should -BeExactly 'DWord'

        $product = @($script:ValueWrites | Where-Object { $_.Name -ceq 'ProductVersion' })
        $product.Count | Should -Be 1
        $product[0].Value | Should -BeExactly 'Windows 11'
        $product[0].PropertyType | Should -BeExactly 'String'

        $release = @($script:ValueWrites |
                Where-Object { $_.Name -ceq 'TargetReleaseVersionInfo' })
        $release.Count | Should -Be 1
        $release[0].Value | Should -BeExactly '24H2'
        $release[0].PropertyType | Should -BeExactly 'String'
    }

    It 'never recreates an existing policy key, preserving sibling policy values' {
        Invoke-FeatureUpdateTarget

        @($script:CreatedKeys).Count | Should -Be 0
    }

    It 'creates the policy key only when it is missing' {
        $script:PolicyKeyExists = $false

        Invoke-FeatureUpdateTarget

        @($script:CreatedKeys) | Should -Be @($script:policyPath)
    }

    It 'refuses to pin when the running DisplayVersion is unreadable' {
        $script:DisplayVersion = ''

        { Invoke-FeatureUpdateTarget } | Should -Throw '*DisplayVersion was empty*'
        @($script:ValueWrites).Count | Should -Be 0
    }

    It 'surfaces a failed policy registry write instead of continuing' {
        $script:RegistryWriteError = New-Object Exception 'registry write denied'

        { Invoke-FeatureUpdateTarget } | Should -Throw '*registry write denied*'
    }
}
