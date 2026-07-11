@{
    Name        = 'Add ''Merge as administrator'' to Context Menu'
    Description = 'Adds a UAC-backed Administrator merge command to the context menu for registry files'
    # The companion owns the complete multi-key transition so it can reject customized
    # state and commit the fixed command before changing the user-visible label.
    Script      = 'merge-as-administrator.ps1'
}
