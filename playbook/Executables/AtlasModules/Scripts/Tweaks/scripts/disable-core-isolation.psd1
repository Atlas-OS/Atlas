@{
    Name        = 'Disable Core Isolation'
    Description  = 'Disables Core Isolation (all virtualization-based security) based on the user''s options. This goes beyond Memory Integrity: Credential Guard and LSA Protection (RunAsPPL) - credential-theft defenses enabled by default on eligible 24H2 systems - are also turned off.'
    Option      = 'disable-core-isolation'
    # Run in a child PowerShell because Set-VbsConfiguration.ps1 calls `exit`, which would
    # otherwise terminate the whole Tweaks phase process.
    Run         = @(
        @{ Exe = 'powershell.exe'; Args = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{windir}\AtlasModules\Scripts\Internal\Set-VbsConfiguration.ps1" -DisableAllVBS' }
    )
}
