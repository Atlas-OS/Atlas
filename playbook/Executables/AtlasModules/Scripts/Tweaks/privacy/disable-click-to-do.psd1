@{
    Name        = 'Disable Click To Do'
    Description = 'Disables the Click To Do AI feature'
    Registry    = @(
        @{ Path = 'HKCU\Software\Policies\Microsoft\Windows\WindowsAI'; Name = 'DisableClickToDo'; Operation = 'Delete' }
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'; Name = 'DisableClickToDo'; Type = 'DWord'; Data = 1 }
    )
}
