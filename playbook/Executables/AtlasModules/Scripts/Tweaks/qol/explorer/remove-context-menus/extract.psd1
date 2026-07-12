@{
    Name        = 'Remove ''Extract'' from Context Menu'
    Description = 'Removes ''Extract'' from Context Menu'
    Run         = @(
        @{
            Exe  = '{windir}\System32\WindowsPowerShell\v1.0\powershell.exe'
            Args = @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', '{windir}\AtlasModules\Scripts\Internal\Invoke-AtlasInstallMachineToggle.ps1', '-Name', 'ExtractContextMenu')
            Wait = $true
        }
    )
}
