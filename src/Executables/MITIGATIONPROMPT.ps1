$WindowTitle = 'Security Mitigations Prompt - Atlas'

$Message = @'
Would you like to disable security CPU mitigations/fixes for vulnerabilities like Meltdown and Spectre?

This is mostly beneficial on older CPUs, recent CPUs have these fixes implemented in hardware. In some cases (like AMD Zen 4 CPUs), it can be significantly worse for performance to disable mitigations.

However, old CPUs do not have these mitigations/fixes at a hardware level, meaning that mitigations can significantly decrease performance.

You can always change this after you have installed Atlas, and it is recommended to benchmark the effects of this tweak, if you use it.

Realistically, you are unlikely to be attacked due to worse security from disabling CPU mitigations. However, disabling them is worse for security, that's why they exist.

Automatically selecting 'No' in 2 minutes...
'@

$sh = New-Object -ComObject "Wscript.Shell"
$intButton = $sh.Popup($Message,120,$WindowTitle,4+64+4096)

if ($intButton -eq '6') {
	Write-Host Disabling mitigiations...
	$loggedinUsername = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty UserName) -replace '^.*\\'
	$mitigationScriptPath = "C:\Users\$loggedInUsername\Desktop\Atlas\3. Configuration\1. General Configuration\Mitigations\Disable All Mitigations.cmd"
	Start-Process -WindowStyle Hidden -FilePath "$mitigationScriptPath" -ArgumentList "/silent"
}