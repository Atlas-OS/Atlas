@{
    Name        = 'Block Adding Microsoft Accounts'
    Description = 'Stops users adding Microsoft accounts to Windows or switching a local account to one in Settings. Signing in to individual apps, such as Microsoft Store and Xbox, still works.'
    Registry    = @(
        # 1 = 'Users can't add Microsoft accounts'. Never use 3 ('can't add or log on with'),
        # which locks out existing MSA users.
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name = 'NoConnectedUser'; Type = 'DWord'; Data = 1 }
    )
}
