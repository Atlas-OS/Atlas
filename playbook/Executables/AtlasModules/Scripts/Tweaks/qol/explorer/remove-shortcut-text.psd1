@{
    Name        = 'Remove Shortcut Text'
    Description = 'Removes ''- Shortcut'' text appended onto the end of shortcuts for QoL'
    Registry    = @(
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates'; Name = 'ShortcutNameTemplate'; Type = 'String'; Data = '"%s.lnk"' }
    )
}
