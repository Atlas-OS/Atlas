function Stop-ThemeProcesses {
    Get-Process 'SystemSettings', 'control' -EA 0 | Stop-Process -Force -EA 0
}

function Set-AtlasTheme {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $themeItem = Get-Item -Path $Path -ErrorAction SilentlyContinue
    if (($null -eq $themeItem) -or ($themeItem.Extension -ne '.theme')) {
        throw "'$Path' is not a valid path to a theme file."
    }

    function Set-ThemeUsingExplorer {
        Write-Warning "Failed to apply theme using COM, falling back to launching file..."

        Stop-ThemeProcesses
        Start-Process -FilePath explorer -ArgumentList $Path
        Start-Sleep 10
    }

    Initialize-AtlasNativeType

    try {
        [Atlas.Native.ThemeManager]::ApplyTheme($Path)
    } catch {
        Set-ThemeUsingExplorer
    }

    Stop-ThemeProcesses
}
