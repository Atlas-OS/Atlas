@{
    Name        = 'Disable Core Isolation'
    Description  = 'Disables Core Isolation (VBS) based on the user''s options.'
    Option      = 'disable-core-isolation'
    # Run in a child PowerShell because Set-VbsConfiguration.ps1 calls `exit`, which would
    # otherwise terminate the whole Tweaks phase process.
    Run         = @(
        @{ Exe = 'powershell.exe'; Args = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{windir}\AtlasModules\Scripts\Internal\Set-VbsConfiguration.ps1" -DisableAllVBS' }
    )
}
