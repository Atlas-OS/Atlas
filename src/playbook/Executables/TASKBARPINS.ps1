param (
    [string]$Browser
)

$scriptPath = Join-Path $PSScriptRoot 'AtlasModules\Scripts\taskbarPins.ps1'
if (!(Test-Path $scriptPath -PathType Leaf)) {
    Write-Error "Taskbar pin script not found at '$scriptPath'."
    exit 1
}

if ($PSBoundParameters.ContainsKey('Browser')) {
    & $scriptPath -Browser $Browser
}
else {
    & $scriptPath
}
