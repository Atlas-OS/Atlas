@{
    Name        = 'Prevent Dev Home and Outlook Reinstalls'
    Description = 'Stops Windows Update reinstalling Dev Home and Outlook. It applies whether or not automatic updates stay on.'
    Registry    = @(
        # Stop Windows Update reinstalling Dev Home and Outlook.
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate'; Operation = 'DeleteKey' }
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate'; Name = 'workCompleted'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate'; Operation = 'DeleteKey' }
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate'; Name = 'workCompleted'; Type = 'DWord'; Data = 1 }
        # The Orchestrator and Shell\Update values behind other app installs, such as Widgets,
        # stay in place: deleting them can't be undone, and nothing shows it helps.
    )
}
