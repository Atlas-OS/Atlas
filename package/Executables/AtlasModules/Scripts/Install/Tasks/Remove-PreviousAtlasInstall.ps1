<#
.SYNOPSIS
    Removes the installed AtlasModules and AtlasDesktop folders before the new files are
    copied, keeping the service backups and the logs.
.DESCRIPTION
    Invoke-AtlasPackageReplacement.ps1 runs it as TrustedInstaller on an update, a
    reinstall or a Rebase.

    Permissions changed by hand can refuse even TrustedInstaller. Then, and only for an
    item inside one of these two verified folders, it takes ownership of the item and
    everything under it, gives SYSTEM and Administrators full control, and tries again.
.PARAMETER LibraryOnly
    Only defines the functions, for tests that dot-source the script.
#>
[CmdletBinding()]
param(
    [switch]$LibraryOnly
)

$trustBootstrap = [IO.Path]::GetFullPath([IO.Path]::Combine(
        $PSScriptRoot, '..', '..', 'Initialize-AtlasPowerShell.ps1'
    ))
if (-not [IO.File]::Exists($trustBootstrap)) {
    throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
}
. $trustBootstrap

$ErrorActionPreference = 'Stop'

function Test-AtlasRemovalAccessDenied {
    <#
    .SYNOPSIS
        Whether Windows refused a removal for its permissions, not for a file in use.
    .DESCRIPTION
        Windows PowerShell's Remove-Item -Force reports a refused delete as an
        ArgumentException under RemoveFileSystemItemArgumentError, keeping only the
        localised message, so that error id counts as a refusal too.
    #>
    param([Parameter(Mandatory = $true)][System.Management.Automation.ErrorRecord]$ErrorRecord)

    if ($ErrorRecord.CategoryInfo.Category -eq [System.Management.Automation.ErrorCategory]::PermissionDenied -or
        ([string]$ErrorRecord.FullyQualifiedErrorId).StartsWith('RemoveFileSystemItemArgumentError,', [StringComparison]::Ordinal) -or
        ([string]$ErrorRecord.FullyQualifiedErrorId).StartsWith('RemoveFileSystemItemUnAuthorizedAccess,', [StringComparison]::Ordinal)) {
        return $true
    }
    for ($cause = $ErrorRecord.Exception; $null -ne $cause; $cause = $cause.InnerException) {
        # 0x80070005 is E_ACCESSDENIED.
        if ($cause -is [UnauthorizedAccessException] -or $cause.HResult -eq -2147024891) {
            return $true
        }
    }
    return $false
}

function Get-AtlasRemovalFailurePath {
    <#
    .SYNOPSIS
        The item a failed removal names, which Remove-Item -Recurse gives as its target,
        or the item that was being removed.
    #>
    param(
        [Parameter(Mandatory = $true)][System.Management.Automation.ErrorRecord]$ErrorRecord,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $target = $ErrorRecord.TargetObject
    if ($target -is [IO.FileSystemInfo]) {
        return $target.FullName
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$target) -and [IO.Path]::IsPathRooted([string]$target)) {
        return [string]$target
    }
    return $Path
}

function Enable-AtlasOwnershipPrivilege {
    # The extracted package's Atlas.Core, which the install session has usually loaded.
    if ($null -eq (Get-Command -Name Initialize-AtlasNativeType -CommandType Function -ErrorAction SilentlyContinue)) {
        Import-Module -Name ([IO.Path]::GetFullPath([IO.Path]::Combine(
                    $PSScriptRoot, '..', '..', 'Modules', 'Atlas.Core', 'Atlas.Core.psd1'))) -ErrorAction Stop
    }
    Initialize-AtlasNativeType
    [Atlas.Native.OwnershipPrivilege]::Enable()
}

function Set-AtlasRemovalDirectoryAccess {
    param([Parameter(Mandatory = $true)][string]$Path, [Parameter(Mandatory = $true)]$Security)
    # Written on this directory alone. SetAccessControl would propagate it, and the
    # repair source under Packages\WinSxS holds hard links to Windows' own manifests,
    # whose security that would rewrite.
    [Atlas.Native.DirectoryDacl]::SetProtected($Path, $Security)
}

