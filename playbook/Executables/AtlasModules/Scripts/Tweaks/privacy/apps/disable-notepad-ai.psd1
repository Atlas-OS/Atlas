@{
    Name        = 'Disable Notepad AI Features'
    Description = 'Turns off the cloud AI features in Notepad, such as Rewrite and Summarize, and their sign-in prompts.'
    Registry    = @(
        # https://learn.microsoft.com/windows/client-management/manage-notepad
        @{ Path = 'HKLM\SOFTWARE\Policies\WindowsNotepad'; Name = 'DisableAIFeatures'; Type = 'DWord'; Data = 1 }
    )
}
