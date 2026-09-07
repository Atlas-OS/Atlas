function Set-AtlasMitigationMask {
    # Fills MitigationAuditOptions and MitigationOptions with one byte pattern, keeping
    # the length Windows already uses for the value (eight bytes when it is absent).
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
    Set-AtlasRegistryValue -Path $Path -Name 'MitigationAuditOptions' -Type Binary -Data $mask
    Set-AtlasRegistryValue -Path $Path -Name 'MitigationOptions' -Type Binary -Data $mask
}

function Disable-AtlasMitigations {
    param($Toggle)

    $kernel = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
    $bcdEdit = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')

    Set-ProcessMitigation -System -Disable CFG -ErrorAction Stop
    # Vanguard requires CFG on its own processes even when it is disabled system-wide.
    foreach ($app in @('valorant', 'valorant-win64-shipping', 'vgtray', 'vgc')) {
        Set-ProcessMitigation -Name "$app.exe" -Enable CFG -ErrorAction Stop
    }
    Invoke-AtlasToggleNativeCommand -FilePath $bcdEdit `
        -ArgumentList ([string[]]@('/set', 'nx', 'OptIn')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
    Set-AtlasMitigationMask -Path $kernel -Fill 0x22
}

function Set-AtlasMitigationsWindowsDefault {
    param($Toggle)

    $bcdEdit = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
    Invoke-AtlasToggleNativeCommand -FilePath $bcdEdit `
        -ArgumentList ([string[]]@('/set', 'nx', 'OptIn')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
}

function Enable-AtlasMitigations {
    param($Toggle)

    # Everything stays in this function: the confirmation must come before any change,
    # and FeatureSettingsOverride depends on the installed processor.
    if (-not $Toggle.Silent) {
        Write-AtlasWarning -Text @(
            'This force-enables every security mitigation. It slows performance and worsens'
            "compatibility; 'Set Windows Default Mitigations' is the recommended choice."
        )
        Wait-AtlasContinue
    }

    $memoryManagement = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
    $kernel = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
    $sessionManager = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    $virtualization = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization'
    $bcdEdit = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')

    Set-AtlasRegistryValue -Path $memoryManagement -Name 'FeatureSettingsOverrideMask' -Type DWord -Data 3
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
    Set-AtlasRegistryValue -Path $memoryManagement -Name 'FeatureSettingsOverride' -Type DWord -Data ([int]$cpuOverrides[0])
    Set-AtlasRegistryValue -Path $kernel -Name 'DisableExceptionChainValidation' -Type DWord -Data 0

    Set-ProcessMitigation -System -Enable CFG -ErrorAction Stop
    Set-AtlasMitigationMask -Path $kernel -Fill 0x11
    Invoke-AtlasToggleNativeCommand -FilePath $bcdEdit `
        -ArgumentList ([string[]]@('/set', 'nx', 'AlwaysOn')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
    Set-AtlasRegistryValue -Path $sessionManager -Name 'ProtectionMode' -Type DWord -Data 1
    Set-AtlasRegistryValue -Path $virtualization -Name 'MinVmVersionForCpuBasedMitigations' -Type String -Data '1.0'
}
