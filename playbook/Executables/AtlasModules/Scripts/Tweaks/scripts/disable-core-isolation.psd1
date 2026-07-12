@{
    Name        = 'Disable Virtualization-Based Security'
    Description = 'Disables VBS and Memory Integrity through Microsoft''s documented runtime registry controls. Credential Guard preferences, LSA protection, kernel stack protection preferences, and optional Windows features are preserved rather than guessed or removed.'
    Option      = 'disable-core-isolation'
    Run         = @(
        @{ Exe = '{windir}\System32\WindowsPowerShell\v1.0\powershell.exe'; Args = @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', '{windir}\AtlasModules\Scripts\Internal\Set-VbsConfiguration.ps1', '-State', 'Disable') }
    )
}
