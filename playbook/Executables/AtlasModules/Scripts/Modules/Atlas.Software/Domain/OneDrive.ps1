# Atlas.Software domain: OneDrive removal.
#
# Everything is best-effort because most of these leftovers only exist in some
# configurations. The actual OneDrive setup in Windows is stripped at a component level
# in the miscellaneous CBS package; this removes the preinstalled client and its
# leftovers.

function Remove-AtlasOneDriveMachineRegistryItem {
    param([Parameter(Mandatory = $true)][string[]]$Path)

    foreach ($item in $Path) {
        if ($item -notmatch '^HKLM:\\') {
            throw "OneDrive machine-registry cleanup rejected non-HKLM path '$item'."
        }
        Remove-Item -LiteralPath $item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Remove-AtlasOneDrive {
    <#
    .SYNOPSIS
        Uninstalls the preinstalled OneDrive client and cleans up its per-user
        registry entries, folders, scheduled tasks and shell extensions.
    #>
    Stop-Process -Name 'OneDrive' -Force -ErrorAction SilentlyContinue

    $atlasSoftwareRoot = [IO.Directory]::GetParent($PSScriptRoot)
    $modulesRoot = $atlasSoftwareRoot.Parent
    $scriptsRoot = $modulesRoot.Parent
    $downloadIntegrity = [IO.Path]::Combine(
        $scriptsRoot.FullName,
        'Internal',
        'Download-Integrity.ps1'
    )
    if (-not [IO.File]::Exists($downloadIntegrity)) {
        throw "The Atlas download-integrity helper is missing at '$downloadIntegrity'."
    }
    . $downloadIntegrity

    $windir = [Environment]::GetFolderPath('Windows')
    $setupPaths = @(
        (Join-Path -Path $windir -ChildPath 'System32\OneDriveSetup.exe')
        (Join-Path -Path $windir -ChildPath 'SysWOW64\OneDriveSetup.exe')
    )

    $setupFound = $false
    foreach ($setupPath in $setupPaths) {
        if (Test-Path -LiteralPath $setupPath -PathType Leaf) {
            $setupFound = $true
            try {
                $setupResult = Invoke-AtlasContainedProcess `
                    -FilePath $setupPath `
                    -ArgumentList ([string[]]@('/uninstall')) `
                    -WorkingDirectory ([IO.Path]::GetDirectoryName($setupPath)) `
                    -TimeoutSeconds 900 `
                    -Description "The protected OneDrive uninstaller '$setupPath'" `
                    -Hidden `
                    -NoWindow
                if (-not $setupResult.ContainmentConfirmed -or -not $setupResult.RootExited -or
                    -not $setupResult.JobDrained) {
                    throw "OneDriveSetup returned without confirmed process-tree containment."
                }
                $setupExitCode = [uint32]$setupResult.ExitCodeUInt32
                if ($setupExitCode -ne 0) {
                    throw "OneDriveSetup exited with code $setupExitCode."
                }
            }
            catch {
                if (Test-AtlasContainedProcessContainmentUnconfirmed -Exception $_.Exception) {
                    throw
                }
                Write-AtlasLog -Level Warning -Message "Running '$setupPath /uninstall' failed: $($_.Exception.Message)"
            }
        }
    }

    # Never fall back to a privileged WinGet uninstall here. WinGet correlates
    # against per-user ARP records, whose uninstall command is writable by that
    # user; executing it from this elevated phase would cross an unsafe trust
    # boundary. The protected inbox setup binaries above are the only executable
    # uninstall authority.
    if (-not $setupFound) {
        Write-AtlasLog -Level Warning -Message 'Protected OneDriveSetup.exe was not found; skipping executable uninstall and continuing declarative cleanup.'
    }

    # Do not mutate user-owned HKEY_USERS trees from this elevated process.
    # Registry symbolic links can redirect provider recursion/writes, and a
    # medium user can race any path precheck. Per-user OneDrive state is left to
    # the protected vendor uninstaller or a future medium-token reconciliation.
    Write-AtlasLog -Message 'Skipped elevated cleanup of user-owned OneDrive registry state.'

    # Do not recursively traverse user-writable filesystem paths from this
    # elevated process. A profile owner can replace an ancestor with a junction
    # between validation and deletion, redirecting a privileged Remove-Item into
    # another profile or machine location. The protected OneDriveSetup binary is
    # the supported filesystem-removal authority; harmless leftovers are safer
    # than privileged traversal of untrusted profile trees.
    Write-AtlasLog -Message 'Skipped elevated deletion of user-owned OneDrive filesystem leftovers.'

    foreach ($taskPattern in @('OneDrive Reporting Task*', 'OneDrive Standalone Update Task*')) {
        foreach ($task in @(Get-ScheduledTask -TaskName $taskPattern -ErrorAction SilentlyContinue)) {
            try {
                Unregister-ScheduledTask -InputObject $task -Confirm:$false -ErrorAction Stop
            }
            catch {
                Write-AtlasLog -Level Warning -Message "Couldn't delete scheduled task '$($task.TaskName)': $($_.Exception.Message)"
            }
        }
    }

    Remove-AtlasOneDriveMachineRegistryItem -Path @(
        'HKLM:\SOFTWARE\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'
        'HKLM:\SOFTWARE\Classes\WOW6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'
        'HKLM:\SOFTWARE\Classes\CLSID\{A0A7DEC5-B1A7-4A47-847D-1D005787621E}'
        'HKLM:\SOFTWARE\Classes\WOW6432Node\CLSID\{A0A7DEC5-B1A7-4A47-847D-1D005787621E}'
    )
}
