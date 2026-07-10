# Atlas.Toggles domain: user setting state registry.
#
# Every toggle choice is recorded under HKLM\SOFTWARE\AtlasOS\Services\<SettingName> as
# declarative data: the subkey identifies the toggle and 'state' is its REG_DWORD value.
# Executable paths are deliberately not persisted. Upgrade replay resolves the current
# installed definition by name so writable registry data can never become code.

$script:AtlasToggleDefaultStateRoot = 'HKLM:\SOFTWARE\AtlasOS\Services'

function Test-AtlasToggleProductionStateRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StateRoot
    )

    return [string]::Equals(
        $StateRoot.TrimEnd('\'),
        $script:AtlasToggleDefaultStateRoot.TrimEnd('\'),
        [System.StringComparison]::OrdinalIgnoreCase
    )
}

function New-AtlasToggleStateAcl {
    <#
    .SYNOPSIS
        Builds the protected ACL used for the production toggle state tree.
    #>
    $acl = New-Object -TypeName System.Security.AccessControl.RegistrySecurity
    $acl.SetAccessRuleProtection($true, $false)

    $administrators = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList 'S-1-5-32-544'
    $acl.SetOwner($administrators)

    # Keep the state readable by ordinary launcher processes, but writable only by the
    # privileged identities that apply Atlas and its TrustedInstaller-only toggles.
    $rules = @(
        @{ Sid = 'S-1-5-18'; Rights = [System.Security.AccessControl.RegistryRights]::FullControl }
        @{ Sid = 'S-1-5-32-544'; Rights = [System.Security.AccessControl.RegistryRights]::FullControl }
        @{ Sid = 'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'; Rights = [System.Security.AccessControl.RegistryRights]::FullControl }
        @{ Sid = 'S-1-5-32-545'; Rights = [System.Security.AccessControl.RegistryRights]::ReadKey }
    )

    foreach ($entry in $rules) {
        $identity = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $entry.Sid
        $rule = New-Object -TypeName System.Security.AccessControl.RegistryAccessRule -ArgumentList @(
            $identity,
            $entry.Rights,
            [System.Security.AccessControl.InheritanceFlags]::ContainerInherit,
            [System.Security.AccessControl.PropagationFlags]::None,
            [System.Security.AccessControl.AccessControlType]::Allow
        )
        $acl.AddAccessRule($rule) | Out-Null
    }

    return $acl
}

function Set-AtlasToggleStateKeyAcl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyPath
    )

    Set-Acl -LiteralPath $KeyPath -AclObject (New-AtlasToggleStateAcl) -ErrorAction Stop
}

function New-AtlasToggleProductionStateRoot {
    <#
    .SYNOPSIS
        Atomically creates the production state root with its protected DACL.
    .DESCRIPTION
        RegistryKey.CreateSubKey applies RegistrySecurity as part of key creation. The
        caller subsequently reopens the path to reset an existing key if another process
        created it immediately before this call.
    #>
    $baseKey = $null
    $stateKey = $null
    try {
        $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
            [Microsoft.Win32.RegistryHive]::LocalMachine,
            [Microsoft.Win32.RegistryView]::Default
        )
        $acl = New-AtlasToggleStateAcl
        $stateKey = $baseKey.CreateSubKey(
            'SOFTWARE\AtlasOS\Services',
            [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
            [Microsoft.Win32.RegistryOptions]::None,
            $acl
        )
        if ($null -eq $stateKey) {
            throw 'Creating the Atlas toggle state root returned no registry key.'
        }
    }
    finally {
        if ($stateKey) {
            $stateKey.Dispose()
        }
        if ($baseKey) {
            $baseKey.Dispose()
        }
    }
}

