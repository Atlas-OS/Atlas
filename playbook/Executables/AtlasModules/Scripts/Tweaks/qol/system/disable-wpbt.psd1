@{
    Name        = 'Disable Windows Platform Binary Table Execution (WPBT)'
    Description = 'Stops Windows running the program that PC firmware can supply through the Windows Platform Binary Table (WPBT) at each start, which is often OEM software. Microsoft doesn''t document the value Atlas sets.'
    Registry    = @(
        # WPBT specification: https://download.microsoft.com/download/8/A/2/8A2FB72D-9B96-4E2D-A559-4A27CF905A80/windows-platform-binary-table.docx
        # The specification does not cover DisableWpbtExecution. Community source:
        # https://github.com/Jamesits/dropWPBT
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'; Name = 'DisableWpbtExecution'; Type = 'DWord'; Data = 1 }
    )
}
