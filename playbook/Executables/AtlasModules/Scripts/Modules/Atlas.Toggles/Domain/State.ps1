# Atlas.Toggles domain: user setting state registry.
#
# Every toggle choice is recorded under HKLM\SOFTWARE\AtlasOS\Services\<SettingName> with
# a 'state' REG_DWORD and a 'path' REG_SZ holding the full path of the on-disk launcher.
# Upgrades re-run the recorded launcher with /silent for every state != 0, so this schema
# is a compatibility contract with existing installs and must stay byte-identical.

$script:AtlasToggleDefaultStateRoot = 'HKLM:\SOFTWARE\AtlasOS\Services'

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
    $path = $null
    if ($properties.PSObject.Properties['state']) {
        $state = [int]$properties.state
    }
    if ($properties.PSObject.Properties['path']) {
        $path = [string]$properties.path
    }

    return [pscustomobject]@{
        Name  = $Name
        State = $state
        Path  = $path
    }
}

function Set-AtlasToggleState {
    <#
    .SYNOPSIS
        Records a toggle choice in the Atlas state registry: 'state' (REG_DWORD) and
        'path' (REG_SZ, full path of the launcher that can re-apply it with /silent).
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [int]$State,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LauncherPath,

        [ValidateNotNullOrEmpty()]
        [string]$StateRoot = $script:AtlasToggleDefaultStateRoot
    )

    $keyPath = Join-Path -Path $StateRoot -ChildPath $Name
    if (-not (Test-Path -LiteralPath $keyPath)) {
        New-Item -Path $keyPath -Force | Out-Null
    }

    New-ItemProperty -LiteralPath $keyPath -Name 'state' -Value $State -PropertyType DWord -Force | Out-Null
    New-ItemProperty -LiteralPath $keyPath -Name 'path' -Value $LauncherPath -PropertyType String -Force | Out-Null
}
