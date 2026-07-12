[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Disable', 'Enable')]
    [string]$Mode
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$scriptsRoot = Split-Path -Parent $PSScriptRoot
$installStateModule = Join-Path -Path $scriptsRoot -ChildPath `
    'Modules\Atlas.InstallState\Atlas.InstallState.psd1'
Import-Module -Name $installStateModule -Force -DisableNameChecking -ErrorAction Stop

$installState = Get-AtlasInstallState
if ($null -eq $installState -or [string]$installState.status -cne 'Running') {
    throw 'Notification changes require committed Atlas install state.'
}

$script:AtlasNotificationPolicyPath =
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications'
$script:AtlasNotificationPolicyName = 'NoToastApplicationNotification'

function Get-AtlasNotificationPolicyState {
    if (-not (Test-Path -LiteralPath $script:AtlasNotificationPolicyPath)) {
        return [pscustomobject][ordered]@{ existed = $false; value = $null }
    }

    $key = Get-Item -LiteralPath $script:AtlasNotificationPolicyPath -ErrorAction Stop
    if (@($key.GetValueNames()) -cnotcontains $script:AtlasNotificationPolicyName) {
        return [pscustomobject][ordered]@{ existed = $false; value = $null }
    }

    $kind = $key.GetValueKind($script:AtlasNotificationPolicyName)
    if ($kind -ne [Microsoft.Win32.RegistryValueKind]::DWord) {
        throw "Notification policy '$script:AtlasNotificationPolicyName' must be a DWORD."
    }

    $value = $key.GetValue(
        $script:AtlasNotificationPolicyName,
        $null,
        [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
    )
    if ($null -eq $value -or $value -isnot [int]) {
        throw "Notification policy '$script:AtlasNotificationPolicyName' has an invalid DWORD value."
    }

    return [pscustomobject][ordered]@{ existed = $true; value = [int]$value }
}

function Write-AtlasNotificationPolicyState {
    param([Parameter(Mandatory = $true)]$State)

    if ($State.existed) {
        [void](New-Item -Path $script:AtlasNotificationPolicyPath -Force -ErrorAction Stop)
        [void](New-ItemProperty -LiteralPath $script:AtlasNotificationPolicyPath `
                -Name $script:AtlasNotificationPolicyName -PropertyType DWord `
                -Value ([int]$State.value) -Force -ErrorAction Stop)
    }
    elseif (Test-Path -LiteralPath $script:AtlasNotificationPolicyPath) {
        Remove-ItemProperty -LiteralPath $script:AtlasNotificationPolicyPath `
            -Name $script:AtlasNotificationPolicyName -ErrorAction SilentlyContinue
    }

    $actual = Get-AtlasNotificationPolicyState
    if ([bool]$actual.existed -ne [bool]$State.existed -or
        ($State.existed -and [int]$actual.value -ne [int]$State.value)) {
        throw 'Notification policy did not match the requested state after writeback.'
    }
}

function Read-AtlasNotificationSnapshot {
    param([Parameter(Mandatory = $true)][string]$Path)

    try {
        $snapshot = [IO.File]::ReadAllText($Path) | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Notification snapshot '$Path' is invalid: $($_.Exception.Message)"
    }

    $properties = @($snapshot.PSObject.Properties.Name)
    if ($properties.Count -ne 2 -or
        $properties -cnotcontains 'existed' -or
        $properties -cnotcontains 'value' -or
        $snapshot.existed -isnot [bool]) {
        throw "Notification snapshot '$Path' has an unsupported shape."
    }
    if ($snapshot.existed) {
        if ($null -eq $snapshot.value) {
            throw "Notification snapshot '$Path' is missing its DWORD value."
        }
        try {
            $value = [int]$snapshot.value
        }
        catch {
            throw "Notification snapshot '$Path' has an invalid DWORD value."
        }
        if ([long]$value -ne [long]$snapshot.value) {
            throw "Notification snapshot '$Path' has an invalid DWORD value."
        }
        $snapshot.value = $value
    }
    elseif ($null -ne $snapshot.value) {
        throw "Notification snapshot '$Path' contains a value for an absent policy."
    }

    return $snapshot
}

function Write-AtlasNotificationSnapshot {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$State
    )

    $temporaryPath = '{0}.{1}.tmp' -f $Path, [Guid]::NewGuid().ToString('N')
    try {
        $json = $State | ConvertTo-Json -Compress
        [IO.File]::WriteAllText($temporaryPath, $json, (New-Object Text.UTF8Encoding($false)))
        [IO.File]::Move($temporaryPath, $Path)
    }
    finally {
        if ([IO.File]::Exists($temporaryPath)) {
            [IO.File]::Delete($temporaryPath)
        }
    }
}

$workRoot = Get-AtlasInstallWorkRoot
if (-not [IO.Directory]::Exists($workRoot)) {
    throw "Atlas install work directory '$workRoot' does not exist."
}
$snapshotPath = Join-Path -Path $workRoot -ChildPath 'notification.json'

if ($Mode -eq 'Disable') {
    if (-not [IO.File]::Exists($snapshotPath)) {
        Write-AtlasNotificationSnapshot -Path $snapshotPath `
            -State (Get-AtlasNotificationPolicyState)
    }
    else {
        [void](Read-AtlasNotificationSnapshot -Path $snapshotPath)
    }

    Write-AtlasNotificationPolicyState -State (
        [pscustomobject][ordered]@{ existed = $true; value = 1 }
    )
    return
}

if (-not [IO.File]::Exists($snapshotPath)) {
    return
}

$previous = Read-AtlasNotificationSnapshot -Path $snapshotPath
Write-AtlasNotificationPolicyState -State $previous
[IO.File]::Delete($snapshotPath)
