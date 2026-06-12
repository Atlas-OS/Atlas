Add-Type -AssemblyName System.Windows.Forms

$windir = [Environment]::GetFolderPath('Windows')
& "$windir\AtlasModules\initPowerShell.ps1"


$result = [System.Windows.Forms.MessageBox]::Show("There was an error when fixing Microsoft Store. Would you like to try again?", "Confirm", "YesNo", "Error")
if ($result -eq "Yes") {
    [System.Windows.Forms.MessageBox]::Show("Please do not close the script under any circumstances. Doing so will result in your Windows installation to break significantly.", "Warning", "OK", "Warning") | Out-Null
    & "$windir\AtlasDesktop\9. Troubleshooting\Fix MS Store Issues.cmd"
}
