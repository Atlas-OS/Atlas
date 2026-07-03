# Atlas.Appx domain: package snapshot and deprovisioning.
#
# The AME !appx removals in atlas\appx.yml are bracketed by these two functions:
# Save-AtlasAppxSnapshot records the installed package families beforehand, and
# Set-AtlasAppxDeprovisioned compares afterwards, registering every removed family
# under the Deprovisioned key so Windows Update doesn't reinstall it.
# https://learn.microsoft.com/en-us/windows/application-management/remove-provisioned-apps-during-update

function Get-AtlasAppxSnapshotPath {
    return Join-Path -Path (Get-AtlasContext).AtlasModulesPath -ChildPath 'AtlasPackagesOld.txt'
}

function Get-AtlasAppxRemovedPackage {
    <#
    .SYNOPSIS
        Returns the package family names present in the snapshot but no longer
        installed (pure diff helper, kept separate for testability).
    #>
    param(
        [AllowEmptyCollection()]
        [string[]]$Snapshot = @(),

        [AllowEmptyCollection()]
        [string[]]$Current = @()
    )

    return @($Snapshot | Where-Object { $_ -and ($Current -notcontains $_) })
}

function Save-AtlasAppxSnapshot {
    <#
    .SYNOPSIS
        Saves the family names of all currently installed AppX packages, so removed
        packages can be deprovisioned afterwards by Set-AtlasAppxDeprovisioned.
    #>
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Path = (Get-AtlasAppxSnapshotPath)
    )

    $parentPath = Split-Path -Parent $Path
    if ($parentPath -and -not (Test-Path -LiteralPath $parentPath -PathType Container)) {
        New-Item -Path $parentPath -ItemType Directory -Force | Out-Null
    }

    (Get-AppxPackage).PackageFamilyName | Set-Content -LiteralPath $Path -Encoding ASCII
    Write-AtlasLog -Message "Saved the AppX package snapshot to '$Path'."
}

function Set-AtlasAppxDeprovisioned {
    <#
    .SYNOPSIS
        Registers every package family that was removed since Save-AtlasAppxSnapshot
        under the AppX Deprovisioned key, then deletes the snapshot. Throws when the
        snapshot is missing, as running without it would deprovision nothing silently.
    #>
    param(
        [ValidateNotNullOrEmpty()]
        [string]$SnapshotPath = (Get-AtlasAppxSnapshotPath),

        [ValidateNotNullOrEmpty()]
        [string]$DeprovisionedKeyPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned',

        # Overridable for tests; defaults to the live package list.
        [AllowEmptyCollection()]
        [string[]]$CurrentPackages = ((Get-AppxPackage).PackageFamilyName)
    )

    if (-not (Test-Path -LiteralPath $SnapshotPath -PathType Leaf)) {
        throw "AppX package snapshot '$SnapshotPath' was not found. Save-AtlasAppxSnapshot must run before deprovisioning."
    }

    New-Item -Path $DeprovisionedKeyPath -Force | Out-Null

    $oldPackages = @(Get-Content -LiteralPath $SnapshotPath -ErrorAction Stop)
    foreach ($family in (Get-AtlasAppxRemovedPackage -Snapshot $oldPackages -Current $CurrentPackages)) {
        New-Item -Path $DeprovisionedKeyPath -Name $family -Force | Out-Null
        Write-AtlasLog -Message "Deprovisioned removed AppX package family '$family'."
    }

    Remove-Item -LiteralPath $SnapshotPath -Force -ErrorAction Stop
}
