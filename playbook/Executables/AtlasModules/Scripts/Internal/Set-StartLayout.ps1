& (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\initPowerShell.ps1')

function Test-AtlasStartPinPolicySupported {
    param(
        [Parameter(Mandatory = $true)][int]$Build,
        [Parameter(Mandatory = $true)][int]$Revision
    )

    # Microsoft added the local Configure Start Pins GPO in 24H2 KB5062660
    # (26100.4770). Later cumulative updates and later Windows builds include it.
    return ($Build -gt 26100 -or ($Build -eq 26100 -and $Revision -ge 4770))
}

$layoutJson = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Other\StartLayout.json'
if (-not (Test-Path -LiteralPath $layoutJson -PathType Leaf)) {
    throw "The Windows 11 Start layout is missing at '$layoutJson'."
}

try {
    $layout = Get-Content -LiteralPath $layoutJson -Raw -ErrorAction Stop |
        ConvertFrom-Json -ErrorAction Stop
}
catch {
    throw "The Windows 11 Start layout is invalid: $($_.Exception.Message)"
}
if ($layout.applyOnce -ne $true -or @($layout.pinnedList).Count -eq 0) {
    throw 'The Windows 11 Start layout must apply once and contain at least one pin.'
}

$currentVersion = Get-ItemProperty -LiteralPath `
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion' `
    -ErrorAction Stop
$windowsBuild = 0
$windowsRevision = 0
$null = [int]::TryParse([string]$currentVersion.CurrentBuildNumber, [ref]$windowsBuild)
$null = [int]::TryParse([string]$currentVersion.UBR, [ref]$windowsRevision)
if (Test-AtlasStartPinPolicySupported -Build $windowsBuild -Revision $windowsRevision) {
    Write-Output "Configure Start Pins policy support detected on OS build $windowsBuild.$windowsRevision."
}
else {
    Write-Warning (
        "Configure Start Pins cannot remove the default promotional pins on OS build " +
        "$windowsBuild.$windowsRevision. Microsoft supports this local GPO starting with " +
        'Windows 11 24H2 KB5062660 (26100.4770); install that or a later cumulative update.'
    )
}

# TrustedInstaller owns only the fixed loaded default-user hive. Never enumerate loaded
# live-user hives or traverse user-controlled registry links from this process.
$userKey = 'Registry::HKEY_USERS\Atlas_DefaultUser'
Write-Title 'Configuring the Windows 11 Start Menu...'
Write-Output "Using the checked Start pin layout at '$layoutJson'."
Write-Output 'Removing advertisements/stubs from the default Start Menu'
Remove-ItemProperty -Path "$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\Start" `
    -Name 'Config' -Force -ErrorAction SilentlyContinue
