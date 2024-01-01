$title = 'Preparing Atlas user settings...'

$Host.UI.RawUI.WindowTitle = $title
Write-Host $title -ForegroundColor Yellow
Write-Host $('-' * ($title.length + 3)) -ForegroundColor Yellow
Write-Host 'You''ll be logged out in 10 to 20 seconds, and once you login again, your new account will be ready for use.'

# Disable Windows 11 context menu & 'Gallery' in File Explorer
if ([System.Environment]::OSVersion.Version.Build -ge 22000) {
    reg import "$env:windir\AtlasDesktop\4. Optional Tweaks\Windows 11 Context Menu\Old Context Menu (default).reg" *>$null
    reg import "$env:windir\AtlasDesktop\4. Optional Tweaks\File Explorer Customization\Gallery\Disable Gallery (default).reg" *>$null
}

# Disable 'Network' in navigation pane
reg import "$env:windir\AtlasDesktop\3. Configuration\Network Discovery\Network Navigation Pane\Disable Network Navigation Pane (default).reg" *>$null

# Set visual effects
Start-Process -FilePath "$env:windir\AtlasDesktop\3. Configuration\Visual Effects\Atlas Visual Effects (default).cmd" -ArgumentList '/silent' -WindowStyle Hidden

# Pin 'Videos' and 'Music' folders to Home/Quick Acesss
$o = new-object -com shell.application
$o.Namespace([Environment]::GetFolderPath("MyVideos")).Self.InvokeVerb('pintohome')
$o.Namespace([Environment]::GetFolderPath("MyMusic")).Self.InvokeVerb('pintohome')

# Set taskbar search box to an icon
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 1

# Leave
Start-Sleep 5
logoff