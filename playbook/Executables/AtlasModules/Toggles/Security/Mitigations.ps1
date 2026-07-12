# Toggle: exploit and process mitigations.
$action = {
    param($Toggle)

    Import-Module -Name (Join-Path $Toggle.ScriptsPath `
            'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop

    $memoryManagement = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
    $kernel = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
    $sessionManager = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    $virtualization = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization'
    $bcdEdit = "$($Toggle.WinDir)\System32\bcdedit.exe"

    $setMitigationMask = {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Path,

            [Parameter(Mandatory = $true)]
            [byte]$Fill
        )

        $key = Get-Item -LiteralPath $Path -ErrorAction Stop
        try {
            [byte[]]$existing = $key.GetValue(
                'MitigationAuditOptions',
                $null,
                [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
            )
        }
        finally {
            $key.Close()
        }

        $length = if ($null -eq $existing -or $existing.Length -eq 0) {
            8
        }
        else {
            $existing.Length
        }
        $mask = New-Object 'byte[]' $length
        for ($i = 0; $i -lt $mask.Length; $i++) {
            $mask[$i] = $Fill
        }
        Set-AtlasRegistryValue -Path $Path -Name 'MitigationAuditOptions' `
            -Type Binary -Data $mask
        Set-AtlasRegistryValue -Path $Path -Name 'MitigationOptions' `
            -Type Binary -Data $mask
    }

    switch ($Toggle.State) {
        'Disable' {
            Set-AtlasRegistryValue -Path $memoryManagement `
                -Name 'FeatureSettingsOverride' -Type DWord -Data 3
            Set-AtlasRegistryValue -Path $memoryManagement `
                -Name 'FeatureSettingsOverrideMask' -Type DWord -Data 3
            Set-AtlasRegistryValue -Path $kernel `
                -Name 'DisableExceptionChainValidation' -Type DWord -Data 1

            Set-ProcessMitigation -System -Disable CFG -ErrorAction Stop
            foreach ($app in @('valorant', 'valorant-win64-shipping', 'vgtray', 'vgc')) {
                Set-ProcessMitigation -Name "$app.exe" -Enable CFG -ErrorAction Stop
            }
            Invoke-AtlasToggleNativeCommand -FilePath $bcdEdit `
                -ArgumentList ([string[]]@('/set', 'nx', 'OptIn')) `
                -AllowedExitCodes ([int[]]@(0)) | Out-Null
            & $setMitigationMask -Path $kernel -Fill 0x22
            Set-AtlasRegistryValue -Path $sessionManager -Name 'ProtectionMode' `
                -Type DWord -Data 0
        }
        'WindowsDefault' {
            Remove-AtlasRegistryValue -Path $memoryManagement -Name 'FeatureSettingsOverride'
            Remove-AtlasRegistryValue -Path $memoryManagement -Name 'FeatureSettingsOverrideMask'
            Remove-AtlasRegistryValue -Path $kernel -Name 'DisableExceptionChainValidation'
            Remove-AtlasRegistryValue -Path $kernel -Name 'MitigationAuditOptions'
            Remove-AtlasRegistryValue -Path $kernel -Name 'MitigationOptions'

            Invoke-AtlasToggleNativeCommand -FilePath $bcdEdit `
                -ArgumentList ([string[]]@('/set', 'nx', 'OptIn')) `
                -AllowedExitCodes ([int[]]@(0)) | Out-Null
            Set-AtlasRegistryValue -Path $sessionManager -Name 'ProtectionMode' `
                -Type DWord -Data 1
            Remove-AtlasRegistryValue -Path $virtualization `
                -Name 'MinVmVersionForCpuBasedMitigations'
        }
        'Enable' {
            if (-not $Toggle.Silent) {
                Write-Host 'WARNING: This will force enable all security mitigations for improved security.' -ForegroundColor Yellow
                Write-Host '         This will slow down performance, and worsen compatibility. It is' -ForegroundColor Yellow
                Write-Host "         recommended to use 'Set Windows Default Mitigations' instead." -ForegroundColor Yellow
                Write-Host ''
                Start-Sleep -Seconds 3
                $null = Read-Host 'Press Enter to continue anyway (or Ctrl+C to cancel)'
            }

            Set-AtlasRegistryValue -Path $memoryManagement `
                -Name 'FeatureSettingsOverrideMask' -Type DWord -Data 3
            $processors = @(Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop)
            if ($processors.Count -eq 0) {
                throw 'No Win32_Processor instances were returned; mitigation policy cannot be selected safely.'
            }
            $cpuOverrides = @($processors | ForEach-Object {
                    if ([int]$_.Architecture -eq 12) {
                        64
                    }
                    elseif ([string]$_.Manufacturer -match '(?i)Intel') {
                        0
                    }
                    elseif ([string]$_.Manufacturer -match '(?i)AMD') {
                        64
                    }
                    else {
                        throw "Unsupported processor manufacturer '$($_.Manufacturer)' and architecture '$($_.Architecture)'."
                    }
                } | Select-Object -Unique)
            if ($cpuOverrides.Count -ne 1) {
                throw 'Processors require conflicting speculative-execution mitigation overrides.'
            }
            Set-AtlasRegistryValue -Path $memoryManagement `
                -Name 'FeatureSettingsOverride' -Type DWord -Data ([int]$cpuOverrides[0])
            Set-AtlasRegistryValue -Path $kernel `
                -Name 'DisableExceptionChainValidation' -Type DWord -Data 0

            Set-ProcessMitigation -System -Enable CFG -ErrorAction Stop
            & $setMitigationMask -Path $kernel -Fill 0x11
            Invoke-AtlasToggleNativeCommand -FilePath $bcdEdit `
                -ArgumentList ([string[]]@('/set', 'nx', 'AlwaysOn')) `
                -AllowedExitCodes ([int[]]@(0)) | Out-Null
            Set-AtlasRegistryValue -Path $sessionManager -Name 'ProtectionMode' `
                -Type DWord -Data 1
            Set-AtlasRegistryValue -Path $virtualization `
                -Name 'MinVmVersionForCpuBasedMitigations' -Type String -Data '1.0'
        }
    }
}

@{
    Name      = 'Mitigations'
    Elevation = 'TrustedInstaller'
    States    = [ordered]@{
        Disable        = @{
            StateValue      = 0
            ReplayScope     = 'Machine'
            Launcher        = '7. Security\Mitigations\Disable All Mitigations.cmd'
            ToolboxLauncher = 'ConfigurationServices\Mitigations\Mitigations_0.cmd'
            Reboot          = 'Recommend'
            Action          = $action
        }
        WindowsDefault = @{
            StateValue      = 1
            ReplayScope     = 'Machine'
            Launcher        = '7. Security\Mitigations\Set Windows Default Mitigations.cmd'
            ToolboxLauncher = 'ConfigurationServices\Mitigations\Mitigations_2.cmd'
            Reboot          = 'Recommend'
            Action          = $action
        }
        Enable         = @{
            StateValue      = 2
            ReplayScope     = 'Machine'
            Launcher        = '7. Security\Mitigations\Enable All Mitigations.cmd'
            ToolboxLauncher = 'ConfigurationServices\Mitigations\Mitigations_1.cmd'
            Reboot          = 'Recommend'
            Action          = $action
        }
    }
}
