@{
    Name        = 'ShortcutText'
    Description = 'The " - Shortcut" text suffix on newly created shortcuts.'
    Elevation   = 'Admin'
    States      = @(
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Shortcut Text\Disable Shortcut Text (default).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates'; Name = 'ShortcutNameTemplate'; Type = 'String'; Data = '"%s.lnk"' }
            )
        }
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Shortcut Text\Restore Shortcut Text.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates'; Name = 'ShortcutNameTemplate'; Operation = 'Delete' }
            )
        }
    )
}
