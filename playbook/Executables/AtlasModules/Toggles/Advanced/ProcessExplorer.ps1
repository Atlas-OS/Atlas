# Toggle: Process Explorer (replace Task Manager with Sysinternals Process Explorer).
#
# Interactive installs prompt before disabling the pcw service; silent installs
# disable it unconditionally. Atlas-owned dependent state is persisted beside
# the protected package so uninstall restores only values Atlas still owns.
@{
    Name      = 'ProcessExplorer'
    Elevation = 'Admin'
    States    = [ordered]@{
        Install   = @{
            StateValue = 1
            Launcher   = '6. Advanced Configuration\Process Explorer\Install Process Explorer.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $packageHelper = [IO.Path]::Combine($Toggle.ScriptsPath, 'Internal', 'ProcessExplorer-Package.ps1')
                if (-not [IO.File]::Exists($packageHelper)) {
                    throw "ProcessExplorer: the protected package helper is missing at '$packageHelper'."
                }
                . $packageHelper

                $operationLock = Enter-AtlasProcessExplorerOperationLock
                try {
                    $recoveryContext = Repair-AtlasProcessExplorerPackageGenerations `
                        -OperationLock $operationLock
                    if ($null -ne $recoveryContext) {
                        $entryResolution = Resolve-AtlasProcessExplorerPendingTransaction `
                            -RecoveryContext $recoveryContext `
                            -OperationLock $operationLock `
                            -WinDir $Toggle.WinDir
                        if ($entryResolution.Resolution -eq 'Committed') {
                            if (-not $Toggle.Silent) { Write-Host 'Finished recovering the prior install.' }
                            return
                        }
                    }

                $appDir = [IO.Path]::Combine($Toggle.AtlasModulesPath, 'Apps', 'ProcessExplorer')
                $debuggerPath = [IO.Path]::Combine($appDir, 'procexp.exe')
                $existingState = Read-AtlasProcessExplorerInstallState `
                    -PackagePath $appDir `
                    -AllowMissing

                $ifeo = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe'
                $currentDebuggerExists = $false
                $currentDebuggerValue = $null
                $currentDebuggerKind = $null
                if (Test-Path -LiteralPath $ifeo -ErrorAction Stop) {
                    $ifeoKey = Get-Item -LiteralPath $ifeo -ErrorAction Stop
                    if ($ifeoKey.GetValueNames() -contains 'Debugger') {
                        $currentDebuggerExists = $true
                        $currentDebuggerValue = [string]$ifeoKey.GetValue(
                            'Debugger',
                            $null,
                            [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
                        )
                        $currentDebuggerKind = [string]$ifeoKey.GetValueKind('Debugger')
                    }
                }
                if ($currentDebuggerExists -and
                    ($currentDebuggerKind -notin @('String', 'ExpandString') -or
                        -not $currentDebuggerValue.Equals(
                            $debuggerPath,
                            [StringComparison]::OrdinalIgnoreCase
                        ))) {
                    throw "ProcessExplorer: refusing to replace a non-Atlas Task Manager Debugger ('$currentDebuggerValue')."
                }

                if ($null -ne $existingState) {
                    $debuggerPriorExists = [bool]$existingState.Debugger.PriorExists
                    $debuggerPriorValue = if ($debuggerPriorExists) {
                        [string]$existingState.Debugger.PriorValue
                    }
                    else { $null }
                    $debuggerPriorKind = if ($debuggerPriorExists) {
                        [string]$existingState.Debugger.PriorKind
                    }
                    else { $null }
                }
                else {
                    # An exact Atlas path without ownership state is a legacy
                    # Atlas install. It is safe to migrate and should be removed,
                    # rather than restored, on a later uninstall.
                    $debuggerPriorExists = $false
                    $debuggerPriorValue = $null
                    $debuggerPriorKind = $null
                }

                $shortcut = Join-Path ([Environment]::GetFolderPath('CommonStartMenu')) 'Programs\Process Explorer.lnk'
                $shortcutState = Get-AtlasProcessExplorerShortcutState `
                    -Path $shortcut `
                    -ReadBytes
                $shortcutExisted = $shortcutState.Exists
                $shortcutBytes = $shortcutState.Bytes
                $shortcutHash = $shortcutState.Sha256
                if ($null -ne $existingState -and $shortcutExisted -and
                    $shortcutHash -ne [string]$existingState.Shortcut.InstalledSha256) {
                    throw 'ProcessExplorer: refusing to replace a Start menu shortcut Atlas no longer owns.'
                }

                if ($null -ne $existingState) {
                    $shortcutPriorExists = [bool]$existingState.Shortcut.PriorExists
                    $shortcutPriorBytes = if ($shortcutPriorExists) {
                        [Convert]::FromBase64String([string]$existingState.Shortcut.PriorBytesBase64)
                    }
                    else { $null }
                }
                else {
                    $shortcutPriorExists = $shortcutExisted
                    $shortcutPriorBytes = $shortcutBytes
                    if ($shortcutExisted) {
                        try {
                            $wshForMigration = New-Object -ComObject WScript.Shell
                            $legacyTarget = [string]$wshForMigration.CreateShortcut($shortcut).TargetPath
                            if ($legacyTarget.Equals($debuggerPath, [StringComparison]::OrdinalIgnoreCase)) {
                                $shortcutPriorExists = $false
                                $shortcutPriorBytes = $null
                            }
                        }
                        catch {
                            # A shortcut that cannot be proven Atlas-owned is
                            # snapshotted and restored instead of being discarded.
                            Write-Verbose 'The existing shortcut was preserved because its target could not be proven Atlas-owned.'
                        }
                    }
                }

                $pcwPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\pcw'
                $currentPcwStart = [int](Get-ItemProperty -LiteralPath $pcwPath -Name Start -ErrorAction Stop).Start
                $pcwStartNames = @{
                    0 = 'boot'
                    1 = 'system'
                    2 = 'auto'
                    3 = 'demand'
                    4 = 'disabled'
                }
                if (-not $pcwStartNames.ContainsKey($currentPcwStart)) {
                    throw "ProcessExplorer: pcw has unsupported Start value '$currentPcwStart'."
                }

                $disablePcw = $true
                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host "The 'pcw' service is needed for Task Manager and performance counters."
                    Write-Host 'Disabling it matters less with Process Explorer, but some software may misbehave.'
                    $answer = Read-Host 'Would you like to disable it? [Y/N]'
                    $disablePcw = ($answer -match '^(y|yes)$')
                }

                if ($disablePcw -and $currentPcwStart -ne 4) {
                    $pcwChangedForState = $true
                    $pcwPriorForState = $currentPcwStart
                    $configurePcw = $true
                }
                elseif ($null -ne $existingState -and
                    [bool]$existingState.Pcw.Changed -and
                    $currentPcwStart -eq 4) {
                    $pcwChangedForState = $true
                    $pcwPriorForState = [int]$existingState.Pcw.PriorStart
                    $configurePcw = $false
                }
                else {
                    $pcwChangedForState = $false
                    $pcwPriorForState = $currentPcwStart
                    $configurePcw = $false
                }

                $installState = New-AtlasProcessExplorerInstallState `
                    -PackagePath $appDir `
                    -DebuggerPriorExists $debuggerPriorExists `
                    -DebuggerPriorValue $debuggerPriorValue `
                    -DebuggerPriorKind $debuggerPriorKind `
                    -PcwChanged $pcwChangedForState `
                    -PcwPriorStart $pcwPriorForState `
                    -ShortcutPriorExists $shortcutPriorExists `
                    -ShortcutPriorBytes $shortcutPriorBytes `
                    -ShortcutInstalledSha256 ('0' * 64)
                $pendingInstall = New-AtlasProcessExplorerPendingInstall `
                    -PackagePath $appDir `
                    -InstallState $installState `
                    -ImmediateDebuggerExists $currentDebuggerExists `
                    -ImmediateDebuggerValue $currentDebuggerValue `
                    -ImmediateDebuggerKind $currentDebuggerKind `
                    -ImmediatePcwStart $currentPcwStart `
                    -ImmediateShortcutExists $shortcutExisted `
                    -ImmediateShortcutBytes $shortcutBytes `
                    -ConfigurePcw $configurePcw

                $packageTransaction = $null
                $scPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'sc.exe')
                try {
                    Write-Host 'Installing Process Explorer...'
                    $packageTransaction = Install-AtlasProcessExplorerPackage `
                        -PendingInstall $pendingInstall `
                        -OperationLock $operationLock
                    $pendingInstall = $packageTransaction.PendingInstall

                    Write-Host 'Creating the Start menu shortcut...'
                    $templatePath = [IO.Path]::Combine(
                        $appDir,
                        'Atlas.ProcessExplorer.Shortcut.lnk'
                    )
                    $templateItem = Get-Item -LiteralPath $templatePath -Force -ErrorAction Stop
                    if (($templateItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
                        $templateItem.Length -le 0 -or $templateItem.Length -gt 1048576) {
                        throw 'ProcessExplorer: the protected shortcut template is invalid.'
                    }
                    $templateBytes = [IO.File]::ReadAllBytes($templateItem.FullName)
                    $installedShortcutHash = Set-AtlasProcessExplorerShortcutBytesAtomically `
                        -Path $shortcut `
                        -Bytes $templateBytes `
                        -ArtifactId ([string]$pendingInstall.OperationId) `
                        -AlternateSha256 $(if ($pendingInstall.Immediate.Shortcut.Exists) {
                                [string]$pendingInstall.Immediate.Shortcut.Sha256
                            }
                            else { $null })
                    if ($installedShortcutHash -ne [string]$pendingInstall.Desired.ShortcutSha256) {
                        throw 'ProcessExplorer: the installed shortcut differs from its pending transaction.'
                    }
                    $pendingInstall.Progress.ShortcutApplied = $true
                    Write-AtlasProcessExplorerPendingInstall `
                        -PackagePath $appDir `
                        -Pending $pendingInstall `
                        -ReplaceExisting

                    Write-Host 'Configuring Process Explorer...'
                    if (-not (Test-Path -LiteralPath $ifeo)) {
                        New-Item -Path $ifeo -Force -ErrorAction Stop | Out-Null
                    }
                    $ifeoKey = Get-Item -LiteralPath $ifeo -ErrorAction Stop
                    $ifeoKey.SetValue(
                        'Debugger',
                        $debuggerPath,
                        [Microsoft.Win32.RegistryValueKind]::String
                    )
                    $actualDebugger = [string]$ifeoKey.GetValue(
                        'Debugger',
                        $null,
                        [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
                    )
                    $actualDebuggerKind = [string]$ifeoKey.GetValueKind('Debugger')
                    if (-not $actualDebugger.Equals($debuggerPath, [StringComparison]::OrdinalIgnoreCase) -or
                        $actualDebuggerKind -ne 'String') {
                        throw 'ProcessExplorer: Task Manager redirection did not retain the expected owned value.'
                    }
                    $pendingInstall.Progress.DebuggerApplied = $true
                    Write-AtlasProcessExplorerPendingInstall `
                        -PackagePath $appDir `
                        -Pending $pendingInstall `
                        -ReplaceExisting

                    if ($configurePcw) {
                        & $scPath @('config', 'pcw', 'start=', 'disabled') | Out-Null
                        $scExitCode = $LASTEXITCODE
                        if ($scExitCode -ne 0) {
                            throw "ProcessExplorer: sc.exe could not disable pcw (exit $scExitCode)."
                        }
                        $actualPcwStart = [int](Get-ItemProperty `
                                -LiteralPath $pcwPath `
                                -Name Start `
                                -ErrorAction Stop).Start
                        if ($actualPcwStart -ne 4) {
                            throw "ProcessExplorer: pcw retained unexpected Start value '$actualPcwStart'."
                        }
                    }
                    $pendingInstall.Progress.PcwApplied = $true
                    Write-AtlasProcessExplorerPendingInstall `
                        -PackagePath $appDir `
                        -Pending $pendingInstall `
                        -ReplaceExisting

                    Write-AtlasProcessExplorerInstallState `
                        -PackagePath $appDir `
                        -State $pendingInstall.InstallState
                    # ReadyToCommit is a durable assertion that no external
                    # shortcut generation remains unresolved.
                    [void](Repair-AtlasProcessExplorerShortcutArtifacts `
                        -Path $shortcut `
                        -ArtifactId ([string]$pendingInstall.OperationId) `
                        -TargetExists $true `
                        -TargetSha256 ([string]$pendingInstall.Desired.ShortcutSha256) `
                        -AlternateSha256 $(if ($pendingInstall.Immediate.Shortcut.Exists) {
                                [string]$pendingInstall.Immediate.Shortcut.Sha256
                            }
                            else { $null }))
                    $pendingInstall.Progress.OwnershipStateWritten = $true
                    $pendingInstall.Phase = 'ReadyToCommit'
                    Write-AtlasProcessExplorerPendingInstall `
                        -PackagePath $appDir `
                        -Pending $pendingInstall `
                        -ReplaceExisting
                    Complete-AtlasProcessExplorerPackageInstall -Transaction $packageTransaction
                }
                catch {
                    $originalFailure = $_.Exception.Message
                    try {
                        # The package helper can fail before returning its typed
                        # transaction even after a rename completed. Always
                        # reconcile observed protected topology before claiming
                        # that the operation rolled back.
                        $recoveryContext = Repair-AtlasProcessExplorerPackageGenerations `
                            -OperationLock $operationLock
                        if ($null -ne $recoveryContext) {
                            $resolution = Resolve-AtlasProcessExplorerPendingTransaction `
                                -RecoveryContext $recoveryContext `
                                -OperationLock $operationLock `
                                -WinDir $Toggle.WinDir
                            if ($resolution.Resolution -eq 'Committed') {
                                Write-Warning "ProcessExplorer: recovered and committed after a transient failure: $originalFailure"
                                return
                            }
                        }
                    }
                    catch {
                        throw "ProcessExplorer: install failed: $originalFailure; durable recovery failed: $($_.Exception.Message). The trusted generations were retained."
                    }
                    throw "ProcessExplorer: install failed and was durably rolled back: $originalFailure"
                }

                if (-not $Toggle.Silent) { Write-Host 'Finished, changes have been applied.' }
                }
                finally {
                    Exit-AtlasProcessExplorerOperationLock -Lock $operationLock
                }
            }
        }
        Uninstall = @{
            StateValue = 0
            Launcher   = '6. Advanced Configuration\Process Explorer\Uninstall Process Explorer.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $packageHelper = [IO.Path]::Combine($Toggle.ScriptsPath, 'Internal', 'ProcessExplorer-Package.ps1')
                if (-not [IO.File]::Exists($packageHelper)) {
                    throw "ProcessExplorer: the protected package helper is missing at '$packageHelper'."
                }
                . $packageHelper

                $operationLock = Enter-AtlasProcessExplorerOperationLock
                try {
                    $uninstallJournalPath = [IO.Path]::Combine(
                        $operationLock.AppsPath,
                        'Atlas.ProcessExplorer.Uninstall.json'
                    )
                    $resumedUninstallJournal = [IO.File]::Exists($uninstallJournalPath)
                    $recoveryContext = Repair-AtlasProcessExplorerPackageGenerations `
                        -OperationLock $operationLock
                    if ($null -ne $recoveryContext) {
                        $entryResolution = Resolve-AtlasProcessExplorerPendingTransaction `
                            -RecoveryContext $recoveryContext `
                            -OperationLock $operationLock `
                            -WinDir $Toggle.WinDir
                        $appDir = [IO.Path]::Combine(
                            $Toggle.AtlasModulesPath,
                            'Apps',
                            'ProcessExplorer'
                        )
                        if ($entryResolution.Resolution -eq 'RolledBack' -and
                            -not [IO.Directory]::Exists($appDir)) {
                            if (-not $Toggle.Silent) { Write-Host 'Finished recovering the interrupted install.' }
                            return
                        }
                    }

                $appDir = [IO.Path]::Combine($Toggle.AtlasModulesPath, 'Apps', 'ProcessExplorer')
                if (-not [IO.Directory]::Exists($appDir)) {
                    if (-not $resumedUninstallJournal) {
                        $dangling = New-Object System.Collections.Generic.List[string]
                        $debuggerPath = [IO.Path]::Combine($appDir, 'procexp.exe')
                        $ifeo = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe'
                        if (Test-Path -LiteralPath $ifeo -ErrorAction Stop) {
                            $ifeoKey = Get-Item -LiteralPath $ifeo -ErrorAction Stop
                            if ($ifeoKey.GetValueNames() -contains 'Debugger') {
                                $debugger = [string]$ifeoKey.GetValue(
                                    'Debugger',
                                    $null,
                                    [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
                                )
                                if ($debugger.Equals($debuggerPath, [StringComparison]::OrdinalIgnoreCase)) {
                                    $dangling.Add('Task Manager still redirects to the absent Atlas package')
                                }
                            }
                        }
                        $shortcut = Join-Path ([Environment]::GetFolderPath('CommonStartMenu')) `
                            'Programs\Process Explorer.lnk'
                        $danglingShortcut = Get-AtlasProcessExplorerShortcutState -Path $shortcut
                        if ($danglingShortcut.Exists) {
                            try {
                                $wsh = New-Object -ComObject WScript.Shell
                                $shortcutTarget = [string]$wsh.CreateShortcut($shortcut).TargetPath
                                if ($shortcutTarget.Equals(
                                        $debuggerPath,
                                        [StringComparison]::OrdinalIgnoreCase
                                    )) {
                                    $dangling.Add('the Start menu shortcut still targets the absent Atlas package')
                                }
                            }
                            catch {
                                $dangling.Add('the existing Process Explorer shortcut could not be proven independent')
                            }
                        }
                        $pcwStart = [int](Get-ItemProperty `
                                -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\pcw' `
                                -Name Start `
                                -ErrorAction Stop).Start
                        if ($pcwStart -eq 4) {
                            $dangling.Add('pcw remains disabled without an ownership record')
                        }
                        if ($dangling.Count -ne 0) {
                            throw "ProcessExplorer: the package is absent but dependent state is unresolved: $($dangling -join '; ')."
                        }
                    }
                    if (-not $Toggle.Silent) { Write-Host 'Process Explorer is already removed.' }
                    return
                }
                $installState = Read-AtlasProcessExplorerInstallState -PackagePath $appDir
                $shortcut = Join-Path ([Environment]::GetFolderPath('CommonStartMenu')) `
                    'Programs\Process Explorer.lnk'
                $shortcutArtifactParameters = @{
                    Path = $shortcut
                    ArtifactId = [string]$installState.InstallId
                    TargetExists = [bool]$installState.Shortcut.PriorExists
                    TargetSha256 = if ($installState.Shortcut.PriorExists) {
                        [string]$installState.Shortcut.PriorSha256
                    }
                    else { $null }
                    AlternateSha256 = [string]$installState.Shortcut.InstalledSha256
                }
                if (-not $installState.RestoreProgress.Shortcut) {
                    $shortcutArtifactParameters.AllowCompleteTarget = $true
                }
                [void](Repair-AtlasProcessExplorerShortcutArtifacts @shortcutArtifactParameters)
                $restoreSteps = New-Object System.Collections.Generic.List[object]
                $persistRestoreProgress = {
                    param($State)
                    Write-AtlasProcessExplorerInstallState `
                        -PackagePath $appDir `
                        -State $State `
                        -ReplaceExisting
                }.GetNewClosure()

                $ifeo = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe'
                $restoreDebugger = {
                    $ifeoExists = Test-Path -LiteralPath $ifeo -ErrorAction Stop
                    if (-not $ifeoExists -and $installState.Debugger.PriorExists) {
                        throw 'the recorded IFEO key is missing'
                    }
                    if ($ifeoExists) {
                        $ifeoKey = Get-Item -LiteralPath $ifeo -ErrorAction Stop
                        $debuggerExists = $ifeoKey.GetValueNames() -contains 'Debugger'
                        if (-not $debuggerExists -and $installState.Debugger.PriorExists) {
                            throw 'the recorded Debugger value is missing'
                        }
                        if ($debuggerExists) {
                            $currentDebugger = [string]$ifeoKey.GetValue(
                                'Debugger',
                                $null,
                                [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
                            )
                            $currentDebuggerKind = [string]$ifeoKey.GetValueKind('Debugger')
                            $debuggerOwned = $currentDebugger.Equals(
                                [string]$installState.Debugger.InstalledValue,
                                [StringComparison]::OrdinalIgnoreCase
                            ) -and $currentDebuggerKind -eq [string]$installState.Debugger.InstalledKind
                            $debuggerAlreadyRestored = $installState.Debugger.PriorExists -and
                                $currentDebugger -ceq [string]$installState.Debugger.PriorValue -and
                                $currentDebuggerKind -eq [string]$installState.Debugger.PriorKind
                            if (-not $debuggerOwned -and -not $debuggerAlreadyRestored) {
                                throw "the Debugger value is neither Atlas-owned nor the recorded prior value ('$currentDebugger')"
                            }
                            if ($debuggerOwned -and $installState.Debugger.PriorExists) {
                                $ifeoKey.SetValue(
                                    'Debugger',
                                    [string]$installState.Debugger.PriorValue,
                                    [Microsoft.Win32.RegistryValueKind]([string]$installState.Debugger.PriorKind)
                                )
                            }
                            elseif ($debuggerOwned) {
                                $ifeoKey.DeleteValue('Debugger', $false)
                            }
                        }
                    }

                    if ($installState.Debugger.PriorExists) {
                        if (-not (Test-Path -LiteralPath $ifeo -ErrorAction Stop)) {
                            throw 'the IFEO key disappeared while verifying restoration'
                        }
                        $ifeoKey = Get-Item -LiteralPath $ifeo -ErrorAction Stop
                        if ($ifeoKey.GetValueNames() -notcontains 'Debugger') {
                            throw 'the prior Debugger value is missing after restoration'
                        }
                        $restoredDebugger = [string]$ifeoKey.GetValue(
                            'Debugger',
                            $null,
                            [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
                        )
                        $restoredDebuggerKind = [string]$ifeoKey.GetValueKind('Debugger')
                        if ($restoredDebugger -cne [string]$installState.Debugger.PriorValue -or
                            $restoredDebuggerKind -ne [string]$installState.Debugger.PriorKind) {
                            throw 'the prior Debugger value did not retain its recorded value and kind'
                        }
                    }
                    elseif (Test-Path -LiteralPath $ifeo -ErrorAction Stop) {
                        $ifeoKey = Get-Item -LiteralPath $ifeo -ErrorAction Stop
                        if ($ifeoKey.GetValueNames() -contains 'Debugger') {
                            throw 'the Atlas-owned Debugger value is still present'
                        }
                    }
                }.GetNewClosure()
                $verifyRestoredDebugger = {
                    $ifeoExists = Test-Path -LiteralPath $ifeo -ErrorAction Stop
                    if ($installState.Debugger.PriorExists) {
                        if (-not $ifeoExists) {
                            throw 'the restored IFEO key is missing'
                        }
                        $ifeoKey = Get-Item -LiteralPath $ifeo -ErrorAction Stop
                        if ($ifeoKey.GetValueNames() -notcontains 'Debugger') {
                            throw 'the restored Debugger value is missing'
                        }
                        $currentDebugger = [string]$ifeoKey.GetValue(
                            'Debugger',
                            $null,
                            [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
                        )
                        $currentDebuggerKind = [string]$ifeoKey.GetValueKind('Debugger')
                        if ($currentDebugger -cne [string]$installState.Debugger.PriorValue -or
                            $currentDebuggerKind -ne [string]$installState.Debugger.PriorKind) {
                            throw 'the restored Debugger no longer matches the recorded prior value'
                        }
                    }
                    elseif ($ifeoExists) {
                        $ifeoKey = Get-Item -LiteralPath $ifeo -ErrorAction Stop
                        if ($ifeoKey.GetValueNames() -contains 'Debugger') {
                            throw 'a Debugger value appeared after restoration completed'
                        }
                    }
                }.GetNewClosure()
                $restoreSteps.Add([pscustomobject]@{
                        Name = 'Debugger'
                        Action = $restoreDebugger
                        VerifyCompleted = $verifyRestoredDebugger
                    })

                $restoreShortcut = {
                    $currentShortcut = Get-AtlasProcessExplorerShortcutState -Path $shortcut
                    if (-not $currentShortcut.Exists) {
                        if ($installState.Shortcut.PriorExists) {
                            throw 'the recorded Atlas shortcut is missing'
                        }
                    }
                    else {
                        $currentShortcutHash = $currentShortcut.Sha256
                        $shortcutOwned = $currentShortcutHash -eq
                            [string]$installState.Shortcut.InstalledSha256
                        $shortcutAlreadyRestored = $installState.Shortcut.PriorExists -and
                            $currentShortcutHash -eq [string]$installState.Shortcut.PriorSha256
                        if (-not $shortcutOwned -and -not $shortcutAlreadyRestored) {
                            throw 'the recorded shortcut is neither Atlas-owned nor the recorded prior file'
                        }
                        if ($shortcutOwned -and $installState.Shortcut.PriorExists) {
                            $priorShortcutBytes = [Convert]::FromBase64String(
                                [string]$installState.Shortcut.PriorBytesBase64
                            )
                            [void](Set-AtlasProcessExplorerShortcutBytesAtomically `
                                -Path $shortcut `
                                -Bytes $priorShortcutBytes `
                                -ArtifactId ([string]$installState.InstallId) `
                                -AlternateSha256 ([string]$installState.Shortcut.InstalledSha256))
                        }
                        elseif ($shortcutOwned) {
                            [IO.File]::Delete($shortcut)
                        }
                    }

                    if ($installState.Shortcut.PriorExists) {
                        $restoredShortcut = Get-AtlasProcessExplorerShortcutState -Path $shortcut
                        if (-not $restoredShortcut.Exists -or
                            $restoredShortcut.Sha256 -ne [string]$installState.Shortcut.PriorSha256) {
                            throw 'the prior shortcut did not retain its recorded bytes'
                        }
                    }
                    elseif ((Get-AtlasProcessExplorerShortcutState -Path $shortcut).Exists) {
                        throw 'the Atlas-owned shortcut is still present'
                    }
                }.GetNewClosure()
                $verifyRestoredShortcut = {
                    if ($installState.Shortcut.PriorExists) {
                        $restoredShortcut = Get-AtlasProcessExplorerShortcutState -Path $shortcut
                        if (-not $restoredShortcut.Exists -or
                            $restoredShortcut.Sha256 -ne [string]$installState.Shortcut.PriorSha256) {
                            throw 'the restored shortcut no longer matches the recorded prior file'
                        }
                    }
                    elseif ((Get-AtlasProcessExplorerShortcutState -Path $shortcut).Exists) {
                        throw 'a shortcut appeared after restoration completed'
                    }
                }.GetNewClosure()
                $restoreSteps.Add([pscustomobject]@{
                        Name = 'Shortcut'
                        Action = $restoreShortcut
                        VerifyCompleted = $verifyRestoredShortcut
                    })

                $restorePcw = {
                    if ($installState.Pcw.Changed) {
                        $pcwPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\pcw'
                        $currentPcwStart = [int](Get-ItemProperty `
                                -LiteralPath $pcwPath `
                                -Name Start `
                                -ErrorAction Stop).Start
                        $pcwStartNames = @{
                            0 = 'boot'
                            1 = 'system'
                            2 = 'auto'
                            3 = 'demand'
                            4 = 'disabled'
                        }
                        $priorPcwStart = [int]$installState.Pcw.PriorStart
                        if ($currentPcwStart -ne [int]$installState.Pcw.InstalledStart -and
                            $currentPcwStart -ne $priorPcwStart) {
                            throw "pcw is neither Atlas-owned nor restored (Start '$currentPcwStart')"
                        }
                        if ($currentPcwStart -eq [int]$installState.Pcw.InstalledStart) {
                            $scPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'sc.exe')
                            & $scPath @(
                                'config',
                                'pcw',
                                'start=',
                                $pcwStartNames[$priorPcwStart]
                            ) | Out-Null
                            $scExitCode = $LASTEXITCODE
                            if ($scExitCode -ne 0) {
                                throw "sc.exe exited with $scExitCode"
                            }
                        }
                        $restoredPcwStart = [int](Get-ItemProperty `
                                -LiteralPath $pcwPath `
                                -Name Start `
                                -ErrorAction Stop).Start
                        if ($restoredPcwStart -ne $priorPcwStart) {
                            throw "pcw retained unexpected Start value '$restoredPcwStart'"
                        }
                    }
                }.GetNewClosure()
                $verifyRestoredPcw = {
                    if ($installState.Pcw.Changed) {
                        $pcwPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\pcw'
                        $currentPcwStart = [int](Get-ItemProperty `
                                -LiteralPath $pcwPath `
                                -Name Start `
                                -ErrorAction Stop).Start
                        if ($currentPcwStart -ne [int]$installState.Pcw.PriorStart) {
                            throw "pcw no longer matches its recorded prior Start value ('$currentPcwStart')"
                        }
                    }
                }.GetNewClosure()
                $restoreSteps.Add([pscustomobject]@{
                        Name = 'Pcw'
                        Action = $restorePcw
                        VerifyCompleted = $verifyRestoredPcw
                    })

                $restoreResult = Invoke-AtlasProcessExplorerRestorePlan `
                    -State $installState `
                    -Steps $restoreSteps.ToArray() `
                    -PersistState $persistRestoreProgress
                if ($restoreResult.Failures.Count -ne 0 -or -not $restoreResult.AllComplete) {
                    throw "ProcessExplorer: dependent state restoration failed; the trusted package was retained: $($restoreResult.Failures -join '; ')"
                }
                Uninstall-AtlasProcessExplorerPackage `
                    -DependentStateRestored `
                    -OperationLock $operationLock

                if ($Toggle.Silent) {
                    Stop-Process -Name taskmgr -Force -ErrorAction SilentlyContinue
                }
                if (-not $Toggle.Silent) { Write-Host 'Finished, changes have been applied.' }
                }
                finally {
                    Exit-AtlasProcessExplorerOperationLock -Lock $operationLock
                }
            }
        }
    }
}
