@{
    Name        = 'LanmanWorkstation'
    Description = 'Lanman Workstation and SMB services plus the SmbDirect feature.'
    Elevation   = 'Admin'
    Warning     = 'Changes the SMB client services. While disabled, this PC cannot open network shares, mapped drives or network printers.'
    Script      = 'LanmanWorkstation.ps1'
    States      = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            Launcher      = '6. Advanced Configuration\Services\Lanman Workstation (SMB)\Disable Lanman Workstation.cmd'
            Reboot        = 'Recommend'
            Services      = @(
                @{ Name = 'KSecPkg'; StartupType = 4 }
                @{ Name = 'LanmanServer'; StartupType = 4 }
                @{ Name = 'LanmanWorkstation'; StartupType = 4 }
                @{ Name = 'mrxsmb'; StartupType = 4 }
                @{ Name = 'mrxsmb20'; StartupType = 4 }
                @{ Name = 'rdbss'; StartupType = 3 }
                @{ Name = 'srv2'; StartupType = 4 }
            )
            MachineAction = 'Disable-AtlasSmbDirectFeature'
        }
        @{
            Name          = 'Enable'
            StateValue    = 1
            Launcher      = '6. Advanced Configuration\Services\Lanman Workstation (SMB)\Enable Lanman Workstation (default).cmd'
            Reboot        = 'Recommend'
            Services      = @(
                @{ Name = 'KSecPkg'; StartupType = 0 }
                @{ Name = 'LanmanServer'; StartupType = 2 }
                @{ Name = 'LanmanWorkstation'; StartupType = 2 }
                @{ Name = 'mrxsmb'; StartupType = 3 }
                @{ Name = 'mrxsmb20'; StartupType = 3 }
                @{ Name = 'rdbss'; StartupType = 1 }
                @{ Name = 'srv2'; StartupType = 3 }
            )
            MachineAction = 'Enable-AtlasSmbDirectFeature'
        }
    )
}
