@{
    Name        = 'Disable Network Navigation Pane in Explorer'
    Description = 'Disables the network navigation pane/item in the Explorer sidebar for QoL by default, as it is mostly unused'
    # Use this instead once AME fixes hives issue:
    # @{ Path = 'HKCU\SOFTWARE\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}'; Name = 'System.IsPinnedToNameSpaceTree'; Type = 'DWord'; Data = 0 }
    Run         = @(
        @{ Exe = '{windir}\AtlasDesktop\3. General Configuration\File Sharing\Network Navigation Pane\Disable Network Navigation Pane (default).cmd'; Args = '/silent'; Wait = $true }
    )
}
