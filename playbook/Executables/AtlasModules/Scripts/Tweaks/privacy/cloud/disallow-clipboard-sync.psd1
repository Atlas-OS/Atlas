@{
    Name        = 'Disallow Clipboard Cloud Sync'
    Description = 'Prevents the clipboard from syncing across devices through the Microsoft account. Local clipboard history (Win+V) keeps working.'
    Registry    = @(
        # https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-privacy#allowcrossdeviceclipboard
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'AllowCrossDeviceClipboard'; Type = 'DWord'; Data = 0 }
    )
}
