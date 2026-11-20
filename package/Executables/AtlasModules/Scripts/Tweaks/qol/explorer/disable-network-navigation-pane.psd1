@{
    Name        = 'Disable Network Navigation Pane in Explorer'
    Description = 'Hides Network in the File Explorer navigation pane.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}'; Name = 'System.IsPinnedToNameSpaceTree'; Type = 'DWord'; Data = 0; VerifyWithToggle = @{ Name = 'NetworkNavigationPane'; State = 1; Operation = 'Delete' } }
    )
}
