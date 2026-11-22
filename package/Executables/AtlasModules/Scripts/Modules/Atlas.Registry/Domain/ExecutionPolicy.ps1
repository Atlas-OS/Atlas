# Atlas.Registry domain: Windows PowerShell execution policy.
#
# The policy lives under the Windows PowerShell shell ID key. On a 64-bit operating
# system both registry views carry their own copy, so the value is written and read
# back through Microsoft.Win32.RegistryKey with an explicit view instead of the
# provider drives, which only expose the native view.

function Get-AtlasWindowsPowerShellExecutionPolicyValue {
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.RegistryKey]$Key
    )

    return [string]$Key.GetValue('ExecutionPolicy', $null)
}

function Set-AtlasWindowsPowerShellExecutionPolicy {
    <#
    .SYNOPSIS
        Sets the machine Windows PowerShell execution policy to RemoteSigned in every
        registry view and verifies that each view retained the value.
    .PARAMETER Hive
        Registry hive that owns the shell ID key. Defaults to LocalMachine; tests target
        CurrentUser together with -SubKey.
    .PARAMETER SubKey
        Key path below the hive that carries the ExecutionPolicy value. Defaults to the
        Windows PowerShell shell ID key.
    #>
    [CmdletBinding()]
    param(
        [Microsoft.Win32.RegistryHive]$Hive = [Microsoft.Win32.RegistryHive]::LocalMachine,

        [ValidateNotNullOrEmpty()]
        [string]$SubKey = 'SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell'
    )

    $views = if ([Environment]::Is64BitOperatingSystem) {
        @(
            [Microsoft.Win32.RegistryView]::Registry64,
            [Microsoft.Win32.RegistryView]::Registry32
        )
    }
    else {
        @([Microsoft.Win32.RegistryView]::Default)
    }

    foreach ($view in $views) {
        $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey($Hive, $view)
        try {
            $key = $baseKey.CreateSubKey($SubKey, $true)
            if ($null -eq $key) {
                throw "Could not open the Windows PowerShell shell ID in the $view registry view."
            }
            try {
                $key.SetValue(
                    'ExecutionPolicy',
                    'RemoteSigned',
                    [Microsoft.Win32.RegistryValueKind]::String
                )
                $actual = Get-AtlasWindowsPowerShellExecutionPolicyValue -Key $key
                if ($actual -cne 'RemoteSigned') {
                    throw "The $view Windows PowerShell execution policy did not retain RemoteSigned."
                }
            }
            finally {
                $key.Dispose()
            }
        }
        finally {
            $baseKey.Dispose()
        }
    }
}
