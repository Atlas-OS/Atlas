Set-StrictMode -Version 3.0

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'ThemeApplication.ps1'
    'ThemeRegistry.ps1'
    'Lockscreen.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required theme domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function Set-Theme, Set-ThemeMRU, Set-LockscreenImage
