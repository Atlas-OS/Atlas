BeforeDiscovery {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Registry\Atlas.Registry.psd1') -Force
}
Describe 'Partial preference updates' {
    InModuleScope Atlas.Registry {
        BeforeEach {
            Mock Get-AtlasRegistryValueState { [pscustomobject]@{ ValueExists=$true; Kind='Binary'; Data=[byte[]]@(255,255,255,255,255,255,255,255) } }
            Mock Set-AtlasRegistryValue {}
        }
        It 'retains every bit outside the animation selection on apply and verification' {
            $entry=@{ Path='HKCU:\Control Panel\Desktop'; Name='UserPreferencesMask'; Type='Binary'; Data=@(0x90,0x12,3,0x80,0x10,0,0,0); Mask=@(14,12,4,0,2,0,0,0) }
            Invoke-AtlasRegistryEntries -Entries @($entry) -IsArm64 $false
            Should -Invoke Set-AtlasRegistryValue -Times 1 -Exactly -ParameterFilter { ($Data -join ',') -eq '241,243,251,255,253,255,255,255' }
            Mock Get-AtlasRegistryValueState { [pscustomobject]@{ ValueExists=$true; Kind='Binary'; Data=[byte[]]@(241,243,251,255,253,255,255,255) } }
            @(Test-AtlasRegistryEntries -Entries @($entry) -IsArm64 $false).Count | Should -Be 0
        }
        It 'keeps an enabled accessibility feature while clearing only its shortcut' {
            $entry=@{ Path='HKCU:\Control Panel\Accessibility\StickyKeys'; Name='Flags'; Type='String'; Data='506'; Mask='4' }
            Mock Get-AtlasRegistryValueState { [pscustomobject]@{ ValueExists=$true; Kind='String'; Data='511' } }
            Invoke-AtlasRegistryEntries -Entries @($entry) -IsArm64 $false
            Should -Invoke Set-AtlasRegistryValue -Times 1 -Exactly -ParameterFilter { $Data -ceq '507' -and $Type -eq 'String' }
        }
        It 'converts explicitly declared legacy DWORD flags without resetting other bits' {
            $entry=@{ Path='HKCU:\Control Panel\Accessibility\StickyKeys'; Name='Flags'; Type='String'; Data='506'; Mask='4'; MigrateDwordToString=$true }
            Mock Get-AtlasRegistryValueState { [pscustomobject]@{ ValueExists=$true; Kind='DWord'; Data=511 } }
            Invoke-AtlasRegistryEntries -Entries @($entry) -IsArm64 $false
            Should -Invoke Set-AtlasRegistryValue -Times 1 -Exactly -ParameterFilter { $Data -ceq '507' -and $Type -eq 'String' }
        }
        It 'preserves the high bit when migrating a signed DWORD' {
            $entry=@{ Path='HKCU:\Control Panel\Accessibility\StickyKeys'; Name='Flags'; Type='String'; Data='506'; Mask='4'; MigrateDwordToString=$true }
            Mock Get-AtlasRegistryValueState { [pscustomobject]@{ ValueExists=$true; Kind='DWord'; Data=-1 } }
            Invoke-AtlasRegistryEntries -Entries @($entry) -IsArm64 $false
            Should -Invoke Set-AtlasRegistryValue -Times 1 -Exactly -ParameterFilter { $Data -ceq '4294967291' -and $Type -eq 'String' }
        }
        It 'rejects DWORD flags without explicit migration permission' {
            $entry=@{ Path='HKCU:\Control Panel\Accessibility\StickyKeys'; Name='Flags'; Type='String'; Data='506'; Mask='4' }
            Mock Get-AtlasRegistryValueState { [pscustomobject]@{ ValueExists=$true; Kind='DWord'; Data=0 } }
            { Invoke-AtlasRegistryEntries -Entries @($entry) -IsArm64 $false } | Should -Throw '*unexpected registry kind*'
            Should -Not -Invoke Set-AtlasRegistryValue
        }
        It 'fails before writing an unfamiliar binary layout' {
            $entry=@{ Path='HKCU:\Control Panel\Desktop'; Name='UserPreferencesMask'; Type='Binary'; Data=@(0,0); Mask=@(4,0) }
            { Invoke-AtlasRegistryEntries -Entries @($entry) -IsArm64 $false } | Should -Throw '*unexpected length*'
            Should -Not -Invoke Set-AtlasRegistryValue
        }
        It 'uses the declared fallback only for an absent value' {
            $entry=@{ Type='String'; Data='506'; Mask='4' }
            Merge-AtlasRegistryMaskedData -Entry $entry -Current $null | Should -BeExactly '506'
        }
    }
}
