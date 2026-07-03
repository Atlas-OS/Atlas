# Companion of search-settings.psd1: OOBE-only fallback for the SearchboxTaskbarMode
# values, as applying them declaratively doesn't seem to work during OOBE installs.
$ErrorActionPreference = 'Stop'

# Only applies during OOBE: the shim writes Interactive.flag for normal installs.
$flagsPath = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Flags'
$isOobe = $false
if (-not (Test-Path -LiteralPath (Join-Path -Path $flagsPath -ChildPath 'Interactive.flag') -PathType Leaf)) {
    try {
        $oobeInProgress = (Get-ItemProperty -Path 'HKLM:\SYSTEM\Setup' -Name 'OOBEInProgress' -ErrorAction Stop).OOBEInProgress
        $isOobe = ($oobeInProgress -eq 1)
    }
    catch {
        $isOobe = $false
    }
}

if (-not $isOobe) {
    return
}

$searchKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
New-Item -Path $searchKey -Force | Out-Null
Set-ItemProperty -Path $searchKey -Name 'SearchboxTaskbarMode' -Value 1 -Type DWord -Force
Set-ItemProperty -Path $searchKey -Name 'SearchboxTaskbarModeCache' -Value 1 -Type DWord -Force
