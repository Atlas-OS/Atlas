@{
    Name        = 'Disable Settings Tips'
    Description = 'Turns off online tips in Settings.'
    Registry    = @(
        # The documented GP mapping of Settings/AllowOnlineTips (the PolicyManager\default
        # mirror is an OS-managed defaults store and has no effect).
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'AllowOnlineTips'; Type = 'DWord'; Data = 0 }
    )
}
