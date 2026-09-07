function Disable-AtlasCpuIdle {
    param($Toggle)

    $powercfg = "$($Toggle.WinDir)\System32\powercfg.exe"
    $idleGuid = '5d76a2ca-e8c0-402f-a133-2158492d58ad'

    # On Hyper-Threading/SMT systems disabling idle harms performance, so reject the
    # transition without changing or recording the requested state.
    $smt = $false
    foreach ($cpu in Get-CimInstance Win32_Processor) {
        if ([int]$cpu.NumberOfLogicalProcessors -gt [int]$cpu.NumberOfCores) {
            $smt = $true
            break
        }
    }

    if ($smt) {
        throw 'Hyper-Threading or SMT is enabled on this processor, and disabling idle states would make overall CPU performance much worse. Nothing was changed; consider disabling C-states in the BIOS instead.'
    }

    if (-not $Toggle.Silent) {
        Write-AtlasNote -Text @(
            'This turns processor idle states off while on AC power, which raises power use and heat.'
            'Task Manager may then show misleadingly high CPU use. The CPU clock speed is not fixed.'
        )
    }

    Invoke-AtlasToggleNativeCommand -FilePath $powercfg `
        -ArgumentList ([string[]]@('/setacvalueindex', 'scheme_current', 'sub_processor', $idleGuid, '1')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
    Invoke-AtlasToggleNativeCommand -FilePath $powercfg `
        -ArgumentList ([string[]]@('/setactive', 'scheme_current')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
}

function Enable-AtlasCpuIdle {
    param($Toggle)

    $powercfg = "$($Toggle.WinDir)\System32\powercfg.exe"
    Invoke-AtlasToggleNativeCommand -FilePath $powercfg `
        -ArgumentList ([string[]]@('/setacvalueindex', 'scheme_current', 'sub_processor', '5d76a2ca-e8c0-402f-a133-2158492d58ad', '0')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
    Invoke-AtlasToggleNativeCommand -FilePath $powercfg `
        -ArgumentList ([string[]]@('/setactive', 'scheme_current')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
}
