# System script domain functions: FileAssociations

function Set-FileAssociations {
    param (
        [string]$Browser
    )

    # Uninstall Edge (if applicable)
    Start-Process -FilePath ".\fileAssoc.cmd" -NoNewWindow -Wait

    # Set default browser
    if ($Browser -in @("Brave", "LibreWolf", "Firefox", "Google Chrome")) {
        Start-Process -FilePath ".\fileAssoc.cmd" -ArgumentList "`"$Browser`"" -NoNewWindow -Wait
    }
}
