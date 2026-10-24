$trustBootstrap = [IO.Path]::GetFullPath([IO.Path]::Combine(
        $PSScriptRoot,
        '..',
        '..',
        'Initialize-AtlasPowerShell.ps1'
    ))
if (-not [IO.File]::Exists($trustBootstrap)) {
    throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
}
. $trustBootstrap

$ErrorActionPreference = 'Stop'

function Add-AtlasPath {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Paths,

        # Tests point these at a scratch key.
        [Microsoft.Win32.RegistryHive]$Hive = [Microsoft.Win32.RegistryHive]::LocalMachine,
        [string]$SubKey = 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
    )

    foreach ($path in $Paths) {
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            throw "Required PATH entry '$path' does not exist as a container."
        }
    }

    # [Environment]'s machine PATH expands every %VAR% on read and stores REG_SZ on
    # write, which freezes entries such as %JAVA_HOME%\bin. Edit the raw value instead
    # and leave every existing entry as it is. Windows restarts after the install, so
    # nothing needs the change broadcast.
    $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey($Hive, [Microsoft.Win32.RegistryView]::Default)
    try {
        $key = $baseKey.OpenSubKey($SubKey, $true)
        if ($null -eq $key) {
            throw "The environment key '$SubKey' is missing."
        }
        try {
            $currentPath = [string]$key.GetValue(
                'Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
            )
            $entries = @($currentPath -split ';' | Where-Object { $_ })
            if ($entries.Count -eq 0) {
                Write-Warning 'The machine PATH variable is currently empty.'
            }

            $present = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
            foreach ($entry in $entries) {
                [void]$present.Add([Environment]::ExpandEnvironmentVariables($entry).TrimEnd('\'))
            }
            foreach ($path in $Paths) {
                if ($present.Add($path.TrimEnd('\'))) {
                    $entries += $path
                }
            }

            # Written even when nothing was added, so a PATH an earlier Atlas left as
            # REG_SZ expands its references again.
            $key.SetValue('Path', ($entries -join ';'), [Microsoft.Win32.RegistryValueKind]::ExpandString)
        }
        finally {
            $key.Dispose()
        }
    }
    finally {
        $baseKey.Dispose()
    }
}

$modulesPath = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules'
Add-AtlasPath -Paths @(
    $modulesPath,
    (Join-Path -Path $modulesPath -ChildPath 'Tools'),
    (Join-Path -Path $modulesPath -ChildPath 'Scripts')
)
