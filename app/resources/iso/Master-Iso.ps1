# Windows' built-in IMAPI2FS: UDF large files and BIOS + UEFI El Torito entries.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$Media, [Parameter(Mandatory)][string]$Output, [Parameter(Mandatory)][string]$CancelFile)
$ErrorActionPreference = 'Stop'
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
 public static void SetBoots(object image, object bios, object efi) {
  ((AtlasFileSystemImage2)image).BootImageOptionsArray = new object[] { new DispatchWrapper(bios), new DispatchWrapper(efi) };
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
    $image.FileSystemsToCreate = 4
    $image.UDFRevision = 0x102
    $image.FreeMediaBlocks = 2147483647
    $image.VolumeName = 'ATLAS'
    $boots = @()
    foreach ($spec in @(@(0, 'boot\etfsboot.com'), @(239, 'efi\microsoft\boot\efisys.bin'))) {
        $stream = New-Object -ComObject ADODB.Stream
        [void]$comObjects.Add($stream)
        $stream.Type = 1
        $stream.Open()
        $stream.LoadFromFile((Join-Path $Media $spec[1]))
        $boot = New-Object -ComObject IMAPI2FS.BootOptions
        [void]$comObjects.Add($boot)
        $boot.PlatformId = [int]$spec[0]
        $boot.Emulation = 0
        $boot.AssignBootImage($stream)
        $boots += $boot
    }
    [AtlasIsoStream]::SetBoots($image, $boots[0], $boots[1])
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
