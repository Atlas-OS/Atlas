@{
    Name        = 'Disable UAC Secure Desktop'
    Description = 'Disables switching to the Secure Desktop when prompting for elevation, so UAC prompts no longer dim the screen. Trade-off: the secure desktop exists so non-admin software cannot spoof or interact with the prompt; without it, UAC dialogs render on the normal desktop where other applications can draw over them or read typed credentials.'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name = 'PromptOnSecureDesktop'; Type = 'DWord'; Data = 0 }
    )
}
