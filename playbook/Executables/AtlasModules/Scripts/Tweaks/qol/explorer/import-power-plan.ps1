# Sets the default ('') registry values for the .pow (power scheme) file association.
# The declarative Registry schema requires a value name, so these are set here.
$ErrorActionPreference = 'Stop'

$defaultValues = @(
    @{ SubKey = 'powerscheme\DefaultIcon'; Data = '%windir%\System32\powercpl.dll,1' }
    # Keep the selected path in argv. The protected handler validates one absolute .pow
    # file, then elevates only the exact inbox powercfg executable.
    @{
        SubKey = 'powerscheme\Shell\open\command'
        Type = [Microsoft.Win32.RegistryValueKind]::ExpandString
        Data = '"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%SystemRoot%\AtlasModules\Scripts\Internal\Import-PowerPlanFile.ps1" -PowerPlanPath "%1"'
    }
    @{ SubKey = '.pow'; Data = 'powerscheme' }
)

foreach ($entry in $defaultValues) {
    $key = [Microsoft.Win32.Registry]::ClassesRoot.CreateSubKey($entry.SubKey)
    if ($null -eq $key) {
        throw "Failed to create or open the registry key 'HKCR\$($entry.SubKey)'."
    }

    try {
        $valueKind = if ($entry.ContainsKey('Type')) {
            $entry.Type
        }
        else {
            [Microsoft.Win32.RegistryValueKind]::String
        }
        $key.SetValue('', $entry.Data, $valueKind)
    }
    finally {
        $key.Close()
    }
}
