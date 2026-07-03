@{
    Name        = 'Remove ''Troubleshooting Compatibility'' from Context Menu'
    Description = 'Removes ''Troubleshooting Compatibility'' from context menu'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'; Name = '{1d27f844-3a1f-4410-85ac-14651078412d}'; Type = 'String'; Data = '' }
        @{ Path = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'; Name = '{1d27f844-3a1f-4410-85ac-14651078412d}'; Type = 'String'; Data = '' }
    )
}
