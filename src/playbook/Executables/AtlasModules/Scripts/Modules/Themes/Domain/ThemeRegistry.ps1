function Set-ThemeMRU {
    if ([System.Environment]::OSVersion.Version.Build -ge 22000) {
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
}
