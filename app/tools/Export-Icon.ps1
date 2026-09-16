<#
.SYNOPSIS
Renders the Atlas mark into the executable icon and the window icon.

.DESCRIPTION
Draws assets/brand/atlas-mark.svg (a single polygon) on a transparent canvas
with the mark filling most of the tile, so the taskbar and title bar show a
glyph like every other Windows app rather than an opaque square. Writes
resources/atlas.ico with the standard 16 to 256 px frames as PNG entries and
assets/brand/atlas-icon-256.png for the window icon. Rerun after changing the
mark or the brand colour; build.rs embeds the .ico at compile time.
#>
[CmdletBinding()]
param(
    [double]$Fill = 0.86,
    [string]$Colour = '#1A91FF'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$svg = Get-Content (Join-Path $root 'assets/brand/atlas-mark.svg') -Raw
if ($svg -notmatch 'viewBox="0 0 (?<w>[\d.]+) (?<h>[\d.]+)"') { throw 'atlas-mark.svg has no viewBox' }
$markWidth = [double]$Matches.w
$markHeight = [double]$Matches.h
if ($svg -notmatch ' d="(?<d>[^"]+)"') { throw 'atlas-mark.svg has no path' }

# The mark is one absolute-and-relative polygon: M/l/h/H/L/z only.
function Get-MarkPoints([string]$path) {
    $points = [System.Collections.Generic.List[double[]]]::new()
    $x = 0.0; $y = 0.0
    foreach ($token in [regex]::Matches($path, '[MLHVmlhvz]|-?[\d.]+(?:e-?\d+)?') | ForEach-Object Value) {
        if ($token -match '^[A-Za-z]$') { $command = $token; $pending = @(); continue }
        $pending += [double]$token
        switch -CaseSensitive ($command) {
            'M' { if ($pending.Count -eq 2) { $x, $y = $pending; $points.Add(@($x, $y)); $pending = @(); $command = 'L' } }
            'L' { if ($pending.Count -eq 2) { $x, $y = $pending; $points.Add(@($x, $y)); $pending = @() } }
            'l' { if ($pending.Count -eq 2) { $x += $pending[0]; $y += $pending[1]; $points.Add(@($x, $y)); $pending = @() } }
            'H' { $x = $pending[0]; $points.Add(@($x, $y)); $pending = @() }
            'h' { $x += $pending[0]; $points.Add(@($x, $y)); $pending = @() }
            'V' { $y = $pending[0]; $points.Add(@($x, $y)); $pending = @() }
            'v' { $y += $pending[0]; $points.Add(@($x, $y)); $pending = @() }
        }
    }
    return $points
}
$mark = Get-MarkPoints $Matches.d

function New-Frame([int]$size) {
    # Render at 4x and downsample so small frames keep clean edges.
    $scale = 4
    $big = New-Object System.Drawing.Bitmap ($size * $scale), ($size * $scale), ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($big)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)
    $unit = $size * $scale * $Fill / $markWidth
    $offsetX = ($size * $scale - $markWidth * $unit) / 2
    $offsetY = ($size * $scale - $markHeight * $unit) / 2
    $polygon = foreach ($p in $mark) { New-Object System.Drawing.PointF ($offsetX + $p[0] * $unit), ($offsetY + $p[1] * $unit) }
    $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($Colour))
    $g.FillPolygon($brush, [System.Drawing.PointF[]]$polygon)
    $g.Dispose()
    $frame = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($frame)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($big, 0, 0, $size, $size)
    $g.Dispose(); $big.Dispose()
    return $frame
}

function Get-Png([System.Drawing.Bitmap]$bitmap) {
    $stream = New-Object System.IO.MemoryStream
    $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
    return $stream.ToArray()
}

$sizes = 16, 20, 24, 32, 48, 64, 256
$frames = [System.Collections.Generic.List[byte[]]]::new()
foreach ($size in $sizes) { $frames.Add((Get-Png (New-Frame $size))) }

# ICO: header, one 16-byte directory entry per frame, then PNG payloads.
$ico = New-Object System.IO.MemoryStream
$writer = New-Object System.IO.BinaryWriter $ico
$writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]$sizes.Count)
$offset = 6 + 16 * $sizes.Count
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $dimension = [byte]($(if ($sizes[$i] -ge 256) { 0 } else { $sizes[$i] }))
    $writer.Write($dimension); $writer.Write($dimension)
    $writer.Write([byte]0); $writer.Write([byte]0)
    $writer.Write([uint16]1); $writer.Write([uint16]32)
    $writer.Write([uint32]$frames[$i].Length); $writer.Write([uint32]$offset)
    $offset += $frames[$i].Length
}
foreach ($frame in $frames) { $writer.Write($frame) }
$writer.Flush()
[System.IO.File]::WriteAllBytes((Join-Path $root 'resources/atlas.ico'), $ico.ToArray())
[System.IO.File]::WriteAllBytes((Join-Path $root 'assets/brand/atlas-icon-256.png'), $frames[$frames.Count - 1])
Write-Host "Wrote resources/atlas.ico ($($sizes -join ', ') px) and assets/brand/atlas-icon-256.png"
