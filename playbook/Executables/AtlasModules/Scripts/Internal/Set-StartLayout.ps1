& (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\initPowerShell.ps1')

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

# TrustedInstaller owns only the fixed loaded default-user hive. Never enumerate loaded
# live-user hives or traverse user-controlled registry links from this process.
$userKey = 'Registry::HKEY_USERS\Atlas_DefaultUser'
Write-Title 'Configuring the Windows 11 Start Menu...'
Write-Output "Using the checked Start pin layout at '$layoutJson'."
Write-Output 'Removing advertisements/stubs from the default Start Menu (23H2+)'
Remove-ItemProperty -Path "$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\Start" `
    -Name 'Config' -Force -ErrorAction SilentlyContinue
