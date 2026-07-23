@{
    Name        = 'Hide Gallery in File Explorer'
    Description = 'Hides the ''Gallery'' picture view in the File Explorer navigation pane'
    Registry    = @(
        @{ Path = 'HKCU\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}'; Name = 'System.IsPinnedToNameSpaceTree'; Type = 'DWord'; Data = 0 }
    )
}
