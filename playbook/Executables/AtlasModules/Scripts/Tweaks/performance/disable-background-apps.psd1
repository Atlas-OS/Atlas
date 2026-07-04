@{
    Name        = 'Disable Background Apps'
    Description = 'Disables background apps so there''s minimal resources used in the background. Trade-off: Store-app background tasks stop (e.g. Mail/Calendar notifications, Phone Link); Windows 11 has no global Settings toggle for this, so re-enabling is per app.'
    Registry    = @(
        # Deliberately the per-user preference, NOT the LetAppsRunInBackground=2 policy:
        # the policy force-deny removes the per-app override UI entirely and Microsoft
        # warns it causes missed notifications/alarms. Do not "upgrade" this to the policy.
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'; Name = 'GlobalUserDisabled'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'BackgroundAppGlobalToggle'; Type = 'DWord'; Data = 0 }
    )
}
