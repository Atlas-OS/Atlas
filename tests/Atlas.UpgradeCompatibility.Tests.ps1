[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter',
    '',
    Justification = 'Pester test-case parameters are consumed inside mock script blocks.'
)]
param()

BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Privacy\Atlas.Privacy.psd1') -Force
    $script:featureUpdateScript = Join-Path $script:AtlasTestScriptsRoot 'Tweaks\qol\windows-update\disable-feature-updates.ps1'
    . (Join-Path $script:AtlasTestScriptsRoot 'Preparation\WindowsTransition.ps1')
}

Describe 'Location recovery when offline maps are unsupported' {
    BeforeEach {
        Mock Set-Service -ModuleName Atlas.Privacy {}
        Mock Write-AtlasLog -ModuleName Atlas.Privacy {}
        Mock Get-CimInstance -ModuleName Atlas.Privacy {
            [pscustomobject]@{ State = 'Stopped'; ExitCode = 50 }
        }
        Mock Get-AtlasLocationServiceController -ModuleName Atlas.Privacy {
            $controller = [pscustomobject]@{ Status = [System.ServiceProcess.ServiceControllerStatus]::Stopped }
            $controller | Add-Member ScriptMethod Refresh {}
            $controller | Add-Member ScriptMethod Start {}
            $controller | Add-Member ScriptMethod Stop {}
            $controller | Add-Member ScriptMethod WaitForStatus { throw 'service transition timed out' }
            $controller | Add-Member ScriptMethod Dispose {}
            return $controller
        }
    }

    It 'warns and continues only when stopped MapsBroker reports ERROR_NOT_SUPPORTED' {
        InModuleScope Atlas.Privacy {
            { Invoke-AtlasLocationServiceState -Name MapsBroker -StartupType 2 -Status Running } | Should -Not -Throw
            Should -Invoke Get-CimInstance -Times 1 -Exactly -ParameterFilter {
                $ClassName -eq 'Win32_Service' -and $Filter -eq "Name='MapsBroker'"
            }
            Should -Invoke Write-AtlasLog -Times 1 -Exactly -ParameterFilter {
                $Level -eq 'Warning' -and $Message -like '*error 50*'
            }
        }
    }

    It 'keeps other MapsBroker failures fatal: <State>, <Code>' -TestCases @(
        @{ State = 'Stopped'; Code = 5 }
        @{ State = 'Start Pending'; Code = 50 }
    ) {
        param($State, $Code)
        Mock Get-CimInstance -ModuleName Atlas.Privacy {
            [pscustomobject]@{ State = $State; ExitCode = $Code }
        }
        InModuleScope Atlas.Privacy {
            { Invoke-AtlasLocationServiceState -Name MapsBroker -StartupType 2 -Status Running } | Should -Throw '*service transition timed out*'
            Should -Invoke Write-AtlasLog -Times 0
        }
    }

    It 'does not hide a geolocation service failure' {
        InModuleScope Atlas.Privacy {
            { Invoke-AtlasLocationServiceState -Name lfsvc -StartupType 3 -Status Running } | Should -Throw '*service transition timed out*'
            Should -Invoke Get-CimInstance -Times 0
        }
    }
}

Describe 'Feature-update targeting on localized Windows' {
    BeforeEach {
        Mock Get-ItemProperty { [pscustomobject]@{ DisplayVersion = '26H2' } }
        Mock Set-AtlasFeatureUpdateTarget {}
    }

    It 'pins the release for <Case>' -TestCases @(
        @{ Case = 'English Windows 11'; Caption = 'Microsoft Windows 11 Education' }
        @{ Case = 'French Windows 11 with a nonbreaking space'; Caption = "Microsoft Windows$([char]0xA0)11 Education" }
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
