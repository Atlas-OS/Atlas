@{
    Name        = 'Disable WU Auto-Updates'
    Description = 'Disables Windows Update from automatically updating Windows for QoL, at the cost of security. Split from disable-auto-updates: only this part is gated on the ''auto-updates-disable'' option.'
    Option      = 'auto-updates-disable'
    Run         = @(
        # Disable auto-updates
        @{
            Exe  = '{windir}\System32\WindowsPowerShell\v1.0\powershell.exe'
            Args = @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', '{windir}\AtlasModules\Scripts\Internal\Invoke-AtlasInstallMachineToggle.ps1', '-Name', 'AutomaticUpdates')
            Wait = $true
        }
    )
}
