@{
    Name        = 'Disable Windows Platform Binary Table Execution (WPBT)'
    Description = 'Disables WPBT with an undocumented Registry value, which is an ACPI table in your firmware to execute a program each boot of Windows such as unwanted OEM bloatware.'
    Registry    = @(
        # https://github.com/Jamesits/dropWPBT
        # https://download.microsoft.com/download/8/A/2/8A2FB72D-9B96-4E2D-A559-4A27CF905A80/windows-platform-binary-table.docx
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'; Name = 'DisableWpbtExecution'; Type = 'DWord'; Data = 1 }
    )
}
