@{
    OnUpgrade   = 'Skip'
    Name        = 'Set File Associations'
    Description = 'Registers the Atlas file handlers for the install user; which apps open each file type stays your choice.'
    Script      = 'set-file-associations.ps1'
    RunAs       = 'User'
}
