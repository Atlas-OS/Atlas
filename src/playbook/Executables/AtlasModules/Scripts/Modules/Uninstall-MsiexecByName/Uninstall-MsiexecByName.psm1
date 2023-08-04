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
    
    $uninstallKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    $uninstallKeys = Get-ChildItem -Path $uninstallKeyPath -EA SilentlyContinue

    foreach ($key in $uninstallKeys.PSPath) {
        $displayName = (Get-ItemProperty -Path "$key").DisplayName
        if ($displayName -like "*$Name*") {
            $uninstallString = (Get-ItemProperty -Path "$key").UninstallString
            if ($uninstallString -like "*MsiExec.exe*") {
                $foundKey = $key | Split-Path -Leaf
                Write-Warning "Uninstalling $displayName..."
                Start-Process -FilePath "msiexec.exe" -ArgumentList "/qn /X$foundKey REBOOT=ReallySuppress /norestart"
            }
        }
    }

    if ($null -eq $foundKey) {
        throw "Uninstall-MsiexecAppByName: No app found with an MSIExec uninstaller with the display name containing '$Name'."
    }
}

Export-ModuleMember -Function Uninstall-MsiexecAppByName