@{
    Name        = 'Disable File Explorer Home'
    Description = 'Removes Home from File Explorer and opens File Explorer to This PC by default'
    MinBuild    = 22000
    Run         = @(
        @{ Exe = '{windir}\AtlasDesktop\4. Interface Tweaks\File Explorer Customization\Home\Disable Home (default).cmd'; Args = '/silent'; Wait = $true }
    )
}
