BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module (Join-Path $AtlasTestModulesRoot 'Atlas.TasksProcs\Atlas.TasksProcs.psd1') -Force
    foreach ($source in @(
        @{ Path = 'Operations\Invoke-AtlasUserShellRefresh.ps1'; Functions = @('Restore-AtlasUserExplorer', 'Write-AtlasShellRefreshFailure') }
        @{ Path = 'Operations\Remove-OneDriveCurrentUserData.ps1'; Functions = @('ConvertTo-AtlasOneDriveUserSid', 'Register-AtlasOneDrivePostBootCleanup') }
    )) {
        $tokens = $null
        $errors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $AtlasTestScriptsRoot $source.Path), [ref]$tokens, [ref]$errors)
        if ($errors.Count) { throw ($errors -join '; ') }
        foreach ($name in $source.Functions) {
            $definition = $ast.Find({
                param($node)
                $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name
            }, $true)
            . ([scriptblock]::Create($definition.Extent.Text))
        }
    }
}

Describe 'Shell refresh preserves the installation window' {
    BeforeEach {
        Mock Start-Process {}
    }
    It 'does not launch a folder when Windows has restored the shell' {
        Mock Wait-AtlasExplorerShellRecovery { [pscustomobject]@{ Id = 42; SessionId = 7 } }
        Restore-AtlasUserExplorer -SessionId 7
        Should -Invoke Start-Process -Times 0 -Exactly
        Should -Invoke Wait-AtlasExplorerShellRecovery -Times 1 -Exactly -ParameterFilter { $SessionId -eq 7 }
    }
    It 'recovers a missing shell once and verifies readiness in the same session' {
        Mock Wait-AtlasExplorerShellRecovery {
            if ($TimeoutSeconds -eq 5) { throw 'shell is missing' }
            [pscustomobject]@{ Id = 42; SessionId = 7 }
        }
        Restore-AtlasUserExplorer -SessionId 7
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -like '*\explorer.exe' -and $WindowStyle -eq 'Hidden'
        }
        Should -Invoke Wait-AtlasExplorerShellRecovery -Times 1 -Exactly -ParameterFilter {
            $SessionId -eq 7 -and $TimeoutSeconds -eq 15
        }
    }
    It 'reports failure when the recovery launch never produces a shell' {
        Mock Wait-AtlasExplorerShellRecovery { throw 'shell is missing' }
        { Restore-AtlasUserExplorer -SessionId 7 } | Should -Throw '*shell is missing*'
        Should -Invoke Start-Process -Times 1 -Exactly
    }
}

