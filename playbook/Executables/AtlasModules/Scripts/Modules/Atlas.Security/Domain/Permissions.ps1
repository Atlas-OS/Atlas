# Atlas.Security domain: Windows TEMP permission repair.
#
# Installer errors 2502 and 2503 come from a Windows TEMP root whose DACL no longer
# grants the Windows default rights. The repair replaces only the root DACL: recursing
# ownership or ACL changes into a writable TEMP tree would let an unprivileged user
# race a privileged traversal through attacker-made descendants. Existing files are
# deliberately left untouched.

function Get-AtlasWindowsTempAccessRuleSpecs {
    $inheritContainersAndObjects =
        [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
        [Security.AccessControl.InheritanceFlags]::ObjectInherit
    $inheritContainers = [Security.AccessControl.InheritanceFlags]::ContainerInherit
    $inheritOnly = [Security.AccessControl.PropagationFlags]::InheritOnly
    $noPropagation = [Security.AccessControl.PropagationFlags]::None

    return @(
        [pscustomobject]@{
            Sid         = 'S-1-5-18'
            Rights      = [Security.AccessControl.FileSystemRights]::FullControl
            Inheritance = $inheritContainersAndObjects
            Propagation = $noPropagation
        }
        [pscustomobject]@{
            Sid         = 'S-1-5-32-544'
            Rights      = [Security.AccessControl.FileSystemRights]::FullControl
            Inheritance = $inheritContainersAndObjects
            Propagation = $noPropagation
        }
        [pscustomobject]@{
            Sid         = 'S-1-3-0'
            Rights      = [Security.AccessControl.FileSystemRights]::FullControl
            Inheritance = $inheritContainersAndObjects
            Propagation = $inheritOnly
        }
        [pscustomobject]@{
            Sid         = 'S-1-5-32-545'
            Rights      = (
                [Security.AccessControl.FileSystemRights]::Synchronize -bor
                [Security.AccessControl.FileSystemRights]::WriteData -bor
                [Security.AccessControl.FileSystemRights]::AppendData -bor
                [Security.AccessControl.FileSystemRights]::ExecuteFile
            )
            Inheritance = $inheritContainers
            Propagation = $noPropagation
        }
    )
}

function Set-AtlasWindowsTempRootAcl {
    <#
    .SYNOPSIS
        Replaces one directory's DACL with the Windows default TEMP rule set and verifies
        the result rule by rule.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $allow = [Security.AccessControl.AccessControlType]::Allow
    $ruleSpecs = @(Get-AtlasWindowsTempAccessRuleSpecs)

    $acl = Get-Acl -LiteralPath $Path -ErrorAction Stop
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($rule in @($acl.Access)) {
        [void]$acl.RemoveAccessRuleSpecific($rule)
    }
    foreach ($spec in $ruleSpecs) {
        $sid = New-Object Security.Principal.SecurityIdentifier($spec.Sid)
        $rule = New-Object Security.AccessControl.FileSystemAccessRule(
            $sid,
            $spec.Rights,
            $spec.Inheritance,
            $spec.Propagation,
            $allow
        )
        $acl.AddAccessRule($rule)
    }
    # Persist only the changed DACL section; owner, group and audit entries are untouched.
    (New-Object IO.DirectoryInfo($Path)).SetAccessControl($acl)

    $verifiedAcl = Get-Acl -LiteralPath $Path -ErrorAction Stop
    if (-not $verifiedAcl.AreAccessRulesProtected) {
        throw 'The Windows TEMP DACL still inherits permissions after repair.'
    }
    $verifiedRules = @($verifiedAcl.Access)
    if ($verifiedRules.Count -ne $ruleSpecs.Count) {
        throw "The Windows TEMP DACL contains $($verifiedRules.Count) rules; expected $($ruleSpecs.Count)."
    }
    foreach ($spec in $ruleSpecs) {
        $matchingRules = @($verifiedRules | Where-Object {
                $identity = $_.IdentityReference.Translate(
                    [Security.Principal.SecurityIdentifier]
                ).Value
                [string]::Equals(
                    $identity,
                    $spec.Sid,
                    [StringComparison]::Ordinal
                ) -and
                $_.AccessControlType -eq $allow -and
                -not $_.IsInherited -and
                [int]$_.FileSystemRights -eq [int]$spec.Rights -and
                $_.InheritanceFlags -eq $spec.Inheritance -and
                $_.PropagationFlags -eq $spec.Propagation
            })
        if ($matchingRules.Count -ne 1) {
            throw "The Windows TEMP DACL did not retain the exact rule for '$($spec.Sid)'."
        }
    }
}

function Repair-AtlasWindowsTempPermissions {
    <#
    .SYNOPSIS
        Resets the DACL of the fixed Windows TEMP root to the Windows default rule set
        (SYSTEM, Administrators, CREATOR OWNER and Users), which fixes installer errors
        2502 and 2503. Requires Administrator rights.
    #>
    [CmdletBinding()]
    param()

    Assert-AtlasPrivilege -Administrator

    $windowsPath = [IO.Path]::GetFullPath(
        [Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)
    )
    $tempPath = [IO.Path]::GetFullPath([IO.Path]::Combine($windowsPath, 'Temp'))
    $expectedPath = $windowsPath.TrimEnd([IO.Path]::DirectorySeparatorChar) +
        [IO.Path]::DirectorySeparatorChar + 'Temp'
    if (-not $tempPath.Equals($expectedPath, [StringComparison]::OrdinalIgnoreCase)) {
        throw "The Windows TEMP path resolved outside the fixed Windows directory: '$tempPath'."
    }
    if (-not [IO.Directory]::Exists($tempPath)) {
        throw "The Windows TEMP directory is missing: '$tempPath'."
    }
    if (([IO.File]::GetAttributes($tempPath) -band
            [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "The Windows TEMP directory is a reparse point: '$tempPath'."
    }

    Set-AtlasWindowsTempRootAcl -Path $tempPath
    Write-AtlasLog -Message "Reset the Windows TEMP root permissions at '$tempPath'."
}
