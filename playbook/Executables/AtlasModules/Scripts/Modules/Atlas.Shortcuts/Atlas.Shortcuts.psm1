function Resolve-AtlasShortcutPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Description,

        [ValidateSet('Any', 'File', 'Directory')]
        [string]$PathType = 'Any',

        [switch]$AllowMissing
    )

    $isDrivePath = $Path -match '\A[A-Za-z]:[\\/]'
    $isUncPath = $Path -match '\A\\\\[^\\]+\\[^\\]+'
    if (-not $isDrivePath -and -not $isUncPath) {
        throw "$Description must be a fully qualified path: '$Path'."
    }

    try {
        $fullPath = [System.IO.Path]::GetFullPath($Path)
    }
    catch {
        throw "$Description is not a valid path: '$Path'. $($_.Exception.Message)"
    }

    if ($AllowMissing) {
        return $fullPath
    }

    $exists = switch ($PathType) {
        'File' { [System.IO.File]::Exists($fullPath) }
        'Directory' { [System.IO.Directory]::Exists($fullPath) }
        default {
            [System.IO.File]::Exists($fullPath) -or
                [System.IO.Directory]::Exists($fullPath)
        }
    }
    if (-not $exists) {
        throw "$Description was not found: '$fullPath'."
    }

    return $fullPath
}

function New-AtlasShortcut {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,

        [ValidateNotNullOrEmpty()]
        [string]$WorkingDir,

        [AllowEmptyString()]
        [string]$Arguments = '',

        [ValidateNotNullOrEmpty()]
        [string]$Icon,

        [switch]$IfExist
    )

    $sourcePath = Resolve-AtlasShortcutPath -Path $Source -Description 'Shortcut source'
    $destinationPath = Resolve-AtlasShortcutPath `
        -Path $Destination `
        -Description 'Shortcut destination' `
        -AllowMissing

    if (-not [string]::Equals(
            [System.IO.Path]::GetExtension($destinationPath),
            '.lnk',
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
        throw "Shortcut destination must use the '.lnk' extension: '$destinationPath'."
    }

    if ($IfExist -and -not [System.IO.File]::Exists($destinationPath)) {
        return
    }

    $destinationDirectory = [System.IO.Path]::GetDirectoryName($destinationPath)
    [void](Resolve-AtlasShortcutPath `
            -Path $destinationDirectory `
            -Description 'Shortcut destination directory' `
            -PathType Directory)

    if ([string]::IsNullOrWhiteSpace($WorkingDir)) {
        $WorkingDir = [System.IO.Path]::GetDirectoryName($sourcePath)
    }
    $workingDirectoryPath = Resolve-AtlasShortcutPath `
        -Path $WorkingDir `
        -Description 'Shortcut working directory' `
        -PathType Directory

    if (-not $PSCmdlet.ShouldProcess($destinationPath, "Create shortcut to '$sourcePath'")) {
        return
    }

    $shell = $null
    $shortcut = $null
    try {
        $shell = New-Object -ComObject WScript.Shell -ErrorAction Stop
        $shortcut = $shell.CreateShortcut($destinationPath)
        $shortcut.TargetPath = $sourcePath
        $shortcut.WorkingDirectory = $workingDirectoryPath
        $shortcut.Arguments = $Arguments
        if (-not [string]::IsNullOrWhiteSpace($Icon)) {
            $shortcut.IconLocation = $Icon
        }
        $shortcut.Save()
    }
    finally {
        if ($null -ne $shortcut -and
            [System.Runtime.InteropServices.Marshal]::IsComObject($shortcut)) {
            [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($shortcut)
        }
        if ($null -ne $shell -and
            [System.Runtime.InteropServices.Marshal]::IsComObject($shell)) {
            [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell)
        }
    }

    if (-not [System.IO.File]::Exists($destinationPath)) {
        throw "WScript.Shell did not create the shortcut '$destinationPath'."
    }
}

Export-ModuleMember -Function New-AtlasShortcut
