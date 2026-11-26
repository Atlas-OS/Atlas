BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:UsbScript = Join-Path (Split-Path $PSScriptRoot -Parent) 'app\resources\iso\Write-Usb.ps1'
    $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile($script:UsbScript,[ref]$null,[ref]$errors)
    if ($errors) { throw ($errors | Out-String) }
    foreach ($name in @('Fail','Read-AtlasUsbRequest','Get-AtlasUsbIdentity','Test-AtlasUsbCandidate','Test-AtlasUsbDisk','Assert-AtlasUsbIdentity','Assert-AtlasUsbPaths','Assert-AtlasUsbContinue','Write-AtlasUsbProgress','Write-AtlasUsbFileBuffer','Copy-AtlasUsbFile','Get-AtlasUsbDeviceHash','Test-AtlasUsbCopy','Get-AtlasUsbParentPath','Assert-AtlasUsbVolume','Get-AtlasUsbVolumeId','Get-AtlasUsbTargetRoot','Format-AtlasUsb','Get-AtlasUsbEjectTarget','Get-AtlasUsbMediaInfo','Mount-AtlasUsbSource','Get-AtlasUsbSourceRoot','Get-AtlasUsbSourcePlan','Invoke-AtlasUsbCheck','Invoke-AtlasUsbEject')) {
        $node = $ast.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true)
        . ([scriptblock]::Create($node.Extent.Text))
    }
    # The worker dot-sources the mount helper it shares with the ISO worker.
    $script:MountHelper = Join-Path (Split-Path $script:UsbScript -Parent) 'Iso-Mount.ps1'
    . $script:MountHelper
    # Invoke-AtlasUsbEject compiles its CM_Request_Device_EjectW wrapper only when no type of
    # that name exists. This stand-in takes its place in the test session, so no device is
    # ejected: it records the device and refuses as many times as a test asks.
    if (-not ('AtlasUsbEject' -as [type])) {
        Add-Type -TypeDefinition @'
public static class AtlasUsbEject {
 public static int Calls;
 public static int Refusals;
 public static string Device;
 public static void Eject(string id) {
  Calls++;
  Device = id;
  if (Calls <= Refusals) throw new System.InvalidOperationException("USB ejection was blocked: 23, veto 6");
 }
}
'@
    }
}

