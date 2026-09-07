# Windows installation media, using Microsoft-signed UEFI files and split WIMs.
# All request values are data. Never accept a disk number alone as authorization.
param(
    [Parameter(Mandatory=$true)][string]$RequestFile,
    [ValidateSet('List','Write','Eject')][string]$Operation = 'List'
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Get-AtlasUsbIdentity {
    param($Disk, [switch]$IncludeVolumes)
    [pscustomobject]@{
        number = [int]$Disk.Number
        name = [string]$Disk.FriendlyName
        serial = ([string]$Disk.SerialNumber).Trim()
        uniqueId = ([string]$Disk.UniqueId).Trim()
        path = [string]$Disk.Path
        size = [long]$Disk.Size
        volumes = if ($IncludeVolumes) { (@(Get-Partition -DiskNumber $Disk.Number -ErrorAction SilentlyContinue | Get-Volume -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.DriveLetter) { '{0}: {1}' -f $_.DriveLetter,$_.FileSystemLabel }
        }) -join ', ') } else { '' }
    }
}

function Test-AtlasUsbDisk {
    param($Disk)
    return ($null -ne $Disk -and [string]$Disk.BusType -eq 'USB' -and
        -not $Disk.IsBoot -and -not $Disk.IsSystem -and -not $Disk.IsReadOnly -and
        -not $Disk.IsOffline -and $Disk.Size -ge 8GB -and $Disk.Size -le 2TB -and
        -not [string]::IsNullOrWhiteSpace([string]$Disk.UniqueId) -and
        -not [string]::IsNullOrWhiteSpace([string]$Disk.Path))
}

function Assert-AtlasUsbIdentity {
    param($Expected)
    if ($null -eq $Expected) { throw 'No USB drive was confirmed.' }
    $disk = Get-Disk -Number ([int]$Expected.number) -ErrorAction Stop
    if (-not (Test-AtlasUsbDisk $disk)) { throw 'The selected drive is not an eligible USB disk.' }
    $actual = Get-AtlasUsbIdentity $disk
    foreach ($key in @('number','name','serial','uniqueId','path','size')) {
        if ([string]$actual.$key -cne [string]$Expected.$key) {
            throw 'The USB drive changed. Select it again and confirm erasing it.'
        }
    }
    return $disk
}

function Assert-AtlasUsbPaths {
    param($Disk, [string[]]$Paths)
    foreach ($path in $Paths) {
        $item = Get-Item -LiteralPath $path -Force -ErrorAction Stop
        if ($item.FullName -notmatch '^[A-Za-z]:\\') { throw 'Use a local source and working directory.' }
        # Reject links/mount points: the drive letter alone must describe the backing disk.
        $ancestor = $item
        while ($null -ne $ancestor) {
            if (($ancestor.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'Linked source or working paths are not supported.' }
            $ancestor = if ($ancestor -is [IO.FileInfo]) { $ancestor.Directory } else { $ancestor.Parent }
        }
        $partition = Get-Partition -DriveLetter $item.FullName.Substring(0,1) -ErrorAction Stop
        if ($partition.DiskNumber -eq $Disk.Number) { throw 'The USB contains the ISO, app or working files. Move them to another drive first.' }
    }
}

function Assert-AtlasUsbContinue {
    if (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'cancel')) { throw [OperationCanceledException]::new('USB creation stopped.') }
}

function Write-AtlasUsbProgress {
    param([string]$Stage, [long]$Done=0, [long]$Total=0)
    Write-Output ('ATLAS_PROGRESS:' + (@{ stage=$Stage; done=$Done; total=$Total } | ConvertTo-Json -Compress))
}

function Assert-AtlasUsbVolume {
    param($ExpectedDrive, $ExpectedVolume)
    $null = Assert-AtlasUsbIdentity $ExpectedDrive
    $volumeId = Get-AtlasUsbVolumeId "$($ExpectedVolume.DriveLetter):\"
    if ($volumeId -ine $ExpectedVolume.UniqueId) {
        throw 'The USB volume changed. Stop and select the drive again.'
    }
}

