@{
    Name        = 'Disable Commonly Annoying Features and Shortcuts'
    Description = 'Disables commonly annoying features such as pressing shift 5 times for sticky keys.'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Accessibility\HighContrast'; Name = 'Flags'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\Control Panel\Accessibility\Keyboard Response'; Name = 'Flags'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\Control Panel\Accessibility\MouseKeys'; Name = 'Flags'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\Control Panel\Accessibility\StickyKeys'; Name = 'Flags'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\Control Panel\Accessibility\ToggleKeys'; Name = 'Flags'; Type = 'DWord'; Data = 0 }

        # Disable language bar shortcuts
        @{ Path = 'HKCU\Control Panel\Input Method\Hot Keys\00000104'; Operation = 'DeleteKey' }
        @{ Path = 'HKCU\Keyboard Layout\Toggle'; Name = 'Layout Hotkey'; Type = 'DWord'; Data = 3 }
        @{ Path = 'HKCU\Keyboard Layout\Toggle'; Name = 'Language Hotkey'; Type = 'DWord'; Data = 3 }
        @{ Path = 'HKCU\Keyboard Layout\Toggle'; Name = 'Hotkey'; Type = 'DWord'; Data = 3 }

        # Disable Narrator shortcut
        @{ Path = 'HKCU\Software\Microsoft\Narrator\NoRoam'; Name = 'WinEnterLaunchEnabled'; Type = 'DWord'; Data = 0 }
    )
}
