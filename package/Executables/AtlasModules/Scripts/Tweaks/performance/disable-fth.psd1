@{
    Name        = 'Disable Fault Tolerant Heap (FTH)'
    Description = 'Turns off Fault Tolerant Heap, which applies mitigations to programs that crash repeatedly and slows them down while it''s active.'
    # Microsoft's page names Windows 7, but later releases have FTH too:
    # https://learn.microsoft.com/windows/win32/win7appqual/fault-tolerant-heap
    # https://devblogs.microsoft.com/oldnewthing/20120125-00/?p=8463
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Microsoft\FTH'; Name = 'Enabled'; Type = 'DWord'; Data = 0; Arch = 'X64' }
    )
    Run         = @(
        # Reset and disable FTH on x64.
        @{ Exe = '{windir}\System32\rundll32.exe'; Args = @('fthsvc.dll,FthSysprepSpecialize'); Arch = 'X64' }
    )
    RemovePaths = @(
        # FTH doesn't exist on ARM64, so its AtlasDesktop folder is removed there.
        @{ Path = '{windir}\AtlasDesktop\7. Security\Mitigations\Fault Tolerant Heap'; Arch = 'ARM64' }
    )
}
