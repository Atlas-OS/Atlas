# Atlas.Themes domain: the recent-themes list. Runs as the signed-in user, from the
# per-user setup at first sign-in.

function Set-AtlasThemeMru {
    <#
    .SYNOPSIS
        Sets the user's recently used themes to the Atlas themes and the Windows dark
        and light themes.
    .DESCRIPTION
        Writes ThemeMRU, the semicolon-separated list of theme files that Settings
        offers under Personalization > Themes.
    #>
    Stop-ThemeProcesses
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes" -Name "ThemeMRU" -Value "$((@(
        "atlas-v0.4.x-dark.theme",
        "atlas-v0.4.x-light.theme",
        "atlas-v0.5.x-dark.theme",
        "atlas-v0.5.x-light.theme",
        "dark.theme",
        "aero.theme"
    ) | ForEach-Object { "$env:SystemRoot\resources\Themes\$_" }) -join ';');" -Type String -Force
}
