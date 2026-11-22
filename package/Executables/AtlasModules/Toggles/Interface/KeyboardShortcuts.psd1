@{
    Name        = 'KeyboardShortcuts'
    Description = 'Turns the Alt+Shift input language and Ctrl+Shift keyboard layout shortcuts on or off. Installed layouts, Windows+Space and IME shortcuts stay as they are.'
    Elevation   = 'Admin'
    States      = @(
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Keyboard Languages\Enable Language Shortcuts.cmd'
            Reboot     = 'Recommend'
            Registry   = @(
                @{ Path = 'HKCU\Keyboard Layout\Toggle'; Name = 'Hotkey'; Type = 'String'; Data = '1' }
                @{ Path = 'HKCU\Keyboard Layout\Toggle'; Name = 'Language Hotkey'; Type = 'String'; Data = '1' }
                @{ Path = 'HKCU\Keyboard Layout\Toggle'; Name = 'Layout Hotkey'; Type = 'String'; Data = '2' }
            )
        }
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Keyboard Languages\Disable Language Shortcuts.cmd'
            Reboot     = 'Recommend'
            Registry   = @(
                @{ Path = 'HKCU\Keyboard Layout\Toggle'; Name = 'Hotkey'; Type = 'String'; Data = '3' }
                @{ Path = 'HKCU\Keyboard Layout\Toggle'; Name = 'Language Hotkey'; Type = 'String'; Data = '3' }
                @{ Path = 'HKCU\Keyboard Layout\Toggle'; Name = 'Layout Hotkey'; Type = 'String'; Data = '3' }
            )
        }
    )
}
