<# : batch portion
@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

set args= & set "args1=%*"
if defined args1 set "args=%args1:"='%"
powershell -nop "& ([Scriptblock]::Create((Get-Content '%~f0' -Raw))) %args%"
exit /b %errorlevel%
: end batch / begin powershell #>

# I have no idea why Windows Defender Application Control randomly enables and causes this issue.
# It may be something to do with removing Defender, although I'm not sure, and I don't know the exact root cause.
# It seems like other custom Windows modifications like ReviOS have also had or have this issue.

# Reproduced by updating from base 22H2.
# https://learn.microsoft.com/en-us/windows/security/application-security/application-control/windows-defender-application-control/deployment/disable-wdac-policies

param (
    [switch]$Setup
)

function PauseNul ($message = "Press any key to exit... ") {
	Write-Host $message -NoNewLine
	$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
}

$EFIPartition = (Get-Partition | Where-Object IsSystem).AccessPaths[0]
$SinglePolicyFormatFileName = "\SiPolicy.p7b"
$SystemCodeIntegrityFolderRoot = $env:windir+"\System32\CodeIntegrity"

if ($null -ne $EFIPartition) {
    $MountPoint =  $env:SystemDrive+"\AtlasEFIMountClearWDAC"
    $EFICodeIntegrityFolderRoot = $MountPoint+"\EFI\Microsoft\Boot"

    # Mount the EFI partition
    if (-Not (Test-Path $MountPoint)) { New-Item -Path $MountPoint -Type Directory -Force | Out-Null }
    mountvol $MountPoint $EFIPartition | Out-Null

    Remove-Item "$EFICodeIntegrityFolderRoot\CiPolicies\Active\*" -Force -Recurse -EA SilentlyContinue
    Remove-Item "$EFICodeIntegrityFolderRoot\$SinglePolicyFormatFileName" -Force -EA SilentlyContinue

    # Dismount the EFI partition
    mountvol $MountPoint /D | Out-Null
    if (Test-Path "$MountPoint\*") {
        Write-Host "It seems like the $MountPoint directory still has files in it, unmounting might of failed." -ForegroundColor Red
        if ($Setup) {exit 1} else {PauseNul}
    } else {
        Remove-Item $MountPoint -Force | Out-Null
    }
}

Remove-Item "$SystemCodeIntegrityFolderRoot\CiPolicies\Active\*" -Force -Recurse -EA SilentlyContinue

Write-Host "`nCompleted!" -ForegroundColor Green
if (!($Setup)) {
	choice /c yn /n /m "Would you like to restart now to apply the changes? [Y/N] "
	if ($lastexitcode -eq 1) {Restart-Computer}
}