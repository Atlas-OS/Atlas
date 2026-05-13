[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$SettingName,

    [Parameter(Mandatory = $true)]
    [int]$StateValue,

    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,

    [string]$ScriptArgs
)

$ErrorActionPreference = 'Stop'

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if ($env:ATLAS_USER_CONTEXT -eq '1') {
    exit 0
}

if (-not (Test-IsAdministrator)) {
    Write-Output 'Administrator privileges are required.'
    $quote = [char]34
    $command = if ([string]::IsNullOrWhiteSpace($ScriptArgs)) {
        $quote + $ScriptPath + $quote
    }
    else {
        $quote + $ScriptPath + $quote + ' ' + $ScriptArgs
    }

    try {
        Start-Process -FilePath 'cmd.exe' -Verb RunAs -ArgumentList @('/c', $command) -ErrorAction Stop
    }
    catch {
        Write-Output 'You must run this script as admin.'
        if ([string]::IsNullOrWhiteSpace($ScriptArgs)) {
            & pause
        }
    }

    exit 1
}

$root = Join-Path -Path 'HKLM:\SOFTWARE\AtlasOS\Services' -ChildPath $SettingName
if (-not (Test-Path -LiteralPath $root)) {
    New-Item -Path $root -Force | Out-Null
}

New-ItemProperty -LiteralPath $root -Name 'state' -Value $StateValue -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $root -Name 'path' -Value $ScriptPath -PropertyType String -Force | Out-Null
