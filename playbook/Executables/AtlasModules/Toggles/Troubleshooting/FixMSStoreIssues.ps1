function Invoke-AtlasStoreFixer {
    param($Toggle)

    # Orphaned AppX deployment rows fail installs on their own, and removing only them
    # needs neither StoreFixer's Safe Mode restart nor a rebuilt deployment database.
    if (Repair-AtlasAppRepositoryOrphan) {
        return
    }

    $storeFixer = Join-Path -Path $Toggle.AtlasModulesPath -ChildPath 'Tools\StoreFixer.exe'
    if (-not (Test-Path -LiteralPath $storeFixer -PathType Leaf)) {
        throw "Required StoreFixer executable is missing: '$storeFixer'."
    }

    # The TrustedInstaller broker always runs this silently.
    Invoke-AtlasToggleNativeCommand -FilePath $storeFixer -ArgumentList ([string[]]@('silent', '-wait')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
}

function Get-AtlasAppRepositoryPath {
    $directory = Join-Path -Path ([Environment]::GetFolderPath('CommonApplicationData')) `
        -ChildPath 'Microsoft\Windows\AppRepository'
    [pscustomobject]@{
        Directory  = $directory
        Deployment = Join-Path -Path $directory -ChildPath 'StateRepository-Deployment.srd'
        Machine    = Join-Path -Path $directory -ChildPath 'StateRepository-Machine.srd'
    }
}

function Get-AtlasAppRepositoryOrphanCount {
    param($Path)

    [Atlas.Native.AppRepositoryOrphans]::Count($Path.Deployment, $Path.Machine)
}

function Remove-AtlasAppRepositoryOrphanRow {
    param($Path)

    [Atlas.Native.AppRepositoryOrphans]::Remove($Path.Deployment, $Path.Machine)
}

function Save-AtlasAppRepositoryBackup {
    param($Path)

    # The database and its write-ahead log are copied together while StateRepository is
    # stopped, so the copy can replace the database as it was.
    $suffix = '.atlas-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
    foreach ($extension in @('', '-wal', '-shm')) {
        $source = $Path.Deployment + $extension
        if (Test-Path -LiteralPath $source -PathType Leaf) {
            Copy-Item -LiteralPath $source -Destination ($source + $suffix) -ErrorAction Stop
        }
    }
    Write-AtlasLog -Message "Saved the AppX deployment database as '$($Path.Deployment)$suffix'."
}

function Repair-AtlasAppRepositoryOrphan {
    <#
    .SYNOPSIS
        Removes AppX deployment rows that belong to no registered package. Returns $true
        when it removed some, and $false when there were none or they could not be
        removed safely, so StoreFixer runs instead.
    #>
    $path = Get-AtlasAppRepositoryPath
    if (-not (Test-Path -LiteralPath $path.Deployment -PathType Leaf) -or
        -not (Test-Path -LiteralPath $path.Machine -PathType Leaf)) {
        Write-AtlasLog -Message 'The AppX package databases were not found, so StoreFixer repairs the Store.'
        return $false
    }

    # StateRepository holds both databases open. Services that depend on it stop with it,
    # and the ones that were running are started again afterwards.
    $service = Get-Service -Name 'StateRepository' -ErrorAction Stop
    $running = @(@($service.DependentServices) | Where-Object { $_.Status -eq 'Running' } |
            ForEach-Object { $_.Name })
    try {
        Initialize-AtlasNativeType
        Stop-Service -Name 'StateRepository' -Force -ErrorAction Stop
        $count = Get-AtlasAppRepositoryOrphanCount -Path $path
        if ($count.Total -eq 0) {
            Write-AtlasLog -Message 'The AppX deployment database has no orphaned rows.'
            return $false
        }

        Save-AtlasAppRepositoryBackup -Path $path
        $removed = Remove-AtlasAppRepositoryOrphanRow -Path $path
        Write-AtlasLog -Message ('Removed {0} AppX deployment rows of packages that are no longer registered: {1} files, {2} manifests and {3} source URIs.' -f
            $removed.Total, $removed.Files, $removed.Manifests, $removed.SourceUris)
        return $true
    }
    catch {
        Write-AtlasLog -Level Warning -ErrorRecord $_ -Message 'Removing orphaned AppX deployment rows failed, so StoreFixer repairs the Store.'
        return $false
    }
    finally {
        foreach ($name in @('StateRepository') + $running) {
            try {
                Start-Service -Name $name -ErrorAction Stop
            }
            catch {
                Write-AtlasLog -Level Warning -ErrorRecord $_ -Message "Starting the '$name' service again failed."
            }
        }
    }
}
