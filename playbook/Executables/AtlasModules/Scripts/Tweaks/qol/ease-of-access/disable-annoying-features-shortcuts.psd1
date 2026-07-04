@{
    Name        = 'Disable Commonly Annoying Features and Shortcuts'
    Description = 'Disables commonly annoying features such as pressing shift 5 times for sticky keys.'
    Registry    = @(
        # Windows stores these Flags as REG_SZ, and the data below is the stock default
        # with only the hotkey bits (HOTKEYACTIVE / CONFIRMHOTKEY) cleared - a DWORD 0
        # would clear every flag (availability/indicator bits included), not just the
        # shortcut, and can be misread by the accessibility stack.
        @{ Path = 'HKCU\Control Panel\Accessibility\HighContrast'; Name = 'Flags'; Type = 'String'; Data = '4194' }
        @{ Path = 'HKCU\Control Panel\Accessibility\Keyboard Response'; Name = 'Flags'; Type = 'String'; Data = '122' }
        @{ Path = 'HKCU\Control Panel\Accessibility\MouseKeys'; Name = 'Flags'; Type = 'String'; Data = '186' }
        @{ Path = 'HKCU\Control Panel\Accessibility\StickyKeys'; Name = 'Flags'; Type = 'String'; Data = '506' }
        @{ Path = 'HKCU\Control Panel\Accessibility\ToggleKeys'; Name = 'Flags'; Type = 'String'; Data = '58' }

        # Disable language bar shortcuts (stock values are REG_SZ; 3 = off)
        @{ Path = 'HKCU\Control Panel\Input Method\Hot Keys\00000104'; Operation = 'DeleteKey' }
        @{ Path = 'HKCU\Keyboard Layout\Toggle'; Name = 'Layout Hotkey'; Type = 'String'; Data = '3' }
        @{ Path = 'HKCU\Keyboard Layout\Toggle'; Name = 'Language Hotkey'; Type = 'String'; Data = '3' }
        @{ Path = 'HKCU\Keyboard Layout\Toggle'; Name = 'Hotkey'; Type = 'String'; Data = '3' }

        # Disable Narrator shortcut
        @{ Path = 'HKCU\Software\Microsoft\Narrator\NoRoam'; Name = 'WinEnterLaunchEnabled'; Type = 'DWord'; Data = 0 }
    )
}
