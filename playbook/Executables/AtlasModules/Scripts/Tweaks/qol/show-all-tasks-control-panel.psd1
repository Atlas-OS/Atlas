@{
    Name        = 'Show All Tasks in Control Panel'
    Description = 'Shows ''All Tasks'' in Control Panel (God Mode), so that people can easily access all settings for QoL'
    Registry    = @(
        @{ Path = 'HKCR\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}'; Name = 'InfoTip'; Type = 'String'; Data = 'View list of all Control Panel tasks' }
        @{ Path = 'HKCR\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}'; Name = 'System.ControlPanel.Category'; Type = 'String'; Data = '5' }
    )
    # The default ('') values cannot be expressed in the Registry schema (a value name
    # is required), so they are written by the companion script.
    Script      = 'show-all-tasks-control-panel.ps1'
}
