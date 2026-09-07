BeforeAll {
    $script:UsbScript = Join-Path (Split-Path $PSScriptRoot -Parent) 'app\resources\iso\Write-Usb.ps1'
    $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile($script:UsbScript,[ref]$null,[ref]$errors)
    if ($errors) { throw ($errors | Out-String) }
    foreach ($name in @('Get-AtlasUsbIdentity','Test-AtlasUsbDisk','Assert-AtlasUsbIdentity','Assert-AtlasUsbPaths','Assert-AtlasUsbContinue','Copy-AtlasUsbFile','Get-AtlasUsbParentPath','Assert-AtlasUsbVolume','Get-AtlasUsbVolumeId','Get-AtlasUsbTargetRoot','Format-AtlasUsb','Get-AtlasUsbEjectTarget')) {
        $node = $ast.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true)
        . ([scriptblock]::Create($node.Extent.Text))
    }
}

Describe 'USB formatting interruption boundaries' {
    BeforeEach {
        $script:Operations = [Collections.Generic.List[string]]::new()
        $script:StopAfter = ''
        $script:ReplaceAfter = ''
        Mock Assert-AtlasUsbContinue {
            if ($script:StopAfter -and $script:Operations.Contains($script:StopAfter)) {
                throw [OperationCanceledException]::new('cancelled')
            }
        }
        Mock Assert-AtlasUsbIdentity {
            if ($script:ReplaceAfter -and $script:Operations.Contains($script:ReplaceAfter)) {
                throw 'The USB drive changed.'
            }
            [Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_Disk', 'root/Microsoft/Windows/Storage')
        }
        Mock Clear-Disk { $script:Operations.Add('clear') }
        Mock Initialize-Disk { $script:Operations.Add('initialize') }
        Mock New-Partition {
            $script:Operations.Add('partition')
            [Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_Partition', 'root/Microsoft/Windows/Storage')
        }
        Mock Format-Volume { $script:Operations.Add('format'); [pscustomobject]@{DriveLetter='Z'} }
    }
    It 'formats only after clearing, initializing and partitioning the confirmed device' {
        (Format-AtlasUsb ([pscustomobject]@{number=42}) 16GB).DriveLetter | Should -Be 'Z'
        ($script:Operations -join ',') | Should -Be 'clear,initialize,partition,format'
        Should -Invoke Assert-AtlasUsbIdentity -Times 4 -Exactly
    }
    It 'starts no further destructive operation after cancellation at <After>' -ForEach @(
        @{After='clear'; Expected='clear'},
        @{After='initialize'; Expected='clear,initialize'},
        @{After='partition'; Expected='clear,initialize,partition'}
    ) {
        $script:StopAfter = $After
        { Format-AtlasUsb ([pscustomobject]@{number=42}) 16GB } | Should -Throw '*cancelled*'
        ($script:Operations -join ',') | Should -Be $Expected
        Should -Invoke Format-Volume -Times 0 -Exactly
    }
    It 'starts no further destructive operation after replacement at <After>' -ForEach @(
        @{After='clear'; Expected='clear'},
        @{After='initialize'; Expected='clear,initialize'},
        @{After='partition'; Expected='clear,initialize,partition'}
    ) {
        $script:ReplaceAfter = $After
        { Format-AtlasUsb ([pscustomobject]@{number=42}) 16GB } | Should -Throw '*changed*'
        ($script:Operations -join ',') | Should -Be $Expected
        Should -Invoke Format-Volume -Times 0 -Exactly
    }
}

Describe 'Safe ejection of USB Attached SCSI storage' {
    BeforeEach {
        $script:UsbParent = 'USB\VID_0951&PID_177F\TEST'
        Mock Get-CimInstance { @([pscustomobject]@{Index=42;PNPDeviceID='SCSI\DISK\USB'},[pscustomobject]@{Index=0;PNPDeviceID='SCSI\DISK\SYSTEM'}) }
        Mock Get-PnpDeviceProperty {
            param($InstanceId,$KeyName)
            if ($KeyName -eq 'DEVPKEY_Device_Service') { return [pscustomobject]@{Data='UASPStor'} }
            if ($InstanceId -eq 'SCSI\DISK\USB') { return [pscustomobject]@{Data=$script:UsbParent} }
            return [pscustomobject]@{Data='PCI\CONTROLLER'}
        }
    }
    It 'selects the physical USB device rather than its non-removable SCSI child' {
        Get-AtlasUsbEjectTarget ([pscustomobject]@{Number=42}) | Should -Be $script:UsbParent
    }
    It 'never climbs to a hub or PCI controller' {
        $script:UsbParent='USB\ROOT_HUB30\HOST'
        { Get-AtlasUsbEjectTarget ([pscustomobject]@{Number=42}) } | Should -Throw '*No removable*'
    }
    It 'refuses a parent that would eject another disk too' {
        Mock Get-PnpDeviceProperty {
            param($InstanceId,$KeyName)
            if ($KeyName -eq 'DEVPKEY_Device_Service') { return [pscustomobject]@{Data='UASPStor'} }
            if ($InstanceId -notin @('SCSI\DISK\USB', 'SCSI\DISK\SYSTEM')) { throw 'Unexpected test device.' }
            return [pscustomobject]@{Data=$script:UsbParent}
        }
        { Get-AtlasUsbEjectTarget ([pscustomobject]@{Number=42}) } | Should -Throw '*Another disk*'
    }
}

Describe 'USB destination safety' {
    It 'keeps the copy target bound to a volume when its drive letter changes' {
        $volume = [pscustomobject]@{ DriveLetter='Z'; UniqueId='\\?\Volume{12345678-1234-1234-1234-123456789abc}\' }
        $target = Get-AtlasUsbTargetRoot $volume
        $volume.DriveLetter = 'Y'
        Get-AtlasUsbTargetRoot $volume | Should -Be $target
        $target | Should -Be $volume.UniqueId
    }
    It 'rejects a mutable drive-letter or malformed target path' -ForEach @('Z:\', '', '\\?\Volume{invalid}\') {
        { Get-AtlasUsbTargetRoot ([pscustomobject]@{UniqueId=$_}) } | Should -Throw '*stable USB volume*'
    }
    BeforeEach {
        $script:Disk = [pscustomobject]@{ Number=42; FriendlyName='Test USB'; SerialNumber='SERIAL-A'; UniqueId='USB-A'; Path='DEVICE-A'; Size=64GB; BusType='USB'; IsBoot=$false; IsSystem=$false; IsReadOnly=$false; IsOffline=$false }
        Mock Get-Disk { $script:Disk }
        Mock Get-Partition { @() }
        $script:Expected = Get-AtlasUsbIdentity $script:Disk
    }
    It 'accepts the same eligible USB and retains its identity' {
        (Assert-AtlasUsbIdentity $script:Expected).Number | Should -Be 42
    }
    It 'rejects a replacement reusing the same disk number' -ForEach @('SerialNumber','UniqueId','Path','FriendlyName') {
        $script:Disk.$_ = 'REPLACEMENT'
        { Assert-AtlasUsbIdentity $script:Expected } | Should -Throw '*changed*'
    }
    It 'rejects a resized or differently reported device' {
        $script:Disk.Size = 128GB
        { Assert-AtlasUsbIdentity $script:Expected } | Should -Throw '*changed*'
    }
    It 'rejects boot, system, read-only and offline disks' -ForEach @('IsBoot','IsSystem','IsReadOnly','IsOffline') {
        $script:Disk.$_ = $true
        { Assert-AtlasUsbIdentity $script:Expected } | Should -Throw '*eligible*'
    }
    It 'rejects internal disks, missing identifiers and unsupported capacities' {
        $script:Disk.BusType = 'NVMe'
        Test-AtlasUsbDisk $script:Disk | Should -BeFalse
        $script:Disk.BusType = 'USB'
        $script:Disk.UniqueId = ''
        Test-AtlasUsbDisk $script:Disk | Should -BeFalse
        $script:Disk.UniqueId = 'USB-A'
        $script:Disk.Size = 4GB
        Test-AtlasUsbDisk $script:Disk | Should -BeFalse
        $script:Disk.Size = 3TB
        Test-AtlasUsbDisk $script:Disk | Should -BeFalse
    }
    It 'fails closed if the USB disappears' {
        Mock Get-Disk { throw 'Device disconnected' }
        { Assert-AtlasUsbIdentity $script:Expected } | Should -Throw '*disconnected*'
    }
    It 'rejects a reused drive letter even when the original USB is still connected' {
        $volume = [pscustomobject]@{ DriveLetter='Z'; UniqueId='VOLUME-A' }
        Mock Get-AtlasUsbVolumeId { 'VOLUME-B' }
        Mock Assert-AtlasUsbIdentity { $script:Disk }
        { Assert-AtlasUsbVolume $script:Expected $volume } | Should -Throw '*volume changed*'
        Mock Get-AtlasUsbVolumeId { 'VOLUME-A' }
        { Assert-AtlasUsbVolume $script:Expected $volume } | Should -Not -Throw
    }
    It 'refuses a source or working file stored on the target disk' {
        $file = Join-Path $TestDrive 'source.iso'
        Set-Content -LiteralPath $file -Value 'data'
        Mock Get-Partition { [pscustomobject]@{ DiskNumber=42 } }
        { Assert-AtlasUsbPaths $script:Disk @($file) } | Should -Throw '*Move them*'
        Mock Get-Partition { [pscustomobject]@{ DiskNumber=7 } }
        { Assert-AtlasUsbPaths $script:Disk @($file) } | Should -Not -Throw
    }
}

Describe 'USB file copy cancellation and existing data' {
    It 'preserves the required separator for files directly on a volume GUID root' {
        $root = '\\?\Volume{12345678-1234-1234-1234-123456789abc}\'
        Get-AtlasUsbParentPath ($root + 'bootmgr') | Should -Be $root
        Get-AtlasUsbParentPath ($root + 'sources\boot.wim') | Should -Be ($root + 'sources\')
    }
    BeforeEach {
        Mock Assert-AtlasUsbContinue { }
        $script:Source = Join-Path $TestDrive 'source.bin'
        $script:Destination = Join-Path $TestDrive 'copied.bin'
        [IO.File]::WriteAllBytes($script:Source,(New-Object byte[] (9MB)))
        if (Test-Path -LiteralPath $script:Destination) { Remove-Item -LiteralPath $script:Destination }
    }
    It 'copies every byte and flushes a verifiable file' {
        Copy-AtlasUsbFile $script:Source $script:Destination
        (Get-FileHash $script:Destination).Hash | Should -Be (Get-FileHash $script:Source).Hash
    }
    It 'does not overwrite an unexpected existing destination file' {
        Set-Content -LiteralPath $script:Destination -Value 'keep'
        { Copy-AtlasUsbFile $script:Source $script:Destination } | Should -Throw
        (Get-Content $script:Destination -Raw).Trim() | Should -Be 'keep'
    }
    It 'interrupts a large copy and releases the destination handle' {
        Mock Assert-AtlasUsbContinue { throw [OperationCanceledException]::new('cancel') }
        { Copy-AtlasUsbFile $script:Source $script:Destination } | Should -Throw '*cancel*'
        { Remove-Item -LiteralPath $script:Destination -ErrorAction Stop } | Should -Not -Throw
    }
}
