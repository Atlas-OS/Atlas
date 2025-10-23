param (
	[switch]$AddLiveLog,
	[switch]$ReplaceOldPlaybook,
	[switch]$DontOpenPbLocation,
	[switch]$NoPassword,
	[ValidateSet('Dependencies', 'Requirements', 'WinverRequirement', 'Verification', IgnoreCase = $true)]
	[array]$Removals,
	[string]$FileName = "Atlas Test"
)

$removals | % { Set-Variable -Name "remove$_" -Value $true }

# Convert paths for convenience, needed for Linux/macOS
function Separator {
	return $args -replace '\\', "$([IO.Path]::DirectorySeparatorChar)"
}

$buildTimer = [System.Diagnostics.Stopwatch]::StartNew()

function Write-BuildStatus {
	param (
		[Parameter(Mandatory = $true)][string]$Message,
		[string]$Color = 'Cyan'
	)

	$timestamp = Get-Date -Format 'HH:mm:ss'
	Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

$isWindowsPlatform = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)
$isLinuxPlatform = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Linux)
$isMacPlatform = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)

# Adds Atlas PSModulesPath to profile for the PowerShell Extension
$userEnv = [System.EnvironmentVariableTarget]::User
if ($psEditor.Workspace.Path -and ([Environment]::GetEnvironmentVariable('LOCALBUILD_DONT_ASK_FOR_MODULES', $userEnv) -ne "$true")) {
	function DontAsk {
		[Environment]::SetEnvironmentVariable('LOCALBUILD_DONT_ASK_FOR_MODULES', $true, $userEnv)
	}

	$title = 'Adding to PowerShell profile'
	$description = @"
Atlas includes some PowerShell modules by default that aren't usually recognised by the VSCode PowerShell extension.
Would you like to add to your PowerShell profile to automatically recognise these modules when developing Atlas?`n`n
"@
	switch ($host.ui.PromptForChoice($title, $description, ('&Yes', '&No', "&Don't ask me again"), 0)) {
		0 {
			if (!(Test-Path $PROFILE)) {
				New-Item -Path $PROFILE -ItemType File -Force | Out-Null
			}

			Add-Content -Path $PROFILE -Value @'
#--LOCAL-BUILD-MODULES-START--#
$workspace = $psEditor.Workspace.Path
$modulesFile = "$workspace\.atlasPsModulesPath"
if ([bool](Test-Path 'Env:\VSCODE_*') -and (Test-Path $workspace -EA 0) -and (Test-Path $modulesFile -EA 0)) {
	$modulePath = Join-Path $workspace (Get-Content $modulesFile -Raw)
	if (!(Test-Path $modulePath -PathType Container)) {
		Write-Warning "Couldn't find module path specified in '$modulesFile', no Atlas modules can be loaded."
	} else {
		$env:PSModulePath += [IO.Path]::PathSeparator + $modulePath
	}
}
#--LOCAL-BUILD-MODULES-END--#
'@

			DontAsk
			& $PROFILE
		}
		2 {
			DontAsk
		}
	}
}

# check 7z
if (Get-Command '7z' -EA 0) {
	$7zPath = '7z'
} elseif (Get-Command '7zz' -EA 0) {
	$7zPath = '7zz'
} elseif ($isWindowsPlatform -and (Test-Path "$([Environment]::GetFolderPath('ProgramFiles'))\7-Zip\7z.exe")) {
	$7zPath = "$([Environment]::GetFolderPath('ProgramFiles'))\7-Zip\7z.exe"
} else {
	throw "This script requires 7-Zip or NanaZip to be installed to continue."
}

# check if playbook dir
if (!(Test-Path playbook.conf -PathType Leaf)) {
	if (Test-Path playbook -PathType Container) {
		$currentDir = $PWD
		Set-Location playbook
		if (!(Test-Path playbook.conf -PathType Leaf)) { throw "playbook.conf file not found in playbook directory." }
	} else {
		throw "playbook.conf file not found in the current directory."
	}
}

# check if old files are in use
$apbxFileName = "$fileName.apbx"
[int]$script:num = 0
function GetNewName {
	while (Test-Path -LiteralPath $apbxFileName) {
		$script:num++
		$script:apbxFileName = "$fileName ($script:num).apbx"
	}
}
if ($replaceOldPlaybook -and (Test-Path -LiteralPath $apbxFileName)) {
	try {
		$stream = [System.IO.File]::Open($(Separator "$PWD\$apbxFileName"), 'Open', 'Read', 'Write')
		$stream.Close()
		Remove-Item -LiteralPath $apbxFileName -Force -EA 0
	} catch {
		Write-Warning "Couldn't replace '$apbxFileName', it's in use."
		GetNewName
	}
} elseif (Test-Path -LiteralPath $apbxFileName) {
	GetNewName
}
$apbxPath = Separator "$PWD\$apbxFileName"

