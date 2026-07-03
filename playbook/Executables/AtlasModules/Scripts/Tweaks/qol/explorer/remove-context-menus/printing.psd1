@{
    Name        = 'Remove ''Printing'' from Context Menus'
    Description = 'Removes printing from context menus as users normally print from apps anyways'
    Run         = @(
        # /justcontext removes only the context menu entries (not the services); /silent
        # is required so the toggle does not pause for "Press Enter to exit" unattended.
        @{ Exe = '{windir}\AtlasDesktop\6. Advanced Configuration\Services\Printing\Disable Printing.cmd'; Args = '/justcontext /silent'; Wait = $true }
    )
}
