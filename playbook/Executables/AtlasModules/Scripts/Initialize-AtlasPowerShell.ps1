# Atlas PowerShell bootstrap.
#
# Every Atlas process entry point dot-sources this file before it invokes any
# autoloadable command. It establishes the protected module-resolution boundary:
#
#   1. PSModulePath is replaced with the Atlas module tree beside this file followed by
#      the inbox Windows PowerShell module root, so inherited per-user module paths can
#      never shadow an Atlas or Microsoft module.
#   2. The four inbox modules that Atlas relies on are imported from their exact
#      protected manifests and verified to have loaded from those paths.
#
# Keep this file limited to PowerShell language features, .NET calls, and
# Microsoft.PowerShell.Core commands; everything else is shadowable until it runs.

$atlasModuleRoot = [IO.Path]::GetFullPath([IO.Path]::Combine($PSScriptRoot, 'Modules'))
$inboxModuleRoot = [IO.Path]::GetFullPath([IO.Path]::Combine($PSHOME, 'Modules'))
$env:PSModulePath = $atlasModuleRoot + [IO.Path]::PathSeparator + $inboxModuleRoot

foreach ($moduleName in @(
        'Microsoft.PowerShell.Management'
        'Microsoft.PowerShell.Utility'
        'Microsoft.PowerShell.Security'
        'Microsoft.PowerShell.Archive'
    )) {
    $manifest = [IO.Path]::Combine($inboxModuleRoot, $moduleName, "$moduleName.psd1")
    if (-not [IO.File]::Exists($manifest)) {
        throw "The protected inbox PowerShell module manifest is missing at '$manifest'."
    }

    $loaded = @(Microsoft.PowerShell.Core\Import-Module -Name $manifest -Force -PassThru -ErrorAction Stop)
    if ($loaded.Count -ne 1 -or
        $loaded[0].Name -ne $moduleName -or
        -not [IO.Path]::GetFullPath($loaded[0].Path).Equals(
            [IO.Path]::GetFullPath($manifest),
            [StringComparison]::OrdinalIgnoreCase
        )) {
        throw "PowerShell did not load '$moduleName' from its protected inbox manifest."
    }
}
