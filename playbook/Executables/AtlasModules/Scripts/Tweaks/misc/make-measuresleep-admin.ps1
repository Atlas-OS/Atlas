# Companion of make-measuresleep-admin.psd1: flags the MeasureSleep utility to always
# run elevated (it requires admin). The value name embeds the Windows directory, so it
# cannot be expressed declaratively.
$ErrorActionPreference = 'Stop'

$layersKey = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
if (-not (Test-Path -LiteralPath $layersKey)) {
    New-Item -Path $layersKey -Force | Out-Null
}

Set-ItemProperty -Path $layersKey `
    -Name "$([Environment]::GetFolderPath('Windows'))\AtlasDesktop\3. General Configuration\Timer Resolution\! MeasureSleep.exe" `
    -Value '~ RUNASADMIN' -Force
