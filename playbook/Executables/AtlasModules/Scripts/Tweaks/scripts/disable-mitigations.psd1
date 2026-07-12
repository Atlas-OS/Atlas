@{
    Name        = 'Disable Mitigations'
    Description  = 'Disables Windows exploit-protection mitigations when the user selected the option.'
    Option      = 'mitigations-disable'
    Run         = @(
        @{
            Exe  = '{windir}\System32\WindowsPowerShell\v1.0\powershell.exe'
            Args = @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', '{windir}\AtlasModules\Scripts\Invoke-Toggle.ps1', '-Name', 'Mitigations', '-State', 'Disable', '/silent')
            Wait = $true
        }
    )
}
