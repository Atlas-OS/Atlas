.\AtlasModules\initPowerShell.ps1
$windir = [Environment]::GetFolderPath('Windows')

function Get-ProfilePathFromSid {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Sid
    )

    $profileListPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$Sid"
    $profilePath = (Get-ItemProperty -Path $profileListPath -Name ProfileImagePath -ErrorAction SilentlyContinue).ProfileImagePath
    if ([string]::IsNullOrEmpty($profilePath)) {
        return $null
    }

    return [Environment]::ExpandEnvironmentVariables($profilePath)
}

function Resolve-UserFolderPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Sid,
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$FallbackChildPath
    )

    $profilePath = Get-ProfilePathFromSid -Sid $Sid
    if (![string]::IsNullOrEmpty($Path)) {
        $resolvedPath = $Path
        if (![string]::IsNullOrEmpty($profilePath)) {
            $resolvedPath = $resolvedPath.Replace('%USERPROFILE%', $profilePath)
        }
        $resolvedPath = [Environment]::ExpandEnvironmentVariables($resolvedPath)
        if (Test-Path $resolvedPath -PathType Container) {
            return $resolvedPath
        }
    }

    if (![string]::IsNullOrEmpty($profilePath)) {
        $fallbackPath = Join-Path $profilePath $FallbackChildPath
        if (Test-Path $fallbackPath -PathType Container) {
            return $fallbackPath
        }
    }

    return $null
}

Write-Title "Creating Desktop & Start Menu shortcuts..."

# Default user
$defaultShortcut = "$(Get-UserPath)\Atlas.lnk"
New-Shortcut -Source "$windir\AtlasDesktop" -Destination $defaultShortcut -Icon "$windir\AtlasModules\Other\atlas-folder.ico,0"

# Copy shortcut to every user
foreach ($userKey in (Get-RegUserPaths -NoDefault).PsPath) {
	$sid = Split-Path $userKey -Leaf
	$folders = Get-ItemProperty -path "$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
	$deskPath = Resolve-UserFolderPath -Sid $sid -Path $folders.Desktop -FallbackChildPath 'Desktop'
	if (![string]::IsNullOrEmpty($deskPath) -and (Test-Path $deskPath -PathType Container)) {
		Write-Output "Copying Desktop shortcut for '$userKey'..."
		Copy-Item $defaultShortcut -Destination $deskPath -Force
	} else {
		Write-Warning "Desktop path not found for '$userKey', shortcuts can't be copied."
	}
}

# Start menu shortcut
Copy-Item $defaultShortcut -Destination "$([Environment]::GetFolderPath('CommonStartMenu'))\Programs" -Force

Write-Title "Creating services restore shortcut..."
$desktop = "$windir\AtlasDesktop"
New-Shortcut -Source "$desktop\9. Troubleshooting\Set services to defaults.cmd" -Destination "$desktop\6. Advanced Configuration\Services\Set services to defaults.lnk"
