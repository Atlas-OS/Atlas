<#
 .Synopsis
  Tests if a path or command exists and optionally exits with an error.

 .Example
  TestPathFatal -Path "reagentc.exe" -Message "Reagentc not found, Recovery is stripped or broken." -ExitCode 1 -CommandOnly
#>

function Test-PathOrCommand {
    param (
        [string]$Path,
        [string]$Message,
        [int]$ExitCode,
        [switch]$CommandOnly
    )

    function WriteError {
        Write-Host "Error: " -NoNewLine -ForegroundColor Red
        Write-Host "$message"
        exit $exitCode
    }

    if (!(Get-Command $path -EA SilentlyContinue)) {
        if (!(Test-Path $path) -or $CommandOnly) {
            if ($ExitCode) {
                WriteError
            } else {
                return $false
            }
        }
    }

    return $true
}

Export-ModuleMember -Function Test-PathOrCommand