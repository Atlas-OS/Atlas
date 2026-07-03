# Sets the default ('') registry values for the 'Merge as TrustedInstaller' verb on
# .reg files. The declarative Registry schema requires a value name, so these are set
# here. %windir% is intentionally left unexpanded, matching the legacy REG_SZ data.
$ErrorActionPreference = 'Stop'

$defaultValues = @(
    @{ SubKey = 'SOFTWARE\Classes\regfile\Shell\RunAs'; Data = 'Merge As TrustedInstaller' }
    @{ SubKey = 'SOFTWARE\Classes\regfile\Shell\RunAs\Command'; Data = 'cmd /c "%windir%\AtlasModules\Scripts\RunAsTI.cmd" "%1"' }
)

foreach ($entry in $defaultValues) {
    $key = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey($entry.SubKey)
    if ($null -eq $key) {
        throw "Failed to create or open the registry key 'HKLM\$($entry.SubKey)'."
    }

    try {
        $key.SetValue('', $entry.Data, [Microsoft.Win32.RegistryValueKind]::String)
    }
    finally {
        $key.Close()
    }
}
