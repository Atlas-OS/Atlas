# Build-Iso.ps1 and Write-Usb.ps1 dot-source this, elevated from their protected media
# job folder, to read a Windows ISO through the drive Windows mounts it as. Each worker
# defines Fail, which writes a typed reason for the app and throws.

# Windows can mount an ISO before its volume has a drive letter, and gives it none where
# automatic mounting is off. The volume is read again every half second for up to about
# 30 seconds, and after about 10 an image Atlas mounted itself gets a free letter.
$script:AtlasIsoLetterPolls = 60
$script:AtlasIsoLetterAssignAfter = 20
# Drive letters Atlas gave its own mounts, by image path, to take back before ejecting.
$script:AtlasIsoLetters = @{}
# The longest any one storage call may take. A storage provider that stops answering
# otherwise holds the worker for minutes, then fails with an unrelated error.
$script:AtlasIsoStorageTimeout = 120
$script:AtlasIsoSession = $null

# The storage cmdlets run as jobs on one local session with that operation timeout.
# Windows doesn't apply the timeout to every call over a local session, so
# Receive-AtlasIsoStorage also waits for each job no longer than that.
function Get-AtlasIsoStorageParameters {
    if ($null -eq $script:AtlasIsoSession) { $script:AtlasIsoSession = New-CimSession -OperationTimeoutSec $script:AtlasIsoStorageTimeout }
    return @{ CimSession = $script:AtlasIsoSession; AsJob = $true; ErrorAction = 'Continue' }
}

# The output of a storage job, or its error. A job still running at the deadline throws a
# TimeoutException and is left alone: stopping a call the provider doesn't answer can
# wait as long. $Action names the call in the message, such as 'mounting the ISO'.
function Receive-AtlasIsoStorage($Job, [string]$Action) {
    $timeout = $script:AtlasIsoStorageTimeout
    $clock = [Diagnostics.Stopwatch]::StartNew()
    if (-not (Wait-Job -Job $Job -Timeout $timeout)) {
        throw [TimeoutException]::new("Windows didn't finish $Action within $timeout seconds.")
    }
    try { Receive-Job -Job $Job -ErrorAction Stop }
    catch {
        # The session's own timeout ends the call with an error of its own.
        if ($clock.Elapsed.TotalSeconds -ge $timeout - 5) {
            throw [TimeoutException]::new("Windows didn't finish $Action within $timeout seconds: $($_.Exception.Message)")
        }
        throw
    }
    finally { Remove-Job -Job $Job -Force }
}

# vdrvroot enumerates the virtual DVD drive a mounted ISO becomes, and cdrom drives it.
# With either disabled (Start 4), Windows mounts no ISO: the mount fails, or waits
# minutes for a drive that never starts.
function Assert-AtlasIsoDrivers {
    $disabled = @(foreach ($name in @('vdrvroot', 'cdrom')) {
        $service = Get-ItemProperty -LiteralPath "HKLM:\SYSTEM\CurrentControlSet\Services\$name" -Name Start -ErrorAction SilentlyContinue
        if ($null -ne $service -and [int]$service.Start -eq 4) { $name }
    })
    if ($disabled.Count) {
        Fail 'iso-mount-drivers' "Windows can't mount an ISO while these drivers are disabled (Start 4): $($disabled -join ', '). Turn them back on and restart the PC."
    }
}

# The TimeoutException a storage call ended with, through any exception that wraps it.
function Get-AtlasIsoTimeout($Failure) {
    for ($exception = $Failure.Exception; $null -ne $exception; $exception = $exception.InnerException) {
        if ($exception -is [TimeoutException]) { return $exception }
    }
    return $null
}

# How the file at $Path is stored; nothing known when Windows can't say.
function Get-AtlasIsoFileAttributes([string]$Path) {
    try { return [IO.File]::GetAttributes($Path) } catch { return [IO.FileAttributes]::Normal }
}

# Stops the worker with the reason Windows couldn't read or mount the image at $ImagePath,
# from the error it gave ($Failure): a call that didn't finish, disabled drivers, or a
# file stored in a way Windows doesn't mount. -OwnFile for an image this worker wrote,
# which copying wouldn't change.
function Resolve-AtlasIsoMountFailure([string]$ImagePath, $Failure, [switch]$OwnFile) {
    $timeout = Get-AtlasIsoTimeout $Failure
    if ($null -ne $timeout) { Fail 'iso-mount-timeout' $timeout.Message }
    $cause = $Failure.Exception.Message
    Assert-AtlasIsoDrivers
    # Windows mounts only files stored uncompressed, unencrypted and not sparse, as a
    # partly allocated download can be. The user's file is left as it is.
    $attributes = Get-AtlasIsoFileAttributes $ImagePath
    $stored = @(foreach ($flag in @('Compressed', 'Encrypted', 'SparseFile')) { if ($attributes -band [IO.FileAttributes]::$flag) { $flag } })
    if ($stored.Count -and -not $OwnFile) {
        Fail 'iso-mount-file' "Windows couldn't mount '$ImagePath', which is stored $($stored -join ', '): $cause Copy it to a new file."
    }
    Fail 'iso-mount' "Windows couldn't mount '$ImagePath': $cause"
}

