# https://ss64.com/vb/msgbox.html
$sh = New-Object -ComObject "Wscript.Shell"

<#
		--------------------------
				Mitigations
		--------------------------
#>

$WindowTitle = 'Security Mitigations Prompt - Atlas'

$Message = @'
Would you like to disable security CPU mitigations/fixes for vulnerabilities like Meltdown and Spectre?

This is mostly beneficial on older CPUs, recent CPUs have these fixes implemented in hardware. In some cases (i.e. AMD Zen 4 CPUs), it can be significantly worse for performance to disable mitigations.

However, old CPUs do not have these mitigations/fixes at a hardware level, meaning that mitigations can significantly decrease performance.

You can always change this after you have installed Atlas, and it is recommended to benchmark the effects of this tweak, if you use it.

Realistically, you are unlikely to be attacked due to worse security from disabling CPU mitigations. However, disabling them is significantly worse for security, that's why they exist.

Automatically selecting 'Yes' in 5 minutes...
'@

# Default option is 'Yes'
$intButton = '6'
$intButton = $sh.Popup($Message,300,$WindowTitle,4+48+0)

if ($intButton -eq '6') { # if 'Yes'
	Write-Host Disabling mitigiations...
	$loggedinUsername = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty UserName) -replace '^.*\\'
	$mitigationScriptPath = "C:\Users\$loggedInUsername\Desktop\Atlas\3. Configuration\1. General Configuration\Mitigations\Disable All Mitigations.cmd"
	Start-Process -WindowStyle Hidden -FilePath "$mitigationScriptPath" -ArgumentList "/silent"
}