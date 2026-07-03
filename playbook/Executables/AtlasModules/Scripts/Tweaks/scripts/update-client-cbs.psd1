@{
    Name        = 'Modify Client.CBS'
    Description  = 'Modifies components related to Client.CBS, the miscellaneous system package in Windows 10+.'
    # Run in a child PowerShell because Update-ClientCbs.ps1 uses `exit`/`exit 1` for flow
    # control (e.g. Windows 10 or no velocity IDs), which would otherwise terminate the
    # whole Tweaks phase process. IgnoreErrors keeps its nonzero exits from failing the tweak.
    Run         = @(
        @{ Exe = 'powershell.exe'; Args = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{windir}\AtlasModules\Scripts\Internal\Update-ClientCbs.ps1"'; IgnoreErrors = $true }
    )
}
