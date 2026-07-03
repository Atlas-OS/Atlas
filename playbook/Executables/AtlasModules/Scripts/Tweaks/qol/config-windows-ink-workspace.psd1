@{
    Name        = 'Configure Windows Ink Workspace'
    Description = 'Configures the Windows Ink Workspace to not be in the way, and have the best usability and privacy'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\PenWorkspace'; Name = 'PenWorkspaceAppSuggestionsEnabled'; Type = 'DWord'; Data = 0 }
    )
}
