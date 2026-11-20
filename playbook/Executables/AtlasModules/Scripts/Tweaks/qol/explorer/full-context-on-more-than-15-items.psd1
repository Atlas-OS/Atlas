@{
    Name        = 'Always Show the Full Context Menu On Items'
    Description = 'Keeps the full context menu when more than 15 files are selected, by raising the limit to 100.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'; Name = 'MultipleInvokePromptMinimum'; Type = 'DWord'; Data = 100 }
    )
}
