@{
    Name        = 'Disable UAC Secure Desktop'
    Description = 'Shows UAC prompts on the normal desktop instead of the secure desktop, so the screen doesn''t dim. The secure desktop stops other software spoofing or interacting with the prompt; without it, other apps can draw over UAC prompts or read what you type into them.'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name = 'PromptOnSecureDesktop'; Type = 'DWord'; Data = 0 }
    )
}