function Grant-AtlasPreviousInstallAccess {
    <#
    .SYNOPSIS
        Takes ownership of an item in a verified Atlas folder, and of every directory and
        file under it, and gives SYSTEM and Administrators full control of each, so
        TrustedInstaller can delete them. Refuses a reparse point.
    .DESCRIPTION
        Hard-linked files share their security with the Windows files they link to, so
        they're unlinked instead: full control of their folder is enough to delete a link,
        where Remove-Item -Force would also need to change the file's attributes.
    #>
    param([Parameter(Mandatory = $true)][string]$Path)

    Enable-AtlasOwnershipPrivilege
    $self = [Security.Principal.WindowsIdentity]::GetCurrent().User
    $allowed = @($self, (New-Object Security.Principal.SecurityIdentifier('S-1-5-32-544'))) |
        Sort-Object -Property Value -Unique
    $fullControl = [Security.AccessControl.FileSystemRights]::FullControl
    $allow = [Security.AccessControl.AccessControlType]::Allow
    $inherit = [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
        [Security.AccessControl.InheritanceFlags]::ObjectInherit

    $pending = New-Object 'Collections.Generic.Stack[string]'
    $pending.Push($Path)
    while ($pending.Count -gt 0) {
        $current = $pending.Pop()
        $attributes = [IO.File]::GetAttributes($current)
        if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Refusing to take ownership through a reparse point at '$current'."
        }
        $isDirectory = ($attributes -band [IO.FileAttributes]::Directory) -ne 0
        if (-not $isDirectory) {
            # A file whose links can't be counted is treated as linked.
            $linkType = try { [string](Get-Item -LiteralPath $current -Force -ErrorAction Stop).LinkType } catch { 'Unknown' }
            if ($linkType -cne '') {
                [IO.File]::Delete($current)
                continue
            }
        }

        if ($isDirectory) {
            $owner = New-Object Security.AccessControl.DirectorySecurity
            $owner.SetOwner($self)
            [IO.Directory]::SetAccessControl($current, $owner)
            $access = New-Object Security.AccessControl.DirectorySecurity
            $access.SetAccessRuleProtection($true, $false)
            foreach ($sid in $allowed) {
                $access.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule(
                            $sid, $fullControl, $inherit, [Security.AccessControl.PropagationFlags]::None, $allow)))
            }
            Set-AtlasRemovalDirectoryAccess -Path $current -Security $access
            foreach ($entry in [IO.Directory]::GetFileSystemEntries($current)) {
                $pending.Push($entry)
            }
        }
        else {
            $owner = New-Object Security.AccessControl.FileSecurity
            $owner.SetOwner($self)
            [IO.File]::SetAccessControl($current, $owner)
            $access = New-Object Security.AccessControl.FileSecurity
            $access.SetAccessRuleProtection($true, $false)
            foreach ($sid in $allowed) {
                $access.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($sid, $fullControl, $allow)))
            }
            [IO.File]::SetAccessControl($current, $access)
        }
    }
}

function Remove-AtlasPreviousInstallItem {
    <#
    .SYNOPSIS
        Removes one item of a verified Atlas folder. A removal Windows refuses for its
        permissions takes the item back and tries once more; a failure names the item.
    #>
    param([Parameter(Mandatory = $true)][string]$Path)

    try {
        Remove-Item -LiteralPath $Path -Force -Recurse -ErrorAction Stop
        return
    }
    catch {
        $refused = Get-AtlasRemovalFailurePath -ErrorRecord $_ -Path $Path
        if (-not (Test-AtlasRemovalAccessDenied -ErrorRecord $_)) {
            throw "Removing '$refused' from the previous Atlas install failed: $($_.Exception.Message)"
        }
    }

    Write-Output "Windows refused access to '$refused', so Atlas takes ownership of '$Path' and gives SYSTEM and Administrators full control before removing it again."
    try {
        Grant-AtlasPreviousInstallAccess -Path $Path
    }
    catch {
        throw "Atlas couldn't take back '$Path' from the previous Atlas install, whose permissions were changed outside Atlas: $($_.Exception.Message) Delete '$Path' yourself, or give Administrators full control of it, then try installing Atlas again."
    }
    try {
        Remove-Item -LiteralPath $Path -Force -Recurse -ErrorAction Stop
    }
    catch {
        $refused = Get-AtlasRemovalFailurePath -ErrorRecord $_ -Path $Path
        throw "Atlas couldn't remove '$refused' from the previous Atlas install, even after taking ownership of '$Path': $($_.Exception.Message) Delete it yourself, or give Administrators full control of it, then try installing Atlas again."
    }
}

