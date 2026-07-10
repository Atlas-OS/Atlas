@{
    Name        = 'Set File Associations'
    Description = 'Registers safe current-user handlers; default-app choices remain user-controlled.'
    # Browser selections are intentionally not interpreted here: Windows owns
    # protected defaults, while safe handler registrations are profile-neutral.
    Script      = 'set-file-associations.ps1'
    RunAs       = 'User'
}