Write-BuildStatus "Starting local build for '$FileName' -> $(Split-Path -Path $apbxPath -Leaf)" -Color 'Yellow'

function Invoke-ArchiveCommand {
	param (
		[string[]]$Arguments,
		[string]$Description
	)

	$processOutput = & $7zPath @Arguments 2>&1
	$exitCode = $LASTEXITCODE
	$outputLines = @()
	if ($processOutput) {
		$outputLines = $processOutput | ForEach-Object { [string]$_ }
		$outputLines = $outputLines | ForEach-Object { $_.Trim() } | Where-Object { $_ }
		$outputLines = $outputLines | Where-Object { $_ -ne 'System.Management.Automation.RemoteException' }
	}
	$outputText = $outputLines -join "`n"
	$lockMessagePattern = 'System ERROR: The process cannot access the file because it is being used by another process\.'

	if ($exitCode -gt 1) {
		if ($outputText) {
			throw "$Description failed (7-Zip exit code $exitCode):`n$outputText"
		}
		throw "$Description failed (7-Zip exit code $exitCode)."
	}

	if ($exitCode -eq 1) {
		if ($outputText) {
			Write-Warning "$Description completed with 7-Zip warnings.`n$outputText"
		} else {
			Write-Warning "$Description completed with 7-Zip warnings."
		}
	} elseif ($outputText) {
		if ($outputText -match $lockMessagePattern) {
			Write-Verbose "$Description encountered a transient file lock reported by 7-Zip; continuing with guarded rename."
		} else {
			Write-Verbose "$Description output:`n$outputText"
		}
	}
}

function Move-ItemSafely {
	param (
		[Parameter(Mandatory = $true)][string]$Source,
		[Parameter(Mandatory = $true)][string]$Destination,
		[int]$RetryCount = 5,
		[int]$DelayMilliseconds = 250
	)

	for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
		try {
			if (Test-Path -LiteralPath $Destination) {
				Remove-Item -LiteralPath $Destination -Force -EA Stop
			}

			Move-Item -LiteralPath $Source -Destination $Destination -Force -EA Stop
			return
		} catch {
			if ($attempt -eq $RetryCount) {
				throw "Failed to finalize playbook archive '$Destination'. $($_.Exception.Message)"
			}

			Start-Sleep -Milliseconds $DelayMilliseconds
		}
	}
}

function Wait-ForFileAccess {
	param (
		[Parameter(Mandatory = $true)][string]$Path,
		[int]$RetryCount = 10,
		[int]$DelayMilliseconds = 200
	)

	for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
		if (!(Test-Path -LiteralPath $Path -PathType Leaf)) {
			Start-Sleep -Milliseconds $DelayMilliseconds
			continue
		}

		try {
			$stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
			$stream.Close()
			return
		} catch {
			if ($attempt -eq $RetryCount) {
				throw "Timed out waiting for exclusive access to '$Path'. $($_.Exception.Message)"
			}

			Start-Sleep -Milliseconds $DelayMilliseconds
		}
	}

	throw "Timed out waiting for '$Path' to be created."
}

function Copy-WorkspaceContent {
	param (
		[Parameter(Mandatory = $true)][string]$Source,
		[Parameter(Mandatory = $true)][string]$Destination,
		[string[]]$Exclude = @()
	)

	if (!(Test-Path -LiteralPath $Destination -PathType Container)) {
		New-Item -ItemType Directory -Path $Destination -Force | Out-Null
	}

	if ($isWindowsPlatform -and (Get-Command 'robocopy' -ErrorAction SilentlyContinue)) {
		$robocopyArgs = @($Source, $Destination, '/E', '/MT:16', '/NFL', '/NDL', '/NJH', '/NJS', '/R:1', '/W:1')

		foreach ($pattern in $Exclude) {
			$robocopyArgs += '/XF'
			$robocopyArgs += $pattern
		}

		& robocopy @robocopyArgs | Out-Null
		$exitCode = $LASTEXITCODE
		if ($exitCode -ge 8) {
			throw "Robocopy failed while staging workspace files (exit code $exitCode)."
		}

		return
	}

	$copyParams = @{
		Path        = (Join-Path $Source '*')
		Destination = $Destination
		Recurse     = $true
		Force       = $true
		Container   = $true
	}

	if ($Exclude.Count -gt 0) {
		$copyParams['Exclude'] = $Exclude
	}

	Copy-Item @copyParams
}

