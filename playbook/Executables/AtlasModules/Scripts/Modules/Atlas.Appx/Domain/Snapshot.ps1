# Atlas.Appx domain: package snapshot and deprovisioning.
#
# The PowerShell AppX removal plan is bracketed by these two functions:
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

    # The removal plan operates across every existing user. Snapshot the same
    # all-user Bundle/Main inventory so deprovision markers do not depend on which
    # account happened to launch the playbook.
    @(Get-AppxPackage -AllUsers -PackageTypeFilter Bundle, Main -ErrorAction Stop).PackageFamilyName |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Sort-Object -Unique |
        Set-Content -LiteralPath $Path -Encoding ASCII
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

        # Overridable for tests. The live all-user inventory is read only after the
        # required snapshot has been validated, so a missing snapshot cannot trigger
        # unrelated package enumeration first.
        [AllowNull()]
        [AllowEmptyCollection()]
        [string[]]$CurrentPackages
    )

    if (-not (Test-Path -LiteralPath $SnapshotPath -PathType Leaf)) {
        throw "AppX package snapshot '$SnapshotPath' was not found. Save-AtlasAppxSnapshot must run before deprovisioning."
    }

    if (-not $PSBoundParameters.ContainsKey('CurrentPackages')) {
        $CurrentPackages = @(
            (Get-AppxPackage -AllUsers -PackageTypeFilter Bundle, Main -ErrorAction Stop).PackageFamilyName |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                Sort-Object -Unique
        )
    }

    # No -Force on an existing key: recreating it would destroy every entry already
    # registered (the Components phase's Edge keys, OEM entries from the factory image).
    if (-not (Test-Path -LiteralPath $DeprovisionedKeyPath)) {
        New-Item -Path $DeprovisionedKeyPath -Force | Out-Null
    }

    $oldPackages = @(Get-Content -LiteralPath $SnapshotPath -ErrorAction Stop)
    foreach ($family in (Get-AtlasAppxRemovedPackage -Snapshot $oldPackages -Current $CurrentPackages)) {
        New-Item -Path $DeprovisionedKeyPath -Name $family -Force | Out-Null
        Write-AtlasLog -Message "Deprovisioned removed AppX package family '$family'."
    }

    Remove-Item -LiteralPath $SnapshotPath -Force -ErrorAction Stop
}
