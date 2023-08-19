$defaultShortcut = "$env:SystemDrive\Users\Default\Desktop\Atlas.lnk"

$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($defaultShortcut)
$Shortcut.TargetPath = "$env:WinDir\AtlasDesktop"
$Shortcut.Save()

foreach ($user in $(Get-ChildItem -Path "$env:SystemDrive\Users" -Directory | Where-Object { 'Public' -notcontains $_.Name }))) {
    Copy-Item $defaultShortcut -Destination "$($user.FullName)\Desktop" -Force
}