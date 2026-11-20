<#
.SYNOPSIS
Captures the README's screenshots of Atlas Manager's Get ready page.

.DESCRIPTION
Opens the existing debug build, app\target\debug\AtlasManager.exe, once per theme on the
Get ready page with the "complete" preview state, and saves the window as
docs\images\atlas-manager-get-ready-<theme>.png. The script builds nothing: run
"cargo build --locked" in app\ first. A window appears for a few seconds for each capture.

Each capture keeps its settings in a fresh folder under %TEMP% (ATLAS_APP_DATA), where the app's
log stays for diagnosis, so it never reads or changes the real app data. The preview state
installs, updates and restarts nothing. Every
ATLAS_ environment variable is cleared for the run, so one left set in the session can't change
the picture, and restored afterwards.

.PARAMETER Theme
The themes to capture: light, dark or both. Both by default.

.PARAMETER OutputDirectory
Where the PNG files go. docs\images in this repository by default.

.EXAMPLE
cargo build --locked; .\tools\Update-ReadmeScreenshots.ps1

.NOTES
Exit codes: 0 when every capture was saved; 1 when the debug build is missing, the window didn't
open or a capture failed.
#>
param(
    [ValidateSet('light', 'dark')][string[]]$Theme = @('light', 'dark'),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\..\docs\images')
)
$ErrorActionPreference = 'Stop'

$exe = Join-Path $PSScriptRoot '..\target\debug\AtlasManager.exe'
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
    throw "There's no debug build at $exe. Run 'cargo build --locked' in the app folder first; this script builds nothing."
}
$exe = (Resolve-Path -LiteralPath $exe).Path
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$OutputDirectory = (Resolve-Path -LiteralPath $OutputDirectory).Path

Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class AtlasReadmeWindow {
 public delegate bool Callback(IntPtr hwnd, IntPtr data);
 [DllImport("user32.dll")] public static extern bool EnumWindows(Callback callback, IntPtr data);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint pid);
 [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hwnd, StringBuilder text, int count);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hwnd, int command);
 [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hwnd, int x, int y, int width, int height, bool repaint);
 public static IntPtr Find(uint pid) {
  IntPtr found = IntPtr.Zero;
  EnumWindows((h,d) => { uint id; GetWindowThreadProcessId(h,out id);
   if(id==pid){ var text=new StringBuilder(256); GetWindowText(h,text,256); if(text.ToString()=="Atlas Manager") found=h; }
   return true; },IntPtr.Zero);
  return found;
 }
}
'@

$saved = Get-ChildItem Env: | Where-Object { $_.Name -like 'ATLAS_*' } | ForEach-Object { [pscustomobject]@{ Name = $_.Name; Value = $_.Value } }
try {
    foreach ($name in $Theme) {
        # A fresh folder each run, so nothing an earlier run saved changes the picture.
        $root = Join-Path $env:TEMP "atlas-readme-$name"
        if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        @{ theme = $name; language = 'en-GB' } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $root 'settings.json') -Encoding UTF8
        foreach ($variable in $saved) { Remove-Item -LiteralPath "Env:$($variable.Name)" -ErrorAction SilentlyContinue }
        $env:ATLAS_APP_DATA = $root
        $env:ATLAS_PREPARATION_PREVIEW = 'complete'
        $env:ATLAS_REVIEW_NO_RESTART = '1'
        $process = $null
        try {
            $process = Start-Process -FilePath $exe -ArgumentList @('--page', 'install', '--language', 'en-GB') -PassThru -WindowStyle Hidden -RedirectStandardError (Join-Path $root 'app.log')
            $deadline = [DateTime]::UtcNow.AddSeconds(15)
            do {
                $handle = [AtlasReadmeWindow]::Find($process.Id)
                if ($handle -eq [IntPtr]::Zero) { Start-Sleep -Milliseconds 100 }
            } while ($handle -eq [IntPtr]::Zero -and [DateTime]::UtcNow -le $deadline -and -not $process.HasExited)
            if ($handle -eq [IntPtr]::Zero) { throw "The Atlas Manager window didn't open; see $root\app.log" }
            [void][AtlasReadmeWindow]::ShowWindow($handle, 5)  # SW_SHOW
            [void][AtlasReadmeWindow]::MoveWindow($handle, 60, 60, 960, 680, $true)
            # Long enough for the window to draw its content and Mica backdrop at the new size.
            Start-Sleep -Milliseconds 1500
            $file = Join-Path $OutputDirectory "atlas-manager-get-ready-$name.png"
            & (Join-Path $PSScriptRoot 'Capture-Window.ps1') -ProcessId $process.Id -OutFile $file
        }
        finally {
            if ($null -ne $process -and -not $process.HasExited) { Stop-Process -Id $process.Id }
        }
    }
}
finally {
    foreach ($name in 'ATLAS_APP_DATA', 'ATLAS_PREPARATION_PREVIEW', 'ATLAS_REVIEW_NO_RESTART') {
        Remove-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
    }
    foreach ($variable in $saved) { Set-Item -LiteralPath "Env:$($variable.Name)" -Value $variable.Value }
}
