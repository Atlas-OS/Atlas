@{
    Name        = 'Remove ''Printing'' from Context Menus'
    Description = 'Removes printing from context menus as users normally print from apps anyways'
    Run         = @(
        # /justcontext only removes the context menu entries, without disabling printing
        @{ Exe = '{windir}\AtlasDesktop\6. Advanced Configuration\Services\Printing\Disable Printing.cmd'; Args = '/justcontext'; Wait = $true }
    )
}
