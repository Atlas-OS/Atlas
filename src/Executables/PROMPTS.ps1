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

	# Kernel-mode Hardware-enforced Stack Protection (Windows 11 only)
	if (Test-Path $credentialGuard) {
		New-ItemProperty -Path $credentialGuard -Name "Enabled" -Value 0 -PropertyType DWORD -Force
		Remove-ItemProperty -Path $credentialGuard -Name "ChangedInBootCycle" -ErrorAction SilentlyContinue
		Remove-ItemProperty -Path $credentialGuard -Name "WasEnabledBy" -ErrorAction SilentlyContinue
	}
} else {
Set-ItemProperty -Path $memIntegrity -Name "Enabled" -Value 1 -Type DWord
Set-ItemProperty -Path $memIntegrity -Name "WasEnabledBy" -Value 2 -Type DWord
}

<#
		--------------------------
				 Cleanmgr
		--------------------------
#>

# As cleanmgr has multiple processes, there's no point in making the window hidden as it won't apply
function Run-AtlasDiskCleanup {
	# Kill running cleanmgr instances, as they will prevent new cleanmgr from starting
	Get-Process -Name cleanmgr | Stop-Process -Force
	# Cleanmgr preset
	# 2 = enabled
	# 0 = disabled
	$baseKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches'
	$regValues = @{
		"Active Setup Temp Folders" = 2
		"BranchCache" = 2
		"D3D Shader Cache" = 2
		"Delivery Optimization Files" = 2
		"Diagnostic Data Viewer database files" = 2
		"Downloaded Program Files" = 2
		"Internet Cache Files" = 2
		"Language Pack" = 0
		"Old ChkDsk Files" = 0
		"Recycle Bin" = 0
		"RetailDemo Offline Content" = 2
		"Setup Log Files" = 2
		"System error memory dump files" = 2
		"System error minidump files" = 2
		"Temporary Files" = 0
		"Thumbnail Cache" = 2
		"Update Cleanup" = 2
		"User file versions" = 2
		"Windows Error Reporting Files" = 2
	}
	foreach ($entry in $regValues.GetEnumerator()) {
		$key = $entry.Key
		$value = $entry.Value
		$path = "$baseKey\$key"
		Set-ItemProperty -Path $path -Name 'StateFlags0064' -Value $value -Type DWORD
	}
	# Run preset 64 (0-65535)
	Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:64"
}

# Check for other installations of Windows
# If so, show the prompt, if not, run Disk Cleanup without input
$excludedDrive = "C"
$drives = Get-PSDrive -PSProvider 'FileSystem' | Where-Object { $_.Name -ne $excludedDrive }
foreach ($drive in $drives) {
    if (Test-Path -Path $(Join-Path -Path $drive.Root -ChildPath 'Windows') -PathType Container) {
        $otherInstalls = $true
    }
}

$WindowTitle = 'Disk Cleanup - Atlas'

$Message = @'
Would you like to run Disk Cleanup (with the Atlas preset)?

Disk Cleanup is a built-in tool in Windows for freeing disk space by removing temporary files, which is good (in this case) to have a clean base installation.

Due to a Disk Cleanup limitation in Windows, you can only clean all drives on a system when using a Disk Cleanup preset, not just the current installation.

Although nothing unexpected should come from using Disk Cleanup, this will modify other installations of Windows on your computer.

Automatically selecting 'No' in 5 minutes...
'@

if ($otherInstalls) {
	# Default option is 'No'
	$intButton = '7'
	$intButton = $sh.Popup($Message,300,$WindowTitle,4+48+256)
	if ($intButton -eq '6') {Run-AtlasDiskCleanup}
} else {Run-AtlasDiskCleanup}