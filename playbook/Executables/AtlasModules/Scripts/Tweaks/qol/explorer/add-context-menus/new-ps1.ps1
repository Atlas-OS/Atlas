# Sets the default ('') registry values registering .ps1 with the PowerShell script
# ProgID. The declarative Registry schema requires a value name, so these are set here.
$ErrorActionPreference = 'Stop'

$defaultValues = @(
    @{ SubKey = '.ps1'; Data = 'Microsoft.PowerShellScript.1' }
    @{ SubKey = 'Microsoft.PowerShellScript.1'; Data = 'Windows PowerShell Script' }
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
