& (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\initPowerShell.ps1')

$layoutXml = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Other\Layout.xml'

# TrustedInstaller owns only the fixed loaded default-user hive. Never enumerate loaded
# live-user hives or traverse user-controlled registry links from this process.
$userKey = 'Registry::HKEY_USERS\Atlas_DefaultUser'
$appData = Get-UserPath -Folder 'F1B32785-6FBA-4FCF-9D55-7B8E7F157091'

Write-Title "Configuring Start Menu for the default user..."
if ([string]::IsNullOrEmpty($appData) -or !(Test-Path $appData -PathType Container)) {
    Write-Warning "Couldn't find default-user Local AppData; skipping Start Menu layout copy."
}
else {
    $shellPath = Join-Path -Path $appData -ChildPath 'Microsoft\Windows\Shell'
    if (-not (Test-Path -LiteralPath $shellPath -PathType Container)) {
        New-Item -Path $shellPath -ItemType Directory -Force | Out-Null
    }
    Write-Output 'Copying default layout XML'
    Copy-Item -Path $layoutXml -Destination (Join-Path $shellPath 'LayoutModification.xml') -Force
}

Write-Output 'Removing advertisements/stubs from the default Start Menu (23H2+)'
Remove-ItemProperty -Path "$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\Start" `
    -Name 'Config' -Force -ErrorAction SilentlyContinue
