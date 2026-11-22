@{
    Name        = 'Modify Client.CBS'
    Description  = 'Updates Client.CBS, a Windows system package, to remove adverts from Settings pages. A failure here doesn''t stop the install.'
    # Run in a child PowerShell because Update-ClientCbs.ps1 uses `exit 1` for flow
    # control (missing wsxpack manifest or a failed CBS write), which would otherwise
    # terminate the whole Tweaks phase process. IgnoreErrors keeps those exits from
    # failing the tweak: the wsxpack layout varies by servicing state and the change
    # is cosmetic (Settings-page ads), so it must never block an install.
    Run         = @(
        @{ Exe = '{windir}\System32\WindowsPowerShell\v1.0\powershell.exe'; Args = @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', '{windir}\AtlasModules\Scripts\Operations\Update-ClientCbs.ps1'); IgnoreErrors = $true }
    )
}
