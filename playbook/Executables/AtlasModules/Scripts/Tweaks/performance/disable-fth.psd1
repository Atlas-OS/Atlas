@{
    Name        = 'Disable Fault Tolerant Heap (FTH)'
    Description = 'FTH is a feature in Windows 7+ that applies mitigations (non-CPU related) to applications that repeatedly crash to prevent further crashes, but when the FTH is active for a certain application, there''s a performance hit.'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Microsoft\FTH'; Name = 'Enabled'; Type = 'DWord'; Data = 0; Arch = 'X64' }
    )
    Run         = @(
        # Reset & disable FTH for AMD64
        @{ Exe = 'rundll32.exe'; Args = 'fthsvc.dll,FthSysprepSpecialize'; Arch = 'X64' }
    )
    RemovePaths = @(
        # https://devblogs.microsoft.com/oldnewthing/20120125-00/?p=8463
        # Document listed as only affected in Windows 7, is also in 7+
        # https://docs.microsoft.com/en-us/windows/win32/win7appqual/fault-tolerant-heap
        # https://www.3dcadworld.com/windows-7-fault-tolerant-heap-prevents-crashing/
        # Delete folder on ARM64, as FTH doesn't exist
        @{ Path = '{windir}\AtlasDesktop\7. Security\Mitigations\Fault Tolerant Heap'; Arch = 'ARM64' }
    )
}
