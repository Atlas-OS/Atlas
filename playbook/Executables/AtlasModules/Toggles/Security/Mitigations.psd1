@{
    Name        = 'Mitigations'
    Description = 'Exploit and process mitigations: speculative-execution overrides, SEHOP, CFG, DEP (nx) and the kernel mitigation masks.'
    Elevation   = 'TrustedInstaller'
    Script      = 'Mitigations.ps1'
    States      = @(
        @{
            Name            = 'Disable'
            StateValue      = 0
            Launcher        = '7. Security\Mitigations\Disable All Mitigations.cmd'
            ToolboxLauncher = 'ConfigurationServices\Mitigations\Mitigations_0.cmd'
            Reboot          = 'Recommend'
            Registry        = @(
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
            ToolboxLauncher = 'ConfigurationServices\Mitigations\Mitigations_2.cmd'
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
            Name            = 'Enable'
            StateValue      = 2
            Launcher        = '7. Security\Mitigations\Enable All Mitigations.cmd'
            ToolboxLauncher = 'ConfigurationServices\Mitigations\Mitigations_1.cmd'
            Reboot          = 'Recommend'
            MachineAction   = 'Enable-AtlasMitigations'
        }
    )
}
