<#
.SYNOPSIS
  Sets the Windows Explorer file icon for .apbx Playbook files (e.g. "EBOS Release.apbx")
  to a custom logo, using playbook.png (converted to playbook.ico).

.NOTES
  - AME Wizard does NOT support an in-playbook <Icon> element in this version
    (it throws "Unrecognized element 'Icon'"), so the icon can only be set as the
    Explorer *file-type* icon via the registry.
  - This registers the .apbx file type (HKCU, no admin needed) and points its
    DefaultIcon at playbook.ico.
  - For a deployed image, use -Deploy: the .ico is copied to C:\ProgramData\AtlasPlaybook
    and the file type is registered under HKLM (machine-wide, all users) — suitable for
    running from SetupComplete.cmd in the SYSTEM context.
#>
[CmdletBinding()]
param(
    [string]$PngPath,
    [string]$IcoPath,
    [string]$ApbxPath,
    [switch]$Deploy,
    [switch]$MakeShortcut
)

$ErrorActionPreference = 'Stop'

# Assets (playbook.png/ico) may live next to this script (deploy: C:\EBOS)
# or in the Playbook root (dev: parent of Executables). Resolve either way.
$searchDirs = @($PSScriptRoot, (Split-Path $PSScriptRoot -Parent))
function Resolve-Asset {
    param([string]$Name)
    foreach ($d in $searchDirs) {
        $candidate = Join-Path $d $Name
        if (Test-Path $candidate) { return $candidate }
    }
    return Join-Path $PSScriptRoot $Name
}
if (-not $PngPath) { $PngPath = Resolve-Asset "playbook.png" }
if (-not $IcoPath) { $IcoPath = Resolve-Asset "playbook.ico" }
if (-not [IO.Path]::IsPathRooted($PngPath)) { $PngPath = Resolve-Asset $PngPath }
if (-not [IO.Path]::IsPathRooted($IcoPath)) { $IcoPath = Resolve-Asset $IcoPath }

if (-not (Test-Path $PngPath)) { throw "Source PNG not found: $PngPath" }

# --- 1. Build a high-quality multi-size .ico from playbook.png (every run) ---
Add-Type -AssemblyName System.Drawing
function New-IcoFromPng {
    param([string]$PngPath, [string]$IcoPath, [int[]]$Sizes = @(256, 48, 32, 16))
    $src = [System.Drawing.Image]::FromFile($PngPath)
    $streams = @()
    try {
        foreach ($s in $Sizes) {
            $bmp = New-Object System.Drawing.Bitmap($s, $s)
            $bmp.SetResolution(96, 96)
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $g.Clear([System.Drawing.Color]::Transparent)
            $g.DrawImage($src, 0, 0, $s, $s)
            $g.Dispose()
            $ms = New-Object System.IO.MemoryStream
            $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
            $streams += $ms
            $bmp.Dispose()
        }
    } finally { $src.Dispose() }
    $out = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($out)
    $bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]$Sizes.Count)
    $offset = 6 + 16 * $Sizes.Count
    $imageBytes = $streams | ForEach-Object { $_.ToArray() }
    for ($i = 0; $i -lt $Sizes.Count; $i++) {
        $s = $Sizes[$i]; $bytes = $imageBytes[$i]
        $w = if ($s -ge 256) { 0 } else { $s }
        $bw.Write([byte]$w); $bw.Write([byte]$w); $bw.Write([byte]0); $bw.Write([byte]0)
        $bw.Write([uint16]1); $bw.Write([uint16]32)
        $bw.Write([uint32]$bytes.Length); $bw.Write([uint32]$offset)
        $offset += $bytes.Length
    }
    foreach ($b in $imageBytes) { $bw.Write($b) }
    $bw.Flush()
    [System.IO.File]::WriteAllBytes($IcoPath, $out.ToArray())
    $bw.Close()
    $streams | ForEach-Object { $_.Dispose() }
}
if (Test-Path $PngPath) {
    New-IcoFromPng -PngPath $PngPath -IcoPath $IcoPath
    Write-Host "Rebuilt multi-size $IcoPath from $PngPath" -ForegroundColor Green
} else {
    Write-Warning "playbook.png not found at $PngPath; keeping existing $(Split-Path $IcoPath -Leaf) if present."
}

