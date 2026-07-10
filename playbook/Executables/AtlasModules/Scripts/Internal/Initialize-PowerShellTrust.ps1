# Establish a protected module-resolution boundary before any autoloadable
# command is invoked by an elevated Atlas helper. Keep this bootstrap limited to
# PowerShell language features, .NET calls, and Microsoft.PowerShell.Core
# commands; all four imported modules are otherwise shadowable through the
# caller's CurrentUser PSModulePath entries.

$moduleRoot = [IO.Path]::GetFullPath([IO.Path]::Combine($PSHOME, 'Modules'))
$env:PSModulePath = $moduleRoot

foreach ($moduleName in @(
        'Microsoft.PowerShell.Management'
        'Microsoft.PowerShell.Utility'
        'Microsoft.PowerShell.Security'
        'Microsoft.PowerShell.Archive'
    )) {
    $manifest = [IO.Path]::Combine($moduleRoot, $moduleName, "$moduleName.psd1")
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
