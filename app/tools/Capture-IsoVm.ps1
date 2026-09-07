# Read-only screenshot of the dedicated ISO validation VM, through Hyper-V.
param([string]$OutFile = (Join-Path $env:TEMP 'atlas-iso-vm.png'), [string]$VMName = 'Atlas-ISO-Beta-Validation')
$ErrorActionPreference = 'Stop'
$id = (Get-VM -Name $VMName).Id.ToString()
$setting = Get-CimInstance -Namespace root/virtualization/v2 -ClassName Msvm_VirtualSystemSettingData -Filter "VirtualSystemIdentifier='$id'" |
    Where-Object VirtualSystemType -eq 'Microsoft:Hyper-V:System:Realized'
$service = Get-CimInstance -Namespace root/virtualization/v2 -ClassName Msvm_VirtualSystemManagementService
$shot = Invoke-CimMethod -InputObject $service -MethodName GetVirtualSystemThumbnailImage -Arguments @{ TargetSystem=$setting; WidthPixels=[uint16]1024; HeightPixels=[uint16]768 }
if ($shot.ReturnValue -ne 0) { throw "Hyper-V screenshot failed: $($shot.ReturnValue)" }
Add-Type -AssemblyName System.Drawing
# Hyper-V may prefix the raw pixels with a four-byte thumbnail header.
# Decode through managed bounds-checked accesses; never copy an unchecked
# provider buffer into unmanaged bitmap memory.
[byte[]]$pixels = $shot.ImageData
$offset = $pixels.Length - (1024 * 768 * 2)
if ($offset -notin @(0,4)) { throw "Unexpected thumbnail size: $($pixels.Length)" }
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System.Drawing;
public static class AtlasVmPixels {
 public static void Save(byte[] bytes, int offset, string path) {
  using (var bitmap = new Bitmap(1024,768)) {
   for (int y=0;y<768;y++) for(int x=0;x<1024;x++) {
    int i=offset+(y*1024+x)*2;
    int rgb=bytes[i]|(bytes[i+1]<<8);
    bitmap.SetPixel(x,y,Color.FromArgb(((rgb>>11)&31)*255/31,((rgb>>5)&63)*255/63,(rgb&31)*255/31));
   }
   bitmap.Save(path,System.Drawing.Imaging.ImageFormat.Png);
  }
 }
}
"@
[AtlasVmPixels]::Save($pixels,$offset,$OutFile)
Write-Output $OutFile