function Open-ExplorerSelection {
	param (
		[Parameter(Mandatory = $true)][string]$Path,
		[Alias('CloseExisting')]
		[switch]$FocusExisting
	)

	if (-not $isWindowsPlatform) {
		Write-Warning "File Explorer automation is only supported on Windows. Output: $Path"
		return $false
	}

	try {
		$fullPath = [System.IO.Path]::GetFullPath($Path)
	} catch {
		Write-Warning "Unable to resolve build output path '$Path'. $($_.Exception.Message)"
		return $false
	}

	if (!(Test-Path -LiteralPath $fullPath)) {
		Write-Warning "Build output not found on disk: $fullPath"
		return $false
	}

	$directory = Split-Path -Path $fullPath -Parent

	if ($FocusExisting) {
		$shellApp = $null
		try {
			$shellApp = New-Object -ComObject Shell.Application
			$existingWindow = $shellApp.Windows() | Where-Object {
				$_.Document -and $_.Document.Folder -and $_.Document.Folder.Self -and ($_.Document.Folder.Self.Path -eq $directory)
			} | Select-Object -First 1

			if ($existingWindow) {
				Write-Verbose "Reusing existing Explorer window for '$directory'."
				try {
					$folderView = $existingWindow.Document
					$fileName = [System.IO.Path]::GetFileName($fullPath)
					if ($folderView -and $folderView.SelectItem) {
						$item = $folderView.Folder.ParseName($fileName)
						if ($item) {
							$folderView.SelectItem($item, 1)
						}
					}
					$existingWindow.Visible = $true
					$existingWindow.Document.Focus()
				} catch {
					Write-Verbose "Unable to focus existing window for '$directory'. $($_.Exception.Message)"
				}
				return $true
			}
		} catch {
			Write-Verbose "Failed to inspect existing Explorer windows for '$directory'. $($_.Exception.Message)"
		} finally {
			if ($shellApp) {
				try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shellApp) | Out-Null } catch { }
			}
		}
	}

	$attempts = @(
		@{
			Description = 'select build output';
			Action      = {
				Start-Process -FilePath 'explorer.exe' -ArgumentList "/n,/select,`"$fullPath`"" -WorkingDirectory $directory -WindowStyle Normal -ErrorAction Stop | Out-Null
			}
		},
		@{
			Description = 'highlight via Shell.Application';
			Action      = {
				$folderShell = New-Object -ComObject Shell.Application
				try {
					$explorerFolder = $folderShell.Namespace($directory)
					if ($explorerFolder) {
						$item = $explorerFolder.ParseName([System.IO.Path]::GetFileName($fullPath))
						if ($item) {
							$item.InvokeVerb('open')
						} else {
							throw "Shell couldn't resolve item."
						}
					} else {
						throw "Shell couldn't open directory."
					}
				} finally {
					if ($folderShell) {
						try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($folderShell) | Out-Null } catch { }
					}
				}
			}
		},
		@{
			Description = 'open build output with Invoke-Item';
			Action      = { Invoke-Item -LiteralPath $fullPath -ErrorAction Stop }
		},
		@{
			Description = 'open containing directory in Explorer';
			Action      = { Start-Process -FilePath 'explorer.exe' -ArgumentList "`"$directory`"" -WorkingDirectory $directory -ErrorAction Stop | Out-Null }
		},
		@{
			Description = 'fallback cmd /c start';
			Action      = { Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', 'start', '', "`"$directory`"" -WorkingDirectory $directory -ErrorAction Stop | Out-Null }
		}
	)

	foreach ($attempt in $attempts) {
		try {
			& $attempt.Action
			Write-Verbose "Explorer open succeeded using '$($attempt.Description)'."
			return $true
		} catch {
			Write-Verbose "Explorer attempt to $($attempt.Description) failed. $($_.Exception.Message)"
		}
	}

	Write-Warning "Unable to launch File Explorer for $fullPath. Please open it manually."
	return $false
}

# make temp directories
$rootTemp = (New-Item (Join-Path -Path $([System.IO.Path]::GetTempPath()) -ChildPath $([System.Guid]::NewGuid())) -ItemType Directory -Force).FullName
if (!(Test-Path -Path $rootTemp)) { throw "Failed to create temporary directory!" }
$playbookTemp = (New-Item (Separator "$rootTemp\playbook") -ItemType Directory).FullName

Write-BuildStatus "Using temporary workspace at $rootTemp" -Color 'DarkGray'

try {
	Write-BuildStatus "Applying requested configuration overrides..." -Color 'Cyan'
	if ($Removals) {
		Write-BuildStatus "Requested removals: $($Removals -join ', ')" -Color 'DarkGray'
	}
	# remove entries in playbook config that make it awkward for testing
	$patterns = @()
	# 0.6.5 has a bug where it will crash without the 'Requirements' field, but all of the requirements are removed
	# "<Requirements>" and # "</Requirements>"
	if ($removeRequirements) {$patterns += "<Requirement>"}
	if ($removeWinverRequirement) {$patterns += "<string>", "</SupportedBuilds>", "<SupportedBuilds>"}
	if ($removeVerification) {$patterns += "<ProductCode>"}

	$tempPbConfPath = Separator "$playbookTemp\playbook.conf"
	if ($patterns.Count -gt 0) {
		Write-BuildStatus "Applying playbook.conf sanitization rules..." -Color 'DarkGray'
		Get-Content -Encoding "utf8" "playbook.conf" | Where-Object { $_ -notmatch ($patterns -join '|') } | Set-Content -Encoding "utf8" $tempPbConfPath
	}

	$customYmlPath = Separator "Configuration\custom.yml"
	$tempCustomYmlPath = Separator "$playbookTemp\$customYmlPath"
	if ($AddLiveLog) {
		Write-BuildStatus "Adding live log launcher to custom.yml..." -Color 'DarkGray'
		if (Test-Path $customYmlPath -PathType Leaf) {
			New-Item (Split-Path $tempCustomYmlPath -Parent) -ItemType Directory -Force | Out-Null
			Copy-Item -Path $customYmlPath -Destination $tempCustomYmlPath -Force
			$customYml = Get-Content -Path $tempCustomYmlPath

			$liveLogScript = {
$a = Join-Path (Get-ChildItem (Join-Path $([Environment]::GetFolderPath('CommonApplicationData')) '\AME\Logs') -Directory |
Sort-Object LastWriteTime -Descending |
Select-Object -First 1).FullName '\OutputBuffer.txt';
while ($true) { Get-Content -Wait -LiteralPath $a -EA 0 | Write-Output; Start-Sleep 1 }
}
			[string]$liveLogText = ($liveLogScript -replace '"','"""' -replace "'","''").Trim() -replace "`r?`n", " "

			$actionsIndex = $customYml.IndexOf('actions:')
			$newCustomYml = $customYml[0..$actionsIndex] + `
				"  - !cmd: {command: 'start `"AME Wizard Live Log`" PowerShell -NoP -C `"$liveLogText`"'}" + `
				$customYml[($actionsIndex + 1)..($customYml.Count)]

			Set-Content -Path $tempCustomYmlPath -Value $newCustomYml
		} else {
			Write-Error "Can't find '$customYmlPath', not adding live log."
		}
	}

	$startYmlPath = Separator "Configuration\atlas\start.yml"
	$tempStartYmlPath = Separator "$playbookTemp\$startYmlPath"
	if ($removeDependencies) {
		Write-BuildStatus "Removing dependency actions from start.yml..." -Color 'DarkGray'
		if (Test-Path $startYmlPath -PathType Leaf) {
			New-Item (Split-Path $tempStartYmlPath -Parent) -ItemType Directory -Force | Out-Null
			Copy-Item -Path $startYmlPath -Destination $tempStartYmlPath -Force
			$startYml = Get-Content -Path $tempStartYmlPath

			$noLocalBuildStart = $startYml.IndexOf('  ################ NO LOCAL BUILD ################')
			$noLocalBuildEnd = $startYml.IndexOf('  ################ END NO LOCAL BUILD ################')
			$newStartYml = $startYml[0..($noLocalBuildStart - 1)] + `
				$startYml[($noLocalBuildEnd + 1)..($startYml.Count)]

			Set-Content -Path $tempStartYmlPath -Value $newStartYml
		} else {
			Write-Error "Can't find '$startYmlPath', not removing dependencies."
		}
	}

	$oemYmlPath = Separator "Configuration\tweaks\misc\config-oem-information.yml"
	$tempOemYmlPath = Separator "$playbookTemp\$oemYmlPath"
	if (Test-Path $oemYmlPath -PathType Leaf) {
		Write-BuildStatus "Updating OEM metadata to match playbook.conf..." -Color 'DarkGray'
		$confXml = ([xml](Get-Content "playbook.conf" -Raw -EA 0)).Playbook
		if ($confXml.Version -match '^(0|[1-9]\d*)(\.(0|[1-9]\d*)){0,2}$') {
			$version = "v$($confXml.Version)"

			if ($confXml.Title | Select-String '(dev)' -Quiet) {
				$version = $version + ' (dev)'
			}

			$oemToReplace = 'AtlasVersionUndefined'
			$oemYml = Get-Content -Path $oemYmlPath -Raw
			$tempOemYml = $oemYml -replace $oemToReplace, $version

			if ($tempOemYml -eq $oemYml) {
				Write-Error "Couldn't find OEM string '$oemToReplace'."
			} else {
				New-Item (Split-Path $tempOemYmlPath) -ItemType Directory -Force | Out-Null
				Set-Content -Path $tempOemYmlPath -Value $tempOemYml
			}
		} else {
			Write-Error "Invalid version format in 'playbook.conf', not setting OEM version."
		}
	} else {
		Write-Error "Can't find '$oemYmlPath', not setting OEM version."
	}

# stage files for packaging
Write-BuildStatus "Staging playbook files..." -Color 'Cyan'
$excludeFiles = @(
	"local-build.*",
	"*.apbx"
)
if (Test-Path $tempCustomYmlPath) { $excludeFiles += "custom.yml" }
if (Test-Path $tempStartYmlPath) { $excludeFiles += "start.yml" }
if (Test-Path $tempPbConfPath) { $excludeFiles += "playbook.conf" }
$stagePath = (New-Item (Separator "$rootTemp\stage") -ItemType Directory -Force).FullName
$workspaceRoot = (Get-Location).ProviderPath
Copy-WorkspaceContent -Source $workspaceRoot -Destination $stagePath -Exclude $excludeFiles

if (Test-Path (Join-Path $playbookTemp '*')) {
	Write-BuildStatus "Merging temporary overrides..." -Color 'Cyan'
	$playbookTempRoot = (Resolve-Path $playbookTemp).ProviderPath
	Copy-WorkspaceContent -Source $playbookTempRoot -Destination $stagePath
}

if (!$NoPassword) { $pass = '-pmalte' }

$apbxTmpPath = "$apbxPath.tmp"
if (Test-Path -LiteralPath $apbxTmpPath) {
	Remove-Item -LiteralPath $apbxTmpPath -Force -EA 0
}

$createArgs = @('a', '-spf', '-y', '-mx1')
if ($pass) { $createArgs += $pass }
$createArgs += '-tzip'

Write-BuildStatus "Packaging playbook archive..." -Color 'Cyan'

Push-Location $stagePath
try {
	$createArgs += $apbxPath
	$createArgs += '*'
	Invoke-ArchiveCommand -Arguments $createArgs -Description 'Creating playbook archive'
} finally {
	Pop-Location
}
if (!(Test-Path -LiteralPath $apbxPath -PathType Leaf) -and (Test-Path -LiteralPath $apbxTmpPath -PathType Leaf)) {
	Wait-ForFileAccess -Path $apbxTmpPath
	Move-ItemSafely -Source $apbxTmpPath -Destination $apbxPath
}
Wait-ForFileAccess -Path $apbxPath

if (Test-Path -LiteralPath $apbxTmpPath -PathType Leaf) {
	Wait-ForFileAccess -Path $apbxTmpPath
	Move-ItemSafely -Source $apbxTmpPath -Destination $apbxPath
}

$apbxFullPath = [System.IO.Path]::GetFullPath($apbxPath)
$apbxDirectory = Split-Path -Path $apbxFullPath -Parent

if ($buildTimer.IsRunning) { $buildTimer.Stop() }
$elapsed = $buildTimer.Elapsed
if ($elapsed.TotalSeconds -lt 60) {
	$elapsedText = "{0:N2}s" -f $elapsed.TotalSeconds
} else {
	$elapsedText = $elapsed.ToString('hh\:mm\:ss')
}
Write-BuildStatus "Build completed in $elapsedText. Output: `"$apbxFullPath`"" -Color 'Green'
	if (!$DontOpenPbLocation) {
		if (-not $isWindowsPlatform) {
			Write-Warning "Can't open to APBX directory as the system isn't Windows."
		} else {
			Write-BuildStatus "Opening output location in File Explorer..." -Color 'DarkGray'
			if (Open-ExplorerSelection -Path $apbxFullPath -FocusExisting) {
				Write-BuildStatus "Explorer window opened for $apbxFullPath." -Color 'DarkGray'
			} else {
				Write-Warning "Couldn't automatically open File Explorer to $apbxFullPath."
			}
		}
	}
} finally {
	if ($buildTimer.IsRunning) { $buildTimer.Stop() }
	Remove-Item $rootTemp -Force -EA 0 -Recurse | Out-Null
	if ($currentDir) { Set-Location $currentDir }
}
