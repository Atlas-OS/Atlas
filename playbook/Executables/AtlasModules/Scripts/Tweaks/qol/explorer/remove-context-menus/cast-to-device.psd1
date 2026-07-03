@{
    Name        = 'Remove ''Cast to device'' from Context Menu'
    Description = 'Removes ''Cast to device'' from Context Menu'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'; Name = '{7AD84985-87B4-4a16-BE58-8B72A5B390F7}'; Type = 'String'; Data = '' }
    )
}
