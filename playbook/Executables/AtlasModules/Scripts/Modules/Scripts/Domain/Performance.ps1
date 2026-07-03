# System script domain functions: Performance

function Optimize-PowerShellStartup {
    # speeds up powershell startup time by 10x
    $env:path = "$([Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory());" + $env:path
    [AppDomain]::CurrentDomain.GetAssemblies().Location | Where-Object { $_ } | ForEach-Object {
        Write-Host "NGENing: $(Split-Path $_ -Leaf)" -ForegroundColor Yellow
        ngen install $_ | Out-Null
    }
}

function Set-PowerSettings {
    param (
        [switch]$DisablePowerSaving,
        [switch]$DisableHibernation
    )

    if ($DisablePowerSaving) {
        Start-Process -FilePath "AtlasDesktop\3. General Configuration\Power-saving\Disable Power-saving.cmd" -ArgumentList "/silent" -NoNewWindow -Wait
    }

    if ($DisableHibernation) {
        Start-Process -FilePath "AtlasDesktop\3. General Configuration\Hibernation\Disable Hibernation (default).cmd" -ArgumentList "/silent" -NoNewWindow -Wait
    }

    if (-not $DisablePowerSaving) {
        Start-Process -FilePath "powercfg.exe" -ArgumentList "/setactive `"381b4222-f694-41f0-9685-ff5bb260df2e`"" -NoNewWindow -Wait
    }
}
