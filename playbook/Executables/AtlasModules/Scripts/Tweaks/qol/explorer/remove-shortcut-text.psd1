@{
    Name        = 'Remove Shortcut Text'
    Description = 'Stops Windows adding " - Shortcut" to the names of new shortcuts.'
    Registry    = @(
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates'; Name = 'ShortcutNameTemplate'; Type = 'String'; Data = '"%s.lnk"' }
    )
}
