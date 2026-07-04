@{
    Name        = 'Disable Notepad AI Features'
    Description = 'Disables Notepad''s cloud-backed AI features (Rewrite, Summarize) and their sign-in prompts'
    Registry    = @(
        # https://learn.microsoft.com/en-us/windows/client-management/manage-notepad
        @{ Path = 'HKLM\SOFTWARE\Policies\WindowsNotepad'; Name = 'DisableAIFeatures'; Type = 'DWord'; Data = 1 }
    )
}
