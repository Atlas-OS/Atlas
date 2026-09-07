# Atlas.Core domain: privilege identity and the closed TrustedInstaller operation API.

function Test-AtlasAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-AtlasCurrentUserSid {
    return [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
}

function Test-AtlasSystem {
    try {
        return (Get-AtlasCurrentUserSid) -eq 'S-1-5-18'
    }
    catch {
        return $false
    }
}

function Test-AtlasTrustedInstaller {
    try {
        return [bool](Get-AtlasCurrentTokenEvidence).IsTrustedInstaller
    }
    catch {
        return $false
    }
}

function Assert-AtlasPrivilege {
    param(
        [switch]$Administrator,
        [switch]$System,
        [switch]$TrustedInstaller
    )

    if ($TrustedInstaller -and -not (Test-AtlasTrustedInstaller)) {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $evidenceText = try {
            $evidence = Get-AtlasCurrentTokenEvidence
            "user=$($evidence.UserSid), enabledTiSid=$($evidence.HasEnabledTrustedInstallerSid), integrity=0x$('{0:X}' -f $evidence.IntegrityRid)"
        }
        catch {
            "tokenEvidenceError=$($_.Exception.Message)"
        }
        throw "[privilege] This operation requires a TrustedInstaller service token (SYSTEM user, enabled NT SERVICE\TrustedInstaller SID, System integrity); current identity is '$($identity.Name)' ($($identity.User.Value)); $evidenceText."
    }

    if ($System -and -not (Test-AtlasSystem)) {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        throw "[privilege] This operation requires LocalSystem (S-1-5-18); current identity is '$($identity.Name)' ($($identity.User.Value))."
    }

    if ($Administrator -and -not (Test-AtlasAdmin)) {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        throw "[privilege] This operation requires Administrator rights; current identity is '$($identity.Name)'."
    }
}

function Invoke-AtlasTrustedInstaller {
    <#
    .SYNOPSIS
        Runs one closed Atlas operation through the fixed elevated broker.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Toggle', 'ResetServices', 'Install')]
        [string]$Operation,

        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$')]
        [string]$Name,

        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$')]
        [string]$State,

        [bool]$Silent = $true,
        [switch]$JustContext,
        [switch]$NoExplorerRestart,
        [switch]$MachineOnly,

        [ValidateSet('ToggleDefaults', 'WindowsBackup', 'AtlasBackup')]
        [string]$RestoreSource,

        [ValidateSet('Capture', 'Run')]
        [string]$InstallPhase,

        [string]$PayloadRoot,

        [ValidateRange(1, 86400)]
        [int]$TimeoutSeconds = 900
    )

    $operationParameterAllowlist = @{
        Toggle        = @('Name', 'State', 'Silent', 'JustContext', 'NoExplorerRestart', 'MachineOnly')
        ResetServices = @('RestoreSource')
        Install       = @('InstallPhase', 'PayloadRoot')
    }
    foreach ($operationParameter in @(
            'Name', 'State', 'Silent', 'JustContext', 'NoExplorerRestart', 'MachineOnly', 'RestoreSource',
            'InstallPhase', 'PayloadRoot'
        )) {
        if ($PSBoundParameters.ContainsKey($operationParameter) -and
            $operationParameter -notin $operationParameterAllowlist[$Operation]) {
            throw "$Operation does not accept the operation input '-$operationParameter'."
        }
    }

    $context = Get-AtlasContext
    $brokerModulesPath = $context.AtlasModulesPath
    if ($Operation -eq 'Install') {
        if ([string]::IsNullOrWhiteSpace($InstallPhase) -or [string]::IsNullOrWhiteSpace($PayloadRoot)) {
            throw 'Install requires typed -InstallPhase and -PayloadRoot values.'
        }
        if (-not [IO.Path]::IsPathRooted($PayloadRoot)) {
            throw 'Install requires an absolute -PayloadRoot.'
        }
        $PayloadRoot = [IO.Path]::GetFullPath($PayloadRoot)
        $stagingRoot = [IO.Path]::GetFullPath((Join-Path $context.WinDir 'AtlasOS\Staging'))
        if (-not $PayloadRoot.StartsWith($stagingRoot + [IO.Path]::DirectorySeparatorChar,
                [StringComparison]::OrdinalIgnoreCase)) {
            throw "Install PayloadRoot must be beneath the protected staging root '$stagingRoot'."
        }
        # A fresh installation has no installed broker yet. Use the broker shipped
        # with this protected candidate, including when upgrading an older payload.
        $brokerModulesPath = Join-Path $PayloadRoot 'AtlasModules'
    }

    $argumentList = [Collections.Generic.List[string]]::new()
    foreach ($argument in @(
            '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
            '-File', (Join-Path $brokerModulesPath `
                'Scripts\Entry\Invoke-AtlasTrustedInstallerBroker.ps1'),
            '-Operation', $Operation,
            '-TimeoutSeconds', [string]$TimeoutSeconds
        )) {
        $argumentList.Add($argument)
    }

    switch ($Operation) {
        'Toggle' {
            if ([string]::IsNullOrWhiteSpace($Name) -or [string]::IsNullOrWhiteSpace($State)) {
                throw 'Toggle requires typed -Name and -State values.'
            }
            if (-not $Silent) {
                throw 'The TrustedInstaller Toggle operation is noninteractive and requires -Silent:$true.'
            }
            $argumentList.Add('-Name')
            $argumentList.Add($Name)
            $argumentList.Add('-State')
            $argumentList.Add($State)
            foreach ($switchName in @('JustContext', 'NoExplorerRestart', 'MachineOnly')) {
                if ($PSBoundParameters[$switchName]) {
                    $argumentList.Add("-$switchName")
                }
            }
        }
        'ResetServices' {
            if ([string]::IsNullOrWhiteSpace($RestoreSource)) {
                throw 'ResetServices requires a typed -RestoreSource value.'
            }
            $argumentList.Add('-RestoreSource')
            $argumentList.Add($RestoreSource)
        }
        'Install' {
            if ([string]::IsNullOrWhiteSpace($InstallPhase) -or [string]::IsNullOrWhiteSpace($PayloadRoot)) {
                throw 'Install requires typed -InstallPhase and -PayloadRoot values.'
            }
            if (-not [IO.Path]::IsPathRooted($PayloadRoot)) {
                throw 'Install requires an absolute -PayloadRoot.'
            }
            $argumentList.Add('-InstallPhase')
            $argumentList.Add($InstallPhase)
            $argumentList.Add('-PayloadRoot')
            $argumentList.Add([IO.Path]::GetFullPath($PayloadRoot))
        }
    }

    Assert-AtlasPrivilege -Administrator
    $context = Get-AtlasContext
    $powershellPath = Join-Path $context.WinDir 'System32\WindowsPowerShell\v1.0\powershell.exe'
    # The broker owns the operation deadline. Give it a short, separate window to
    # terminate and drain its kill-on-close job before the caller treats the broker
    # itself as unresponsive.
    $brokerProcessTimeoutSeconds = $TimeoutSeconds + 15
    return Invoke-AtlasHiddenProcess `
        -FilePath $powershellPath `
        -ArgumentList $argumentList.ToArray() `
        -Wait `
        -CaptureOutput `
        -TimeoutSeconds $brokerProcessTimeoutSeconds
}
