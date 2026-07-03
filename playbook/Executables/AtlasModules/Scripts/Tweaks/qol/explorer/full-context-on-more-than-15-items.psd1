@{
    Name        = 'Always Show the Full Context Menu On Items'
    Description = 'Fixes context menu items missing when more than 15 files are selected, this sets it to 100 items instead of 15, where some context menu items disappear'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'; Name = 'MultipleInvokePromptMinimum'; Type = 'DWord'; Data = 100 }
    )
}
