# Atlas.Shell domain: File Explorer Home pins.

function Get-AtlasShellApplication {
    <#
    .SYNOPSIS
        Creates the Shell.Application automation object for the current user's session.
    #>
    return New-Object -ComObject Shell.Application
}

function Add-AtlasMusicVideosToHome {
    <#
    .SYNOPSIS
        Pins the current user's Music and Videos folders to File Explorer Home when
        they exist and are not pinned yet.
    .DESCRIPTION
        Runs as the signed-in user; the Home namespace belongs to that user's shell.
        A missing shell folder is logged and skipped rather than failing setup.
    #>
    $shell = Get-AtlasShellApplication
    $homeNamespace = $shell.Namespace('shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}')
    if ($null -eq $homeNamespace) {
        throw 'Could not open the File Explorer Home namespace.'
    }

    $currentPins = @($homeNamespace.Items() | ForEach-Object { $_.Path })
    foreach ($path in @(
        [Environment]::GetFolderPath('MyVideos'),
        [Environment]::GetFolderPath('MyMusic')
    )) {
        if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -LiteralPath $path -PathType Container)) {
            Write-AtlasLog -Level Warning -Message "Skipping missing shell folder '$path'."
            continue
        }

        if ($currentPins -notcontains $path) {
            $folder = $shell.Namespace($path)
            if ($null -eq $folder) {
                throw "Could not open shell namespace for '$path'."
            }

            $folder.Self.InvokeVerb('pintohome')
        }
    }
}
