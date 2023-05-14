# https://learn.microsoft.com/en-us/windows/security/threat-protection/device-guard/enable-virtualization-based-protection-of-code-integrity#validate-enabled-vbs-and-memory-integrity-features

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
					Write-Host "$feature"
				}
			}

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

			if ($SecurityServicesConfigured -contains '0') {
				Write-Host "No Virtualization Based Security features are configured.`n" -ForegroundColor Green
			} else {
				Write-Host "Virtualization Based Security features configured:`n" -ForegroundColor Yellow
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
		Title = "VBS Security Properties Avaliable"
		Commands = {
			$AvailableSecurityProperties = (Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard).AvailableSecurityProperties

			$VirtualizationBasedSecurityAvaliableSecurity = @(
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
				Write-Host "No security features are avaliable for Virtualization Based Security.`n" -ForegroundColor Green
			} else {
				Write-Host "Security features avaliable for Virtualization Based Security:`n" -ForegroundColor Yellow
			}
			
			foreach ($feature in $VirtualizationBasedSecurityAvaliableSecurity) {
				if ($feature -eq "None") {
					continue
				}
				
				Write-Host " - " -NoNewLine
				
				if ($AvailableSecurityProperties -contains $VirtualizationBasedSecurityAvaliableSecurity.IndexOf($feature)) {
					Write-Host "$feature is avaliable" -ForegroundColor Green
				} else {
					# $($VirtualizationBasedSecurityAvaliableSecurity.IndexOf($feature)). 
					Write-Host "$feature is not avaliable" -ForegroundColor Red
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