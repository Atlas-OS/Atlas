# Sets the default ('') registry values for the .pow (power scheme) file association.
# The declarative Registry schema requires a value name, so these are set here.
$ErrorActionPreference = 'Stop'

$defaultValues = @(
    @{ SubKey = 'powerscheme\DefaultIcon'; Data = '%windir%\System32\powercpl.dll,1' }
    @{ SubKey = 'powerscheme\Shell\open\command'; Data = 'powercfg /import "%1"' }
    @{ SubKey = '.pow'; Data = 'powerscheme' }
)

foreach ($entry in $defaultValues) {
    $key = [Microsoft.Win32.Registry]::ClassesRoot.CreateSubKey($entry.SubKey)
    if ($null -eq $key) {
        throw "Failed to create or open the registry key 'HKCR\$($entry.SubKey)'."
    }

    try {
        $key.SetValue('', $entry.Data, [Microsoft.Win32.RegistryValueKind]::String)
    }
    finally {
        $key.Close()
    }
}
