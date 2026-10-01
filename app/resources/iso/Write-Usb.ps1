# Elevated USB worker: lists, writes and ejects. The media boots from the ISO's own
# Microsoft-signed UEFI files; a WIM over 4 GB is split for FAT32.
# Request values are data; a disk number alone never authorizes a write.
param(
    [Parameter(Mandatory=$true)][string]$RequestFile,
    [ValidateSet('List','Write','Eject')][string]$Operation = 'List'
)
# This elevated worker must never autoload a module from an inherited user path.
$env:PSModulePath = [IO.Path]::Combine($PSHOME, 'Modules')
$ErrorActionPreference = 'Stop'
# The app reads stdout as UTF-8; volume labels and drive names are not ASCII-only.
[Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
$ProgressPreference = 'SilentlyContinue'

# A typed reason the app turns into advice; the message goes to the log.
function Fail([string]$Reason, [string]$Message) {
    [Console]::Out.WriteLine("ATLAS_ERROR:$Reason")
    throw $Message
}

function Read-AtlasUsbRequest {
    param([string]$Path)
    # The app writes UTF-8 without a byte order mark; Get-Content would read it as ANSI.
    return ([IO.File]::ReadAllText($Path) | ConvertFrom-Json)
}

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
    # A missing disk is one that changed: it was removed or renumbered.
    $disk = Get-Disk -Number ([int]$Expected.number) -ErrorAction SilentlyContinue
    if (-not (Test-AtlasUsbDisk $disk)) { Fail 'drive-changed' 'The selected drive is not an eligible USB disk.' }
    $actual = Get-AtlasUsbIdentity $disk
    foreach ($key in @('number','name','serial','uniqueId','path','size')) {
        if ([string]$actual.$key -cne [string]$Expected.$key) {
            Fail 'drive-changed' 'The USB drive changed. Select it again and confirm erasing it.'
        }
    }
    return $disk
}

