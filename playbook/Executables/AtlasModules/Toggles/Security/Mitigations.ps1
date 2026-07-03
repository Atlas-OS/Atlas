# Toggle: Exploit / process mitigations (disable all / Windows default / enable all).
# Converted from 'AtlasDesktop\7. Security\Mitigations\{Disable All Mitigations,
# Set Windows Default Mitigations,Enable All Mitigations}.cmd'.
#
# One setting ('Mitigations') with three launchers, so this is a three-state definition
# (each launcher records its own StateValue: Disable=0, WindowsDefault=1, Enable=2).
#
# REG_BINARY bitmask parity: the batch scripts read the existing MitigationAuditOptions
# REG_BINARY value (a hex string via 'reg query') and replaced every hex nibble with '1'
# (enable all) or '2' (disable all), i.e. every byte becomes 0x11 or 0x22, then wrote that
# same-length blob back to MitigationAuditOptions and MitigationOptions. This is reproduced
# here with a byte[] of the existing value's length filled with 0x11 / 0x22. Set-Process-
# Mitigation -System is called first (as in the batch) so the value exists before it's read.
#
# Elevation is TrustedInstaller (a superset): 'Enable All' relaunched via RunAsTI in the
# original, and TI can perform everything the Admin-only 'Disable'/'Windows Default'
# launchers did (all writes are HKLM/system, no HKCU), so behavior is preserved.
@{
    Name      = 'Mitigations'
    Elevation = 'TrustedInstaller'
    States    = [ordered]@{
        Disable        = @{
            StateValue = 0
            Launcher   = '7. Security\Mitigations\Disable All Mitigations.cmd'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                $mm = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
                $kernel = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
                $sessionManager = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'

                # Disable Spectre and Meltdown
                New-ItemProperty -LiteralPath $mm -Name 'FeatureSettingsOverride' -Value 3 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $mm -Name 'FeatureSettingsOverrideMask' -Value 3 -PropertyType DWord -Force | Out-Null

                # Disable Structured Exception Handling Overwrite Protection (SEHOP)
                New-ItemProperty -LiteralPath $kernel -Name 'DisableExceptionChainValidation' -Value 1 -PropertyType DWord -Force | Out-Null

                # Initialize the mitigation bit mask in the registry (parity with the batch)
                Set-ProcessMitigation -System -Disable CFG -ErrorAction SilentlyContinue

                # Read the existing mask and set every nibble to 2 (disable all mitigations)
                $existing = (Get-ItemProperty -LiteralPath $kernel -Name 'MitigationAuditOptions' -ErrorAction SilentlyContinue).MitigationAuditOptions
                if ($null -eq $existing -or @($existing).Count -eq 0) {
                    $existing = New-Object 'byte[]' 8
                }
                $mask = New-Object 'byte[]' (@($existing).Count)
                for ($i = 0; $i -lt $mask.Length; $i++) { $mask[$i] = 0x22 }

                # Fix Valorant with mitigations disabled - keep CFG enabled for its executables
                foreach ($app in @('valorant', 'valorant-win64-shipping', 'vgtray', 'vgc')) {
                    Set-ProcessMitigation -Name "$app.exe" -Enable CFG -ErrorAction SilentlyContinue
                }

                # Data Execution Prevention (DEP) for operating system components only
                & "$($Toggle.WinDir)\System32\bcdedit.exe" /set nx OptIn | Out-Null

                # Apply the mask to the kernel
                New-ItemProperty -LiteralPath $kernel -Name 'MitigationAuditOptions' -Value $mask -PropertyType Binary -Force | Out-Null
                New-ItemProperty -LiteralPath $kernel -Name 'MitigationOptions' -Value $mask -PropertyType Binary -Force | Out-Null

                # Disable file system mitigations
                New-ItemProperty -LiteralPath $sessionManager -Name 'ProtectionMode' -Value 0 -PropertyType DWord -Force | Out-Null
            }
        }
        WindowsDefault = @{
            StateValue = 1
            Launcher   = '7. Security\Mitigations\Set Windows Default Mitigations.cmd'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                $mm = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
                $kernel = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
                $sessionManager = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
                $virtualization = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization'

                # Restore default Spectre / Meltdown behavior
                Remove-ItemProperty -LiteralPath $mm -Name 'FeatureSettingsOverride' -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath $mm -Name 'FeatureSettingsOverrideMask' -Force -ErrorAction SilentlyContinue

                # Restore default SEHOP behavior
                Remove-ItemProperty -LiteralPath $kernel -Name 'DisableExceptionChainValidation' -Force -ErrorAction SilentlyContinue

                # Clear the custom mitigation mask (revert to Windows defaults)
                Remove-ItemProperty -LiteralPath $kernel -Name 'MitigationAuditOptions' -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath $kernel -Name 'MitigationOptions' -Force -ErrorAction SilentlyContinue

                # Data Execution Prevention (DEP) for operating system components only
                & "$($Toggle.WinDir)\System32\bcdedit.exe" /set nx OptIn | Out-Null

                # Enable file system mitigations
                New-ItemProperty -LiteralPath $sessionManager -Name 'ProtectionMode' -Value 1 -PropertyType DWord -Force | Out-Null

                # Default Hyper-V settings
                Remove-ItemProperty -LiteralPath $virtualization -Name 'MinVmVersionForCpuBasedMitigations' -Force -ErrorAction SilentlyContinue
            }
        }
        Enable         = @{
            StateValue = 2
            Launcher   = '7. Security\Mitigations\Enable All Mitigations.cmd'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                if (-not $Toggle.Silent) {
                    Write-Host 'WARNING: This will force enable all security mitigations for improved security.' -ForegroundColor Yellow
                    Write-Host '         This will slow down performance, and worsen compatibility. It is' -ForegroundColor Yellow
                    Write-Host "         recommended to use 'Set Windows Default Mitigations' instead." -ForegroundColor Yellow
                    Write-Host ''
                    Start-Sleep -Seconds 3
                    $null = Read-Host 'Press Enter to continue anyway (or Ctrl+C to cancel)'
                }

                $mm = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
                $kernel = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
                $sessionManager = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
                $virtualization = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization'

                # Enable Spectre and Meltdown mitigations (CPU vendor specific override)
                New-ItemProperty -LiteralPath $mm -Name 'FeatureSettingsOverrideMask' -Value 3 -PropertyType DWord -Force | Out-Null
                $processorName = (Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1).Name
                $cpuOverride = $null
                if ($processorName -match 'Intel') { $cpuOverride = 0 }
                elseif ($processorName -match 'AMD') { $cpuOverride = 64 }
                if ($null -ne $cpuOverride) {
                    New-ItemProperty -LiteralPath $mm -Name 'FeatureSettingsOverride' -Value $cpuOverride -PropertyType DWord -Force | Out-Null
                }

                # Enable Structured Exception Handling Overwrite Protection (SEHOP)
                New-ItemProperty -LiteralPath $kernel -Name 'DisableExceptionChainValidation' -Value 0 -PropertyType DWord -Force | Out-Null

                # Enable Control Flow Guard (CFG) and initialize the mask
                Set-ProcessMitigation -System -Enable CFG -ErrorAction SilentlyContinue

                # Read the existing mask and set every nibble to 1 (enable all mitigations)
                $existing = (Get-ItemProperty -LiteralPath $kernel -Name 'MitigationAuditOptions' -ErrorAction SilentlyContinue).MitigationAuditOptions
                if ($null -eq $existing -or @($existing).Count -eq 0) {
                    $existing = New-Object 'byte[]' 8
                }
                $mask = New-Object 'byte[]' (@($existing).Count)
                for ($i = 0; $i -lt $mask.Length; $i++) { $mask[$i] = 0x11 }

                New-ItemProperty -LiteralPath $kernel -Name 'MitigationAuditOptions' -Value $mask -PropertyType Binary -Force | Out-Null
                New-ItemProperty -LiteralPath $kernel -Name 'MitigationOptions' -Value $mask -PropertyType Binary -Force | Out-Null

                # Data Execution Prevention (DEP) always on
                & "$($Toggle.WinDir)\System32\bcdedit.exe" /set nx AlwaysOn | Out-Null

                # Enable file system mitigations
                New-ItemProperty -LiteralPath $sessionManager -Name 'ProtectionMode' -Value 1 -PropertyType DWord -Force | Out-Null

                # Enable for Hyper-V
                New-ItemProperty -LiteralPath $virtualization -Name 'MinVmVersionForCpuBasedMitigations' -Value '1.0' -PropertyType String -Force | Out-Null
            }
        }
    }
}
