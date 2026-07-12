function ConvertTo-AtlasShellWindowsArgument {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value
    )

    if ($Value.Length -gt 32767) {
        throw 'A shell-handler argument exceeds the Windows command-line length boundary.'
    }

    # Apply the CommandLineToArgvW/CRT quoting rules even when quoting would be
    # optional. In particular, a trailing backslash must be doubled before the
    # closing quote so a drive root such as C:\ remains one unchanged argv item.
    $builder = [Text.StringBuilder]::new()
    [void]$builder.Append([char]34)
    $backslashCount = 0
    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq [char]92) {
            $backslashCount++
            continue
        }
        if ($character -eq [char]34) {
            [void]$builder.Append([char]92, (($backslashCount * 2) + 1))
            [void]$builder.Append([char]34)
            $backslashCount = 0
            continue
        }
        if ($backslashCount -gt 0) {
            [void]$builder.Append([char]92, $backslashCount)
            $backslashCount = 0
        }
        [void]$builder.Append($character)
    }
    if ($backslashCount -gt 0) {
        [void]$builder.Append([char]92, ($backslashCount * 2))
    }
    [void]$builder.Append([char]34)
    return $builder.ToString()
}

function Get-AtlasTakeOwnershipArgumentPlan {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('File', 'Directory', 'Drive')]
        [string]$TargetType,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetPath,

        [AllowNull()]
        [string]$YesChoice
    )

    $takeOwnArguments = @('/f', $TargetPath)
    # /l keeps icacls on a link itself instead of following its destination.
    $icaclsArguments = @($TargetPath, '/grant', '*S-1-3-4:F', '/t', '/c', '/l')

    if ($TargetType -ne 'File') {
        if ([string]::IsNullOrWhiteSpace($YesChoice) -or $YesChoice.Length -ne 1) {
            throw 'Recursive Take Ownership requires one localized affirmative choice character.'
        }

        # Atlas targets Windows 11 builds whose inbox takeown.exe documents
        # /SKIPSL as the /R no-follow switch. This prevents recursive ownership
        # changes from escaping through descendant symbolic links or junctions.
        $takeOwnArguments += @('/r', '/d', $YesChoice, '/SKIPSL')
    }
    if ($TargetType -eq 'Directory') {
        $icaclsArguments += '/q'
    }

    return [pscustomobject]@{
        TakeOwnArguments = [string[]]$takeOwnArguments
        IcaclsArguments  = [string[]]$icaclsArguments
    }
}

function Assert-AtlasTakeOwnershipTree {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RootPath
    )

    $pendingDirectories = [Collections.Generic.Stack[string]]::new()
    $pendingDirectories.Push($RootPath)

    while ($pendingDirectories.Count -gt 0) {
        $directoryPath = $pendingDirectories.Pop()
        foreach ($entryPath in [IO.Directory]::GetFileSystemEntries($directoryPath)) {
            $attributes = [IO.File]::GetAttributes($entryPath)
            if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "The recursive Take Ownership target contains a descendant reparse point: '$entryPath'."
            }
            if (($attributes -band [IO.FileAttributes]::Directory) -ne 0) {
                $pendingDirectories.Push($entryPath)
            }
        }
    }
}
