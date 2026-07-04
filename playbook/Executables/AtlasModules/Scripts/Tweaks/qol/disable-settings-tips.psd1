@{
    Name        = 'Disable Settings Tips'
    Description = 'Disables Settings tips for QoL, as most of the time, they only get in the way'
    Registry    = @(
        # The documented GP mapping of Settings/AllowOnlineTips (the PolicyManager\default
        # mirror is an OS-managed defaults store and was dropped as ineffective).
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'AllowOnlineTips'; Type = 'DWord'; Data = 0 }
    )
}