Describe 'USB destination write errors' {
    It 'reports a destination that became unavailable during write or flush using HRESULT <Code>' -ForEach @(
        @{ Code = 0x800701B1 }, @{ Code = 0x80070456 }, @{ Code = 0x8007048F }
    ) {
        $stream = [pscustomobject]@{ Code = $Code }
        $stream | Add-Member ScriptMethod Write { throw [IO.IOException]::new('Translated device message', $this.Code) }
        $stream | Add-Member ScriptMethod Flush { throw [IO.IOException]::new('Translated device message', $this.Code) }
        Mock Fail { throw "$Reason|$Message" }

        { Write-AtlasUsbFileBuffer -Stream $stream -Buffer ([byte[]]@(1)) -Count 1 -ToUsb } |
            Should -Throw 'drive-unavailable|*Translated device message*'
        { Write-AtlasUsbFileBuffer -Stream $stream -Flush -ToUsb } |
            Should -Throw 'drive-unavailable|*Translated device message*'
        { Write-AtlasUsbFileBuffer -Stream $stream -Flush } |
            Should -Throw '*Translated device message*'
        Should -Invoke Fail -Times 2 -Exactly
    }

    It 'preserves a different destination write error' {
        $stream = [pscustomobject]@{}
        $stream | Add-Member ScriptMethod Write { throw [IO.IOException]::new('Disk full', 0x80070070) }
        Mock Fail { throw "$Reason|$Message" }

        { Write-AtlasUsbFileBuffer -Stream $stream -Buffer ([byte[]]@(1)) -Count 1 -ToUsb } |
            Should -Throw '*Disk full*'
        Should -Invoke Fail -Times 0 -Exactly
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
        Copy-Item -LiteralPath $script:UsbScript, $script:MountHelper -Destination $job
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
        Copy-Item -LiteralPath $script:UsbScript, $script:MountHelper -Destination $job
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
        Mock Set-Disk { $script:Operations.Add('convert') }
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
    Context 'removable media, which Clear-Disk leaves initialized' {
        It 'partitions a <Style> drive after clearing it, without initializing it again' -ForEach @(
            @{Style='MBR'; Value=1; Expected='clear,partition,format'},
            @{Style='GPT'; Value=2; Expected='clear,convert,partition,format'}
        ) {
            # A USB flash drive another tool, such as Rufus or Windows setup, already partitioned.
            Mock Assert-AtlasUsbIdentity {
                $disk = [Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_Disk', 'root/Microsoft/Windows/Storage')
                $disk.CimInstanceProperties.Add([Microsoft.Management.Infrastructure.CimProperty]::Create('PartitionStyle', [uint16]$Value, [Microsoft.Management.Infrastructure.CimFlags]::None))
                $disk
            }
            (Format-AtlasUsb ([pscustomobject]@{number=42}) 16GB).DriveLetter | Should -Be 'Z'
            ($script:Operations -join ',') | Should -Be $Expected
            Should -Invoke Initialize-Disk -Times 0 -Exactly
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
    It 'returns the volume GUID path, never a drive-letter root' {
        $volume = [pscustomobject]@{ DriveLetter='Z'; UniqueId='\\?\Volume{12345678-1234-1234-1234-123456789abc}\' }
        Get-AtlasUsbTargetRoot $volume | Should -BeExactly $volume.UniqueId
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
    It 'refuses a drive letter with no partition behind it as a source location' {
        $file = Join-Path $TestDrive 'source.iso'
        Set-Content -LiteralPath $file -Value 'data'
        # What Get-Partition reports for a mapped network or encrypted-container drive.
        Mock Get-Partition { Write-Error -Message 'No MSFT_Partition objects found' -Category ObjectNotFound -ErrorAction Stop }
        { Assert-AtlasUsbPaths $script:Disk @($file) } | Should -Throw 'source-location|*no local disk partition*'
        # Any other lookup failure isn't the user's to fix, so it stays untyped.
        Mock Get-Partition { Write-Error -Message 'Injected storage failure' -Category NotSpecified -ErrorAction Stop }
        { Assert-AtlasUsbPaths $script:Disk @($file) } | Should -Throw 'Injected storage failure'
        Should -Invoke Fail -Times 1 -Exactly
    }
    It 'refuses a path through a junction but accepts a reparse point that is not a link' {
        Mock Get-Partition { [pscustomobject]@{ DiskNumber=7 } }
        Mock Fail { throw "$Reason|$Message" }
        $target = Join-Path $TestDrive 'target'
        [void][IO.Directory]::CreateDirectory($target)
        Set-Content -LiteralPath (Join-Path $target 'source.iso') -Value 'data'
        $junction = Join-Path $TestDrive 'linked'
        $null = cmd.exe /d /c mklink /J "$junction" "$target"
        try { { Assert-AtlasUsbPaths $script:Disk @(Join-Path $junction 'source.iso') } | Should -Throw 'source-location|*Linked*' }
        finally { [IO.Directory]::Delete($junction) }
        # OneDrive Files On-Demand marks backed-up folders such as the Desktop this way.
        Mock Get-Item { [pscustomobject]@{ FullName='C:\Users\Someone\OneDrive\Desktop\AtlasManager.exe'; Attributes=[IO.FileAttributes]'Archive, ReparsePoint'; LinkType=$null; Parent=$null } }
        { Assert-AtlasUsbPaths $script:Disk @('C:\Users\Someone\OneDrive\Desktop\AtlasManager.exe') } | Should -Not -Throw
    }
    Context 'the write worker' {
        BeforeAll {
            # The worker writes its manifest beside the script, and a function made from
            # a script block has no $PSScriptRoot, so load it from a file in a job folder.
            $ast = [Management.Automation.Language.Parser]::ParseFile($script:UsbScript,[ref]$null,[ref]$null)
            $worker = $ast.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Invoke-AtlasUsbWorker'},$true)
            $script:Job = Join-Path $TestDrive 'write-job'
            [void][IO.Directory]::CreateDirectory($script:Job)
            [IO.File]::WriteAllText((Join-Path $script:Job 'Invoke-AtlasUsbWorker.ps1'), $worker.Extent.Text, (New-Object Text.UTF8Encoding($true)))
            . (Join-Path $script:Job 'Invoke-AtlasUsbWorker.ps1')
        }
        BeforeEach {
            $script:Source = Join-Path $TestDrive 'Windows.iso'
            Set-Content -LiteralPath $script:Source -Value 'fixture'
            $script:Root = '\\?\Volume{12345678-1234-1234-1234-123456789abc}\'
            $script:Destinations = [Collections.Generic.List[string]]::new()
            $script:Image = [Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_DiskImage', 'root/Microsoft/Windows/Storage')
            $script:Image.CimInstanceProperties.Add([Microsoft.Management.Infrastructure.CimProperty]::Create('Attached', $true, [Microsoft.Management.Infrastructure.CimFlags]::None))
            Mock Read-AtlasUsbRequest { [pscustomobject]@{ drive=$script:Expected; eraseConfirmed=$true; source=$script:Source; app=$script:Source; supportedBuilds=@(26200) } }
            Mock Assert-AtlasUsbIdentity { $script:Disk }
            Mock Assert-AtlasUsbPaths { }
            Mock Assert-AtlasUsbContinue { }
            Mock Write-AtlasUsbProgress { }
            # The mocked Get-ChildItem takes -File only for a path on an existing
            # FileSystem drive, so the mounted ISO reports the test drive's letter.
            $script:MediaRoot = [IO.Path]::GetPathRoot($TestDrive)
            Mock Get-DiskImage { $script:Image }
            Mock Get-Volume { [pscustomobject]@{ DriveLetter=$script:MediaRoot.Substring(0,1) } }
            Mock Import-Module { }
            Mock Get-AtlasUsbMediaInfo { [pscustomobject]@{ imagePath=($script:MediaRoot + 'sources\install.wim'); architecture=9 } }
            Mock Get-ChildItem {
                [pscustomobject]@{ FullName=($script:MediaRoot + 'setup.exe'); Length=1KB; Attributes=[IO.FileAttributes]::Archive }
                [pscustomobject]@{ FullName=($script:MediaRoot + 'sources\boot.wim'); Length=1MB; Attributes=[IO.FileAttributes]::Archive }
            }
            Mock Get-FileHash { [pscustomobject]@{ Hash='HASH' } }
            Mock Format-AtlasUsb { [pscustomobject]@{ DriveLetter='Z'; UniqueId=$script:Root } }
            Mock Assert-AtlasUsbVolume { }
            Mock Copy-AtlasUsbFile { $script:Destinations.Add($Destination) }
            $script:Order = [Collections.Generic.List[string]]::new()
            Mock Test-AtlasUsbCopy { $script:Order.Add('verify') }
            Mock Invoke-AtlasUsbEject { $script:Order.Add('eject') }
        }
        It 'ejects the confirmed drive by itself once every file is verified' {
            $script:RequestFile = Join-Path $script:Job 'usb-request.json'
            $script:Operation = 'Write'
            $output = @(Invoke-AtlasUsbWorker) -join "`n"
            ($script:Order -join ',') | Should -BeExactly 'verify,eject'
            Should -Invoke Invoke-AtlasUsbEject -Times 1 -Exactly -ParameterFilter { $Drive.uniqueId -ceq $script:Expected.uniqueId }
            Should -Invoke Write-AtlasUsbProgress -Times 1 -Exactly -ParameterFilter { $Stage -eq 'eject' }
            $result = ($output -split "`n" | Where-Object { $_ -like 'ATLAS_RESULT:*' }).Substring(13) | ConvertFrom-Json
            $result.verified | Should -BeTrue
            $result.ejected | Should -BeTrue
        }
        It 'reports a drive Windows would not let go as ready, not as a failed write' {
            $script:RequestFile = Join-Path $script:Job 'usb-request.json'
            $script:Operation = 'Write'
            # Something, such as a scan of the files just written, holds the drive.
            Mock Invoke-AtlasUsbEject { throw 'USB ejection was blocked: 23, veto 6' }
            $output = @(Invoke-AtlasUsbWorker) -join "`n"
            $result = ($output -split "`n" | Where-Object { $_ -like 'ATLAS_RESULT:*' }).Substring(13) | ConvertFrom-Json
            $result.verified | Should -BeTrue
            $result.ejected | Should -BeFalse
        }
        It 'ejects without failure markers, as the verified drive is ready whatever the eject finds' {
            $script:RequestFile = Join-Path $script:Job 'usb-request.json'
            $script:Operation = 'Write'
            $null = Invoke-AtlasUsbWorker
            Should -Invoke Invoke-AtlasUsbEject -Times 1 -Exactly -ParameterFilter { $Quiet }
        }
        It 'never ejects a drive that failed verification' {
            $script:RequestFile = Join-Path $script:Job 'usb-request.json'
            $script:Operation = 'Write'
            Mock Test-AtlasUsbCopy { throw 'USB verification failed: setup.exe' }
            { Invoke-AtlasUsbWorker } | Should -Throw 'USB verification failed: setup.exe'
            Should -Invoke Invoke-AtlasUsbEject -Times 0 -Exactly
        }
        It 'copies to and verifies the formatted volume by its GUID path, not its drive letter' {
            # The worker reads its script parameters through dynamic scope.
            $script:RequestFile = Join-Path $script:Job 'usb-request.json'
            $script:Operation = 'Write'
            $null = Invoke-AtlasUsbWorker
            # Windows can hand Z: to another volume while the copy runs.
            ($script:Destinations -join ',') | Should -BeExactly "$($script:Root)setup.exe,$($script:Root)sources\boot.wim"
            Should -Invoke Test-AtlasUsbCopy -Times 1 -Exactly -ParameterFilter { $Target -ceq $script:Root }
        }
        It 'keeps the outcome when the split folder cannot be removed' {
            $script:RequestFile = Join-Path $script:Job 'usb-request.json'
            $script:Operation = 'Write'
            $script:Split = Join-Path $script:Job 'split'
            [void][IO.Directory]::CreateDirectory($script:Split)
            Mock Remove-Item { throw 'held open' } -ParameterFilter { $LiteralPath -eq $script:Split }
            # A scratch file another process still holds must not fail a verified write.
            (@(Invoke-AtlasUsbWorker) -join "`n") | Should -Match '^ATLAS_RESULT:.*"verified":true'
            # A cleanup failure must not replace the error in flight.
            Mock Test-AtlasUsbCopy { throw 'USB verification failed: setup.exe' }
            { Invoke-AtlasUsbWorker } | Should -Throw 'USB verification failed: setup.exe'
            Should -Invoke Remove-Item -Times 2 -Exactly -ParameterFilter { $LiteralPath -eq $script:Split }
        }
    }
}

Describe 'USB ISO check before a drive is chosen' {
    BeforeEach {
        $script:Source = Join-Path $TestDrive 'Windows.iso'
        Set-Content -LiteralPath $script:Source -Value 'fixture'
        # The check reads its script parameter through dynamic scope.
        $script:RequestFile = Join-Path $TestDrive 'usb-request.json'
        $script:Request = [pscustomobject]@{ source=$script:Source; app=$script:Source; supportedBuilds=@(26200,26300) }
        $script:Owned = $true
        Mock Fail { throw "$Reason|$Message" }
        Mock Assert-AtlasUsbPaths { }
        Mock Assert-AtlasUsbContinue { }
        Mock Mount-AtlasUsbSource { [pscustomobject]@{ image='mounted'; owned=$script:Owned } }
        Mock Get-AtlasUsbSourceRoot { 'Z:\' }
        Mock Import-Module { }
        Mock Get-AtlasUsbSourcePlan {
            [pscustomobject]@{
                imagePath = 'Z:\sources\install.wim'
                files = @([pscustomobject]@{ bytes=1KB }, [pscustomobject]@{ bytes=5GB })
                large = @()
            }
        }
        Mock Dismount-DiskImage { }
        # Nothing a check does may touch a disk.
        Mock Clear-Disk { }
        Mock New-Partition { }
        Mock Format-Volume { }
    }
    It 'reports the bytes a write would copy, and changes nothing' {
        $output = @(Invoke-AtlasUsbCheck $script:Request) -join "`n"
        $output | Should -Match '^ATLAS_RESULT:'
        $result = $output.Substring(13) | ConvertFrom-Json
        $result.checked | Should -BeTrue
        $result.bytes | Should -Be (1KB + 5GB)
        # The same path rules a write applies, without a drive to compare them with.
        Should -Invoke Assert-AtlasUsbPaths -Times 1 -Exactly -ParameterFilter {
            $null -eq $Disk -and $Paths -contains $script:Source -and $Paths -contains $script:RequestFile
        }
        Should -Invoke Get-AtlasUsbSourcePlan -Times 1 -Exactly -ParameterFilter { ($SupportedBuilds -join ',') -eq '26200,26300' }
        foreach ($command in 'Clear-Disk', 'New-Partition', 'Format-Volume') { Should -Invoke $command -Times 0 -Exactly }
    }
    It 'dismounts an ISO it mounted, also when the check fails' {
        Mock Get-AtlasUsbSourcePlan { Fail 'working-space' 'There is not enough working space to prepare the Windows image.' }
        { Invoke-AtlasUsbCheck $script:Request } | Should -Throw 'working-space|*'
        Should -Invoke Dismount-DiskImage -Times 1 -Exactly -ParameterFilter { $ImagePath -eq $script:Source }
    }
    It 'leaves an ISO that was already mounted as it was' {
        $script:Owned = $false
        $null = Invoke-AtlasUsbCheck $script:Request
        Should -Invoke Dismount-DiskImage -Times 0 -Exactly
    }
    It 'refuses a file that is not an ISO without mounting it' {
        $image = Join-Path $TestDrive 'Windows.img'
        Set-Content -LiteralPath $image -Value 'fixture'
        $script:Request.source = $image
        { Invoke-AtlasUsbCheck $script:Request } | Should -Throw 'iso-unsupported|*'
        Should -Invoke Mount-AtlasUsbSource -Times 0 -Exactly
    }
    It 'stops before mounting when cancelled' {
        Mock Assert-AtlasUsbContinue { throw [OperationCanceledException]::new('cancel') }
        { Invoke-AtlasUsbCheck $script:Request } | Should -Throw '*cancel*'
        Should -Invoke Mount-AtlasUsbSource -Times 0 -Exactly
    }
}

Describe 'USB checks and writes take turns' {
    BeforeAll {
        $script:Job = Join-Path $TestDrive 'exclusion'
        [void][IO.Directory]::CreateDirectory($script:Job)
        Copy-Item -LiteralPath $script:UsbScript, $script:MountHelper -Destination $script:Job
        $script:Iso = Join-Path $script:Job 'Windows.iso'
        Set-Content -LiteralPath $script:Iso -Value 'fixture'
        $request = @{ source=$script:Iso; app=$script:Iso; supportedBuilds=@(26200) } | ConvertTo-Json -Compress
        [IO.File]::WriteAllText((Join-Path $script:Job 'usb-request.json'), $request, (New-Object Text.UTF8Encoding($false)))
        $script:Mounted = Join-Path $script:Job 'mounted.txt'
        $script:Release = Join-Path $script:Job 'release.txt'
        # Runs the worker in a process of its own, as the app does. Functions take precedence
        # over the Storage cmdlets, so no image is mounted: reading the ISO records that it
        # began, waits for the test to release it, then stops the check.
        function script:Start-AtlasUsbWorker([string]$Operation) {
            $command = @"
`$ProgressPreference = 'SilentlyContinue'
function Get-Partition { [pscustomobject]@{ DiskNumber=0 } }
function Get-DiskImage { [IO.File]::WriteAllText('$script:Mounted', 'mounted'); while (-not (Test-Path -LiteralPath '$script:Release')) { Start-Sleep -Milliseconds 50 }; throw 'stopped by the test' }
function Mount-DiskImage { throw 'Mount-DiskImage must not run in tests.' }
& '$(Join-Path $script:Job 'Write-Usb.ps1')' -RequestFile '$(Join-Path $script:Job 'usb-request.json')' -Operation $Operation
"@
            $start = New-Object Diagnostics.ProcessStartInfo (Join-Path $PSHOME 'powershell.exe')
            $start.Arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand ' + [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
            $start.UseShellExecute = $false
            $start.CreateNoWindow = $true
            $start.RedirectStandardOutput = $true
            $start.RedirectStandardError = $true
            return [Diagnostics.Process]::Start($start)
        }
        # Waits for the worker and returns its standard output; its errors go to its job's error.txt.
        function script:Wait-AtlasUsbWorker($Process) {
            $errors = $Process.StandardError.ReadToEndAsync()
            $output = $Process.StandardOutput.ReadToEnd()
            $Process.WaitForExit()
            $null = $errors.Result
            return $output
        }
    }
    BeforeEach {
        Remove-Item -LiteralPath $script:Mounted, $script:Release -ErrorAction SilentlyContinue
        $script:Lock = [Threading.Mutex]::new($false, 'Global\AtlasOS.UsbWriter')
    }
    AfterEach { $script:Lock.Dispose() }
    It 'holds the writer lock while a check reads the ISO, so a write cannot remove it' {
        $check = Start-AtlasUsbWorker 'Check'
        try {
            $deadline = [DateTime]::UtcNow.AddSeconds(60)
            while (-not (Test-Path -LiteralPath $script:Mounted)) {
                if ($check.HasExited -or [DateTime]::UtcNow -gt $deadline) { throw 'The check never read the ISO.' }
                Start-Sleep -Milliseconds 50
            }
            $taken = $false
            try { $taken = $script:Lock.WaitOne(0) } catch [Threading.AbandonedMutexException] { $taken = $true }
            if ($taken) { $script:Lock.ReleaseMutex() }
            $taken | Should -BeFalse
        }
        finally {
            Set-Content -LiteralPath $script:Release -Value 'release'
            $null = Wait-AtlasUsbWorker $check
        }
    }
    It 'reports a check busy, without reading the ISO, while a write holds the lock' {
        # A check that read the ISO anyway stops at once instead of waiting.
        Set-Content -LiteralPath $script:Release -Value 'release'
        $script:Lock.WaitOne(0) | Should -BeTrue
        try {
            $check = Start-AtlasUsbWorker 'Check'
            $output = Wait-AtlasUsbWorker $check
        }
        finally { $script:Lock.ReleaseMutex() }
        $check.ExitCode | Should -Be 0
        $output.Trim() | Should -BeExactly 'ATLAS_RESULT:{"busy":true}'
        Test-Path -LiteralPath $script:Mounted | Should -BeFalse
    }
}

Describe 'USB failure markers' {
    BeforeEach {
        $script:Disk = [pscustomobject]@{ Number=42; FriendlyName='Test USB'; SerialNumber='SERIAL-A'; UniqueId='USB-A'; Path='DEVICE-A'; Size=64GB; BusType='USB'; IsBoot=$false; IsSystem=$false; IsReadOnly=$false; IsOffline=$false }
        Mock Get-Disk { $script:Disk }
        Mock Get-Partition { @() }
        $script:Expected = Get-AtlasUsbIdentity $script:Disk
        # Another drive with the same serial number, model and size took its place.
        $script:Disk.UniqueId = 'USB-B'
        # The worker writes its markers straight to the console.
        $script:Console = [Console]::Out
        $script:Captured = New-Object IO.StringWriter
        [Console]::SetOut($script:Captured)
    }
    AfterEach { [Console]::SetOut($script:Console) }
    It 'names a changed drive when the failure ends the job' {
        { Invoke-AtlasUsbEject $script:Expected } | Should -Throw '*changed*'
        $script:Captured.ToString().Trim() | Should -BeExactly 'ATLAS_ERROR:drive-changed'
    }
    It 'leaves the marker out where the write it ends has already verified the drive' {
        { Invoke-AtlasUsbEject $script:Expected -Quiet } | Should -Throw '*changed*'
        $script:Captured.ToString() | Should -BeNullOrEmpty
    }
}

Describe 'Automatic USB ejection' {
    BeforeEach {
        [AtlasUsbEject]::Calls = 0
        [AtlasUsbEject]::Refusals = 0
        [AtlasUsbEject]::Device = $null
        $script:Target = 'USB\VID_0951&PID_177F\TEST'
        Mock Assert-AtlasUsbIdentity { [pscustomobject]@{ Number=42 } }
        Mock Get-AtlasUsbEjectTarget { $script:Target }
        Mock Start-Sleep { }
        $script:Drive = [pscustomobject]@{ number=42; uniqueId='USB-A' }
    }
    It 'ejects the USB device that holds the confirmed drive' {
        Invoke-AtlasUsbEject $script:Drive
        [AtlasUsbEject]::Calls | Should -Be 1
        [AtlasUsbEject]::Device | Should -BeExactly $script:Target
        # The drive is checked again after finding its device, just before ejecting it.
        Should -Invoke Assert-AtlasUsbIdentity -Times 2 -Exactly -ParameterFilter { $Expected.uniqueId -eq 'USB-A' }
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }
    It 'tries again, two seconds apart, while Windows refuses' {
        [AtlasUsbEject]::Refusals = 2
        { Invoke-AtlasUsbEject $script:Drive } | Should -Not -Throw
        [AtlasUsbEject]::Calls | Should -Be 3
        Should -Invoke Start-Sleep -Times 2 -Exactly -ParameterFilter { $Seconds -eq 2 }
    }
    It 'gives up after five refusals' {
        [AtlasUsbEject]::Refusals = 99
        { Invoke-AtlasUsbEject $script:Drive } | Should -Throw '*blocked*'
        [AtlasUsbEject]::Calls | Should -Be 5
        Should -Invoke Start-Sleep -Times 4 -Exactly
    }
    It 'never ejects a drive that changed' {
        Mock Assert-AtlasUsbIdentity { throw 'drive-changed|The USB drive changed.' }
        { Invoke-AtlasUsbEject $script:Drive } | Should -Throw 'drive-changed|*'
        [AtlasUsbEject]::Calls | Should -Be 0
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
