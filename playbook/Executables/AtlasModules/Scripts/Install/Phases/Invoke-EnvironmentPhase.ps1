# Environment phase.
# Configures PowerShell before the rest of the install runs:
#   - NGEN the loaded .NET assemblies (speeds up PowerShell startup ~10x)
#   - Set Windows PowerShell to RemoteSigned on fresh installs
#   - Opt out of PowerShell Core telemetry (machine scope)
# Runs as TrustedInstaller; the HKLM value and machine environment variable are not user
# state. NGEN failing must not abort the install.

Assert-AtlasPrivilege -TrustedInstaller

$scriptsRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$modulesRoot = Join-Path -Path $scriptsRoot -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop

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
