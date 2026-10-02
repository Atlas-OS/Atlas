<#
.SYNOPSIS
    Puts back the Windows Update settings Atlas Manager turned on to update Windows,
    after this install has replayed the user's recorded choices and written its pin.
.DESCRIPTION
    Runs in every install mode. Without an open Windows Update record it does nothing.
    A problem here is a warning, never an install failure: the record stays open and
    Atlas Manager offers to put the settings back from Home.
#>
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
Assert-AtlasPrivilege -TrustedInstaller
. (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'Preparation\WindowsTransition.ps1')

try {
    foreach ($line in @(Complete-AtlasWindowsTransition)) {
        Write-AtlasLog -Message ([string]$line)
    }
}
catch {
    Write-AtlasLog -Level Warning -Message "Windows Update settings were not put back: $($_.Exception.Message) Atlas Manager offers to put them back from Home."
}
