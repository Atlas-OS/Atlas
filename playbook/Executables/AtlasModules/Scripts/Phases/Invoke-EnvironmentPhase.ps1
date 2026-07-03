# Environment phase.
# Configures PowerShell before the rest of the install runs:
#   - NGEN the loaded .NET assemblies (speeds up PowerShell startup ~10x)
#   - Set the temporary Unrestricted execution policy (Finalize/custom.yml tightens it
#     back to RemoteSigned at the end of the install)
#   - Opt out of PowerShell Core telemetry (machine scope)
# Runs elevated (runas: currentUserElevated); the HKLM value and the machine environment
# variable both require administrator rights. NGEN failing must not abort the install.

Assert-AtlasPrivilege -Administrator

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

# Set PowerShell execution policy to Unrestricted temporarily during installation.
# This allows all Atlas installation scripts to run without signature verification.
# custom.yml resets it to RemoteSigned once the install is complete.
$shellIdKey = 'HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell'
if (-not (Test-Path -LiteralPath $shellIdKey)) {
    New-Item -Path $shellIdKey -Force | Out-Null
}
Set-ItemProperty -LiteralPath $shellIdKey -Name 'ExecutionPolicy' -Value 'Unrestricted' -Type String -Force

# Disable PowerShell Core telemetry
[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', 'Machine')
