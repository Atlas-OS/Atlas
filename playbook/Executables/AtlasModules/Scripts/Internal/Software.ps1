# Thin forwarder kept for Executables\SOFTWARE.ps1; the installer logic lives in the
# Atlas.Software module (Install-AtlasSoftware). Without switches it installs the
# initial utilities (Visual C++ Runtimes, NanaZip/7-Zip, DirectX), matching the old
# behavior. Exits 1 when any component fails to install.
param (
    [switch]$Chrome,
    [switch]$Brave,
    [switch]$Firefox,
    [switch]$Toolbox
)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Modules\Atlas.Software\Atlas.Software.psd1')

$components = @()
if ($Toolbox) { $components += 'Toolbox' }
if ($Brave) { $components += 'Brave' }
if ($Firefox) { $components += 'Firefox' }
if ($Chrome) { $components += 'Chrome' }
if ($components.Count -eq 0) {
    $components = @('VCRedist', 'SevenZip', 'DirectX')
}

if (-not (Install-AtlasSoftware -Component $components)) {
    exit 1
}
