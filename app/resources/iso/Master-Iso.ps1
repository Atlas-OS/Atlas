<#
.SYNOPSIS
    Masters a bootable ISO from a media folder with Windows' built-in IMAPI2FS.
.DESCRIPTION
    Writes UDF, which allows files over 4 GiB, with BIOS and UEFI boot for x64 and
    UEFI boot only for ARM64. Build-Iso.ps1 calls it within its elevated process.
.PARAMETER Media
    The folder to master, laid out as Windows installation media.
.PARAMETER Output
    The ISO file to create; it must not exist.
.PARAMETER CancelFile
    A file whose appearance stops mastering.
.PARAMETER Architecture
    x64 or arm64; decides the boot entries.
.NOTES
    Throws on failure or cancellation, and Build-Iso.ps1 reports the error.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$Media, [Parameter(Mandatory)][string]$Output, [Parameter(Mandatory)][string]$CancelFile,
    [ValidateSet('x64','arm64')][string]$Architecture = 'x64')
$ErrorActionPreference = 'Stop'
# The GUID is IFileSystemImage2's interface ID, and DISPID 60 its BootImageOptionsArray,
# which takes several boot images as a SAFEARRAY of VARIANTs holding IDispatch pointers.
# PowerShell's late binding can't build that array, so this typed interface sets it.
Add-Type @'
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
[ComImport, Guid("D7644B2C-1537-4767-B62F-F1387B02DDFD"), InterfaceType(ComInterfaceType.InterfaceIsIDispatch)]
public interface AtlasFileSystemImage2 {
 [DispId(60)] object[] BootImageOptionsArray {
  [return: MarshalAs(UnmanagedType.SafeArray, SafeArraySubType=VarEnum.VT_VARIANT)] get;
  [param: MarshalAs(UnmanagedType.SafeArray, SafeArraySubType=VarEnum.VT_VARIANT)] set;
 }
}
public static class AtlasIsoStream {
 public static void SetBoots(object image, object[] boots) {
  var options = new object[boots.Length];
  for (int i = 0; i < boots.Length; i++) options[i] = new DispatchWrapper(boots[i]);
  ((AtlasFileSystemImage2)image).BootImageOptionsArray = options;
 }
 public static void Save(object source, string path, string cancel) {
  var stream = (IStream)source;
  var count = Marshal.AllocHGlobal(4);
  try {
   using (var output = new FileStream(path, FileMode.CreateNew, FileAccess.Write, FileShare.None)) {
    var buffer = new byte[1024 * 1024];
    for (;;) {
     if (File.Exists(cancel)) throw new OperationCanceledException("ISO creation cancelled.");
     stream.Read(buffer, buffer.Length, count);
     int read = Marshal.ReadInt32(count);
     if (read == 0) break;
     output.Write(buffer, 0, read);
    }
    output.Flush(true);
   }
  } finally { Marshal.FreeHGlobal(count); }
 }
}
'@
$comObjects = New-Object Collections.ArrayList
try {
    $image = New-Object -ComObject IMAPI2FS.MsftFileSystemImage
    [void]$comObjects.Add($image)
    $image.FileSystemsToCreate = 4 # FsiFileSystemUDF: UDF only
    $image.UDFRevision = 0x102 # UDF 1.02
    $image.FreeMediaBlocks = 2147483647 # no size limit
    $image.VolumeName = 'ATLAS'
    # Platform 0 = BIOS, 0xEF = UEFI.
    $specs = @(
        if ($Architecture -eq 'x64') { @{ Platform = 0; File = 'boot\etfsboot.com' } }
        @{ Platform = 0xEF; File = 'efi\microsoft\boot\efisys.bin' }
    )
    # An ArrayList keeps the raw COM objects; a PowerShell array would wrap them.
    $boots = New-Object Collections.ArrayList
    foreach ($spec in $specs) {
        $stream = New-Object -ComObject ADODB.Stream
        [void]$comObjects.Add($stream)
        $stream.Type = 1 # adTypeBinary
        $stream.Open()
        $stream.LoadFromFile((Join-Path $Media $spec.File))
        $boot = New-Object -ComObject IMAPI2FS.BootOptions
        [void]$comObjects.Add($boot)
        $boot.PlatformId = $spec.Platform
        $boot.Emulation = 0 # no emulation
        $boot.AssignBootImage($stream)
        [void]$boots.Add($boot)
    }
    [AtlasIsoStream]::SetBoots($image, $boots.ToArray())
    # The root retains source streams until its COM reference is released.
    $root = $image.Root
    [void]$comObjects.Add($root)
    $root.AddTree($Media, $false)
    $result = $image.CreateResultImage()
    [void]$comObjects.Add($result)
    $outputStream = $result.ImageStream
    [void]$comObjects.Add($outputStream)
    [AtlasIsoStream]::Save($outputStream, $Output, $CancelFile)
    if ((Get-Item -LiteralPath $Output).Length -ne [long]$result.TotalBlocks * [long]$result.BlockSize) { throw 'Image stream was incomplete.' }
}
finally {
    for ($i = $comObjects.Count - 1; $i -ge 0; $i--) { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($comObjects[$i]) }
}
