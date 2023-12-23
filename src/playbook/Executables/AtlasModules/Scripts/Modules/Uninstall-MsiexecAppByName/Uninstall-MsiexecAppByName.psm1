<#
 .Synopsis
  Uninstalls MSIExec uninstaller applications by name.

 .Description
  Uninstalls applications that use MSIExec uninstallers recursively based on a 
  wildcarded display name (DisplayName in Registry).

 .Parameter Name
  The display name of the MSIExec uninstaller application(s) to wildcard
  and uninstall.
 
 .Example
  # Uninstalls any apps matching "Microsoft Update Health Tools"
  Uninstall-MsiexecAppByName -Name "Microsoft Update Health Tools"
#>

function Uninstall-MsiexecAppByName {
	param(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Name
	)

	if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
		throw "Uninstall-MsiexecAppByName: Not running as an administrator!"
	}

	$uninstallKeyPath = "Microsoft\Windows\CurrentVersion\Uninstall"
	$uninstallKeys = (Get-ChildItem -Path @(
		"HKLM:\SOFTWARE\$uninstallKeyPath",
		"HKLM:\SOFTWARE\WOW6432Node\$uninstallKeyPath",
		"HKCU:\SOFTWARE\$uninstallKeyPath",
		"HKCU:\SOFTWARE\WOW6432Node\$uninstallKeyPath"
	) -EA SilentlyContinue) -match "\{\b[A-Fa-f0-9]{8}(?:-[A-Fa-f0-9]{4}){3}-[A-Fa-f0-9]{12}\b\}"

	foreach ($key in $uninstallKeys.PSPath) {
		$displayName = (Get-ItemProperty -Path $key).DisplayName
		if (($displayName -like "*$Name*") -and ((Get-ItemProperty -Path $key).UninstallString -like "*MsiExec.exe*")) {
			Write-Output "Uninstalling $displayName..."
			Start-Process -FilePath "msiexec.exe" -ArgumentList "/qn /X$(Split-Path -Path $key -Leaf) REBOOT=ReallySuppress /norestart" 2>&1 | Out-Null
		}
	}

	if ($null -eq $foundKey) {
		throw "Uninstall-MsiexecAppByName: No app found with an MSIExec uninstaller with the display name containing '$Name'."
	}
}

Export-ModuleMember -Function Uninstall-MsiexecAppByName