# --- 2. Optional: copy to a stable deploy location ---
$iconRef = $IcoPath
if ($Deploy) {
    $destDir = Join-Path $env:ProgramData "AtlasPlaybook"
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    Copy-Item -Path $IcoPath -Destination (Join-Path $destDir "playbook.ico") -Force
    $iconRef = Join-Path $destDir "playbook.ico"
    Write-Host "Deployed icon to $iconRef" -ForegroundColor Green
}

# --- 3. Register the .apbx file type icon ---
# Without -Deploy: per-user (HKCU, no admin). With -Deploy: machine-wide (HKLM),
# so it applies to every user when run during image setup (SYSTEM context).
$prog = "AtlasPlaybook.apbx"
if ($Deploy) {
    $classes = "HKLM:\Software\Classes"
} else {
    $classes = "HKCU:\Software\Classes"
}
New-Item -Path "$classes\.apbx" -Force | Out-Null
Set-ItemProperty -Path "$classes\.apbx" -Name "(default)" -Value $prog
New-Item -Path "$classes\$prog" -Force | Out-Null
Set-ItemProperty -Path "$classes\$prog" -Name "(default)" -Value "Atlas Playbook"
New-Item -Path "$classes\$prog\DefaultIcon" -Force | Out-Null
Set-ItemProperty -Path "$classes\$prog\DefaultIcon" -Name "(default)" -Value "$iconRef,0"
Write-Host "Registered .apbx icon ($classes) -> $iconRef,0" -ForegroundColor Green

# --- 4. Refresh the Explorer icon cache ---
cmd /c "ie4uinit.exe -show" 2>$null
Write-Host "Done. Restart Explorer if the icon doesn't refresh immediately." -ForegroundColor Green

# --- 5. (Optional) Create a desktop shortcut to the .apbx that carries the E icon ---
# NOTE: Windows cannot give a per-file icon to a .apbx itself (Explorer only shows the
# file-TYPE icon). A .lnk shortcut CAN carry its own icon, so this is the practical
# "per-file" route: the shortcut on the desktop shows the E, the file-type stays generic.
if ($MakeShortcut) {
    if (-not $ApbxPath) {
        $cand = @(
            (Join-Path $env:PUBLIC "Desktop\EBOS Release.apbx"),
            (Join-Path $env:ProgramData "EBOS\EBOS Release.apbx"),
            "C:\EBOS\EBOS Release.apbx",
            (Join-Path (Split-Path $PSScriptRoot -Parent) "EBOS Release.apbx")
        )
        foreach ($c in $cand) { if (Test-Path $c) { $ApbxPath = $c; break } }
    }
    if (-not $ApbxPath -or -not (Test-Path $ApbxPath)) {
        Write-Warning "-MakeShortcut: could not locate the .apbx; skipping shortcut."
    } else {
        $linkDir = Join-Path $env:PUBLIC "Desktop"
        if (-not (Test-Path $linkDir)) { $linkDir = [Environment]::GetFolderPath('CommonDesktopDirectory') }
        $link = Join-Path $linkDir "EBOS Release.lnk"
        $ws = New-Object -ComObject WScript.Shell
        $sc = $ws.CreateShortcut($link)
        $sc.TargetPath = $ApbxPath
        $sc.IconLocation = "$iconRef,0"
        $sc.Description = "EBOS Playbook (AME Wizard)"
        $sc.Save()
        Write-Host "Created shortcut $link -> $ApbxPath (icon: $iconRef)" -ForegroundColor Green
    }
}
