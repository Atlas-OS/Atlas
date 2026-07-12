[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Begin', 'RecordOption', 'Commit')]
    [string]$Operation,

    [ValidateSet('Fresh', 'Upgrade', 'Reapply')]
    [string]$Mode,

    [switch]$Oobe,

    [ValidateSet(
        'auto-updates-default',
        'auto-updates-disable',
        'browser-brave',
        'browser-chrome',
        'browser-firefox',
        'browser-librewolf',
        'defender-disable',
        'defender-enable',
        'disable-core-isolation',
        'disable-hibernation',
        'disable-power-saving',
        'install-another-browser',
        'install-toolbox',
        'mitigations-default',
        'mitigations-disable',
        'remove-snipping-tool',
        'uninstall-edge'
    )]
    [string]$Option
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$stateManifest = Join-Path -Path $PSScriptRoot `
    -ChildPath 'Modules\Atlas.InstallState\Atlas.InstallState.psd1'
Import-Module -Name $stateManifest -Force -DisableNameChecking -ErrorAction Stop

function Get-AtlasTargetVersion {
    $playbookPath = [IO.Path]::GetFullPath(
        (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\playbook.conf')
    )
    if (-not [IO.File]::Exists($playbookPath)) {
        throw "Atlas playbook.conf was not found at '$playbookPath'."
    }
    [xml]$playbook = [IO.File]::ReadAllText($playbookPath)
    $version = [string]$playbook.Playbook.Version
    if ($version -notmatch '^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$') {
        throw "Atlas target version '$version' is invalid."
    }
    return $version
}

function Find-AtlasInstallUserMarker {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Nonce
    )

    $markers = New-Object 'Collections.Generic.List[object]'
    $usersRoot = [Microsoft.Win32.Registry]::Users
    foreach ($hiveName in $usersRoot.GetSubKeyNames()) {
        if ($hiveName -notmatch '^S-1-5-21-(?:\d+-){3}\d+$') {
            continue
        }
        $marker = $usersRoot.OpenSubKey(
            "$hiveName\Software\AtlasOS\InstallSession",
            $false
        )
        if ($null -eq $marker) {
            continue
        }
        try {
            $markerNonce = [string]$marker.GetValue('Nonce', $null)
            if ($markerNonce -cne $Nonce) {
                continue
            }
            $claimedSid = [string]$marker.GetValue('UserSid', $null)
            $sessionId = $marker.GetValue('SessionId', $null)
            if ($claimedSid -cne $hiveName -or
                $sessionId -isnot [int] -or
                [int]$sessionId -lt 1) {
                throw "Install-user marker in '$hiveName' is invalid."
            }
            $markers.Add([pscustomobject]@{
                    Sid       = $hiveName
                    SessionId = [int]$sessionId
                })
        }
        finally {
            $marker.Dispose()
        }
    }

    if ($markers.Count -ne 1) {
        throw "Expected one current-user install marker for nonce '$Nonce'; found $($markers.Count)."
    }
    return $markers[0]
}

switch ($Operation) {
    'Begin' {
        if ([string]::IsNullOrWhiteSpace($Mode)) {
            throw 'Begin requires -Mode.'
        }
        if (-not [string]::IsNullOrWhiteSpace($Option)) {
            throw 'Begin does not accept -Option.'
        }
        $state = Start-AtlasInstallState `
            -TargetVersion (Get-AtlasTargetVersion) `
            -Mode $Mode `
            -IsOobe ([bool]$Oobe) `
            -CaptureNonce ([guid]::NewGuid().ToString('D'))
        Write-Output "Atlas install state ready for $($state.mode) (OOBE=$($state.isOobe))."
    }
    'RecordOption' {
        if ([string]::IsNullOrWhiteSpace($Option)) {
            throw 'RecordOption requires -Option.'
        }
        if (-not [string]::IsNullOrWhiteSpace($Mode) -or $Oobe) {
            throw 'RecordOption accepts only -Option.'
        }
        Add-AtlasInstallOption -Name $Option | Out-Null
    }
    'Commit' {
        if (-not [string]::IsNullOrWhiteSpace($Mode) -or
            -not [string]::IsNullOrWhiteSpace($Option) -or
            $Oobe) {
            throw 'Commit does not accept mode, option, or OOBE arguments.'
        }

        $state = Get-AtlasInstallState
        $installUser = $null
        if (-not [bool]$state.isOobe) {
            $installUser = Find-AtlasInstallUserMarker `
                -Nonce ([string]$state.captureNonce)
            Set-AtlasInstallUser -UserSid $installUser.Sid `
                -UserSessionId $installUser.SessionId | Out-Null
        }
        Commit-AtlasInstallState | Out-Null

        if ($null -ne $installUser) {
            try {
                $sidRoot = [Microsoft.Win32.Registry]::Users.OpenSubKey(
                    $installUser.Sid,
                    $true
                )
                if ($null -eq $sidRoot) {
                    throw "User registry hive '$($installUser.Sid)' is unavailable."
                }
                try {
                    $sidRoot.DeleteSubKeyTree(
                        'Software\AtlasOS\InstallSession',
                        $false
                    )
                }
                finally {
                    $sidRoot.Dispose()
                }
            }
            catch {
                Write-Warning -WarningAction Continue -Message (
                    'Atlas install state was committed, but its current-user ' +
                    "marker could not be removed: $($_.Exception.Message)"
                )
            }
        }
        Write-Output 'Atlas install state committed.'
    }
}
