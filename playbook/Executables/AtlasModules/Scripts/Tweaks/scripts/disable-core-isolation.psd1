@{
    Name        = 'Disable Core Isolation'
    Description  = 'Disables Core Isolation (all virtualization-based security) based on the user''s options. This goes beyond Memory Integrity: Credential Guard and LSA Protection (RunAsPPL) - credential-theft defenses enabled by default on eligible 24H2 systems - are also turned off, and the Virtual Machine Platform feature is removed (breaks WSL2, Windows Sandbox and WSA until re-enabled).'
    Option      = 'disable-core-isolation'
    # Run in a child PowerShell because Set-VbsConfiguration.ps1 calls `exit`, which would
    # otherwise terminate the whole Tweaks phase process.
    Run         = @(
        @{ Exe = 'powershell.exe'; Args = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{windir}\AtlasModules\Scripts\Internal\Set-VbsConfiguration.ps1" -DisableAllVBS' }
        # Virtual Machine Platform is the other feature Microsoft's own gaming-performance
        # guidance names alongside Memory Integrity. IgnoreErrors: already-absent feature.
        # DISM exits 3010 (reboot required) on success, which the engine treats as success.
        @{ Exe = '{windir}\System32\dism.exe'; Args = '/Online /Disable-Feature /FeatureName:VirtualMachinePlatform /NoRestart'; IgnoreErrors = $true }
    )
}
