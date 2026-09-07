@{
    Name        = 'Animation'
    Description = 'Visual effects and animations: the Atlas minimal set or the Windows defaults. Both states offer a sign-out afterwards so the changes apply.'
    Elevation   = 'Admin'
    Script      = 'Animation.ps1'
    States      = @(
        @{
            Name       = 'Atlas'
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Visual Effects (Animations)\Atlas Visual Effects (default).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'FontSmoothing'; Type = 'String'; Data = '2' }
                @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'UserPreferencesMask'; Mask = @(0x0E, 0x0C, 0x04, 0, 0x02, 0, 0, 0); Type = 'Binary'; Data = @(0x90, 0x12, 0x03, 0x80, 0x10, 0x00, 0x00, 0x00) }
                @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'DragFullWindows'; Type = 'String'; Data = '1' }
                @{ Path = 'HKCU:\Control Panel\Desktop\WindowMetrics'; Name = 'MinAnimate'; Type = 'String'; Data = '0' }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ListviewAlphaSelect'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'IconsOnly'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarAnimations'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ListviewShadow'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'; Name = 'VisualFXSetting'; Type = 'DWord'; Data = 3 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\DWM'; Name = 'EnableAeroPeek'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\DWM'; Name = 'AlwaysHibernateThumbnails'; Type = 'DWord'; Data = 0 }
            )
            UserAction = 'Invoke-AtlasAnimationLogoffPrompt'
        }
        @{
            Name       = 'Default'
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Visual Effects (Animations)\Default Windows Visual Effects.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'FontSmoothing'; Type = 'String'; Data = '2' }
                @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'UserPreferencesMask'; Mask = @(0x0E, 0x0C, 0x04, 0, 0x02, 0, 0, 0); Type = 'Binary'; Data = @(0x9E, 0x1E, 0x07, 0x80, 0x12, 0x00, 0x00, 0x00) }
                @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'DragFullWindows'; Type = 'String'; Data = '1' }
                @{ Path = 'HKCU:\Control Panel\Desktop\WindowMetrics'; Name = 'MinAnimate'; Type = 'String'; Data = '1' }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ListviewAlphaSelect'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'IconsOnly'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarAnimations'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ListviewShadow'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'; Name = 'VisualFXSetting'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\DWM'; Name = 'EnableAeroPeek'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\DWM'; Name = 'AlwaysHibernateThumbnails'; Type = 'DWord'; Data = 1 }
            )
            UserAction = 'Invoke-AtlasAnimationLogoffPrompt'
        }
    )
}
