# Toggle: Visual effects / animations (Atlas minimal set vs Windows defaults).
$animationMachineAction = { param($Toggle) }
$animationUserAction = {
    param($Toggle)

    $windowsDefault = switch -CaseSensitive ([string]$Toggle.State) {
        'Atlas' { $false }
        'Default' { $true }
        default { throw "Animation: unsupported state '$($Toggle.State)'." }
    }

    Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath `
            -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') `
        -ErrorAction Stop

    $desktopKey = 'HKCU:\Control Panel\Desktop'
    $advancedKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    $dwmKey = 'HKCU:\SOFTWARE\Microsoft\Windows\DWM'
    $preferencesMask = if ($windowsDefault) {
        [byte[]]@(0x9E, 0x1E, 0x07, 0x80, 0x12, 0x00, 0x00, 0x00)
    }
    else {
        [byte[]]@(0x90, 0x12, 0x03, 0x80, 0x10, 0x00, 0x00, 0x00)
    }
    $animationValue = [int]$windowsDefault
    $minAnimate = if ($windowsDefault) { '1' } else { '0' }
    $visualFxSetting = if ($windowsDefault) { 0 } else { 3 }

    Set-AtlasRegistryValue -Path $desktopKey -Name 'FontSmoothing' -Type String -Data '2'
    Set-AtlasRegistryValue -Path $desktopKey -Name 'UserPreferencesMask' -Type Binary -Data $preferencesMask
    Set-AtlasRegistryValue -Path $desktopKey -Name 'DragFullWindows' -Type String -Data '1'
    Set-AtlasRegistryValue -Path "$desktopKey\WindowMetrics" -Name 'MinAnimate' `
        -Type String -Data $minAnimate
    Set-AtlasRegistryValue -Path $advancedKey -Name 'ListviewAlphaSelect' -Type DWord -Data 1
    Set-AtlasRegistryValue -Path $advancedKey -Name 'IconsOnly' -Type DWord -Data 0
    Set-AtlasRegistryValue -Path $advancedKey -Name 'TaskbarAnimations' -Type DWord `
        -Data $animationValue
    Set-AtlasRegistryValue -Path $advancedKey -Name 'ListviewShadow' -Type DWord -Data 1
    Set-AtlasRegistryValue `
        -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' `
        -Name 'VisualFXSetting' -Type DWord -Data $visualFxSetting
    Set-AtlasRegistryValue -Path $dwmKey -Name 'EnableAeroPeek' -Type DWord `
        -Data $animationValue
    Set-AtlasRegistryValue -Path $dwmKey -Name 'AlwaysHibernateThumbnails' -Type DWord `
        -Data $animationValue

    if ($Toggle.Silent) { return }

    $answer = Read-Host 'Finished, would you like to logout to apply the changes? [Y/N]'
    if ($answer -match '^[Yy]') {
        $logoff = Join-Path -Path $Toggle.WinDir -ChildPath 'System32\logoff.exe'
        if (-not (Test-Path -LiteralPath $logoff -PathType Leaf)) {
            throw "Animation: logoff.exe is missing at '$logoff'."
        }
        Invoke-AtlasToggleNativeCommand -FilePath $logoff `
            -ArgumentList ([string[]]@()) -AllowedExitCodes ([int[]]@(0)) | Out-Null
    }
}

@{
    Name      = 'Animation'
    Elevation = 'Admin'
    States    = [ordered]@{
        Atlas   = @{
            StateValue       = 0
            Launcher         = '4. Interface Tweaks\Visual Effects (Animations)\Atlas Visual Effects (default).cmd'
            Reboot           = 'None'
            StateRecordScope = 'Machine'
            MachineAction    = $animationMachineAction
            UserAction       = $animationUserAction
        }
        Default = @{
            StateValue       = 1
            Launcher         = '4. Interface Tweaks\Visual Effects (Animations)\Default Windows Visual Effects.cmd'
            Reboot           = 'None'
            StateRecordScope = 'Machine'
            MachineAction    = $animationMachineAction
            UserAction       = $animationUserAction
        }
    }
}
