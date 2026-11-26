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

# The volumes of the image at $ImagePath, from a fresh image object: the one
# Mount-DiskImage returns can predate its volume.
function Get-AtlasIsoVolumes([string]$ImagePath) {
    Get-DiskImage -ImagePath $ImagePath | Get-Volume
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
    $volumes = @($Disk | Get-Volume)
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
        catch { $volumes = @(); $queryError = " The last query failed: $($_.Exception.Message)" }
        $lettered = @($volumes | Where-Object DriveLetter)
    }
    return "$($lettered[0].DriveLetter):\"
}

# Ejects the image at $ImagePath, taking back any letter Atlas gave it first. A failure
# is written and the worker carries on, unless the caller needs the image released.
function Dismount-AtlasIso([string]$ImagePath, [switch]$Required) {
    try { Remove-AtlasIsoLetter $ImagePath }
    catch { [Console]::Error.WriteLine("Couldn't take back the drive letter Atlas gave '$ImagePath'. $_") }
    $action = if ($Required) { 'Stop' } else { 'Continue' }
    Dismount-DiskImage -ImagePath $ImagePath -ErrorAction $action | Out-Null
}