function Protect-AtlasToggleStateRoot {
    <#
    .SYNOPSIS
        Creates or migrates the production state tree to its protected DACL.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$StateRoot,

        [switch]$Create,

        [switch]$IncludeChildren
    )

    # Alternate roots are an explicit test/integration seam. The production replay path
    # always uses the fixed HKLM root and is the boundary that requires this DACL.
    if (-not (Test-AtlasToggleProductionStateRoot -StateRoot $StateRoot)) {
        return
    }

    if (-not (Test-Path -LiteralPath $StateRoot)) {
        if (-not $Create) {
            return
        }
        New-AtlasToggleProductionStateRoot
    }

    # Existing installs may have inherited a user-writable DACL. Reopen with the registry
    # provider's ACL rights and replace it before inspecting or migrating any child record.
    # This also closes a race where CreateSubKey opened a key another process just created.
    Set-AtlasToggleStateKeyAcl -KeyPath $StateRoot

    if ($IncludeChildren) {
        foreach ($child in @(Get-ChildItem -LiteralPath $StateRoot -Recurse -ErrorAction Stop)) {
            Set-AtlasToggleStateKeyAcl -KeyPath $child.PSPath
        }
    }
}

function Remove-AtlasToggleLegacyPath {
    <#
    .SYNOPSIS
        Removes the legacy executable 'path' value without disturbing declarative or
        product metadata that other Atlas components may read.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyPath
    )

    $key = Get-Item -LiteralPath $KeyPath -ErrorAction Stop
    if (@($key.GetValueNames()) -contains 'path') {
        Remove-ItemProperty -LiteralPath $KeyPath -Name 'path' -Force -ErrorAction Stop
    }
}

function Initialize-AtlasToggleStateStore {
    <#
    .SYNOPSIS
        Hardens the production state tree and removes legacy executable paths.
    #>
    param(
        [ValidateNotNullOrEmpty()]
        [string]$StateRoot = $script:AtlasToggleDefaultStateRoot
    )

    Protect-AtlasToggleStateRoot -StateRoot $StateRoot -Create -IncludeChildren
    if (-not (Test-Path -LiteralPath $StateRoot)) {
        return
    }
    foreach ($child in @(Get-ChildItem -LiteralPath $StateRoot -ErrorAction Stop)) {
        Remove-AtlasToggleLegacyPath -KeyPath $child.PSPath
    }
}

function Get-AtlasToggleState {
    <#
    .SYNOPSIS
        Reads the recorded state of a toggle from the Atlas state registry. Returns $null
        when the toggle has never been recorded.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [ValidateNotNullOrEmpty()]
        [string]$StateRoot = $script:AtlasToggleDefaultStateRoot
    )

    $keyPath = Join-Path -Path $StateRoot -ChildPath $Name
    if (-not (Test-Path -LiteralPath $keyPath)) {
        return $null
    }

    $properties = Get-ItemProperty -LiteralPath $keyPath -ErrorAction SilentlyContinue
    if ($null -eq $properties) {
        return $null
    }

    $state = $null
    if ($properties.PSObject.Properties['state']) {
        $state = [int]$properties.state
    }

    return [pscustomobject]@{
        Name  = $Name
        State = $state
    }
}

function Set-AtlasToggleState {
    <#
    .SYNOPSIS
        Records a declarative toggle choice in the Atlas state registry.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [int]$State,

        # Retained as an ignored compatibility parameter for older internal callers.
        [string]$LauncherPath,

        [ValidateNotNullOrEmpty()]
        [string]$StateRoot = $script:AtlasToggleDefaultStateRoot
    )

    # Referencing this compatibility-only parameter documents that it is intentionally
    # discarded rather than accidentally omitted from persistence.
    $null = $LauncherPath

    $productionStateRoot = Test-AtlasToggleProductionStateRoot -StateRoot $StateRoot
    Protect-AtlasToggleStateRoot -StateRoot $StateRoot -Create

    $keyPath = Join-Path -Path $StateRoot -ChildPath $Name
    if (-not (Test-Path -LiteralPath $keyPath)) {
        New-Item -Path $keyPath -Force -ErrorAction Stop | Out-Null
    }

    if ($productionStateRoot) {
        Set-AtlasToggleStateKeyAcl -KeyPath $keyPath
    }

    Remove-AtlasToggleLegacyPath -KeyPath $keyPath
    New-ItemProperty -LiteralPath $keyPath -Name 'state' -Value $State -PropertyType DWord -Force | Out-Null
}
