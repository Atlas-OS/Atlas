[CmdletBinding()]
param (
    [Parameter()][Switch]$DisableAllVBS,
    [Parameter()][Switch]$EnableMemoryIntegrity
)

# https://learn.microsoft.com/en-us/windows/security/threat-protection/device-guard/enable-virtualization-based-protection-of-code-integrity#validate-enabled-vbs-and-memory-integrity-features

$memIntegrity = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
$kernelShadowStacks = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\KernelShadowStacks"
$credentialGuard = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\CredentialGuard"

if ($DisableAllVBS) {
	Write-Warning "Disabling VBS features..."

	# Memory Integrity
	if (Test-Path $memIntegrity) {
		New-ItemProperty -Path $memIntegrity -Name "Enabled" -Value 0 -PropertyType DWORD -Force
		Remove-ItemProperty -Path $memIntegrity -Name "ChangedInBootCycle" -EA 0
		Remove-ItemProperty -Path $memIntegrity -Name "WasEnabledBy" -EA 0
	}

	# Kernel-mode Hardware-enforced Stack Protection (Windows 11 only)
	if (Test-Path $kernelShadowStacks) {
		New-ItemProperty -Path $kernelShadowStacks -Name "Enabled" -Value 0 -PropertyType DWORD -Force
		Remove-ItemProperty -Path $kernelShadowStacks -Name "ChangedInBootCycle" -EA 0
		Remove-ItemProperty -Path $kernelShadowStacks -Name "WasEnabledBy" -EA 0
	}

	# Credential Guard (Windows 11 only)
	if (Test-Path $credentialGuard) {
		New-ItemProperty -Path $credentialGuard -Name "Enabled" -Value 0 -PropertyType DWORD -Force
		Remove-ItemProperty -Path $credentialGuard -Name "ChangedInBootCycle" -EA 0
		Remove-ItemProperty -Path $credentialGuard -Name "WasEnabledBy" -EA 0
	}

	# LSA Protection (24H2 only)
	New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RunAsPPL" -Value 0 -PropertyType DWORD -Force
	exit
} elseif ($EnableMemoryIntegrity) {
	Write-Warning "Enabling memory integrity..."
	Set-ItemProperty -Path $memIntegrity -Name "Enabled" -Value 1 -Type DWord
	Set-ItemProperty -Path $memIntegrity -Name "WasEnabledBy" -Value 2 -Type DWord
	exit
}

