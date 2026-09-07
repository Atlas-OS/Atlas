function Set-AtlasVbsState {
    param($Toggle)

    # The state name is the Set-AtlasVbsConfiguration -State value: Disable or Enable.
    Import-AtlasModule -Name Atlas.Security
    Set-AtlasVbsConfiguration -State $Toggle.State
}
