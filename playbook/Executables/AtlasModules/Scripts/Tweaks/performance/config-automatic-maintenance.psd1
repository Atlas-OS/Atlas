@{
    Name        = 'Configure Automatic Maintenance'
    Description = 'Stops Automatic Maintenance waking the PC. Maintenance itself stays on, because it runs drive optimisation (defragmentation and TRIM) and other upkeep.'
    Registry    = @(
        # Group Policy: Windows Components > Maintenance Scheduler >
        # Automatic Maintenance WakeUp Policy (msched.admx), set to Disabled.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Task Scheduler\Maintenance'; Name = 'WakeUp'; Type = 'DWord'; Data = 0 }
    )
}
