# Restores the old (Windows 10) context menu on Windows 11 by setting the DEFAULT
# value of the InprocServer32 key to an empty string. The declarative Registry schema
# cannot write default ('') values, and the key is per-user, so it is written here for
# every loaded user hive (including the AME default-user hives so new accounts inherit
# it), replacing the legacy 'reg add HKCU\...' that ran as 'currentUserElevated'.
$ErrorActionPreference = 'Stop'

if (-not (Get-Command -Name 'Get-RegUserPaths' -ErrorAction SilentlyContinue)) {
    Import-Module -Name 'Atlas.Registry' -Force
}

$subKey = 'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
foreach ($userHive in @(Get-RegUserPaths)) {
    $key = [Microsoft.Win32.Registry]::Users.CreateSubKey("$($userHive.PSChildName)\$subKey")
    if ($null -eq $key) {
        throw "Failed to create the registry key '$subKey' under the user hive '$($userHive.PSChildName)'."
    }

    try {
        $key.SetValue('', '', [Microsoft.Win32.RegistryValueKind]::String)
    }
    finally {
        $key.Close()
    }
}
