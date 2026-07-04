@{
    Name        = 'Configure Automatic Maintenance'
    Description = 'Prevents Automatic Maintenance from waking the computer. Maintenance itself deliberately stays enabled - it drives auto-defrag/TRIM and more.'
    Registry    = @(
        # https://www.elevenforum.com/t/enable-or-disable-automatic-maintenance-to-wake-up-computer-in-windows-11.16690/
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Task Scheduler\Maintenance'; Name = 'WakeUp'; Type = 'DWord'; Data = 0 }
    )
}
