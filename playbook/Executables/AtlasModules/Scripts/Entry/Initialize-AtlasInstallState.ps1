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
        'install-eclean',
        'keyboard-shortcuts',
        'keyboard-selector',
        'keyboard-single',
        'mitigations-default',
        'mitigations-disable',
        'remove-snipping-tool',
        'uninstall-edge'
    )]
    [string]$Option
)

$scriptsRoot = [IO.Path]::GetFullPath([IO.Path]::GetDirectoryName($PSScriptRoot))
$bootstrap = [IO.Path]::Combine($scriptsRoot, 'Initialize-AtlasPowerShell.ps1')
if (-not [IO.File]::Exists($bootstrap)) { throw "The PowerShell bootstrap is missing at '$bootstrap'." }
. $bootstrap

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$stateManifest = Join-Path -Path $scriptsRoot `
    -ChildPath 'Modules\Atlas.InstallState\Atlas.InstallState.psd1'
Import-Module -Name $stateManifest -Force -DisableNameChecking -ErrorAction Stop

function Find-AtlasInstallUserMarker {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Nonce,

        [Microsoft.Win32.RegistryKey]$UsersRoot = [Microsoft.Win32.Registry]::Users
    )

    $markers = New-Object 'Collections.Generic.List[object]'
    # Work or school (Microsoft Entra ID) accounts load as S-1-12-1 hives. The
    # install plan can't act for them, so a marker there is only named.
    $entraHives = New-Object 'Collections.Generic.List[string]'
    foreach ($hiveName in $UsersRoot.GetSubKeyNames()) {
        $entra = $hiveName -match '^S-1-12-1-(?:\d+-){3}\d+$'
        if (-not $entra -and $hiveName -notmatch '^S-1-5-21-(?:\d+-){3}\d+$') {
            continue
        }
        $marker = $UsersRoot.OpenSubKey(
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
            if ($entra) {
                $entraHives.Add($hiveName)
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

    if ($markers.Count -eq 0 -and $entraHives.Count -gt 0) {
        throw ("The install was started from a work or school (Microsoft Entra ID) account ($($entraHives -join ', ')). " +
            "Atlas can't be installed from such an account; sign in with a local account or a Microsoft account, then try again.")
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
        # AME Wizard chooses the mode by itself, so it stops before anything changes
        # where the front door would refuse or choose a Rebase.
        . (Join-Path -Path $scriptsRoot -ChildPath 'Preparation\WindowsTransition.ps1')
        Assert-AtlasWindowsTransitionAllowsAme -WindowsBuild ([int](Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name CurrentBuildNumber).CurrentBuildNumber)
        $state = Start-AtlasInstallState `
            -TargetVersion (Get-AtlasPlaybookVersion) `
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
        if ($null -eq $state) {
            throw 'No active Atlas install state exists to commit.'
        }
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
