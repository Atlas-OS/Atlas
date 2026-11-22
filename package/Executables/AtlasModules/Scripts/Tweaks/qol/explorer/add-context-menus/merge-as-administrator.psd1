@{
    Name        = 'Add ''Merge as administrator'' to Context Menu'
    Description = 'Adds Merge as administrator to the context menu of registry (.reg) files, which merges the file after an administrator prompt.'
    # The companion owns the complete multi-key transition so it can reject customised
    # state and commit the fixed command before changing the user-visible label.
    Script      = 'merge-as-administrator.ps1'
}
