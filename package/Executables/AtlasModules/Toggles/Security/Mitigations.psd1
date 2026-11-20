@{
    Name        = 'Mitigations'
    Description = 'Turns off all exploit and process mitigations, restores the Windows defaults, or turns them all on: speculative execution overrides, SEHOP, CFG, DEP and the kernel mitigation masks.'
    Elevation   = 'TrustedInstaller'
    Script      = 'Mitigations.ps1'
    States      = @(
        @{
            Name            = 'Disable'
            StateValue      = 0
            Launcher        = '7. Security\Mitigations\Disable All Mitigations.cmd'
            Reboot          = 'Recommend'
            Registry        = @(
                # Microsoft documents FeatureSettingsOverride = 3 with FeatureSettingsOverrideMask = 3
                # as turning off the mitigations for Spectre variant 2 (CVE-2017-5715) and Meltdown
                # (CVE-2017-5754).
                @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'FeatureSettingsOverride'; Type = 'DWord'; Data = 3 }
                @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'FeatureSettingsOverrideMask'; Type = 'DWord'; Data = 3 }
                @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'; Name = 'DisableExceptionChainValidation'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'; Name = 'ProtectionMode'; Type = 'DWord'; Data = 0 }
            )
            MachineAction   = 'Disable-AtlasMitigations'
        }
        @{
            Name            = 'WindowsDefault'
            StateValue      = 1
            Launcher        = '7. Security\Mitigations\Set Windows Default Mitigations.cmd'
            Reboot          = 'Recommend'
            Registry        = @(
                @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'FeatureSettingsOverride'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'FeatureSettingsOverrideMask'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'; Name = 'DisableExceptionChainValidation'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'; Name = 'MitigationAuditOptions'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'; Name = 'MitigationOptions'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'; Name = 'ProtectionMode'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization'; Name = 'MinVmVersionForCpuBasedMitigations'; Operation = 'Delete' }
            )
            MachineAction   = 'Set-AtlasMitigationsWindowsDefault'
        }
        @{
            Name             = 'Enable'
            StateValue       = 2
            Launcher         = '7. Security\Mitigations\Enable All Mitigations.cmd'
            Reboot           = 'Recommend'
            MachineAction    = 'Enable-AtlasMitigations'
            InteractiveState = 'Confirm-AtlasMitigationsEnable'
        }
    )
}
