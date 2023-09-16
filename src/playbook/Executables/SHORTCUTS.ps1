function New-Shortcut {
    [CmdletBinding()]
    param (
        [Parameter( Mandatory = $True )][string]$ShortcutPath,
        [Parameter( Mandatory = $True )][string]$Target,
        [string]$Arguments,
        [string]$Icon
    )

    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $Target
    if ($null -ne $Icon) { $Shortcut.IconLocation = $Icon }
    if ($null -ne $Arguments) { $Shortcut.Arguments = $Arguments }
    $Shortcut.Save()
}

$defaultShortcut = "$env:SystemDrive\Users\Default\Desktop\Atlas.lnk"
New-Shortcut -Icon "$env:WinDir\AtlasModules\Other\atlas-folder.ico,0" -Target "$env:WinDir\AtlasDesktop" -ShortcutPath $defaultShortcut
foreach ($user in $(Get-ChildItem -Path "$env:SystemDrive\Users" -Directory | Where-Object { 'Public' -notcontains $_.Name })) {
    Copy-Item $defaultShortcut -Destination "$($user.FullName)\Desktop" -Force
}
Copy-Item $defaultShortcut -Destination "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Force

$runAsTI = "$env:WinDir\AtlasModules\Scripts\RunAsTI.cmd"
$default = "$env:WinDir\AtlasDesktop\8. Troubleshooting\Default"
New-Shortcut -ShortcutPath "$default Windows Services and Drivers.lnk" -Target "$runAsTI" -Arguments "$env:WinDir\AtlasModules\Other\winServices.reg" -Icon "$env:WinDir\regedit.exe,1"
New-Shortcut -ShortcutPath "$default Atlas Services and Drivers.lnk" -Target "$runAsTI" -Arguments "$env:WinDir\AtlasModules\Other\atlasServices.reg" -Icon "$env:WinDir\regedit.exe,1"
