@{
    Name        = 'Disable Background Apps'
    Description = 'Turns off background activity for Store apps, which saves memory and CPU time. Their background tasks stop too, such as Mail and Calendar notifications and Phone Link. Windows 11 Settings only allows apps again one at a time; the Background Apps launcher turns them all back on.'
    Registry    = @(
        # Deliberately the per-user preference, NOT the LetAppsRunInBackground=2 policy:
        # the policy force-deny removes the per-app override UI entirely and Microsoft
        # warns it causes missed notifications and alarms. Keep the preference, not the policy.
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'; Name = 'GlobalUserDisabled'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'BackgroundAppGlobalToggle'; Type = 'DWord'; Data = 0; AllowOsProtected = $true }
    )
}