$pages = @(
	@{
		Title = "VBS Features Running"
		Commands = {
			$SecurityServicesRunning = (Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard).SecurityServicesRunning
			$VirtualizationBasedSecurityStatus = (Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard).VirtualizationBasedSecurityStatus
			
			$VirtualizationBasedSecurityStatusList = @(
				"VBS isn't enabled",
				"VBS is enabled but not running",
				"VBS is enabled and running"
			)
			
			$VirtualizationBasedSecurityRunningFeatures = @(
				"None",
				"Windows Defender Credential Guard",
				"Memory Integrity",
				"System Guard Secure Launch",
				"SMM Firmware Measurement"
			)

			foreach ($feature in $VirtualizationBasedSecurityStatusList) {
				if ($VirtualizationBasedSecurityStatus -contains $VirtualizationBasedSecurityStatusList.IndexOf($feature)) {
					Write-Host "VBS Status: " -NoNewLine -ForegroundColor Magenta
					Write-Host "$feature`n"
				}
			}
			
			Write-Host "Notes: " -ForegroundColor Yellow -NoNewLine
			Write-Host "Some features here are exclusive to Windows 11, you will be mostly looking at Memory Integrity on Windows 10."
			Write-Host "       Please note that on older CPUs especially, features like Memory Integrity will reduce performance significantly.`n"
			Write-Host "       You can configure VBS/Core Isolation settings in Windows Security."

			if ($SecurityServicesRunning -contains '0') {
				Write-Host "`nNo Virtualization Based Security features are running.`n" -ForegroundColor Green
			} else {
				Write-Host "`nVirtualization Based Security features currently running:`n" -ForegroundColor Yellow
			}
			
			foreach ($feature in $VirtualizationBasedSecurityRunningFeatures) {
				if ($feature -eq "None") {
					continue
				}
				
				Write-Host " - " -NoNewLine
				
				if ($SecurityServicesRunning -contains $VirtualizationBasedSecurityRunningFeatures.IndexOf($feature)) {
					Write-Host "$feature is running" -ForegroundColor Green
				} else {
					# $($VirtualizationBasedSecurityRunningFeatures.IndexOf($feature)). 
					Write-Host "$feature is not running" -ForegroundColor Red
				}
			}
		}
	},
	@{
		Title = "VBS Features Configured"
		Commands = {
			$SecurityServicesConfigured = (Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard).SecurityServicesConfigured

			$VirtualizationBasedSecurityConfiguredFeatures = @(
				"None",
				"Windows Defender Credential Guard",
				"Memory Integrity",
				"System Guard Secure Launch",
				"SMM Firmware Measurement"
			)
			
			Write-Host "Note: " -ForegroundColor Yellow -NoNewLine
			Write-Host "These are the features configured on startup."
			
			if ($SecurityServicesConfigured -contains '0') {
				Write-Host "`nNo Virtualization Based Security features are configured.`n" -ForegroundColor Green
			} else {
				Write-Host "`nVirtualization Based Security features configured:`n" -ForegroundColor Yellow
			}
			
			foreach ($feature in $VirtualizationBasedSecurityConfiguredFeatures) {
				if ($feature -eq "None") {
					continue
				}
				
				Write-Host " - " -NoNewLine
				
				if ($SecurityServicesConfigured -contains $VirtualizationBasedSecurityConfiguredFeatures.IndexOf($feature)) {
					Write-Host "$feature is configured" -ForegroundColor Green
				} else {
					# $($VirtualizationBasedSecurityConfiguredFeatures.IndexOf($feature)). 
					Write-Host "$feature is not configured" -ForegroundColor Red
				}
			}
		}
	},
	@{
		Title = "VBS Security Properties Required"
		Commands = {
			$RequiredSecurityProperties = (Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard).RequiredSecurityProperties

			$VirtualizationBasedSecurityRequiredSecurity = @(
				"None",
				"Hypervisor support",
				"Secure Boot",
				"DMA protection",
				"Secure Memory Overwrite",
				"NX protections",
				"SMM mitigations",
				"MBEC/GMET"
			)

			if ($RequiredSecurityProperties -contains '0') {
				Write-Host "No security features are required for Virtualization Based Security.`n" -ForegroundColor Green
			} else {
				Write-Host "Security features needed for Virtualization Based Security:`n" -ForegroundColor Yellow
			}
			
			foreach ($feature in $VirtualizationBasedSecurityRequiredSecurity) {
				if ($feature -eq "None") {
					continue
				}
				
				Write-Host " - " -NoNewLine
				
				if ($RequiredSecurityProperties -contains $VirtualizationBasedSecurityRequiredSecurity.IndexOf($feature)) {
					Write-Host "$feature is required" -ForegroundColor Green
				} else {
					# $($VirtualizationBasedSecurityRequiredSecurity.IndexOf($feature)). 
					Write-Host "$feature is not required" -ForegroundColor Red
				}
			}
		}
	},
	@{
		Title = "VBS Security Properties Available"
		Commands = {
			$AvailableSecurityProperties = (Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard).AvailableSecurityProperties

			$VirtualizationBasedSecurityAvailableSecurity = @(
				"None",
				"Hypervisor support",
				"Secure Boot",
				"DMA protection",
				"Secure Memory Overwrite",
				"NX protections",
				"SMM mitigations",
				"MBEC/GMET",
				"APIC virtualization"
			)

			if ($AvailableSecurityProperties -contains '0') {
				Write-Host "No security features are available for Virtualization Based Security.`n" -ForegroundColor Green
			} else {
				Write-Host "Security features available for Virtualization Based Security:`n" -ForegroundColor Yellow
			}
			
			foreach ($feature in $VirtualizationBasedSecurityAvailableSecurity) {
				if ($feature -eq "None") {
					continue
				}
				
				Write-Host " - " -NoNewLine
				
				if ($AvailableSecurityProperties -contains $VirtualizationBasedSecurityAvailableSecurity.IndexOf($feature)) {
					Write-Host "$feature is available" -ForegroundColor Green
				} else {
					# $($VirtualizationBasedSecurityAvailableSecurity.IndexOf($feature)). 
					Write-Host "$feature is not available" -ForegroundColor Red
				}
			}
		}
	}
)

$currentPageIndex = 0

function Wait-Key {
	[console]::CursorVisible = $false
	$pageInput = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

	switch ($pageInput.VirtualKeyCode) {
		# Next
		78 {
			$currentPageIndex = ($currentPageIndex + 1) % $pages.Count
		}
		# Back
		66 {
			$currentPageIndex = ($currentPageIndex - 1) % $pages.Count
			if ($currentPageIndex -lt 0) {
				$currentPageIndex += $pages.Count
			}
		}
		default {
			# Do nothing
			Wait-Key
		}
	}
	
	Show-Page
}

function Show-Page {
	Clear-Host
	$currentPage = $pages[$currentPageIndex]
	$Host.UI.RawUI.WindowTitle = "$($currentPage.Title)"
	
	& $currentPage.Commands
	
	# Write-Host "`nCurrent Page: $($currentPage.Title)" -ForegroundColor Yellow
	Write-Host "`n------------- Page $($currentPageIndex + 1) -------------" -ForegroundColor Yellow
	Write-Host "(n) Next Page || (b) Previous Page"

	Wait-Key
}

Show-Page
