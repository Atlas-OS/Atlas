@{
    Name          = 'RemovePythonStorePrompt'
    Description   = 'Opens Advanced app settings for selecting App execution aliases and disabling only the App Installer Python Store prompts, preserving installed Python distributions. Requires user selection and records no state.'
    Elevation     = 'None'
    NoStateRecord = $true
    Script        = 'RemovePythonStorePrompt.ps1'
    States        = @(
        @{
            Name     = 'Run'
            Launcher = '1. Software\Remove Python Store Prompt.cmd'
            Reboot   = 'None'
            Action   = 'Remove-AtlasPythonStoreAlias'
        }
    )
}
