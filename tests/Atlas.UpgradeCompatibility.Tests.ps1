[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter',
    '',
    Justification = 'Pester test-case parameters are consumed inside mock script blocks.'
)]
param()

BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:featureUpdateScript = Join-Path $script:AtlasTestScriptsRoot 'Tweaks\qol\windows-update\disable-feature-updates.ps1'
    . (Join-Path $script:AtlasTestScriptsRoot 'Preparation\WindowsTransition.ps1')
}

Describe 'Feature-update targeting on localized Windows' {
    BeforeEach {
        Mock Get-ItemProperty { [pscustomobject]@{ DisplayVersion = '26H2' } }
        Mock Set-AtlasFeatureUpdateTarget {}
    }

    It 'pins the release for <Case>' -TestCases @(
        @{ Case = 'English Windows 11'; Caption = 'Microsoft Windows 11 Education' }
        @{ Case = 'French Windows 11 with a nonbreaking space'; Caption = "Microsoft Windows$([char]0xA0)11 $([char]0xC9)ducation" }
    ) {
        param($Case, $Caption)
        [void]$Case
        Mock Get-CimInstance { [pscustomobject]@{ Caption = $Caption } }
        & $script:featureUpdateScript
        Should -Invoke Set-AtlasFeatureUpdateTarget -Times 1 -Exactly -ParameterFilter { $Release -eq '26H2' }
    }

    It 'still refuses Windows 10 before writing the update policy' {
        Mock Get-CimInstance { [pscustomobject]@{ Caption = 'Microsoft Windows 10 Education' } }
        { & $script:featureUpdateScript } | Should -Throw '*is not Windows 11*'
        Should -Invoke Set-AtlasFeatureUpdateTarget -Times 0
        Should -Invoke Get-ItemProperty -Times 0
    }
}
