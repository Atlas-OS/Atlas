@{
    Name        = 'Hide Gallery in File Explorer'
    Description = 'Hides the new 23H2 ''Gallery'' in File Explorer for viewing pictures'
    # Use this instead once AME fixes hives issue:
    # @{ Path = 'HKCU\SOFTWARE\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}'; Name = 'System.IsPinnedToNameSpaceTree'; Type = 'DWord'; Data = 0 }
    Run         = @(
        @{ Exe = '{windir}\AtlasDesktop\4. Interface Tweaks\File Explorer Customization\Gallery\Disable Gallery (default).cmd'; Args = '/silent'; Wait = $true }
    )
}
