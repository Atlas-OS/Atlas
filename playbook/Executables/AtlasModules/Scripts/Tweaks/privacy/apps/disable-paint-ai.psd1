@{
    Name        = 'Disable Paint AI Features'
    Description = 'Disables Paint''s AI features (Cocreator, Image Creator, generative fill), which are cloud-backed and account-linked. Applied by policy so they stay off if Paint is reinstalled from the Store.'
    Registry    = @(
        # Note the unusual key: these policies live under CurrentVersion\Policies, not
        # Software\Policies. https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-windowsai#disablecocreator
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint'; Name = 'DisableCocreator'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint'; Name = 'DisableImageCreator'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint'; Name = 'DisableGenerativeFill'; Type = 'DWord'; Data = 1 }
    )
}
