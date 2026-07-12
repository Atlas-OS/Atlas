@{
    Name        = 'Hide Gallery in File Explorer'
    Description = 'Hides the new 23H2 ''Gallery'' in File Explorer for viewing pictures'
    Registry    = @(
        @{ Path = 'HKCU\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}'; Name = 'System.IsPinnedToNameSpaceTree'; Type = 'DWord'; Data = 0 }
    )
}
