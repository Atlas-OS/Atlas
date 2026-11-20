# Atlas.Themes domain: applying a .theme file. Runs as the signed-in user, from the
# per-user setup at first sign-in, because a theme belongs to the user's profile.

function Stop-ThemeProcesses {
    <#
    .SYNOPSIS
        Closes Settings and Control Panel, which applying a theme can leave open.
    #>
    Get-Process 'SystemSettings', 'control' -EA 0 | Stop-Process -Force -EA 0
}

function Set-AtlasTheme {
    <#
    .SYNOPSIS
        Applies a .theme file to the current user.
    .DESCRIPTION
        Uses the shell's IThemeManager first. If that fails, opens the file through
        Explorer, which applies it with the Personalization settings.
    .PARAMETER Path
        The .theme file to apply.
    #>
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
        param([string]$Reason)

        Write-Warning "Applying the theme through IThemeManager failed: $Reason Opening '$Path' through Explorer instead."

        Stop-ThemeProcesses
        Start-Process -FilePath explorer -ArgumentList $Path
        # Explorer returns at once, and Windows applies the theme in the background
        # with Settings open and no signal when it's done. Ten seconds lets it finish
        # before Settings is closed below.
        Start-Sleep 10
    }

    Initialize-AtlasNativeType

    try {
        [Atlas.Native.ThemeManager]::ApplyTheme($Path)
    } catch {
        Set-ThemeUsingExplorer -Reason $_.Exception.Message
    }

    Stop-ThemeProcesses
}
