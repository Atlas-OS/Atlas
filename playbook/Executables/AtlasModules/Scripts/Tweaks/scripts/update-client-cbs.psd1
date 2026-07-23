@{
    Name        = 'Modify Client.CBS'
    Description  = 'Modifies components related to Client.CBS, the miscellaneous system package in Windows 10+.'
    # Run in a child PowerShell because Update-ClientCbs.ps1 uses `exit 1` for flow
    # control (missing wsxpack manifest or a failed CBS write), which would otherwise
    # terminate the whole Tweaks phase process. IgnoreErrors keeps those exits from
    # failing the tweak: the wsxpack layout varies by servicing state and the change
    # is cosmetic (Settings-page ads), so it must never block an install.
    Run         = @(
        @{ Exe = '{windir}\System32\WindowsPowerShell\v1.0\powershell.exe'; Args = @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', '{windir}\AtlasModules\Scripts\Internal\Update-ClientCbs.ps1'); IgnoreErrors = $true }
    )
}
