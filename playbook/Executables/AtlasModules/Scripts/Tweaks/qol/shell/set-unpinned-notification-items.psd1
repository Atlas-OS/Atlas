@{
    Name        = 'Set Unpinned Control Center Items'
    Description = 'Disables unused control center items by default for QoL'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Quick Actions\Control Center\Unpinned'; Name = 'Microsoft.QuickAction.Cast'; Type = 'None' }
        @{ Path = 'HKCU\Control Panel\Quick Actions\Control Center\Unpinned'; Name = 'Microsoft.QuickAction.NearShare'; Type = 'None' }
        @{ Path = 'HKCU\Control Panel\Quick Actions\Control Center\QuickActionsStateCapture'; Name = 'Toggles'; Type = 'String'; Data = 'Toggles,Microsoft.QuickAction.BlueLightReduction:false,Microsoft.QuickAction.Accessibility:false,Microsoft.QuickAction.ProjectL2:false' }
    )
    # Reload the exact user's shell only after the separated live-HKCU pass succeeds.
    PostUserRegistryRefresh = 'ExplorerRefresh'
}
