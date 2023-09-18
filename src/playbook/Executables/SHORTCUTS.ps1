function New-Shortcut {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)][string]$ShortcutPath,
        [Parameter(Mandatory = $True)][string]$Target,
        [string]$Arguments,
        [string]$IfExist,
        [string]$Icon
    )

    if ($null -ne $IfExist -and $IfExist -ne "") {
        if (-not (Test-Path -Path $ShortcutPath -PathType Leaf)) {
            exit 1
        }
    }

    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $Target
    if ($Icon -ne $null -and $Icon -ne "") {$Shortcut.IconLocation = $Icon}
    if ($null -ne $Arguments) { $Shortcut.Arguments = $Arguments }
    $Shortcut.Save()
}

$defaultShortcut = "C:\Users\Default\Desktop\Atlas.lnk"
New-Shortcut -Icon "$env:windir\AtlasModules\Other\atlas-folder.ico,0" -Target "$env:windir\AtlasDesktop" -ShortcutPath $defaultShortcut
foreach ($user in $(Get-ChildItem -Path "C:\Users" -Directory | Where-Object { 'Public' -notcontains $_.Name })) {
    Copy-Item $defaultShortcut -Destination "$($user.FullName)\Desktop" -Force
}
Copy-Item $defaultShortcut -Destination "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Force

$runAsTI = "$env:windir\AtlasModules\Scripts\RunAsTI.cmd"
$default = "$env:windir\AtlasDesktop\8. Troubleshooting\Default"
New-Shortcut -ShortcutPath "$default Windows Services and Drivers.lnk" -Target "$runAsTI" -Arguments "$env:windir\AtlasModules\Other\winServices.reg" -Icon "$env:windir\regedit.exe,1"
New-Shortcut -ShortcutPath "$default Atlas Services and Drivers.lnk" -Target "$runAsTI" -Arguments "$env:windir\AtlasModules\Other\atlasServices.reg" -Icon "$env:windir\regedit.exe,1"

# Fix Windows Tools shortcut in Windows 11
$shortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Administrative Tools.lnk"
$newTargetPath = "explorer.exe"
$newArgs = "shell:::{D20EA4E1-3957-11d2-A40B-0C5020524153}"
New-Shortcut -ShortcutPath $shortcutPath -Target $newTargetPath -Arguments $newArgs -IfExist "True"