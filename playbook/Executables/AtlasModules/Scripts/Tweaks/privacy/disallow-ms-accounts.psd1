@{
    Name        = 'Disallow Users to Be Non-local'
    Description = 'For privacy and QoL, users are prevented from adding Microsoft accounts as user accounts instead of local accounts'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name = 'NoConnectedUser'; Type = 'DWord'; Data = 1 }
    )
}
