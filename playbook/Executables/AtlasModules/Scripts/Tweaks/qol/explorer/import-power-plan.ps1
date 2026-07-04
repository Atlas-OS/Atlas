# Sets the default ('') registry values for the .pow (power scheme) file association.
# The declarative Registry schema requires a value name, so these are set here.
$ErrorActionPreference = 'Stop'

$defaultValues = @(
    @{ SubKey = 'powerscheme\DefaultIcon'; Data = '%windir%\System32\powercpl.dll,1' }
    # powercfg /import requires administrator rights, so the verb elevates first -
    # a plain 'powercfg /import "%1"' fails silently when launched from Explorer.
    @{ SubKey = 'powerscheme\Shell\open\command'; Data = 'powershell.exe -NoProfile -WindowStyle Hidden -Command "Start-Process ''powercfg.exe'' -ArgumentList ''/import'',''""%1""'' -Verb RunAs"' }
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
