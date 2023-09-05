<# : batch portion
@echo off
:: GPL-3.0-only license
:: he3als 2023
:: https://github.com/he3als/online-sxs

if "%~1"=="-Help" (goto help) else (if "%~1"=="-help" (goto help) else (if "%~1"=="/h" (goto help) else (goto main)))

:help
echo Usage = online-sxs.cmd [-Help] [[-Silent] -CabPath ""]
exit /b

:main
fltmc >nul 2>&1 || (
	echo Administrator privileges are required.
	if "%*"=="" (
		PowerShell Start -Verb RunAs '%0' 2> nul || goto error
	) else (
		PowerShell Start -Verb RunAs '%0' -ArgumentList '%*' 2> nul || goto error
	)
	exit /b 0
)

set args= & set "args1=%*"
if defined args1 set "args=%args1:"='%"
powershell -nop "& ([Scriptblock]::Create((Get-Content '%~f0' -Raw))) %args%"
exit /b %errorlevel%

:error
echo You must run this script as admin.
pause & exit /b 1

: end batch / begin PowerShell #>

param (
    [string]$CabPaths, 
    [switch]$Silent
)

# You can automate this script with variables as well:
# $CabPaths = "C:\Package.cab"
# Note: only works if $cabPath is defined
# $Silent = $true

if ($CabPaths) {
	$cabArg = $true

    if (!(Test-Path $CabPaths -PathType Leaf)) {
        Write-Host "The specified files do not exist or aren't files." -ForegroundColor Red
        exit 1
    }

    if (!((Get-Item $CabPaths).Extension -eq '.cab')) {
        Write-Host "The specified files are not .cab files." -ForegroundColor Red
        exit 1
    }
} else {$Silent = $false}

$certRegPath = "HKLM:\Software\Microsoft\SystemCertificates\ROOT\Certificates"

function PauseNul ($message = "Press any key to exit... ") {
	Write-Host $message -NoNewLine
	$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
}

if ($silent) {$ProgressPreference = 'SilentlyContinue'}

if (!($cabArg)) {
	Write-Host "This will install a specified CBS package online, meaning live on your current install of Windows." -ForegroundColor Yellow
	Start-Sleep 1
	PauseNul "Press any key to continue... "
	Write-Host "`n"
	
	Write-Warning "Opening file dialog to select CBS package CAB..."
	Add-Type -AssemblyName System.Windows.Forms
	$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$openFileDialog.Multiselect = $true
	$openFileDialog.Filter = "CBS Package Files (*.cab)|*.cab"
	$openFileDialog.Title = "Select a CBS Package File"
	if ($openFileDialog.ShowDialog() -eq 'OK') {
		Clear-Host
	} else {exit}
}

function ProcessCab($cabPath) {
	try {
		if (!($Silent)) {
			$filePath = Split-Path $cabPath -Leaf
			if ($global:notFirstCab) {Write-Host ""}
			Write-Host "Installing $filePath..." -ForegroundColor Green
			Write-Host "----------------------------------------------------------------------------------------" -ForegroundColor Blue
			$global:notFirstCab = $true
		}

		if (!($silent)) {Write-Warning "Importing and checking certificate..."}
		try {
			$cert = (Get-AuthenticodeSignature $cabPath).SignerCertificate
			foreach ($usage in $cert.Extensions.EnhancedKeyUsages) { if ($usage.Value -eq "1.3.6.1.4.1.311.10.3.6") { $correctUsage = $true } }
			if (!($correctUsage)) {
				Write-Host 'The certificate inside of the CAB selected does not have the "Windows System Component Verification" enhanced key usage.' -ForegroundColor Red
				if (!($cabArg)) {PauseNul}; exit 1
			}
			$certPath = [System.IO.Path]::GetTempFileName()
			[System.IO.File]::WriteAllBytes($certPath, $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))
			Import-Certificate $certPath -CertStoreLocation "Cert:\LocalMachine\Root" | Out-Null
			Copy-Item -Path "$certRegPath\$($cert.Thumbprint)" "$certRegPath\8A334AA8052DD244A647306A76B8178FA215F344" -Force | Out-Null
		} catch {
			Write-Host "`nSomething went wrong importing and checking the certificate of: $cabPath" -ForegroundColor Red
			Write-Host "$_`n" -ForegroundColor Red
			if (!($cabArg)) {PauseNul}; exit 1
		}

		if (!($silent)) {Write-Warning "Adding package..."}
		try {
			Add-WindowsPackage -Online -PackagePath $cabPath -NoRestart -IgnoreCheck -LogLevel 1 *>$null
		} catch {
			Write-Host "Something went wrong adding the package: $cabPath" -ForegroundColor Red
			Write-Host "$_`n" -ForegroundColor Red
			if (!($cabArg)) {PauseNul}; exit 1
		}
	} finally {
		if (!($silent)) {Write-Warning "Cleaning up certificates..."}
		Get-ChildItem "Cert:\LocalMachine\Root\$($cert.Thumbprint)" | Remove-Item -Force | Out-Null
		Remove-Item "$certRegPath\8A334AA8052DD244A647306A76B8178FA215F344" -Force -Recurse | Out-Null
	}
}

if ($cabArg) {
	foreach ($cabPath in $CabPaths) {ProcessCab $cabPath}
} else {
	foreach ($cabPath in $openFileDialog.FileNames) {ProcessCab $cabPath}
}

if (!($silent)) {Write-Host "`nCompleted!" -ForegroundColor Green}
if (!($cabArg)) {
	choice /c yn /n /m "Would you like to restart now to apply the changes? [Y/N] "
	if ($lastexitcode -eq 1) {Restart-Computer}
}