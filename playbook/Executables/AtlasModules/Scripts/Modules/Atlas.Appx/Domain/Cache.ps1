# Atlas.Appx domain: package cache clearing.
#
# For every user profile's package folder matching the name pattern, processes running
# from the package are stopped, the TempState folder is emptied and every '*Cache*'
# folder under LocalState is emptied (keeping SettingsCache.txt).

function Stop-AtlasAppxPackageProcess {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PackageDirectory
    )

    foreach ($exe in @(Get-ChildItem -LiteralPath $PackageDirectory -Filter '*.exe' -File -ErrorAction SilentlyContinue)) {
        foreach ($process in @(Get-Process -Name $exe.BaseName -ErrorAction SilentlyContinue)) {
            try {
                if ($process.Path -and $process.Path.StartsWith($PackageDirectory, [System.StringComparison]::OrdinalIgnoreCase)) {
                    Stop-Process -InputObject $process -Force -ErrorAction Stop
                }
            }
            catch {
                Write-AtlasLog -Level Warning -Message "Couldn't stop package process '$($process.ProcessName)': $($_.Exception.Message)"
            }
        }
    }
}

function Clear-AtlasAppxDirectoryContent {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Directory,

        [string]$ExcludeFileName
    )

    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        return
    }

    foreach ($item in @(Get-ChildItem -LiteralPath $Directory -Force -ErrorAction SilentlyContinue)) {
        if ($ExcludeFileName -and -not $item.PSIsContainer -and ($item.Name -eq $ExcludeFileName)) {
            continue
        }

        try {
            Remove-Item -LiteralPath $item.FullName -Recurse -Force -ErrorAction Stop
        }
        catch {
            Write-AtlasLog -Level Warning -Message "Couldn't delete '$($item.FullName)': $($_.Exception.Message)"
        }
    }
}

function Clear-AtlasAppxCache {
    <#
    .SYNOPSIS
        Clears the per-user caches of AppX packages matching the given name patterns
        (e.g. '*MicrosoftWindows.Client.CBS*'), stopping package processes first.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        # Overridable for tests; defaults to the live user profiles root.
        [ValidateNotNullOrEmpty()]
        [string]$UsersRoot = (Join-Path -Path $env:SystemDrive -ChildPath 'Users')
    )

    foreach ($pattern in $Name) {
        # Stop processes running from matching application folders first.
        $applicationRoots = @(
            (Join-Path -Path $env:ProgramFiles -ChildPath 'WindowsApps')
            (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'SystemApps')
        )
        foreach ($userProfile in @(Get-ChildItem -LiteralPath $UsersRoot -Directory -ErrorAction SilentlyContinue)) {
            $applicationRoots += Join-Path -Path $userProfile.FullName -ChildPath 'AppData\Local\Microsoft\WindowsApps'
        }

        foreach ($applicationRoot in $applicationRoots) {
            foreach ($packageDir in @(Get-ChildItem -LiteralPath $applicationRoot -Directory -Filter $pattern -ErrorAction SilentlyContinue)) {
                Stop-AtlasAppxPackageProcess -PackageDirectory $packageDir.FullName
            }
        }

        # Clear the per-user package caches.
        foreach ($userProfile in @(Get-ChildItem -LiteralPath $UsersRoot -Directory -ErrorAction SilentlyContinue)) {
            $packagesRoot = Join-Path -Path $userProfile.FullName -ChildPath 'AppData\Local\Packages'
            foreach ($packageDir in @(Get-ChildItem -LiteralPath $packagesRoot -Directory -Filter $pattern -ErrorAction SilentlyContinue)) {
                Stop-AtlasAppxPackageProcess -PackageDirectory $packageDir.FullName

                Clear-AtlasAppxDirectoryContent -Directory (Join-Path -Path $packageDir.FullName -ChildPath 'TempState')

                $localState = Join-Path -Path $packageDir.FullName -ChildPath 'LocalState'
                foreach ($cacheDir in @(Get-ChildItem -LiteralPath $localState -Directory -Filter '*Cache*' -ErrorAction SilentlyContinue)) {
                    Clear-AtlasAppxDirectoryContent -Directory $cacheDir.FullName -ExcludeFileName 'SettingsCache.txt'
                }
            }
        }
    }
}
