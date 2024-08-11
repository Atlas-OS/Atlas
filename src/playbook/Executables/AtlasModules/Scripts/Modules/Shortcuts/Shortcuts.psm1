function New-Shortcut {
    [CmdletBinding()]
	param (
        [Parameter(Mandatory = $True)][ValidateNotNullOrEmpty()][string]$Source,
        [Parameter(Mandatory = $True)][ValidateNotNullOrEmpty()][string]$Destination,
        [ValidateNotNullOrEmpty()][string]$WorkingDir,
        [ValidateNotNullOrEmpty()][string]$Arguments,
		[ValidateNotNullOrEmpty()][string]$Icon,
        [switch]$IfExist
    )

    if (!(Test-Path $Source)) {
        throw "Source '$source' not found."
    }

    if ($IfExist -and !(Test-Path $Destination)) {
        return
    }

    if (!$WorkingDir) {
        $WorkingDir = Split-Path $Source
    }

	$WshShell = New-Object -ComObject WScript.Shell
	$Shortcut = $WshShell.CreateShortcut($Destination)
	$Shortcut.TargetPath = $Source
	$Shortcut.WorkingDirectory = $WorkingDir
	if ($Icon) { $Shortcut.IconLocation = $Icon }
	if ($Arguments) { $Shortcut.Arguments = $Arguments }
	$Shortcut.Save()
}

Export-ModuleMember -Function New-Shortcut