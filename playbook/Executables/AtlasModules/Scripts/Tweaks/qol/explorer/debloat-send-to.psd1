@{
    OnUpgrade   = 'Skip'
    Name        = 'Debloat Send-To Context Menu'
    Description = 'Removes commonly un-used items from the Send-To context menu in Explorer'
    Oobe        = $false
    Script      = 'debloat-send-to.ps1'
    RunAs       = 'User'
}
