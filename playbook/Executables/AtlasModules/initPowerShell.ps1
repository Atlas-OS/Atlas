# Keep Atlas' protected module tree ahead of inherited per-user module paths. All
# privileged entry points import Atlas modules by manifest path as well; ordering this
# path first protects the remaining command auto-loading used by standalone scripts.
$atlasModulesRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Scripts\Modules'
$pathSeparator = [IO.Path]::PathSeparator
$trimCharacters = [char[]]@('\', '/')
$normalizedAtlasRoot = $atlasModulesRoot.TrimEnd($trimCharacters)

$inheritedPaths = @($env:PSModulePath -split [regex]::Escape([string]$pathSeparator) |
    Where-Object {
        -not [string]::IsNullOrWhiteSpace($_) -and
        -not [string]::Equals(
            $_.Trim().TrimEnd($trimCharacters),
            $normalizedAtlasRoot,
            [StringComparison]::OrdinalIgnoreCase
        )
    })

$env:PSModulePath = (@($atlasModulesRoot) + $inheritedPaths) -join $pathSeparator