function Get-AtlasUsbVolumeId {
    param([string]$Root)
    if (-not ('AtlasUsbVolume' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.ComponentModel;
using System.Runtime.InteropServices;
public static class AtlasUsbVolume {
 [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
 [return: MarshalAs(UnmanagedType.Bool)]
 static extern bool GetVolumeNameForVolumeMountPointW(string root, StringBuilder name, uint length);
 public static string Identity(string root) {
  var name = new StringBuilder(260);
  if(!GetVolumeNameForVolumeMountPointW(root,name,260)) throw new Win32Exception(Marshal.GetLastWin32Error());
  return name.ToString();
 }
}
'@
    }
    return [AtlasUsbVolume]::Identity($Root)
}

function Get-AtlasUsbTargetRoot {
    param($Volume)
    $root = [string]$Volume.UniqueId
    if ($root -notmatch '^\\\\\?\\Volume\{[0-9a-fA-F-]{36}\}\\$') {
        throw 'Windows did not provide a stable USB volume path.'
    }
    return $root
}

function Format-AtlasUsb {
    param($ExpectedDrive, [long]$Capacity)
    Assert-AtlasUsbContinue
    $disk = Assert-AtlasUsbIdentity $ExpectedDrive
    Clear-Disk -InputObject $disk -RemoveData -RemoveOEM -Confirm:$false
    Assert-AtlasUsbContinue
    $disk = Assert-AtlasUsbIdentity $ExpectedDrive
    Initialize-Disk -InputObject $disk -PartitionStyle MBR
    Assert-AtlasUsbContinue
    $disk = Assert-AtlasUsbIdentity $ExpectedDrive
    $partition = New-Partition -InputObject $disk -Size $Capacity -AssignDriveLetter -IsActive
    Assert-AtlasUsbContinue
    $null = Assert-AtlasUsbIdentity $ExpectedDrive
    return ($partition | Format-Volume -FileSystem FAT32 -NewFileSystemLabel 'ATLAS' -Confirm:$false -Force)
}

function Get-AtlasUsbParentPath {
    param([string]$Path)
    # Split-Path removes the trailing separator from a volume GUID root.
    # Win32 requires it when opening the volume as a directory.
    return (Split-Path -Parent $Path).TrimEnd('\') + '\'
}

function Copy-AtlasUsbFile {
    param([string]$Source,[string]$Destination)
    $parent = Get-AtlasUsbParentPath $Destination
    [void][IO.Directory]::CreateDirectory($parent)
    $inputStream = [IO.File]::Open($Source,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
    try {
        $outputStream = [IO.File]::Open($Destination,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        try {
            $buffer = New-Object byte[] (4MB)
            while (($read = $inputStream.Read($buffer,0,$buffer.Length)) -gt 0) {
                Assert-AtlasUsbContinue
                $outputStream.Write($buffer,0,$read)
            }
            $outputStream.Flush($true)
        } finally { $outputStream.Dispose() }
    } finally { $inputStream.Dispose() }
}

function Get-AtlasUsbEjectTarget {
    param($Disk)
    $devices = @(Get-CimInstance Win32_DiskDrive)
    $device = @($devices | Where-Object Index -eq $Disk.Number)
    if ($device.Count -ne 1) { throw 'The USB device could not be located.' }
    $target = [string]$device[0].PNPDeviceID
    # UAS disks are non-removable SCSI children. Eject their physical USB device,
    # never a root hub/controller or a parent shared with another disk.
    for ($depth=0; $depth -lt 6; $depth++) {
        if ($target -match '^USB\\VID_[0-9A-F]{4}&PID_[0-9A-F]{4}[^\\]*\\') { break }
        $target = [string](Get-PnpDeviceProperty -InstanceId $target -KeyName DEVPKEY_Device_Parent -ErrorAction Stop).Data
        if ([string]::IsNullOrWhiteSpace($target) -or $target -match '^USB\\ROOT_HUB|^PCI\\') { throw 'No removable USB parent was found.' }
    }
    if ($target -notmatch '^USB\\VID_[0-9A-F]{4}&PID_[0-9A-F]{4}[^\\]*\\') { throw 'No removable USB parent was found.' }
    $service = [string](Get-PnpDeviceProperty -InstanceId $target -KeyName DEVPKEY_Device_Service -ErrorAction Stop).Data
    if ($service -match 'hub') { throw 'A USB hub cannot be ejected by this writer.' }
    foreach ($other in @($devices | Where-Object Index -ne $Disk.Number)) {
        $ancestor = [string]$other.PNPDeviceID
        for ($depth=0; $depth -lt 8 -and $ancestor; $depth++) {
            if ($ancestor -ieq $target) { throw 'Another disk shares this USB device. Use Windows to safely remove it.' }
            if ($ancestor -match '^USB\\ROOT_HUB|^PCI\\|^HTREE\\') { break }
            $ancestor = [string](Get-PnpDeviceProperty -InstanceId $ancestor -KeyName DEVPKEY_Device_Parent -ErrorAction Stop).Data
        }
    }
    return $target
}

function Invoke-AtlasUsbWorker {
    $request = Get-Content -LiteralPath $RequestFile -Raw | ConvertFrom-Json
    if ($Operation -eq 'List') {
        $drives = @(Get-Disk | Where-Object { Test-AtlasUsbDisk $_ } | ForEach-Object { Get-AtlasUsbIdentity $_ -IncludeVolumes })
        Write-Output ('ATLAS_RESULT:' + (@{ drives=$drives } | ConvertTo-Json -Depth 5 -Compress))
        return
    }
    $disk = Assert-AtlasUsbIdentity $request.drive
    if ($Operation -eq 'Eject') {
        Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class AtlasUsbEject {
 [DllImport("cfgmgr32.dll", CharSet=CharSet.Unicode)] public static extern uint CM_Locate_DevNodeW(out uint node, string id, uint flags);
 [DllImport("cfgmgr32.dll", CharSet=CharSet.Unicode)] public static extern uint CM_Request_Device_EjectW(uint node, out uint veto, StringBuilder name, uint length, uint flags);
 public static void Eject(string id) {
  uint node, veto; var name = new StringBuilder(260);
  uint result = CM_Locate_DevNodeW(out node, id, 0);
  if(result != 0) throw new InvalidOperationException("USB device could not be located: " + result);
  result = CM_Request_Device_EjectW(node, out veto, name, 260, 0);
  if(result != 0) throw new InvalidOperationException("USB ejection was blocked: " + result + ", veto " + veto);
 }
}
'@
        $device = Get-AtlasUsbEjectTarget $disk
        $null = Assert-AtlasUsbIdentity $request.drive
        [AtlasUsbEject]::Eject($device)
        Write-Output 'ATLAS_RESULT:{"ejected":true}'
        return
    }
    if ($request.eraseConfirmed -ne $true) { throw 'Erasing this USB drive has not been confirmed.' }
    Assert-AtlasUsbPaths $disk @($request.source,$RequestFile,$request.app)
    $source = (Get-Item -LiteralPath $request.source).FullName
    if ([IO.Path]::GetExtension($source) -ine '.iso') { throw 'Select a Windows installation ISO.' }
    $sourceLock = [IO.File]::Open($source,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
    $ownedMount = $false
    try {
        Write-AtlasUsbProgress 'prepare'
        Assert-AtlasUsbContinue
        $mount = Get-DiskImage -ImagePath $source -ErrorAction SilentlyContinue
        if (-not $mount -or -not $mount.Attached) {
            $mount = Mount-DiskImage -ImagePath $source -PassThru
            $ownedMount = $true
        }
        $volume = @($mount | Get-Volume)
        if ($volume.Count -ne 1 -or -not $volume[0].DriveLetter) { throw 'The ISO has no readable filesystem.' }
        $root = "$($volume[0].DriveLetter):\"
        foreach ($required in @('efi\boot\bootx64.efi','sources\boot.wim','setup.exe')) {
            if (-not (Test-Path -LiteralPath (Join-Path $root $required) -PathType Leaf)) { throw 'The ISO is not x64 Windows UEFI installation media.' }
        }
        Import-Module Dism
        $images = @('sources\install.wim','sources\install.esd' | ForEach-Object { Join-Path $root $_ } | Where-Object { Test-Path -LiteralPath $_ })
        if ($images.Count -ne 1) { throw 'Expected one install.wim or install.esd in the ISO.' }
        foreach ($edition in @(Get-WindowsImage -ImagePath $images[0])) {
            $info = Get-WindowsImage -ImagePath $images[0] -Index $edition.ImageIndex
            if ([int]$info.Architecture -ne 9 -or ([version]$info.Version).Build -ne 26200 -or $info.InstallationType -ne 'Client') { throw 'Use Windows 11 25H2 x64 installation media.' }
        }
        $files = @(Get-ChildItem -LiteralPath $root -Recurse -File -Force | ForEach-Object {
            if (($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'The ISO contains a linked file.' }
            [pscustomobject]@{ source=$_.FullName; relative=$_.FullName.Substring($root.Length); bytes=$_.Length; hash=$null }
        })
        $large = @($files | Where-Object { $_.bytes -ge 4GB })
        foreach ($file in $large) { if ($file.source -ine $images[0]) { throw "This file exceeds the FAT32 limit: $($file.relative)" } }
        if ($large.Count -gt 0) {
            $scratch = Join-Path $PSScriptRoot 'split'
            [void][IO.Directory]::CreateDirectory($scratch)
            $workVolume = Get-Volume -DriveLetter $PSScriptRoot.Substring(0,1)
            $needed = [long]$large[0].bytes * 3 + 2GB
            if ($workVolume.SizeRemaining -lt $needed) { throw 'There is not enough working space to prepare the Windows image.' }
            $wim = $images[0]
            if ([IO.Path]::GetExtension($wim) -ieq '.esd') {
                $wim = Join-Path $scratch 'install.wim'
                foreach ($edition in @(Get-WindowsImage -ImagePath $images[0])) {
                    Assert-AtlasUsbContinue
                    Export-WindowsImage -SourceImagePath $images[0] -SourceIndex $edition.ImageIndex -DestinationImagePath $wim -CompressionType Max -CheckIntegrity | Out-Null
                }
            } else {
                # WIMGAPI's integrity-checked split can request write access to its input.
                # Work on our own writable copy, never on the mounted optical image.
                $wim = Join-Path $scratch 'install.wim'
                Copy-AtlasUsbFile $images[0] $wim
            }
            Assert-AtlasUsbContinue
            Split-WindowsImage -ImagePath $wim -SplitImagePath (Join-Path $scratch 'install.swm') -FileSize 3800 -CheckIntegrity | Out-Null
            $files = @($files | Where-Object { $_.source -ine $images[0] })
            $files += @(Get-ChildItem -LiteralPath $scratch -Filter '*.swm' -File | ForEach-Object {
                [pscustomobject]@{ source=$_.FullName; relative=('sources\'+$_.Name); bytes=$_.Length; hash=$null }
            })
        }
        $capacity = [long]([math]::Floor([math]::Min(32000000000, $disk.Size - 16MB) / 1MB) * 1MB)
        $total = [long](($files | Measure-Object bytes -Sum).Sum)
        if ($total + 512MB -gt $capacity -or @($files | Where-Object { $_.bytes -ge 4GB }).Count -gt 0) { throw 'The prepared files do not fit the USB installation partition.' }
        # Hash the immutable source before erasing anything. Generated SWMs stay in the job for verification.
        foreach ($file in $files) {
            Assert-AtlasUsbContinue
            $file.hash = (Get-FileHash -LiteralPath $file.source -Algorithm SHA256).Hash
        }
        $files | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Encoding UTF8
        Assert-AtlasUsbContinue
        $disk = Assert-AtlasUsbIdentity $request.drive
        Assert-AtlasUsbPaths $disk @($source,$RequestFile,$request.app)
        Write-AtlasUsbProgress 'format'
        # Preserve the CIM disk identity across the destructive calls; never rescan and pick a replacement.
        $usbVolume = Format-AtlasUsb $request.drive $capacity
        if (-not $usbVolume.DriveLetter) { throw 'Windows did not assign the USB a drive letter.' }
        # A drive letter can be reassigned between validation and opening a file.
        # Open the confirmed volume itself so a replacement cannot receive writes.
        $target = Get-AtlasUsbTargetRoot $usbVolume
        $done = 0L
        foreach ($file in $files) {
            Assert-AtlasUsbContinue
            Assert-AtlasUsbVolume $request.drive $usbVolume
            Copy-AtlasUsbFile $file.source (Join-Path $target $file.relative)
            $done += $file.bytes
            Write-AtlasUsbProgress 'copy' $done $total
        }
        $done = 0L
        foreach ($file in $files) {
            Assert-AtlasUsbContinue
            Assert-AtlasUsbVolume $request.drive $usbVolume
            $destination = Join-Path $target $file.relative
            if ((Get-Item -LiteralPath $destination).Length -ne $file.bytes -or (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -cne $file.hash) { throw "USB verification failed: $($file.relative)" }
            $done += $file.bytes
            Write-AtlasUsbProgress 'verify' $done $total
        }
        Assert-AtlasUsbVolume $request.drive $usbVolume
        Write-Output ('ATLAS_RESULT:' + (@{ verified=$true; driveLetter=[string]$usbVolume.DriveLetter; files=$files.Count } | ConvertTo-Json -Compress))
    } finally {
        if ($ownedMount) { Dismount-DiskImage -ImagePath $source -ErrorAction Continue | Out-Null }
        $sourceLock.Dispose()
        # Only this worker's fixed scratch child can be removed; retain logs and hashes.
        $scratchPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'split'))
        if ($scratchPath.StartsWith([IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $scratchPath)) {
            Remove-Item -LiteralPath $scratchPath -Recurse -Force
        }
    }
}

$mutex = $null
$ownsMutex = $false
try {
    if ($Operation -ne 'List') {
        $mutex = [Threading.Mutex]::new($false,'Global\AtlasOS.UsbWriter')
        try { $ownsMutex = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $ownsMutex = $true }
        if (-not $ownsMutex) { throw 'Another Atlas USB operation is running. Wait for it to finish.' }
    }
    Invoke-AtlasUsbWorker
} catch {
    $_ | Out-String | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'error.txt') -Encoding UTF8
    Write-Error $_
    exit 1
} finally {
    if ($ownsMutex) { $mutex.ReleaseMutex() }
    if ($null -ne $mutex) { $mutex.Dispose() }
}
