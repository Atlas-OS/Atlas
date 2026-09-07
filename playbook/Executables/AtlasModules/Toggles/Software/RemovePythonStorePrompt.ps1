function Remove-AtlasPythonStoreAlias {
    param($Toggle)

    # A python*.exe filename does not identify its owning package. Windows exposes
    # the owner in this UI; never delete aliases belonging to a real interpreter.
    if ($Toggle.Silent) {
        throw 'Disabling the Python Store prompt requires selecting the App Installer aliases in App execution aliases.'
    }
    Write-AtlasNote -Text @(
        'Windows cannot tell which package owns a python.exe alias, so Atlas opens the'
        'Settings page and leaves the choice to you. No Python files are deleted.'
    )
    Write-AtlasBlankLine
    Write-AtlasStep -Text 'Opening Settings > Apps > Advanced app settings...'
    # Windows 11 exposes aliases beneath Advanced app settings. The old direct
    # alias URI falls back to System on 25H2 instead of opening the alias list.
    Start-Process 'ms-settings:advanced-apps' -ErrorAction Stop
    Write-AtlasManualStep -Text @(
        'select App execution aliases, then turn off python.exe and python3.exe'
        'under App Installer. Keep the aliases of any Python you installed yourself.'
    )
    Write-AtlasNote -Text 'If Settings did not open that page, go to Apps > Advanced app settings.'
}
