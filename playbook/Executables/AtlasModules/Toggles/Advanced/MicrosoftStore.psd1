@{
    Name        = 'MicrosoftStore'
    Description = 'Removes Microsoft Store for all users or restores it for your account, downloading its package from Microsoft when needed.'
    Elevation   = 'Admin'
    Warning     = 'Disable removes Microsoft Store for every user on this PC. Enable restores it for your account only and may need an Internet connection.'
    Script      = 'MicrosoftStore.ps1'
    States      = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            Launcher      = '6. Advanced Configuration\Microsoft Store\Disable Microsoft Store.cmd'
            Reboot        = 'None'
            MachineAction = 'Remove-AtlasMicrosoftStore'
        }
        @{
            Name          = 'Enable'
            StateValue    = 1
            Launcher      = '6. Advanced Configuration\Microsoft Store\Enable Microsoft Store (default).cmd'
            Reboot        = 'None'
            UserAction    = 'Register-AtlasMicrosoftStore'
        }
    )
}
