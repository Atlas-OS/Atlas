function New-Shortcut {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)][ValidateNotNullOrEmpty()][string]$ShortcutPath,
        [Parameter(Mandatory = $True)][ValidateNotNullOrEmpty()][string]$Target,
        [ValidateNotNullOrEmpty()][string]$Arguments,
        [ValidateNotNullOrEmpty()][string]$Icon,
        [switch]$IfExist
    )

    if ($IfExist) {
        if (-not (Test-Path -Path $ShortcutPath -PathType Leaf)) {
            return
        }
    }

    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $Target
    if ($Icon) { $Shortcut.IconLocation = $Icon }
    if ($Arguments) { $Shortcut.Arguments = $Arguments }
    $Shortcut.Save()
}

$defaultShortcut = "$env:SystemDrive\Users\Default\Desktop\Atlas.lnk"
New-Shortcut -Icon "$([Environment]::GetFolderPath('Windows'))\AtlasModules\Other\atlas-folder.ico,0" -Target "$([Environment]::GetFolderPath('Windows'))\AtlasDesktop" -ShortcutPath $defaultShortcut
foreach ($user in $(Get-ChildItem -Path "$env:SystemDrive\Users" -Directory | Where-Object { 'Public' -notcontains $_.Name })) {
    Copy-Item $defaultShortcut -Destination "$($user.FullName)\Desktop" -Force
}
Copy-Item $defaultShortcut -Destination "$([Environment]::GetFolderPath('CommonStartMenu'))\Programs" -Force

$runAsTI = "$([Environment]::GetFolderPath('Windows'))\AtlasModules\Scripts\RunAsTI.cmd"
$default = "$([Environment]::GetFolderPath('Windows'))\AtlasDesktop\8. Troubleshooting\Default"
New-Shortcut -ShortcutPath "$default Windows Services and Drivers.lnk" -Target "$runAsTI" -Arguments "$([Environment]::GetFolderPath('Windows'))\AtlasModules\Other\winServices.reg" -Icon "$([Environment]::GetFolderPath('Windows'))\regedit.exe,1"
New-Shortcut -ShortcutPath "$default Atlas Services and Drivers.lnk" -Target "$runAsTI" -Arguments "$([Environment]::GetFolderPath('Windows'))\AtlasModules\Other\atlasServices.reg" -Icon "$([Environment]::GetFolderPath('Windows'))\regedit.exe,1"

# Fix Windows Tools shortcut in Windows 11
$shortcutPath = "$([Environment]::GetFolderPath('ApplicationData'))\Microsoft\Windows\Start Menu\Programs\Administrative Tools.lnk"
$newTargetPath = "$([Environment]::GetFolderPath('Windows'))\explorer.exe"
$newArgs = "shell:::{D20EA4E1-3957-11d2-A40B-0C5020524153}"
New-Shortcut -ShortcutPath $shortcutPath -Target $newTargetPath -Arguments $newArgs -IfExist