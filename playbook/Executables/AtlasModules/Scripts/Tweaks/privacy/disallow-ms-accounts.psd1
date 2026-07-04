@{
    Name        = 'Disallow Users to Be Non-local'
    Description = 'For privacy and QoL, users are prevented from adding Microsoft accounts as user accounts instead of local accounts. Settings-driven MSA flows (add account, local-to-MSA conversion, settings backup sign-in) are blocked; signing into individual apps (Store, Xbox) still works.'
    Registry    = @(
        # 1 = 'Users can't add Microsoft accounts'. Never use 3 ('can't add OR LOG ON'),
        # which locks out existing MSA users.
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name = 'NoConnectedUser'; Type = 'DWord'; Data = 1 }
    )
}
