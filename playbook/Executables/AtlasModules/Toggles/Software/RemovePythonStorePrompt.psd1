@{
    Name          = 'RemovePythonStorePrompt'
    Description   = 'Opens App execution aliases in Settings so you can turn off the App Installer prompts that offer Python from Microsoft Store. Installed Python versions stay as they are.'
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
