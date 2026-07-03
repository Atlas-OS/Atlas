@{
    Name        = 'Remove ''Extract'' from Context Menu'
    Description = 'Removes ''Extract'' from Context Menu'
    Run         = @(
        @{ Exe = '{windir}\AtlasDesktop\4. Interface Tweaks\Context Menus\Extract\Remove Extract (default).cmd'; Args = '/silent'; Wait = $true }
    )
}
