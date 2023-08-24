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
if "%*"=="" (
	fltmc >nul 2>&1 || (
		echo Administrator privileges are required.
		PowerShell Start -Verb RunAs '%0' 2> nul || (
			echo You must run this script as admin.
			pause & exit /b 1
		)
		exit /b
	)
)

set args= & set "args1=%*"
if defined args1 set "args=%args1:"='%"
powershell -nop "& ([Scriptblock]::Create((Get-Content '%~f0' -Raw))) %args%"
exit /b %errorlevel%
: end batch / begin PowerShell #>

param (
    [string]$CabPath,
    [switch]$Silent
)

# You can automate this script with variables as well:
# $CabPath = "C:\Package.cab"
# Note: only works if $CabPath is defined
# $Silent = $true

if ($CabPath) {
	$cabArg = $true

    if (!(Test-Path $CabPath -PathType Leaf)) {
        Write-Host "The specified .cab file does not exist or isn't a file." -ForegroundColor Red
        exit 1
    }

    if (!((Get-Item $CabPath).Extension -eq '.cab')) {
        Write-Host "The specified file is not a .cab file." -ForegroundColor Red
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
	$openFileDialog.Filter = "CBS Package Files (*.cab)|*.cab"
	$openFileDialog.Title = "Select a CBS Package File"
	if ($openFileDialog.ShowDialog() -eq 'OK') {
		$cabPath = $openFileDialog.FileName
		cls
	} else {exit}
}

try {
	if (!($silent)) {Write-Warning "Importing and checking certificate..."}
	try {
		$cert = (Get-AuthenticodeSignature $cabPath).SignerCertificate
		foreach ($usage in $cert.Extensions.EnhancedKeyUsages) { if ($usage.Value -eq "1.3.6.1.4.1.311.10.3.6") { $correctUsage = $true } }
		if (!($correctUsage)) {
			Write-Host 'The certificate inside of the CAB selected does not have the "Windows System Component Verification" enhanced key usage.' -ForegroundColor Red
			if (!($cabArg)) {PauseNul}; exit 2
		}
		$certPath = [System.IO.Path]::GetTempFileName()
		[System.IO.File]::WriteAllBytes($certPath, $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))
		Import-Certificate $certPath -CertStoreLocation "Cert:\LocalMachine\Root" | Out-Null
		Copy-Item -Path "$certRegPath\$($cert.Thumbprint)" "$certRegPath\8A334AA8052DD244A647306A76B8178FA215F344" -Force | Out-Null
	} catch {
		Write-Host "`nSomething went wrong importing and checking the certificate of: $cabPath" -ForegroundColor Red
		Write-Host "$_`n" -ForegroundColor Red
		if (!($cabArg)) {PauseNul}; exit 3
	}

	if (!($silent)) {Write-Warning "Adding package..."}
	try {
		Add-WindowsPackage -Online -PackagePath $cabPath -NoRestart -IgnoreCheck -LogLevel 1 *>$null
	} catch {
		Write-Host "Something went wrong adding the package: $cabPath" -ForegroundColor Red
		Write-Host "$_`n" -ForegroundColor Red
		if (!($cabArg)) {PauseNul}; exit 4
	}
} finally {
	if (!($silent)) {Write-Warning "Cleaning up certificates..."}
	Get-ChildItem "Cert:\LocalMachine\Root\$($cert.Thumbprint)" -EA SilentlyContinue | Remove-Item -Force -EA SilentlyContinue | Out-Null
	Remove-Item "$certRegPath\8A334AA8052DD244A647306A76B8178FA215F344" -Force -Recurse -EA SilentlyContinue | Out-Null
}

if (!($silent)) {Write-Host "`nCompleted!" -ForegroundColor Green}
if (!($cabArg)) {
	choice /c yn /n /m "Would you like to restart now to apply the changes? [Y/N] "
	if ($lastexitcode -eq 1) {Restart-Computer}
}