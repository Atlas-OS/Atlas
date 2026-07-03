@{
    Name        = 'Configure OEM Information'
    Description = 'Configures OEM information to contain the Atlas version and the Atlas Discord server'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation'; Name = 'Manufacturer'; Type = 'String'; Data = 'Atlas Team' }
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation'; Name = 'SupportURL'; Type = 'String'; Data = 'https://discord.atlasos.net' }
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation'; Name = 'SupportPhone'; Type = 'String'; Data = 'https://github.com/Atlas-OS/Atlas' }
    )
    # Fills in the dynamic values (Atlas version/model) that cannot be expressed declaratively.
    Script      = 'config-oem-information.ps1'
}