# The image object for $ImagePath. Windows can refuse even to read an image it can't
# mount. -Quiet leaves any other failure to the mount that follows.
function Get-AtlasIsoImage([string]$ImagePath, [switch]$Quiet) {
    try {
        $parameters = Get-AtlasIsoStorageParameters
        return (Receive-AtlasIsoStorage (Get-DiskImage -ImagePath $ImagePath @parameters) 'reading the ISO')
    }
    catch {
        if ($Quiet -and $null -eq (Get-AtlasIsoTimeout $_)) { return $null }
        Resolve-AtlasIsoMountFailure $ImagePath $_
    }
}

# Mounts the image at $ImagePath and returns its image object. Disabled drivers stop the
# worker first, as the mount would otherwise wait minutes for a drive that never starts.
function Mount-AtlasIso([string]$ImagePath, [switch]$ReadOnly, [switch]$OwnFile) {
    Assert-AtlasIsoDrivers
    try {
        $parameters = Get-AtlasIsoStorageParameters
        if ($ReadOnly) { $parameters.Access = 'ReadOnly' }
        return (Receive-AtlasIsoStorage (Mount-DiskImage -ImagePath $ImagePath -PassThru @parameters) 'mounting the ISO')
    }
    catch { Resolve-AtlasIsoMountFailure $ImagePath $_ -OwnFile:$OwnFile }
}

# The volumes of the image at $ImagePath, from a fresh image object: the one
# Mount-DiskImage returns can predate its volume.
function Get-AtlasIsoVolumes([string]$ImagePath) {
    $parameters = Get-AtlasIsoStorageParameters
    $image = Receive-AtlasIsoStorage (Get-DiskImage -ImagePath $ImagePath @parameters) 'reading the ISO'
    Receive-AtlasIsoStorage (Get-Volume -DiskImage $image @parameters) "reading the ISO's volume"
}

# What the log needs to tell a late letter from a missing filesystem.
function Format-AtlasIsoVolumes($Volumes) {
    $Volumes = @($Volumes)
    $described = @($Volumes | ForEach-Object {
        $letter = if ($_.DriveLetter) { [string]$_.DriveLetter } else { 'none' }
        $fileSystem = if ($_.FileSystem) { [string]$_.FileSystem } else { 'none' }
        "FileSystem=$fileSystem, DriveLetter=$letter, HealthStatus=$($_.HealthStatus), OperationalStatus=$($_.OperationalStatus)"
    })
    return "$($Volumes.Count) volume(s)" + $(if ($described.Count) { ': [' + ($described -join '; ') + ']' } else { '' })
}

# The highest letter from Z: to D: that isn't in use, as mount roots such as 'E:\'.
function Get-AtlasIsoFreeLetter([string[]]$Used) {
    foreach ($code in 90..68) {
        $root = [string][char]$code + ':\'
        if ($Used -notcontains $root) { return $root }
    }
    throw 'Every drive letter from D: to Z: is in use.'
}

function Initialize-AtlasIsoMountPoint {
    if ('AtlasIsoMountPoint' -as [type]) { return }
    Add-Type -TypeDefinition @'
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
public static class AtlasIsoMountPoint {
 [DllImport("kernel32.dll", CharSet=CharSet.Unicode, ExactSpelling=true, SetLastError=true)]
 static extern bool SetVolumeMountPointW(string mountPoint, string volumeName);
 [DllImport("kernel32.dll", CharSet=CharSet.Unicode, ExactSpelling=true, SetLastError=true)]
 static extern bool DeleteVolumeMountPointW(string mountPoint);
 [DllImport("kernel32.dll", CharSet=CharSet.Unicode, ExactSpelling=true, SetLastError=true)]
 static extern bool GetVolumeNameForVolumeMountPointW(string mountPoint, StringBuilder name, uint length);
 public static void Add(string root, string volume) {
  if (!SetVolumeMountPointW(root, volume)) throw new Win32Exception(Marshal.GetLastWin32Error());
 }
 public static void Remove(string root) {
  if (!DeleteVolumeMountPointW(root)) throw new Win32Exception(Marshal.GetLastWin32Error());
 }
 public static string Volume(string root) {
  var name = new StringBuilder(64);
  if (!GetVolumeNameForVolumeMountPointW(root, name, (uint)name.Capacity)) throw new Win32Exception(Marshal.GetLastWin32Error());
  return name.ToString();
 }
}
'@
}

