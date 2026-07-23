# Environment phase.
# Configures PowerShell before the rest of the install runs:
#   - NGEN the loaded .NET assemblies (speeds up PowerShell startup ~10x)
#   - Set Windows PowerShell to RemoteSigned on fresh installs
#   - Opt out of PowerShell Core telemetry (machine scope)
# Runs as TrustedInstaller; the HKLM value and machine environment variable are not user
# state. NGEN failing must not abort the install.

Assert-AtlasPrivilege -TrustedInstaller

function Set-AtlasWindowsPowerShellExecutionPolicy {
    $subKey = 'SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell'
    $views = if ([Environment]::Is64BitOperatingSystem) {
        @(
            [Microsoft.Win32.RegistryView]::Registry64,
            [Microsoft.Win32.RegistryView]::Registry32
        )
    }
    else {
        @([Microsoft.Win32.RegistryView]::Default)
    }

    foreach ($view in $views) {
        $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
            [Microsoft.Win32.RegistryHive]::LocalMachine,
            $view
        )
        try {
            $key = $baseKey.CreateSubKey($subKey, $true)
            if ($null -eq $key) {
                throw "Could not open the Windows PowerShell shell ID in the $view registry view."
            }
            try {
                $key.SetValue(
                    'ExecutionPolicy',
                    'RemoteSigned',
                    [Microsoft.Win32.RegistryValueKind]::String
                )
                $actual = [string]$key.GetValue('ExecutionPolicy', $null)
                if ($actual -cne 'RemoteSigned') {
                    throw "The $view Windows PowerShell execution policy did not retain RemoteSigned."
                }
            }
            finally {
                $key.Dispose()
            }
        }
        finally {
            $baseKey.Dispose()
        }
    }
}

$context = Get-AtlasContext
if (-not $context.IsUpgrade) {
    Set-AtlasWindowsPowerShellExecutionPolicy
    Write-AtlasLog -Message 'Set 64-bit and 32-bit Windows PowerShell execution policy to RemoteSigned for the fresh install.'
}
else {
    Write-AtlasLog -Message 'Preserving the existing Windows PowerShell execution policy during upgrade or reapply.'
}

# NGEN - .NET assemblies PowerShell optimization (speeds up PowerShell startup time)
try {
    $env:path = "$([Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory());" + $env:path
    [AppDomain]::CurrentDomain.GetAssemblies().Location | Where-Object { $_ } | ForEach-Object {
        Write-Host "NGENing: $(Split-Path $_ -Leaf)" -ForegroundColor Yellow
        ngen install $_ | Out-Null
    }
}
catch {
    Write-AtlasLog -Level Warning -Message "NGEN optimization failed: $($_.Exception.Message)"
}

# Disable PowerShell Core telemetry
[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', 'Machine')