if ($LibraryOnly) {
    return
}

$windowsPath = [Environment]::GetFolderPath('Windows')
if ([string]::IsNullOrWhiteSpace($windowsPath) -or -not (Test-Path -LiteralPath $windowsPath -PathType Container)) {
    throw "Windows directory '$windowsPath' is not available."
}

$resolvedWindowsPath = (Resolve-Path -LiteralPath $windowsPath).ProviderPath.TrimEnd('\')
foreach ($childName in @('AtlasDesktop', 'AtlasModules')) {
    $target = Join-Path -Path $resolvedWindowsPath -ChildPath $childName
    if (-not (Test-Path -LiteralPath $target)) {
        continue
    }

    $resolvedTarget = (Resolve-Path -LiteralPath $target).ProviderPath.TrimEnd('\')
    if (-not $resolvedTarget.StartsWith($resolvedWindowsPath + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove unexpected Atlas path '$resolvedTarget'."
    }

    # These files describe this device before Atlas changed its services. They
    # cannot be recreated from the already optimised installation.
    $backupNames = @('winServices.reg', 'atlasServices.reg')
    $otherPath = Join-Path $resolvedTarget 'Other'
    $backups = @()
    $kept = @()
    if ($childName -eq 'AtlasModules' -and (Test-Path -LiteralPath $otherPath -PathType Container)) {
        $other = Get-Item -LiteralPath $otherPath -Force
        if ($other.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "Refusing to preserve service backups through a reparse point at '$otherPath'."
        }
        $backups = @(Get-ChildItem -LiteralPath $otherPath -Force | Where-Object {
            -not $_.PSIsContainer -and $backupNames -contains $_.Name -and
            -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint)
        })
        if ($backups.Count -gt 0) { $kept += $otherPath }
    }
    # The logs are the evidence of earlier installs and of this one, which has been
    # writing to them since it began; the new files never bring any.
    $logsPath = Join-Path $resolvedTarget 'Logs'
    if ($childName -eq 'AtlasModules' -and (Test-Path -LiteralPath $logsPath -PathType Container)) {
        $logs = Get-Item -LiteralPath $logsPath -Force
        if ($logs.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "Refusing to keep Atlas's logs through a reparse point at '$logsPath'."
        }
        $kept += $logsPath
    }
    if ($kept.Count -eq 0) {
        Remove-AtlasPreviousInstallItem -Path $resolvedTarget
        continue
    }

    # Keep these in place across interruption; the new files merge into these
    # directories without carrying forward any old executable scripts.
    foreach ($item in Get-ChildItem -LiteralPath $resolvedTarget -Force) {
        if ($kept -contains $item.FullName) { continue }
        $resolvedItem = (Resolve-Path -LiteralPath $item.FullName).ProviderPath
        if (-not $resolvedItem.StartsWith($resolvedTarget + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove unexpected Atlas path '$resolvedItem'."
        }
        Remove-AtlasPreviousInstallItem -Path $resolvedItem
    }
    if ($backups.Count -eq 0) { continue }
    foreach ($item in Get-ChildItem -LiteralPath $otherPath -Force) {
        if ($backups.FullName -contains $item.FullName) { continue }
        $resolvedItem = (Resolve-Path -LiteralPath $item.FullName).ProviderPath
        if (-not $resolvedItem.StartsWith($otherPath + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove unexpected Atlas path '$resolvedItem'."
        }
        Remove-AtlasPreviousInstallItem -Path $resolvedItem
    }
}
