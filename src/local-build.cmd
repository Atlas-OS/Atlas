<# : batch portion
@echo off & powershell -nop Get-Content "%~f0" -Raw ^| iex & exit /b
: end batch / begin PowerShell #>

$excludeFiles = @("local-build.cmd", "Release ZIP")
$apbxFileName = "Atlas Test.apbx"

# ------ #
# script #
# ------ #

if (!(Test-Path -Path "playbook.conf")) {
	Write-Host "playbook.conf file not found in the current directory." -ForegroundColor Red
	exit 1
}

$filteredItems = Get-ChildItem | Where-Object { $excludeFiles -notcontains $_.Name }
$zipFileName = [System.IO.Path]::ChangeExtension($apbxFileName, "zip")

if (Test-Path -Path $apbxFileName) {Remove-Item -Path $apbxFileName -Force}

Compress-Archive -Path $filteredItems.FullName -DestinationPath $zipFileName
Rename-Item -Path $zipFileName -NewName $apbxFileName

Write-Host "Completed." -ForegroundColor Green