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

<#
		--------------------------
			  Core Isolation
		--------------------------
#>

$WindowTitle = 'Core Isolation - Atlas'

$Message = @'
Would you like to enable Core Isolation (Virtualization Based Security)?

Core Isolation is a feature in Windows that aims to protect very important parts of the operating system. Its main feature is called Memory Integrity.

This prevents attackers, malware or compromised programs from using vulnerabilities within drivers or other important components of Windows to gain access to the operating system.

Although this improves security, it will significantly worsen performance (up to ~10% in some cases), especially on older CPUs like Intel 8th gen or AMD Zen 2, but it is even impactful on recent CPUs.

You can configure this later in Windows Security app.

Automatically selecting 'No' in 5 minutes, which will disable Core Isolation features...
'@

# Default option is 'No'
$intButton = '7'
$intButton = $sh.Popup($Message,300,$WindowTitle,4+48+0)

$memIntegrity = "HKLM:\System\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
$kernelShadowStacks = "HKLM:\System\CurrentControlSet\Control\DeviceGuard\Scenarios\KernelShadowStacks"
$credentialGuard = "HKLM:\System\CurrentControlSet\Control\DeviceGuard\Scenarios\CredentialGuard"

if ($intButton -eq '7') { # if 'No'
	Write-Host Disabling VBS features...

	# Memory Integrity
	if (Test-Path $memIntegrity) {
		New-ItemProperty -Path $memIntegrity -Name "Enabled" -Value 0 -PropertyType DWORD -Force
		Remove-ItemProperty -Path $memIntegrity -Name "ChangedInBootCycle" -ErrorAction SilentlyContinue
		Remove-ItemProperty -Path $memIntegrity -Name "WasEnabledBy" -ErrorAction SilentlyContinue
	}

	# Kernel-mode Hardware-enforced Stack Protection (Windows 11 only)
	if (Test-Path $kernelShadowStacks) {
		New-ItemProperty -Path $kernelShadowStacks -Name "Enabled" -Value 0 -PropertyType DWORD -Force
		Remove-ItemProperty -Path $kernelShadowStacks -Name "ChangedInBootCycle" -ErrorAction SilentlyContinue
		Remove-ItemProperty -Path $kernelShadowStacks -Name "WasEnabledBy" -ErrorAction SilentlyContinue
	}

	# Credential Guard (Windows 11 only)
	if (Test-Path $credentialGuard) {
		New-ItemProperty -Path $credentialGuard -Name "Enabled" -Value 0 -PropertyType DWORD -Force
		Remove-ItemProperty -Path $credentialGuard -Name "ChangedInBootCycle" -ErrorAction SilentlyContinue
		Remove-ItemProperty -Path $credentialGuard -Name "WasEnabledBy" -ErrorAction SilentlyContinue
	}
} else {
	Set-ItemProperty -Path $memIntegrity -Name "Enabled" -Value 1 -Type DWord
	Set-ItemProperty -Path $memIntegrity -Name "WasEnabledBy" -Value 2 -Type DWord
}