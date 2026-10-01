@{
    Name        = 'Configure Automatic Maintenance'
    Description = 'Prevents Automatic Maintenance from waking the computer. Maintenance itself deliberately stays enabled - it drives auto-defrag/TRIM and more.'
    Registry    = @(
        # Group Policy: Windows Components > Maintenance Scheduler >
        # Automatic Maintenance WakeUp Policy (msched.admx), set to Disabled.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Task Scheduler\Maintenance'; Name = 'WakeUp'; Type = 'DWord'; Data = 0 }
    )
}
