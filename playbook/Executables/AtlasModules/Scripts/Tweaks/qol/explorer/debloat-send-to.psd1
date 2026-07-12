@{
    Name        = 'Debloat Send-To Context Menu'
    Description = 'Removes commonly un-used items from the Send-To context menu in Explorer'
    Oobe        = $false
    Run         = @(
        @{ Exe = '{windir}\System32\WindowsPowerShell\v1.0\powershell.exe'; Args = @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', '{windir}\AtlasModules\Scripts\Internal\Set-SendToContextMenu.ps1', '-DebloatDefaults'); Wait = $true; RunAs = 'User' }
    )
}
