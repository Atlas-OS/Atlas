@{
    Name        = 'Disable Commonly Annoying Features and Shortcuts'
    Description = 'Disables commonly annoying features such as pressing shift 5 times for sticky keys.'
    Registry    = @(
        # Clear HOTKEYACTIVE (0x4) only, retaining enabled features and other flags.
        # Data supplies the existing Atlas fallback only when a value is absent.
        @{ Path = 'HKCU\Control Panel\Accessibility\HighContrast'; Name = 'Flags'; Mask = '4'; MigrateDwordToString = $true; Type = 'String'; Data = '4194' }
        @{ Path = 'HKCU\Control Panel\Accessibility\Keyboard Response'; Name = 'Flags'; Mask = '4'; MigrateDwordToString = $true; Type = 'String'; Data = '122' }
        @{ Path = 'HKCU\Control Panel\Accessibility\MouseKeys'; Name = 'Flags'; Mask = '4'; MigrateDwordToString = $true; Type = 'String'; Data = '186' }
        @{ Path = 'HKCU\Control Panel\Accessibility\StickyKeys'; Name = 'Flags'; Mask = '4'; MigrateDwordToString = $true; Type = 'String'; Data = '506' }
        @{ Path = 'HKCU\Control Panel\Accessibility\ToggleKeys'; Name = 'Flags'; Mask = '4'; MigrateDwordToString = $true; Type = 'String'; Data = '58' }

        # Disable language bar shortcuts (stock values are REG_SZ; 3 = off)
        @{ Path = 'HKCU\Control Panel\Input Method\Hot Keys\00000104'; Operation = 'DeleteKey' }
        @{ Path = 'HKCU\Keyboard Layout\Toggle'; Name = 'Layout Hotkey'; Type = 'String'; Data = '3' }
        @{ Path = 'HKCU\Keyboard Layout\Toggle'; Name = 'Language Hotkey'; Type = 'String'; Data = '3' }
        @{ Path = 'HKCU\Keyboard Layout\Toggle'; Name = 'Hotkey'; Type = 'String'; Data = '3' }

        # Disable Narrator shortcut
        @{ Path = 'HKCU\Software\Microsoft\Narrator\NoRoam'; Name = 'WinEnterLaunchEnabled'; Type = 'DWord'; Data = 0 }
    )
}
