@{
    Name        = 'Set File Associations'
    Description = 'Registers safe current-user handlers; default-app choices remain user-controlled.'
    Oobe        = $false
    Script      = 'set-file-associations.ps1'
    RunAs       = 'User'
}
