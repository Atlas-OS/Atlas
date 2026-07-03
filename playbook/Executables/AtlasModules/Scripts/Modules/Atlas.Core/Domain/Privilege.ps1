# Atlas.Core domain: privilege checks and TrustedInstaller elevation.
#
# AME Wizard runs actions as TrustedInstaller (SYSTEM, SID S-1-5-18) unless the shim
# downgrades them with runas. Post-install tools reach the same context through the
# vendored RunAsTI.cmd (AveYo, MIT), wrapped here with an absolute path so callers
# never depend on the working directory.

function Test-AtlasAdmin {
    <#
    .SYNOPSIS
        Returns whether the current process runs with Administrator rights.
    #>
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-AtlasTrustedInstaller {
    <#
    .SYNOPSIS
        Returns whether the current process runs as SYSTEM/TrustedInstaller (S-1-5-18).
    #>
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    return $identity.User.Value -eq 'S-1-5-18'
}

function Assert-AtlasPrivilege {
    <#
    .SYNOPSIS
        Throws when the current process lacks the required privilege. The thrown message
        carries the '[privilege]' marker that Invoke-AtlasInstall.ps1 maps to exit code 2.
    #>
    param(
        [switch]$Administrator,
        [switch]$TrustedInstaller
    )

    if ($TrustedInstaller -and -not (Test-AtlasTrustedInstaller)) {
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        throw "[privilege] This operation requires SYSTEM/TrustedInstaller (S-1-5-18); current identity is '$($identity.Name)' ($($identity.User.Value))."
    }

    if ($Administrator -and -not (Test-AtlasAdmin)) {
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        throw "[privilege] This operation requires Administrator rights; current identity is '$($identity.Name)'."
    }
}

function Invoke-AtlasTrustedInstaller {
    <#
    .SYNOPSIS
        Relaunches the given command line as SYSTEM/TrustedInstaller via the vendored
        RunAsTI.cmd. Returns $false when already running as S-1-5-18 (no relaunch
        happened); returns $true after scheduling the relaunch, in which case the caller
        should exit.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CommandLine
    )

    if (Test-AtlasTrustedInstaller) {
        return $false
    }

    $runAsTiPath = Join-Path -Path (Get-AtlasContext).AtlasModulesPath -ChildPath 'Scripts\RunAsTI.cmd'
    if (-not (Test-Path -LiteralPath $runAsTiPath -PathType Leaf)) {
        throw "RunAsTI.cmd not found at '$runAsTiPath'; cannot elevate to TrustedInstaller."
    }

    & "$env:ComSpec" /c "call `"$runAsTiPath`" $CommandLine"
    return $true
}
