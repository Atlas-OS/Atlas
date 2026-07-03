$ErrorActionPreference = 'Stop'

function Add-AtlasPath {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Paths
    )

    $machine = [System.EnvironmentVariableTarget]::Machine
    $separator = [IO.Path]::PathSeparator

    foreach ($path in $Paths) {
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            throw "Required PATH entry '$path' does not exist as a container."
        }
    }

    $currentPath = [Environment]::GetEnvironmentVariable('PATH', $machine)
    $newPath = @()
    if (-not [string]::IsNullOrWhiteSpace($currentPath)) {
        $newPath += $currentPath -split [regex]::Escape($separator)
    }
    else {
        Write-Warning 'The machine PATH variable is currently empty.'
    }

    $newPath += $Paths
    $newPath = $newPath | Where-Object { $_ } | Select-Object -Unique

    [Environment]::SetEnvironmentVariable('PATH', ($newPath -join $separator), $machine)
}

$modulesPath = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules'
Add-AtlasPath -Paths @(
    $modulesPath,
    (Join-Path -Path $modulesPath -ChildPath 'Tools'),
    (Join-Path -Path $modulesPath -ChildPath 'Scripts')
)
