# Sets the default ('') registry values for the 'All Tasks' (God Mode) Control Panel
# entry. The declarative Registry schema requires a value name, so these are set here.
$ErrorActionPreference = 'Stop'

$defaultValues = @(
    @{ BaseKey = [Microsoft.Win32.Registry]::ClassesRoot; SubKey = 'CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}'; Data = 'All Tasks' }
    @{ BaseKey = [Microsoft.Win32.Registry]::ClassesRoot; SubKey = 'CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}\DefaultIcon'; Data = '%windir%\System32\imageres.dll,-27' }
    @{ BaseKey = [Microsoft.Win32.Registry]::ClassesRoot; SubKey = 'CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}\Shell\Open\Command'; Data = 'explorer.exe shell:::{ED7BA470-8E54-465E-825C-99712043E01C}' }
    @{ BaseKey = [Microsoft.Win32.Registry]::LocalMachine; SubKey = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}'; Data = 'All Tasks' }
)

foreach ($entry in $defaultValues) {
    $key = $entry.BaseKey.CreateSubKey($entry.SubKey)
    if ($null -eq $key) {
        throw "Failed to create or open the registry key '$($entry.SubKey)'."
    }

    try {
        $key.SetValue('', $entry.Data, [Microsoft.Win32.RegistryValueKind]::String)
    }
    finally {
        $key.Close()
    }
}
