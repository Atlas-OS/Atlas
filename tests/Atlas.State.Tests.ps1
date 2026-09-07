BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.State\Atlas.State.psd1') -Force
}

Describe 'Machine state document' {
    BeforeEach {
        $script:DocumentPath = Join-Path $TestDrive 'AtlasOS\state.json'
        Remove-Item -LiteralPath $script:DocumentPath -Force -ErrorAction SilentlyContinue
    }

    It 'is absent until an install completes' {
        Get-AtlasState -Path $script:DocumentPath | Should -BeNullOrEmpty
    }

    It 'records a completed install with its options and appends history on upgrade' {
        $fresh = [pscustomobject]@{
            targetVersion = '0.6.0'; mode = 'Fresh'; isOobe = $false
            options = @('defender-enable', 'browser-brave'); transactionId = '11111111-1111-4111-8111-111111111111'
        }
        Set-AtlasStateInstall -InstallState $fresh -Path $script:DocumentPath | Out-Null

        $document = Get-AtlasState -Path $script:DocumentPath
        $document.installedVersion | Should -Be '0.6.0'
        $document.mode | Should -Be 'Fresh'
        $document.isInteractive | Should -BeTrue
        @($document.options) | Should -Be @('defender-enable', 'browser-brave')
        @($document.history).Count | Should -Be 1

        $upgrade = [pscustomobject]@{
            targetVersion = '0.7.0'; mode = 'Upgrade'; isOobe = $true
            options = @('defender-disable'); transactionId = '22222222-2222-4222-8222-222222222222'
        }
        Set-AtlasStateInstall -InstallState $upgrade -Path $script:DocumentPath | Out-Null

        $document = Get-AtlasState -Path $script:DocumentPath
        $document.installedVersion | Should -Be '0.7.0'
        $document.isOobe | Should -BeTrue
        $document.isInteractive | Should -BeFalse
        @($document.history | ForEach-Object { $_.version }) | Should -Be @('0.6.0', '0.7.0')
    }

    It 'mirrors toggle records and rebuilds the toggle view from the store' {
        Set-AtlasStateToggle -Name 'Bluetooth' -State 0 -Path $script:DocumentPath | Out-Null
        Set-AtlasStateToggle -Name 'Bluetooth' -State 1 -Path $script:DocumentPath | Out-Null
        Set-AtlasStateToggle -Name 'Printing' -State 1 -Path $script:DocumentPath | Out-Null

        $document = Get-AtlasState -Path $script:DocumentPath
        $document.toggles.Bluetooth.state | Should -Be 1
        $document.toggles.Printing.state | Should -Be 1
        $document.installedVersion | Should -BeNullOrEmpty

        Sync-AtlasStateToggles -Records @{ Printing = 0; SuperFetch = 1 } -Path $script:DocumentPath | Out-Null

        $document = Get-AtlasState -Path $script:DocumentPath
        @($document.toggles.PSObject.Properties.Name | Sort-Object) | Should -Be @('Printing', 'SuperFetch')
        $document.toggles.Printing.state | Should -Be 0
    }

    It 'rejects a malformed document instead of trusting it' {
        New-Item -Path (Split-Path $script:DocumentPath) -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath $script:DocumentPath -Value '{"schemaVersion":1,"toggles":{}}'
        { Get-AtlasState -Path $script:DocumentPath } | Should -Throw '*missing*'

        Set-Content -LiteralPath $script:DocumentPath -Value 'not json'
        { Get-AtlasState -Path $script:DocumentPath } | Should -Throw '*malformed*'
    }

    It 'rejects toggle names outside the record grammar' {
        { Set-AtlasStateToggle -Name 'bad name' -State 1 -Path $script:DocumentPath } | Should -Throw
        { Sync-AtlasStateToggles -Records @{ 'bad\name' = 1 } -Path $script:DocumentPath } | Should -Throw '*invalid*'
    }

    It 'replaces the file atomically and leaves no temporary files behind' {
        Set-AtlasStateToggle -Name 'A' -State 1 -Path $script:DocumentPath | Out-Null
        Set-AtlasStateToggle -Name 'B' -State 1 -Path $script:DocumentPath | Out-Null

        @(Get-ChildItem -LiteralPath (Split-Path $script:DocumentPath) -Force | ForEach-Object { $_.Name }) | Should -Be @('state.json')
    }
}