Describe 'Shell refresh failure record' {
    BeforeAll {
        function New-TestErrorRecord {
            try { throw 'Access is denied.' } catch { $_ }
        }
    }

    It 'writes the stage, the error and its script position for the run' {
        $id = [guid]::NewGuid().ToString('N')

        Write-AtlasShellRefreshFailure -Stage 'ProcessStop' -ErrorRecord (New-TestErrorRecord) `
            -RecordId $id -LogDirectory (Join-Path $TestDrive 'Logs')

        $lines = @(Get-Content -LiteralPath (Join-Path $TestDrive "Logs\shell-refresh-$id.log"))
        $lines[0] | Should -BeExactly 'Stage: ProcessStop'
        $lines[1] | Should -BeExactly 'Error: Access is denied.'
        $lines[2] | Should -Match '^Position: .*Atlas\.InstallPresentation\.Tests\.ps1:\d+'
        $lines.Count | Should -Be 3
    }

    It 'writes nothing when the caller asked for no record' {
        Write-AtlasShellRefreshFailure -Stage 'ProcessStop' -ErrorRecord (New-TestErrorRecord) `
            -RecordId '' -LogDirectory (Join-Path $TestDrive 'Unasked')

        Test-Path -LiteralPath (Join-Path $TestDrive 'Unasked') | Should -BeFalse
    }

    It 'never fails the helper when the record cannot be written' {
        $file = Join-Path $TestDrive 'not-a-folder'
        Set-Content -LiteralPath $file -Value ''

        { Write-AtlasShellRefreshFailure -Stage 'ProcessStop' -ErrorRecord (New-TestErrorRecord) `
                -RecordId ([guid]::NewGuid().ToString('N')) -LogDirectory (Join-Path $file 'Logs') } |
            Should -Not -Throw
    }

    It 'keeps the stage exit code and hands the failure to the record' {
        # A copy of the helper beside stub modules, whose administrator token it refuses
        # before it looks for any process. The stub bootstrap aliases the record writer,
        # because an alias outranks the helper's own function, and keeps what the trap
        # hands it in TestDrive.
        $root = Join-Path $TestDrive 'Scripts'
        $operations = New-Item -ItemType Directory -Force -Path (Join-Path $root 'Operations')
        Copy-Item -LiteralPath (Join-Path $AtlasTestScriptsRoot 'Operations\Invoke-AtlasUserShellRefresh.ps1') `
            -Destination $operations.FullName
        $captured = Join-Path $TestDrive 'captured.txt'
        Set-Content -LiteralPath (Join-Path $root 'Initialize-AtlasPowerShell.ps1') -Value @"
function Save-TestShellRefreshFailure {
    param([string]`$Stage, `$ErrorRecord)
    Set-Content -LiteralPath '$captured' -Value @(`$Stage, `$ErrorRecord.Exception.Message, `$FailureRecordId)
}
Set-Alias -Name Write-AtlasShellRefreshFailure -Value Save-TestShellRefreshFailure
"@
        foreach ($module in @(
                @{ Name = 'Atlas.Core'; Body = 'function Test-AtlasSystem { $false }; function Test-AtlasAdmin { $true }' }
                @{ Name = 'Atlas.TasksProcs'; Body = 'function Stop-AtlasProcess { throw ''Access is denied to explorer.'' }' }
            )) {
            $folder = New-Item -ItemType Directory -Force -Path (Join-Path $root "Modules\$($module.Name)")
            Set-Content -LiteralPath (Join-Path $folder.FullName "$($module.Name).psm1") -Value $module.Body
            New-ModuleManifest -Path (Join-Path $folder.FullName "$($module.Name).psd1") -RootModule "$($module.Name).psm1"
        }
        $id = [guid]::NewGuid().ToString('N')

        $powershell = Join-Path ([Environment]::SystemDirectory) 'WindowsPowerShell\v1.0\powershell.exe'
        & $powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass `
            -File (Join-Path $operations.FullName 'Invoke-AtlasUserShellRefresh.ps1') `
            -CurrentSession -FailureRecordId $id | Out-Null

        $LASTEXITCODE | Should -Be 11
        $lines = @(Get-Content -LiteralPath $captured)
        $lines[0] | Should -BeExactly 'CurrentSessionIdentity'
        $lines[1] | Should -BeLike 'User-shell refresh requires a non-elevated interactive user token*'
        $lines[2] | Should -BeExactly $id
    }
}

Describe 'Deferred cleanup preserves other startup registrations' {
    BeforeEach {
        $script:launcherFixture = Join-Path $TestDrive 'cleanup.vbs'
        [IO.File]::WriteAllText($script:launcherFixture, '')
        Mock Join-Path { $script:launcherFixture } -ParameterFilter {
            $ChildPath -like '*Invoke-OneDriveCleanupHidden.vbs'
        }
        Mock New-Item {}
        Mock New-ItemProperty {}
    }
    It 'does not recreate an existing startup key containing Atlas and other apps' {
        Mock Test-Path { $true }
        Register-AtlasOneDrivePostBootCleanup -UserSid 'S-1-5-21-1000-2000-3000-1001' -BootUtcTicks 638925000000000000L
        Should -Invoke New-Item -Times 0 -Exactly
        Should -Invoke New-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'AtlasOneDriveCleanup' -and $LiteralPath -eq 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
        }
    }
    It 'creates a missing startup key before registering cleanup' {
        Mock Test-Path { $false }
        Register-AtlasOneDrivePostBootCleanup -UserSid 'S-1-5-21-1000-2000-3000-1001' -BootUtcTicks 638925000000000000L
        Should -Invoke New-Item -Times 1 -Exactly
        Should -Invoke New-ItemProperty -Times 1 -Exactly
    }
}