# Gives the volume of the image Atlas mounted a free drive letter, and remembers it so
# Dismount-AtlasIso takes it back before ejecting the image.
function Add-AtlasIsoLetter([string]$ImagePath, [string]$VolumePath) {
    if ($VolumePath -notmatch '^\\\\\?\\Volume\{[0-9a-fA-F-]{36}\}\\$') { throw "Windows didn't give the ISO's volume a stable path: '$VolumePath'." }
    Initialize-AtlasIsoMountPoint
    $root = Get-AtlasIsoFreeLetter ([Environment]::GetLogicalDrives())
    [AtlasIsoMountPoint]::Add($root, $VolumePath)
    $script:AtlasIsoLetters[$ImagePath] = [pscustomobject]@{ Root = $root; Volume = $VolumePath }
    return $root
}

# Takes back the letter Add-AtlasIsoLetter gave, while it still names the same volume.
function Remove-AtlasIsoLetter([string]$ImagePath) {
    $letter = $script:AtlasIsoLetters[$ImagePath]
    if ($null -eq $letter) { return }
    $script:AtlasIsoLetters.Remove($ImagePath)
    Initialize-AtlasIsoMountPoint
    if ([AtlasIsoMountPoint]::Volume($letter.Root) -ieq $letter.Volume) { [AtlasIsoMountPoint]::Remove($letter.Root) }
}

# The root of the one volume, with a drive letter, of the image at $ImagePath, whose
# image object is $Disk. $Owned when this worker mounted it, so it may give it a letter.
function Get-AtlasIsoRoot {
    param([string]$ImagePath, $Disk, [switch]$Owned)
    try {
        $parameters = Get-AtlasIsoStorageParameters
        $volumes = @(Receive-AtlasIsoStorage (Get-Volume -DiskImage $Disk @parameters) "reading the ISO's volume")
        $lettered = @($volumes | Where-Object DriveLetter)
        $assigned = ''
        $queryError = ''
        for ($poll = 1; $lettered.Count -ne 1; $poll++) {
            if ($poll -gt $script:AtlasIsoLetterPolls) {
                $detail = (Format-AtlasIsoVolumes $volumes) + $assigned + $queryError
                Fail 'iso-mount' "Windows mounted '$ImagePath', but it has no single volume with a drive letter after about $([int]($script:AtlasIsoLetterPolls / 2)) seconds. $detail"
            }
            # A volume without a filesystem is no drive to read, whatever its letter.
            if ($Owned -and -not $assigned -and $poll -gt $script:AtlasIsoLetterAssignAfter -and
                $volumes.Count -eq 1 -and $volumes[0].FileSystem -and -not $volumes[0].DriveLetter) {
                try { $assigned = " Atlas gave it $(Add-AtlasIsoLetter $ImagePath ([string]$volumes[0].Path))." }
                catch { $assigned = " Atlas couldn't give it a drive letter: $($_.Exception.Message)" }
            }
            else { Start-Sleep -Milliseconds 500 }
            try { $volumes = @(Get-AtlasIsoVolumes $ImagePath); $queryError = '' }
            catch [TimeoutException] { throw }
            catch { $volumes = @(); $queryError = " The last query failed: $($_.Exception.Message)" }
            $lettered = @($volumes | Where-Object DriveLetter)
        }
        return "$($lettered[0].DriveLetter):\"
    }
    catch [TimeoutException] { Fail 'iso-mount-timeout' $_.Exception.Message }
}

# Ejects the image at $ImagePath, taking back any letter Atlas gave it first. A failure
# is written and the worker carries on, without a marker that would replace the reason
# it's failing for, unless the caller needs the image released.
function Dismount-AtlasIso([string]$ImagePath, [switch]$Required) {
    try { Remove-AtlasIsoLetter $ImagePath }
    catch { [Console]::Error.WriteLine("Couldn't take back the drive letter Atlas gave '$ImagePath'. $_") }
    try {
        $parameters = Get-AtlasIsoStorageParameters
        $null = Receive-AtlasIsoStorage (Dismount-DiskImage -ImagePath $ImagePath @parameters) 'ejecting the ISO'
    }
    catch {
        if ($Required) { throw }
        [Console]::Error.WriteLine("Couldn't eject '$ImagePath'. $($_.Exception.Message)")
    }
}
