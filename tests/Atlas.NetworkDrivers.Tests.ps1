BeforeAll {
    . (Join-Path $PSScriptRoot '..\app\resources\iso\Network-Drivers.ps1')
}

Describe 'ISO network driver selection' {
    It 'deduplicates physical adapter packages and excludes unrelated or inbox drivers' {
        Mock Get-NetAdapter { @(
            [pscustomobject]@{ InterfaceType=71; PnPDeviceID='PCI\WIFI' },
            [pscustomobject]@{ InterfaceType=71; PnPDeviceID='PCI\WIFI' },
            [pscustomobject]@{ InterfaceType=6; PnPDeviceID='PCI\LAN' }
        ) }
        Mock Get-CimInstance { @(
            [pscustomobject]@{ DeviceID='PCI\WIFI'; InfName='oem7.inf'; IsSigned=$true; DeviceName='Wi-Fi'; DriverProviderName='Vendor'; DriverVersion='1.2.3' },
            [pscustomobject]@{ DeviceID='PCI\LAN'; InfName='netinbox.inf'; IsSigned=$true },
            [pscustomobject]@{ DeviceID='ROOT\VPN'; InfName='oem8.inf'; IsSigned=$true }
        ) }
        $packages = @(Get-AtlasNetworkPackages)
        $packages.Count | Should -Be 1
        $packages[0].inf | Should -Be 'oem7.inf'
    }
    It 'refuses an unsigned package for the selected hardware' {
        Mock Get-NetAdapter { [pscustomobject]@{ InterfaceType=71; PnPDeviceID='PCI\WIFI' } }
        Mock Get-CimInstance { [pscustomobject]@{ DeviceID='PCI\WIFI'; InfName='oem7.inf'; IsSigned=$false } }
        { Get-AtlasNetworkPackages } | Should -Throw '*unsigned*'
    }
    It 'only accepts Windows Update network drivers matching a physical adapter hardware ID' {
        $ids = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
        [void]$ids.Add('PCI\VEN_1234&DEV_5678')
        Test-AtlasNetworkUpdate ([pscustomobject]@{ Type=2; DriverClass='NET'; DriverHardwareID='pci\ven_1234&dev_5678' }) $ids | Should -BeTrue
        Test-AtlasNetworkUpdate ([pscustomobject]@{ Type=2; DriverClass='NET'; DriverHardwareID='PCI\OTHER' }) $ids | Should -BeFalse
        Test-AtlasNetworkUpdate ([pscustomobject]@{ Type=2; DriverClass='Display'; DriverHardwareID='PCI\VEN_1234&DEV_5678' }) $ids | Should -BeFalse
        Test-AtlasNetworkUpdate ([pscustomobject]@{ Type=1; DriverClass='NET'; DriverHardwareID='PCI\VEN_1234&DEV_5678' }) $ids | Should -BeFalse
    }
    It 'does not silently claim an empty installed-driver backup succeeded' {
        Mock Get-AtlasNetworkPackages { @() }
        { Export-AtlasNetworkDrivers -Destination $TestDrive -CancelFile (Join-Path $TestDrive 'cancel') -LogPath (Join-Path $TestDrive 'log') } | Should -Throw '*No installed*'
    }
    It 'checks cancellation before starting a package export' {
        Mock Get-AtlasNetworkPackages { [pscustomobject]@{ inf='oem7.inf' } }
        New-Item -Path (Join-Path $TestDrive 'cancel') -ItemType File | Out-Null
        { Export-AtlasNetworkDrivers -Destination $TestDrive -CancelFile (Join-Path $TestDrive 'cancel') -LogPath (Join-Path $TestDrive 'log') } | Should -Throw '*cancelled*'
    }
    It 'downloads and copies a matching update without creating an installer' {
        Mock Assert-AtlasNetworkDownloadConnection { }
        Mock Test-Path { $false } -ParameterFilter { $LiteralPath -like '*cancel*' }
        Mock Get-AtlasNetworkHardwareIds {
            $ids = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
            [void]$ids.Add('PCI\WIFI')
            return ,$ids
        }
        $script:downloadCalled = $false
        $script:offered = [pscustomobject]@{ Type=2; DriverClass='NET'; DriverHardwareID='PCI\WIFI'; EulaAccepted=$true; MaxDownloadSize=1024; Title='Wi-Fi update'; Identity=[pscustomobject]@{ UpdateID='test-update' } }
        $script:offered | Add-Member ScriptMethod CopyFromCache { param($folder,$extract) $extract | Should -BeTrue; Set-Content (Join-Path $folder 'driver.inf') 'test'; Set-Content (Join-Path $folder 'driver.cat') 'test' }
        $script:collection = [pscustomobject]@{ Count=0; Update=$null }
        $script:collection | Add-Member ScriptMethod Add { param($update) $this.Update=$update; $this.Count=1; return 0 }
        $script:collection | Add-Member ScriptMethod Item { param($index) $index | Should -Be 0; return $this.Update }
        $script:searcher = [pscustomobject]@{ Online=$false; ServerSelection=0 }
        $script:searcher | Add-Member ScriptMethod Search { param($query) $query | Should -Be "IsInstalled=0 and IsHidden=0 and Type='Driver'"; return [pscustomobject]@{ ResultCode=2; Updates=@($script:offered) } }
        $script:downloader = [pscustomobject]@{ Updates=$null }
        $script:downloader | Add-Member ScriptMethod Download { $script:downloadCalled=$true; return [pscustomobject]@{ ResultCode=2 } }
        $script:session = [pscustomobject]@{ ClientApplicationID='' }
        $script:session | Add-Member ScriptMethod CreateUpdateSearcher { return $script:searcher }
        $script:session | Add-Member ScriptMethod CreateUpdateDownloader { return $script:downloader }
        Mock New-Object { $script:session } -ParameterFilter { $ComObject -eq 'Microsoft.Update.Session' }
        Mock New-Object { $script:collection } -ParameterFilter { $ComObject -eq 'Microsoft.Update.UpdateColl' }
        $report = @(Export-AtlasNetworkUpdates -Destination $TestDrive -CancelFile (Join-Path $TestDrive 'cancel') -LogPath (Join-Path $TestDrive 'log'))
        $script:downloadCalled | Should -BeTrue
        $report.Count | Should -Be 1
        $report[0].source | Should -Be 'windows-update'
        Test-Path (Join-Path $TestDrive 'windows-update-0\driver.inf') | Should -BeTrue
    }
}