function Assert-AtlasUsbPaths {
    param($Disk, [string[]]$Paths)
    foreach ($path in $Paths) {
        $item = Get-Item -LiteralPath $path -Force -ErrorAction Stop
        if ($item.FullName -notmatch '^[A-Za-z]:\\') { Fail 'source-location' 'Use a local source and working directory.' }
        # Reject links/mount points: the drive letter alone must describe the backing disk.
        $ancestor = $item
        while ($null -ne $ancestor) {
            if (($ancestor.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { Fail 'source-location' 'Linked source or working paths are not supported.' }
            $ancestor = if ($ancestor -is [IO.FileInfo]) { $ancestor.Directory } else { $ancestor.Parent }
        }
        $partition = Get-Partition -DriveLetter $item.FullName.Substring(0,1) -ErrorAction Stop
        if ($partition.DiskNumber -eq $Disk.Number) { Fail 'source-location' 'The USB contains the ISO, app or working files. Move them to another drive first.' }
    }
}

function Assert-AtlasUsbContinue {
    if (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'cancel')) { throw [OperationCanceledException]::new('USB creation stopped.') }
}

function Write-AtlasUsbProgress {
    param([string]$Stage, [long]$Done=0, [long]$Total=0)
    # Straight to the console: a caller that captures output must not swallow it.
    [Console]::Out.WriteLine('ATLAS_PROGRESS:' + (@{ stage=$Stage; done=$Done; total=$Total } | ConvertTo-Json -Compress))
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
    # Clear-Disk rejects an uninitialized (RAW) disk, such as one left by a
    # cancelled write or diskpart clean. Such a disk has nothing to clear.
    if ($disk.PartitionStyle -ne 'RAW') {
        Clear-Disk -InputObject $disk -RemoveData -RemoveOEM -Confirm:$false
        Assert-AtlasUsbContinue
        $disk = Assert-AtlasUsbIdentity $ExpectedDrive
    }
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

function Get-AtlasUsbDeviceHash {
    param([string]$Path)
    # Pages just written stay in the file cache, where an ordinary read would
    # find them. An unbuffered handle makes the file data come from the device.
    if (-not ('AtlasUsbDeviceReader' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
public sealed class AtlasUsbDeviceReader : IDisposable {
 // Unbuffered reads need sector-aligned sizes and buffers; a page-aligned
 // allocation of whole megabytes satisfies both.
 public const int BufferSize = 4 * 1024 * 1024;
 [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
 static extern SafeFileHandle CreateFileW(string name, uint access, uint share, IntPtr security, uint disposition, uint flags, IntPtr template);
 [DllImport("kernel32.dll", SetLastError=true)]
 [return: MarshalAs(UnmanagedType.Bool)]
 static extern bool ReadFile(SafeFileHandle file, IntPtr buffer, int length, out int read, IntPtr overlapped);
 [DllImport("kernel32.dll", SetLastError=true)]
 static extern IntPtr VirtualAlloc(IntPtr address, UIntPtr size, uint type, uint protect);
 [DllImport("kernel32.dll", SetLastError=true)]
 [return: MarshalAs(UnmanagedType.Bool)]
 static extern bool VirtualFree(IntPtr address, UIntPtr size, uint type);
 readonly SafeFileHandle file;
 IntPtr buffer;
 public AtlasUsbDeviceReader(string path) {
  // GENERIC_READ, FILE_SHARE_READ, OPEN_EXISTING, FILE_FLAG_NO_BUFFERING | FILE_FLAG_SEQUENTIAL_SCAN
  file = CreateFileW(path, 0x80000000, 1, IntPtr.Zero, 3, 0x20000000 | 0x08000000, IntPtr.Zero);
  if (file.IsInvalid) throw new Win32Exception(Marshal.GetLastWin32Error());
  // MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE
  buffer = VirtualAlloc(IntPtr.Zero, (UIntPtr)BufferSize, 0x3000, 0x04);
  if (buffer == IntPtr.Zero) { int error = Marshal.GetLastWin32Error(); file.Dispose(); throw new Win32Exception(error); }
 }
 public int Read(byte[] destination) {
  int read;
  if (!ReadFile(file, buffer, BufferSize, out read, IntPtr.Zero)) throw new Win32Exception(Marshal.GetLastWin32Error());
  Marshal.Copy(buffer, destination, 0, read);
  return read;
 }
 public void Dispose() {
  // MEM_RELEASE
  if (buffer != IntPtr.Zero) { VirtualFree(buffer, UIntPtr.Zero, 0x8000); buffer = IntPtr.Zero; }
  file.Dispose();
 }
}
'@
    }
    $hasher = [Security.Cryptography.HashAlgorithm]::Create('SHA256')
    $reader = $null
    try {
        $reader = [AtlasUsbDeviceReader]::new($Path)
        $buffer = New-Object byte[] ([AtlasUsbDeviceReader]::BufferSize)
        while (($read = $reader.Read($buffer)) -gt 0) {
            Assert-AtlasUsbContinue
            [void]$hasher.TransformBlock($buffer, 0, $read, $null, 0)
        }
        [void]$hasher.TransformFinalBlock($buffer, 0, 0)
        return [BitConverter]::ToString($hasher.Hash).Replace('-', '')
    } finally {
        if ($null -ne $reader) { $reader.Dispose() }
        $hasher.Dispose()
    }
}

function Test-AtlasUsbCopy {
    param($Files, [string]$Target, $ExpectedDrive, $ExpectedVolume, [long]$Total)
    $done = 0L
    foreach ($file in $Files) {
        Assert-AtlasUsbContinue
        Assert-AtlasUsbVolume $ExpectedDrive $ExpectedVolume
        $destination = Join-Path $Target $file.relative
        if ((Get-Item -LiteralPath $destination).Length -ne $file.bytes -or (Get-AtlasUsbDeviceHash $destination) -cne $file.hash) { throw "USB verification failed: $($file.relative)" }
        $done += $file.bytes
        Write-AtlasUsbProgress 'verify' $done $Total
    }
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

function Get-AtlasUsbMediaInfo {
    param([string]$Root, [int[]]$SupportedBuilds)
    foreach ($required in @('sources\boot.wim','setup.exe')) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $required) -PathType Leaf)) { Fail 'iso-unsupported' 'The ISO is not Windows UEFI installation media.' }
    }
    $images = @('sources\install.wim','sources\install.esd' | ForEach-Object { Join-Path $Root $_ } | Where-Object { Test-Path -LiteralPath $_ })
    if ($images.Count -ne 1) { Fail 'iso-unsupported' 'Expected one install.wim or install.esd in the ISO.' }
    $architecture = $null
    foreach ($edition in @(Get-WindowsImage -ImagePath $images[0])) {
        $info = Get-WindowsImage -ImagePath $images[0] -Index $edition.ImageIndex
        # The package's supported builds decide, as for ISO creation; an empty list supports nothing.
        if ([int]$info.Architecture -notin @(9,12) -or $SupportedBuilds -notcontains ([version]$info.Version).Build -or $info.InstallationType -ne 'Client') {
            Fail 'iso-unsupported' "Unsupported Windows image $($info.Version), architecture $($info.Architecture). Use Windows 11 x64 or ARM64 installation media for a build this Atlas package supports."
        }
        if ($null -ne $architecture -and $architecture -ne [int]$info.Architecture) { Fail 'iso-unsupported' 'Mixed x64 and ARM64 installation images are not supported.' }
        $architecture = [int]$info.Architecture
    }
    if ($null -eq $architecture) { Fail 'iso-unsupported' 'The ISO contains no Windows installation images.' }
    $bootFile = if ($architecture -eq 12) { 'efi\boot\bootaa64.efi' } else { 'efi\boot\bootx64.efi' }
    if (-not (Test-Path -LiteralPath (Join-Path $Root $bootFile) -PathType Leaf)) { Fail 'iso-unsupported' "The ISO is missing its architecture's UEFI boot file: $bootFile" }
    return [pscustomobject]@{ imagePath=$images[0]; architecture=$architecture }
}

function Write-AtlasUsbDriveList {
    $drives = @(Get-Disk | Where-Object { Test-AtlasUsbDisk $_ } | ForEach-Object { Get-AtlasUsbIdentity $_ -IncludeVolumes })
    Write-Output ('ATLAS_RESULT:' + (@{ drives=$drives } | ConvertTo-Json -Depth 5 -Compress))
}

function Invoke-AtlasUsbEject {
    param($Request)
    $disk = Assert-AtlasUsbIdentity $Request.drive
    if (-not ('AtlasUsbEject' -as [type])) {
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
    }
    $device = Get-AtlasUsbEjectTarget $disk
    $null = Assert-AtlasUsbIdentity $Request.drive
    [AtlasUsbEject]::Eject($device)
    Write-Output 'ATLAS_RESULT:{"ejected":true}'
}

function Invoke-AtlasUsbWorker {
    $request = Read-AtlasUsbRequest $RequestFile
    if ($Operation -eq 'List') { Write-AtlasUsbDriveList; return }
    if ($Operation -eq 'Eject') { Invoke-AtlasUsbEject $request; return }
    $disk = Assert-AtlasUsbIdentity $request.drive
    if ($request.eraseConfirmed -ne $true) { throw 'Erasing this USB drive has not been confirmed.' }
    Assert-AtlasUsbPaths $disk @($request.source,$RequestFile,$request.app)
    $source = (Get-Item -LiteralPath $request.source).FullName
    if ([IO.Path]::GetExtension($source) -ine '.iso') { Fail 'iso-unsupported' 'Select a Windows installation ISO.' }
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
        if ($volume.Count -ne 1 -or -not $volume[0].DriveLetter) { Fail 'iso-unsupported' 'The ISO has no readable filesystem.' }
        $root = "$($volume[0].DriveLetter):\"
        Import-Module Dism
        $mediaInfo = Get-AtlasUsbMediaInfo $root @($request.supportedBuilds)
        $images = @($mediaInfo.imagePath)
        $files = @(Get-ChildItem -LiteralPath $root -Recurse -File -Force | ForEach-Object {
            if (($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { Fail 'iso-unsupported' 'The ISO contains a linked file.' }
            [pscustomobject]@{ source=$_.FullName; relative=$_.FullName.Substring($root.Length); bytes=$_.Length; hash=$null }
        })
        $large = @($files | Where-Object { $_.bytes -ge 4GB })
        foreach ($file in $large) { if ($file.source -ine $images[0]) { Fail 'iso-unsupported' "This file exceeds the FAT32 limit: $($file.relative)" } }
        if ($large.Count -gt 0) {
            $scratch = Join-Path $PSScriptRoot 'split'
            [void][IO.Directory]::CreateDirectory($scratch)
            $workVolume = Get-Volume -DriveLetter $PSScriptRoot.Substring(0,1)
            $needed = [long]$large[0].bytes * 3 + 2GB
            if ($workVolume.SizeRemaining -lt $needed) { Fail 'working-space' 'There is not enough working space to prepare the Windows image.' }
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
            # 3800 MB parts stay under FAT32's 4 GB file limit.
            Split-WindowsImage -ImagePath $wim -SplitImagePath (Join-Path $scratch 'install.swm') -FileSize 3800 -CheckIntegrity | Out-Null
            $files = @($files | Where-Object { $_.source -ine $images[0] })
            $files += @(Get-ChildItem -LiteralPath $scratch -Filter '*.swm' -File | ForEach-Object {
                [pscustomobject]@{ source=$_.FullName; relative=('sources\'+$_.Name); bytes=$_.Length; hash=$null }
            })
        }
        # Windows formats FAT32 only up to 32 GB. 16 MB stays free for the partition
        # table and alignment.
        $capacity = [long]([math]::Floor([math]::Min(32000000000, $disk.Size - 16MB) / 1MB) * 1MB)
        $total = [long](($files | Measure-Object bytes -Sum).Sum)
        if ($total + 512MB -gt $capacity -or @($files | Where-Object { $_.bytes -ge 4GB }).Count -gt 0) { Fail 'does-not-fit' 'The prepared files do not fit the USB installation partition.' }
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
        Test-AtlasUsbCopy $files $target $request.drive $usbVolume $total
        Assert-AtlasUsbVolume $request.drive $usbVolume
        Write-Output ('ATLAS_RESULT:' + (@{ verified=$true; driveLetter=[string]$usbVolume.DriveLetter; files=$files.Count } | ConvertTo-Json -Compress))
    } finally {
        if ($ownedMount) { Dismount-DiskImage -ImagePath $source -ErrorAction Continue | Out-Null }
        $sourceLock.Dispose()
        # Remove only the split scratch folder; logs and manifest.json stay in the job.
        $scratchPath = Join-Path $PSScriptRoot 'split'
        if (Test-Path -LiteralPath $scratchPath) { Remove-Item -LiteralPath $scratchPath -Recurse -Force }
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
