# Captures a top-level window into a PNG through PrintWindow, so overlapping
# windows do not end up in the picture. Developer tooling for UI review.
param(
    [string]$ProcessName = 'atlas',
    [int]$ProcessId = 0,
    [Parameter(Mandatory = $true)][string]$OutFile
)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Win {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr hwnd, int attr, out RECT rect, int size);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hwnd, IntPtr hdc, uint flags);
}
"@
$process = if ($ProcessId) { Get-Process -Id $ProcessId -ErrorAction Stop } else { Get-Process -Name $ProcessName -ErrorAction Stop | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1 }
if (-not $process) { throw "No window for $ProcessName" }
$hwnd = $process.MainWindowHandle

# PrintWindow renders the full window rectangle (including the invisible resize
# border); DWM reports the visible frame so the border can be cropped away.
$full = New-Object Win+RECT
[void][Win]::GetWindowRect($hwnd, [ref]$full)
$visible = New-Object Win+RECT
[void][Win]::DwmGetWindowAttribute($hwnd, 9, [ref]$visible, [Runtime.InteropServices.Marshal]::SizeOf($visible))

$fullWidth = $full.Right - $full.Left; $fullHeight = $full.Bottom - $full.Top
$bitmap = New-Object System.Drawing.Bitmap $fullWidth, $fullHeight
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$hdc = $graphics.GetHdc()
[void][Win]::PrintWindow($hwnd, $hdc, 2)  # PW_RENDERFULLCONTENT
$graphics.ReleaseHdc($hdc)

$crop = New-Object System.Drawing.Rectangle ($visible.Left - $full.Left), ($visible.Top - $full.Top), ($visible.Right - $visible.Left), ($visible.Bottom - $visible.Top)
$cropped = $bitmap.Clone($crop, $bitmap.PixelFormat)
$cropped.Save($OutFile, [System.Drawing.Imaging.ImageFormat]::Png)
"$($crop.Width) x $($crop.Height) -> $OutFile"
