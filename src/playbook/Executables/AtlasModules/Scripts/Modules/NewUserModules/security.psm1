# Blocks Anonymous Enumeration of SAM Accounts
function Block-AnonymousSAMEnumeration {
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "RestrictAnonymousSAM" /t REG_DWORD /d 1 /f
}

# Disables Remote Assistance
function Disable-RemoteAssistance {
    $key = "HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance"
    
    reg add $key /v "fAllowFullControl" /t REG_DWORD /d 0 /f
    reg add $key /v "fAllowToGetHelp" /t REG_DWORD /d 0 /f

    Start-Process -FilePath "netsh" -ArgumentList 'advfirewall firewall set rule group="Remote Assistance" new enable=no' -NoNewWindow -Wait
}

function Invoke-AllSecurityTweaks {
    Block-AnonymousSAMEnumeration
    Disable-RemoteAssistance
}

Export-ModuleMember -Function Invoke-AllSecurityTweaks