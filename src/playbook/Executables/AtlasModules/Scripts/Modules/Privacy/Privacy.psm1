# Privacy module surface.
# Domain implementations live under .\Domain. This module intentionally keeps
# its previous empty export surface; current playbook YAML does not call these
# functions directly through module autoloading.
$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'Advertising.ps1'
    'AppTelemetry.ps1'
    'CloudExperience.ps1'
    'InputSpeech.ps1'
    'SystemReporting.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required privacy domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @()
