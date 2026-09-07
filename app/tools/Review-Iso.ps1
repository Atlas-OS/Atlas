# Capture read-only debug fixtures with isolated preferences. Never builds an ISO.
param(
    [string]$Language = 'en-GB',
    [ValidateSet('home','files','choices','before','before-desktop','review','review-before','progress','failed','release-unknown','complete','prepare-idle','prepare-busy','prepare-complete','prepare-failed','prepare-reboot','prepare-network','prepare-previous-worker','network-drivers','usb-select','usb-empty','usb-review','usb-progress','usb-failed','usb-complete')][string]$State = 'choices',
    [int]$Width = 900, [int]$Height = 680,
    [int]$Scroll = 0,
    [switch]$Desktop,
    [ValidateSet('light','dark')][string]$Theme = 'dark'
)
$ErrorActionPreference = 'Stop'
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class AtlasIsoReviewWindow {
 public delegate bool Callback(IntPtr hwnd, IntPtr data);
 [DllImport("user32.dll")] public static extern bool EnumWindows(Callback callback, IntPtr data);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint pid);
 [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hwnd, StringBuilder text, int count);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hwnd, int command);
 [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hwnd, int x, int y, int width, int height, bool repaint);
 [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hwnd, uint message, IntPtr wparam, IntPtr lparam);
 public static IntPtr Find(uint pid) {
  IntPtr found = IntPtr.Zero;
  EnumWindows((h,d) => { uint id; GetWindowThreadProcessId(h,out id);
   if(id==pid){ var text=new StringBuilder(256); GetWindowText(h,text,256); if(text.ToString()=="Atlas Manager") found=h; }
   return true; },IntPtr.Zero);
  return found;
 }
}
'@
$name = "atlas-iso-$Language-$State-$Width-$Theme"
$root = Join-Path $env:TEMP $name
New-Item -ItemType Directory -Path $root -Force | Out-Null
@{ theme=$Theme; language=$Language } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $root 'settings.json') -Encoding UTF8
$savedData = $env:ATLAS_APP_DATA
$savedPreparation = $env:ATLAS_PREPARATION_PREVIEW
$savedPreview = $env:ATLAS_ISO_PREVIEW
$savedDesktop = $env:ATLAS_DESKTOP_PREVIEW
if ($Desktop) { $env:ATLAS_DESKTOP_PREVIEW = '1' }
$env:ATLAS_APP_DATA = $root
$env:ATLAS_ISO_PREVIEW = $State
if ($State.StartsWith('prepare-')) { $env:ATLAS_PREPARATION_PREVIEW = $State.Substring(8) }
$process = $null
try {
    $exe = Join-Path $PSScriptRoot '..\target\debug\AtlasManager.exe'
    $page = if ($State.StartsWith('prepare-')) { 'install' } elseif ($State -eq 'home') { 'home' } else { 'iso' }
    $process = Start-Process -FilePath $exe -ArgumentList @('--page',$page,'--language',$Language) -PassThru -WindowStyle Hidden -RedirectStandardError (Join-Path $root 'app.log')
    $deadline = [DateTime]::UtcNow.AddSeconds(15)
    do {
        $handle = [AtlasIsoReviewWindow]::Find($process.Id)
        if ($handle -eq [IntPtr]::Zero) { Start-Sleep -Milliseconds 100 }
    } while ($handle -eq [IntPtr]::Zero -and [DateTime]::UtcNow -le $deadline -and -not $process.HasExited)
    if ($handle -eq [IntPtr]::Zero) { throw "Atlas window did not open; see $root\app.log" }
    [void][AtlasIsoReviewWindow]::ShowWindow($handle, 5)
    [void][AtlasIsoReviewWindow]::MoveWindow($handle, 60, 60, $Width, $Height, $true)
    Start-Sleep -Milliseconds 700
    if ($Scroll -ne 0) {
        [void][AtlasIsoReviewWindow]::SendMessage($handle, 0x020A, [IntPtr]($Scroll -shl 16), [IntPtr]((300 -shl 16) -bor 300))
        Start-Sleep -Milliseconds 300
    }
    & (Join-Path $PSScriptRoot 'Get-AccessibilityTree.ps1') -ProcessId $process.Id -Json | Set-Content -LiteralPath (Join-Path $root 'accessibility.json') -Encoding UTF8
    & (Join-Path $PSScriptRoot 'Capture-Window.ps1') -ProcessId $process.Id -OutFile (Join-Path $env:TEMP "$name.png")
}
finally {
    if ($null -ne $process -and -not $process.HasExited) { Stop-Process -Id $process.Id }
    $env:ATLAS_APP_DATA = $savedData
    $env:ATLAS_ISO_PREVIEW = $savedPreview
    $env:ATLAS_PREPARATION_PREVIEW = $savedPreparation
    $env:ATLAS_DESKTOP_PREVIEW = $savedDesktop
}
