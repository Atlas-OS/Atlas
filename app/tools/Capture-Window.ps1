# Captures a top-level window into a PNG through PrintWindow, so overlapping
# windows do not end up in the picture. Developer tooling for UI review.
param(
    [string]$ProcessName = 'AtlasManager',
    [int]$ProcessId = 0,
    [Parameter(Mandatory = $true)][string]$OutFile
)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class AtlasCaptureWin {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr hwnd, int attr, out RECT rect, int size);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hwnd, IntPtr hdc, uint flags);
    [DllImport("user32.dll")] public static extern bool IsZoomed(IntPtr hwnd);
}
"@
$process = if ($ProcessId) { Get-Process -Id $ProcessId -ErrorAction Stop } else { Get-Process -Name $ProcessName -ErrorAction Stop | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1 }
if (-not $process) { throw "No window for $ProcessName" }
$hwnd = $process.MainWindowHandle

# PrintWindow renders the full window rectangle (including the invisible resize
# border); DWM reports the visible frame so the border can be cropped away.
$full = New-Object AtlasCaptureWin+RECT
[void][AtlasCaptureWin]::GetWindowRect($hwnd, [ref]$full)
$visible = New-Object AtlasCaptureWin+RECT
[void][AtlasCaptureWin]::DwmGetWindowAttribute($hwnd, 9, [ref]$visible, [Runtime.InteropServices.Marshal]::SizeOf($visible))  # DWMWA_EXTENDED_FRAME_BOUNDS

$fullWidth = $full.Right - $full.Left; $fullHeight = $full.Bottom - $full.Top
$bitmap = New-Object System.Drawing.Bitmap $fullWidth, $fullHeight
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$hdc = $graphics.GetHdc()
[void][AtlasCaptureWin]::PrintWindow($hwnd, $hdc, 2)  # PW_RENDERFULLCONTENT
$graphics.ReleaseHdc($hdc)

# Windows 11 draws a 1px border on a window's left, right and bottom edges
# itself, inside the visible frame. PrintWindow doesn't paint it, so it comes
# out near-black, which shows against a light theme. It's left out of every
# capture of a window that isn't maximised, so both themes have the same size.
$border = if ([AtlasCaptureWin]::IsZoomed($hwnd)) { 0 } else { 1 }
$crop = New-Object System.Drawing.Rectangle `
    ($visible.Left - $full.Left + $border), ($visible.Top - $full.Top), `
    ($visible.Right - $visible.Left - 2 * $border), ($visible.Bottom - $visible.Top - $border)
$cropped = $bitmap.Clone($crop, $bitmap.PixelFormat)
$cropped.Save($OutFile, [System.Drawing.Imaging.ImageFormat]::Png)
"$($crop.Width) x $($crop.Height) -> $OutFile"
