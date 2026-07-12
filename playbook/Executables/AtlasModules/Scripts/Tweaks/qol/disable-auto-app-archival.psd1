@{
    Name        = 'Disable Automatic Store App Archiving'
    Description = 'Disables automatic Store app archiving so that less commonly apps don''t disappear and have to be redownloaded'
    Run         = @(
        @{
            Exe  = '{windir}\System32\WindowsPowerShell\v1.0\powershell.exe'
            Args = @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', '{windir}\AtlasModules\Scripts\Internal\Invoke-AtlasInstallMachineToggle.ps1', '-Name', 'AppStoreArchiving')
            Wait = $true
        }
    )
}
