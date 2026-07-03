@{
    Name        = 'Disable File Explorer Home'
    Description = 'Removes Home from File Explorer and opens File Explorer to This PC by default'
    # Legacy playbook gated this to Windows 11 (builds >= 22000); the launcher is a
    # no-op on Windows 10, where Explorer Home does not exist.
    Run         = @(
        @{ Exe = '{windir}\AtlasDesktop\4. Interface Tweaks\File Explorer Customization\Home\Disable Home (default).cmd'; Args = '/silent'; Wait = $true }
    )
}
