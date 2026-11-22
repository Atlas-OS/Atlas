@{
    Name        = 'Disallow Clipboard Cloud Sync'
    Description = 'Stops the clipboard syncing across devices through your Microsoft account. Local clipboard history (Windows+V) still works.'
    Registry    = @(
        # https://learn.microsoft.com/windows/client-management/mdm/policy-csp-privacy#allowcrossdeviceclipboard
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'AllowCrossDeviceClipboard'; Type = 'DWord'; Data = 0 }
    )
}
