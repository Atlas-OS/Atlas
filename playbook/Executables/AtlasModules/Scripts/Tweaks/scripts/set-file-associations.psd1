@{
    Name        = 'Set File Associations'
    Description  = 'Sets file associations for the user-selected web browser and other apps.'
    # The launcher is invoked conditionally per option (including the negated
    # '!uninstall-edge' base case), which a single Option gate cannot express.
    Script       = 'set-file-associations.ps1'
}
