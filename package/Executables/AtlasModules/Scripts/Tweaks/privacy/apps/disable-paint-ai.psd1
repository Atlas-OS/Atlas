@{
    Name        = 'Disable Paint AI Features'
    Description = 'Turns off the AI features in Paint (Cocreator, Image Creator and generative fill), which need the cloud and a Microsoft account. A policy applies it, so it stays off if Paint is reinstalled from Microsoft Store.'
    Registry    = @(
        # Note the unusual key: these policies live under CurrentVersion\Policies, not Software\Policies.
        # https://learn.microsoft.com/windows/client-management/mdm/policy-csp-windowsai#disablecocreator
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint'; Name = 'DisableCocreator'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint'; Name = 'DisableImageCreator'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint'; Name = 'DisableGenerativeFill'; Type = 'DWord'; Data = 1 }
    )
}
