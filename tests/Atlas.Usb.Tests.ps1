BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:UsbScript = Join-Path (Split-Path $PSScriptRoot -Parent) 'app\resources\iso\Write-Usb.ps1'
    $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile($script:UsbScript,[ref]$null,[ref]$errors)
    if ($errors) { throw ($errors | Out-String) }
    foreach ($name in @('Fail','Read-AtlasUsbRequest','Get-AtlasUsbIdentity','Test-AtlasUsbDisk','Assert-AtlasUsbIdentity','Assert-AtlasUsbPaths','Assert-AtlasUsbContinue','Write-AtlasUsbProgress','Copy-AtlasUsbFile','Get-AtlasUsbDeviceHash','Test-AtlasUsbCopy','Get-AtlasUsbParentPath','Assert-AtlasUsbVolume','Get-AtlasUsbVolumeId','Get-AtlasUsbTargetRoot','Format-AtlasUsb','Get-AtlasUsbEjectTarget','Get-AtlasUsbMediaInfo')) {
        $node = $ast.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true)
        . ([scriptblock]::Create($node.Extent.Text))
    }
}

Describe 'USB media architecture validation before erasing' {
    BeforeEach {
        $script:MediaRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $MediaRoot 'sources'),(Join-Path $MediaRoot 'efi\boot') -Force | Out-Null
        foreach ($file in @('setup.exe','sources\boot.wim','sources\install.wim','efi\boot\bootx64.efi','efi\boot\bootaa64.efi')) { Set-Content -LiteralPath (Join-Path $MediaRoot $file) 'fixture' }
        $script:MediaImages = @([pscustomobject]@{ImageIndex=1;Architecture=9;Version='10.0.26200.8037';InstallationType='Client'})
        Mock Get-WindowsImage {
            param($Index)
            if ($Index) { $script:MediaImages | Where-Object ImageIndex -eq $Index } else { $script:MediaImages }
        }
        # The reason is what the app shows; the message only reaches the log.
        Mock Fail { throw "$Reason|$Message" }
    }
    It 'uses the matching UEFI loader for architecture <Architecture>' -ForEach @(
        @{Architecture=9; OtherLoader='bootaa64.efi'}, @{Architecture=12; OtherLoader='bootx64.efi'}
    ) {
        $script:MediaImages[0].Architecture = $Architecture
        Remove-Item -LiteralPath (Join-Path $MediaRoot ('efi\boot\'+$OtherLoader))
        (Get-AtlasUsbMediaInfo $MediaRoot @(26200)).architecture | Should -Be $Architecture
    }
    It 'rejects ARM64 media containing only an x64 loader' {
        $script:MediaImages[0].Architecture = 12
        Remove-Item -LiteralPath (Join-Path $MediaRoot 'efi\boot\bootaa64.efi')
        { Get-AtlasUsbMediaInfo $MediaRoot @(26200) } | Should -Throw 'iso-unsupported|*bootaa64.efi*'
    }
    It 'accepts 26H2 installation media for architecture <Architecture> when the package lists it' -ForEach @(@{Architecture=9},@{Architecture=12}) {
        $script:MediaImages[0].Architecture = $Architecture
        $script:MediaImages[0].Version = '10.0.26300.9457'
        (Get-AtlasUsbMediaInfo $MediaRoot @(26200,26300)).architecture | Should -Be $Architecture
    }
    It 'rejects a build the package does not list' {
        $script:MediaImages[0].Version = '10.0.26300.9457'
        { Get-AtlasUsbMediaInfo $MediaRoot @(26200) } | Should -Throw 'iso-unsupported|*'
    }
    It 'supports nothing when no builds are supplied' {
        { Get-AtlasUsbMediaInfo $MediaRoot @() } | Should -Throw 'iso-unsupported|*'
        { Get-AtlasUsbMediaInfo $MediaRoot } | Should -Throw 'iso-unsupported|*'
    }
    It 'rejects mixed architectures' {
        $script:MediaImages += [pscustomobject]@{ImageIndex=2;Architecture=12;Version='10.0.26200.8037';InstallationType='Client'}
        { Get-AtlasUsbMediaInfo $MediaRoot @(26200) } | Should -Throw 'iso-unsupported|*Mixed x64 and ARM64*'
    }
    It 'rejects empty installation images' {
        $script:MediaImages = @()
        { Get-AtlasUsbMediaInfo $MediaRoot @(26200) } | Should -Throw 'iso-unsupported|*no Windows installation images*'
    }
    It 'still rejects 32-bit and wrong-build images' -ForEach @(
        @{Architecture=0;Version='10.0.26200.8037'}, @{Architecture=12;Version='10.0.26100.8037'}
    ) {
        $script:MediaImages[0].Architecture = $Architecture
        $script:MediaImages[0].Version = $Version
        { Get-AtlasUsbMediaInfo $MediaRoot @(26200,26300) } | Should -Throw 'iso-unsupported|*x64 or ARM64*'
    }
}

Describe 'USB worker request and module resolution' {
    It 'reads a request with non-ASCII paths and names exactly as the app writes it' {
        # Built from code points so this file's own encoding cannot hide a decoding fault.
        $source = "C:\Users\Jos$([char]0xE9)\Downloads\Windows.iso"
        $app = "C:\Users\$([char]0x674E)\Downloads\AtlasManager.exe"
        $name = "Cl$([char]0xE9) $([char]0x424)"
        $path = Join-Path $TestDrive 'usb-request.json'
        $json = @{ source=$source; app=$app; drive=@{ name=$name } } | ConvertTo-Json -Compress
        [IO.File]::WriteAllText($path, $json, (New-Object Text.UTF8Encoding($false)))
        $request = Read-AtlasUsbRequest $path
        $request.source | Should -BeExactly $source
        $request.app | Should -BeExactly $app
        $request.drive.name | Should -BeExactly $name
    }
    It 'writes the drive list as UTF-8 so non-ASCII names reach the app intact' {
        $job = Join-Path $TestDrive 'encoding'
        [void][IO.Directory]::CreateDirectory($job)
        Copy-Item -LiteralPath $script:UsbScript -Destination $job
        [IO.File]::WriteAllText((Join-Path $job 'usb-request.json'), '{}')
        $name = "Cl$([char]0xE9) $([char]0x424)$([char]0x5C0F)"
        # Functions take precedence over the Storage cmdlets, so no real disk is read.
        $command = @"
`$ProgressPreference = 'SilentlyContinue'
function Get-Disk { [pscustomobject]@{ Number=7; FriendlyName='$name'; SerialNumber='S'; UniqueId='U'; Path='P'; Size=16GB; BusType='USB'; IsBoot=`$false; IsSystem=`$false; IsReadOnly=`$false; IsOffline=`$false } }
function Get-Partition { }
function Get-Volume { }
& '$(Join-Path $job 'Write-Usb.ps1')' -RequestFile '$(Join-Path $job 'usb-request.json')' -Operation List
"@
        $start = New-Object Diagnostics.ProcessStartInfo (Join-Path $PSHOME 'powershell.exe')
        $start.Arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand ' + [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
        $start.UseShellExecute = $false
        $start.CreateNoWindow = $true
        $start.RedirectStandardOutput = $true
        $process = [Diagnostics.Process]::Start($start)
        $bytes = New-Object IO.MemoryStream
        $process.StandardOutput.BaseStream.CopyTo($bytes)
        $process.WaitForExit()
        $process.ExitCode | Should -Be 0
        # The app reads stdout as strict UTF-8, as this does.
        $output = (New-Object Text.UTF8Encoding($false, $true)).GetString($bytes.ToArray())
        $output | Should -Match ([regex]::Escape("ATLAS_RESULT:{`"drives`":[{") + '.*' + [regex]::Escape("`"name`":`"$name`""))
    }
    It 'lists drives with inbox storage cmdlets despite an inherited shadow module' {
        $job = Join-Path $TestDrive 'job'
        $shadow = Join-Path $TestDrive 'modules\Storage'
        $marker = Join-Path $TestDrive 'shadow-imported.txt'
        [void][IO.Directory]::CreateDirectory($job)
        [void][IO.Directory]::CreateDirectory($shadow)
        Copy-Item -LiteralPath $script:UsbScript -Destination $job
        [IO.File]::WriteAllText((Join-Path $job 'usb-request.json'), '{}')
        [IO.File]::WriteAllText((Join-Path $shadow 'Storage.psd1'), "@{ RootModule = 'Storage.psm1'; ModuleVersion = '99.0.0'; FunctionsToExport = @('Get-Disk') }")
        [IO.File]::WriteAllText((Join-Path $shadow 'Storage.psm1'), "[IO.File]::WriteAllText('$marker', 'imported'); function Get-Disk { }")
        $savedPath = $env:PSModulePath
        try {
            $env:PSModulePath = (Split-Path $shadow -Parent) + [IO.Path]::PathSeparator + (Join-Path $PSHOME 'Modules')
            $output = & (Join-Path $PSHOME 'powershell.exe') -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $job 'Write-Usb.ps1') -RequestFile (Join-Path $job 'usb-request.json') -Operation List
            $LASTEXITCODE | Should -Be 0
        }
        finally { $env:PSModulePath = $savedPath }
        ($output -join "`n") | Should -Match '^ATLAS_RESULT:'
        [IO.File]::Exists($marker) | Should -BeFalse
    }
}

Describe 'USB formatting interruption points' {
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
    Context 'an uninitialized (RAW) disk' {
        BeforeEach {
            # A cancelled write or diskpart clean leaves the disk without a partition table.
            Mock Assert-AtlasUsbIdentity {
                if ($script:ReplaceAfter -and $script:Operations.Contains($script:ReplaceAfter)) {
                    throw 'The USB drive changed.'
                }
                $disk = [Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_Disk', 'root/Microsoft/Windows/Storage')
                $disk.CimInstanceProperties.Add([Microsoft.Management.Infrastructure.CimProperty]::Create('PartitionStyle', [uint16]0, [Microsoft.Management.Infrastructure.CimFlags]::None))
                $disk
            }
        }
        It 'initializes it without clearing' {
            (Format-AtlasUsb ([pscustomobject]@{number=42}) 16GB).DriveLetter | Should -Be 'Z'
            ($script:Operations -join ',') | Should -Be 'initialize,partition,format'
            Should -Invoke Clear-Disk -Times 0 -Exactly
            Should -Invoke Assert-AtlasUsbIdentity -Times 3 -Exactly
        }
        It 'starts no further destructive operation after <Kind> at initialize' -ForEach @(
            @{Kind='cancellation'; Stop='initialize'; Replace=''; Message='*cancelled*'},
            @{Kind='replacement'; Stop=''; Replace='initialize'; Message='*changed*'}
        ) {
            $script:StopAfter = $Stop
            $script:ReplaceAfter = $Replace
            { Format-AtlasUsb ([pscustomobject]@{number=42}) 16GB } | Should -Throw $Message
            ($script:Operations -join ',') | Should -Be 'initialize'
            Should -Invoke Format-Volume -Times 0 -Exactly
        }
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
        # A drive that no longer matches the list is typed, so the app can send
        # the user to Refresh; the message only reaches the log.
        Mock Fail { throw "$Reason|$Message" }
        $script:Expected = Get-AtlasUsbIdentity $script:Disk
    }
    It 'accepts the same eligible USB and retains its identity' {
        (Assert-AtlasUsbIdentity $script:Expected).Number | Should -Be 42
    }
    It 'rejects a replacement reusing the same disk number' -ForEach @('SerialNumber','UniqueId','Path','FriendlyName') {
        $script:Disk.$_ = 'REPLACEMENT'
        { Assert-AtlasUsbIdentity $script:Expected } | Should -Throw 'drive-changed|*changed*'
    }
    It 'rejects a resized or differently reported device' {
        $script:Disk.Size = 128GB
        { Assert-AtlasUsbIdentity $script:Expected } | Should -Throw 'drive-changed|*changed*'
    }
    It 'rejects boot, system, read-only and offline disks' -ForEach @('IsBoot','IsSystem','IsReadOnly','IsOffline') {
        $script:Disk.$_ = $true
        { Assert-AtlasUsbIdentity $script:Expected } | Should -Throw 'drive-changed|*eligible*'
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
        # Get-Disk finds no disk with that number and reports nothing.
        Mock Get-Disk { }
        { Assert-AtlasUsbIdentity $script:Expected } | Should -Throw 'drive-changed|*eligible*'
        Should -Invoke Get-Disk -ParameterFilter { $ErrorAction -eq 'SilentlyContinue' }
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
        Mock Fail { throw "$Reason|$Message" }
        { Assert-AtlasUsbPaths $script:Disk @($file) } | Should -Throw 'source-location|*Move them*'
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

Describe 'USB read-back verification' {
    BeforeEach {
        Mock Assert-AtlasUsbContinue { }
    }
    It 'hashes <Bytes> bytes read without the file cache exactly as Get-FileHash does' -ForEach @(
        @{Bytes=0}, @{Bytes=1}, @{Bytes=4095}, @{Bytes=4096}, @{Bytes=(9MB + 3)}
    ) {
        $path = Join-Path $TestDrive "sample-$Bytes.bin"
        $data = New-Object byte[] $Bytes
        (New-Object Random 7).NextBytes($data)
        [IO.File]::WriteAllBytes($path, $data)
        Get-AtlasUsbDeviceHash $path | Should -BeExactly (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    }
    It 'stops between chunks when cancelled and releases the file' {
        $path = Join-Path $TestDrive 'cancelled.bin'
        [IO.File]::WriteAllBytes($path, (New-Object byte[] (9MB)))
        Mock Assert-AtlasUsbContinue { throw [OperationCanceledException]::new('cancel') }
        { Get-AtlasUsbDeviceHash $path } | Should -Throw '*cancel*'
        { Remove-Item -LiteralPath $path -ErrorAction Stop } | Should -Not -Throw
    }
    Context 'the verify pass' {
        BeforeEach {
            $script:Target = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            [void][IO.Directory]::CreateDirectory((Join-Path $script:Target 'sources'))
            [IO.File]::WriteAllBytes((Join-Path $script:Target 'sources\install.swm'), [byte[]](1,2,3))
            $script:Files = @([pscustomobject]@{ relative='sources\install.swm'; bytes=3; hash='EXPECTED' })
            Mock Assert-AtlasUsbVolume { }
            Mock Write-AtlasUsbProgress { }
            Mock Get-FileHash { throw 'The read-back must not use the file cache.' }
        }
        It 'accepts a copy whose device read-back matches its source hash' {
            Mock Get-AtlasUsbDeviceHash { 'EXPECTED' }
            { Test-AtlasUsbCopy $script:Files $script:Target $null $null 3 } | Should -Not -Throw
            Should -Invoke Get-AtlasUsbDeviceHash -Times 1 -Exactly -ParameterFilter { $Path -eq (Join-Path $script:Target 'sources\install.swm') }
            Should -Invoke Assert-AtlasUsbVolume -Times 1 -Exactly
        }
        It 'fails on a mismatched read-back' {
            Mock Get-AtlasUsbDeviceHash { 'DIFFERENT' }
            { Test-AtlasUsbCopy $script:Files $script:Target $null $null 3 } | Should -Throw 'USB verification failed: sources\install.swm'
        }
        It 'fails on a truncated file without hashing it' {
            Mock Get-AtlasUsbDeviceHash { 'EXPECTED' }
            $script:Files[0].bytes = 4
            { Test-AtlasUsbCopy $script:Files $script:Target $null $null 4 } | Should -Throw 'USB verification failed*'
            Should -Invoke Get-AtlasUsbDeviceHash -Times 0 -Exactly
        }
    }
}
