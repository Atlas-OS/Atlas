# Applies one declarative tweak category in four ordered scopes: machine work and the
# narrowly allowed live-user policy roots as TrustedInstaller, ordinary HKCU work as
# the exact installing user, then the default hive.
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('networking', 'performance', 'privacy', 'qol', 'security', 'debloat', 'scripts', 'misc')]
    [string]$Category
)

Assert-AtlasPrivilege -TrustedInstaller

$context = Get-AtlasContext -Refresh
if (-not $context.IsInstallStateBacked) {
    throw 'Tweaks phase requires active Atlas install state.'
}
if ([string]::IsNullOrWhiteSpace([string]$context.TransactionId)) {
    throw 'Tweaks phase requires the Atlas transaction id.'
}
if (-not $context.IsOobe -and
    [string]::IsNullOrWhiteSpace([string]$context.InteractiveUserSid)) {
    throw 'Non-OOBE tweaks require the install-state user SID.'
}

$scriptsRoot = Split-Path -Path $PSScriptRoot -Parent
$modulesRoot = Join-Path -Path $scriptsRoot -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Tweaks\Atlas.Tweaks.psd1') -Force -ErrorAction Stop

# Companion scripts execute in this machine pass. RegistryScope keeps HKCU out of it.
Invoke-AtlasTweakCategory -Name $Category -RegistryScope Machine

if (-not $context.IsOobe) {
    $powerShellPath = Join-Path -Path ([string]$context.WinDir) `
        -ChildPath 'System32\WindowsPowerShell\v1.0\powershell.exe'
    if (-not (Test-Path -LiteralPath $powerShellPath -PathType Leaf)) {
        throw "Windows PowerShell is missing at '$powerShellPath'."
    }

    function Invoke-AtlasTweakUserScript {
        param(
            [Parameter(Mandatory = $true)][string]$Path,
            [Parameter(Mandatory = $true)][string[]]$ArgumentList,
            [Parameter(Mandatory = $true)][string]$Description
        )

        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw "$Description script is missing at '$Path'."
        }
        $hostArguments = [string[]]@(
            '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
            '-File', $Path
        ) + $ArgumentList
        $arguments = ConvertTo-AtlasWindowsArgumentString -ArgumentList $hostArguments
        $exitCode = Invoke-AtlasAsUser -FilePath $powerShellPath `
            -Arguments $arguments -WorkingDirectory ([string]$context.WinDir)
        if ($exitCode -ne 0) {
            throw "$Description exited with code $exitCode."
        }
    }

    $optionSnapshot = [string[]]@($context.Options)
    $optionsJson = ConvertTo-Json -Compress -InputObject $optionSnapshot
    $optionsBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($optionsJson))

    $policyArguments = [string[]]@(
        '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
        '-File', (Join-Path $scriptsRoot 'Tasks\Invoke-AtlasInstallingUserPolicyRegistry.ps1'),
        '-Category', $Category,
        '-ExpectedUserSid', [string]$context.InteractiveUserSid,
        '-TransactionId', [string]$context.TransactionId,
        '-OptionsBase64', $optionsBase64,
        '-WindowsBuild', [string]$context.WindowsBuild
    )
    if ($context.IsUpgrade) { $policyArguments += '-IsUpgrade' }
    if ($context.IsArm64) { $policyArguments += '-IsArm64' }
    Invoke-AtlasHiddenProcess -FilePath $powerShellPath -ArgumentList $policyArguments `
        -Wait | Out-Null

    $registryArguments = @(
        '-Category', $Category,
        '-ExpectedUserSid', [string]$context.InteractiveUserSid,
        '-OptionsBase64', $optionsBase64,
        '-WindowsBuild', [string]$context.WindowsBuild
    )
    if ($context.IsUpgrade) { $registryArguments += '-IsUpgrade' }
    if ($context.IsArm64) { $registryArguments += '-IsArm64' }

    Invoke-AtlasTweakUserScript `
        -Path (Join-Path $scriptsRoot 'Tasks\Invoke-AtlasInstallingUserRegistry.ps1') `
        -ArgumentList $registryArguments `
        -Description "Installing-user registry category '$Category'"

    $refreshOperations = @(Get-AtlasTweakCategoryPostUserRegistryRefresh `
            -Name $Category -Context $context)
    foreach ($operation in $refreshOperations) {
        Invoke-AtlasTweakUserScript `
            -Path (Join-Path $scriptsRoot 'Internal\Invoke-AtlasUserShellRefresh.ps1') `
            -ArgumentList @(
                '-Operation', [string]$operation,
                '-ExpectedUserSid', [string]$context.InteractiveUserSid
            ) `
            -Description "Post-registry shell refresh '$operation' for '$Category'"
    }
}

# Default-user data is applied only after any live-user work succeeds.
$null = Initialize-AtlasRegistryIdentityContext -DefaultUserOnly `
    -TransactionId ([string]$context.TransactionId)
Invoke-AtlasTweakCategory -Name $Category -RegistryScope DefaultUser -RegistryOnly
