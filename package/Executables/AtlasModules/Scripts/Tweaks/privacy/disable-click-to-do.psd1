@{
    Name        = 'Disable Click To Do'
    Description = 'Turns off Click To Do, the AI feature that suggests actions for what''s on your screen.'
    Registry    = @(
        @{ Path = 'HKCU\Software\Policies\Microsoft\Windows\WindowsAI'; Name = 'DisableClickToDo'; Operation = 'Delete' }
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'; Name = 'DisableClickToDo'; Type = 'DWord'; Data = 1 }
    )
}
