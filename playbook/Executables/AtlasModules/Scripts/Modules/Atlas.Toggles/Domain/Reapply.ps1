# Atlas.Toggles domain: upgrade re-apply.
#
# Port of the legacy Executables\DEFAULT.ps1: on upgrades, every toggle recorded under
# HKLM\SOFTWARE\AtlasOS\Services with state != 0 is re-applied by re-running the launcher
# recorded in 'path' with /silent (or -Silent for .ps1 launchers). Keys whose launcher no
# longer exists on disk are cleaned up.

function Invoke-AtlasToggleReapply {
    <#
    .SYNOPSIS
        Re-applies every recorded toggle whose state is not 0 by re-running its recorded
        launcher silently. Removes state keys whose launcher file is gone.
    #>
    param(
        [ValidateNotNullOrEmpty()]
        [string]$StateRoot = $script:AtlasToggleDefaultStateRoot
    )

    if (-not (Test-Path -LiteralPath $StateRoot)) {
        Write-Host "Registry path '$StateRoot' not found, skipping." -ForegroundColor Yellow
        return
    }

    foreach ($subkey in @(Get-ChildItem -LiteralPath $StateRoot)) {
        $properties = Get-ItemProperty -LiteralPath $subkey.PSPath -ErrorAction SilentlyContinue
        if ($null -eq $properties) {
            continue
        }
        if (-not $properties.PSObject.Properties['state'] -or -not $properties.PSObject.Properties['path']) {
            continue
        }

        $launcherPath = [string]$properties.path
        if (-not (Test-Path -LiteralPath $launcherPath)) {
            Write-Host "Launcher not found, cleaning up obsolete registry key: $launcherPath" -ForegroundColor Yellow
            Remove-Item -LiteralPath $subkey.PSPath -Force -Recurse -ErrorAction SilentlyContinue
            continue
        }

        if ([int]$properties.state -ne 0) {
            Write-Host "Running: $launcherPath" -ForegroundColor Cyan
            if ($launcherPath -like '*.ps1') {
                & $launcherPath -Silent
            }
            else {
                & $launcherPath /silent
            }
        }
    }
}
