BeforeAll {
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.TasksProcs\Atlas.TasksProcs.psd1') -Force

    $script:missingTask = '\AtlasRewriteTest\TaskThatDoesNotExist'
}

Describe 'Disable-AtlasScheduledTask' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.TasksProcs
    }

    It 'warns when the task does not exist' {
        { Disable-AtlasScheduledTask -Path $script:missingTask } | Should -Not -Throw

        Should -Invoke Write-AtlasLog -ModuleName Atlas.TasksProcs -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -like '*was not found*'
        }
    }

    It 'stays silent about a missing task with -IgnoreMissing' {
        { Disable-AtlasScheduledTask -Path $script:missingTask -IgnoreMissing } | Should -Not -Throw

        Should -Invoke Write-AtlasLog -ModuleName Atlas.TasksProcs -Times 0 -Exactly
    }
}

Describe 'Enable-AtlasScheduledTask' {
    It 'warns when the task does not exist' {
        Mock Write-AtlasLog -ModuleName Atlas.TasksProcs

        { Enable-AtlasScheduledTask -Path $script:missingTask } | Should -Not -Throw

        Should -Invoke Write-AtlasLog -ModuleName Atlas.TasksProcs -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning'
        }
    }
}

Describe 'Remove-AtlasScheduledTask' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.TasksProcs
    }

    It 'warns when the task does not exist' {
        { Remove-AtlasScheduledTask -Path $script:missingTask } | Should -Not -Throw

        Should -Invoke Write-AtlasLog -ModuleName Atlas.TasksProcs -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning'
        }
    }

    It 'stays silent about a missing task with -IgnoreMissing' {
        { Remove-AtlasScheduledTask -Path $script:missingTask -IgnoreMissing } | Should -Not -Throw

        Should -Invoke Write-AtlasLog -ModuleName Atlas.TasksProcs -Times 0 -Exactly
    }
}

Describe 'Stop-AtlasProcess' {
    It 'silently skips processes that are not running' {
        { Stop-AtlasProcess -Name 'AtlasRewriteTestNoSuchProcess*' } | Should -Not -Throw
    }

    It 'accepts multiple wildcard patterns' {
        { Stop-AtlasProcess -Name 'AtlasRewriteTestNoSuchProcess*', 'AnotherMissingProcess*' } | Should -Not -Throw
    }

    It 'force-stops a matching process' {
        Mock Get-Process -ModuleName Atlas.TasksProcs -ParameterFilter { $Name -eq 'msteams*' } -MockWith {
            [System.Diagnostics.Process]::GetCurrentProcess()
        }
        Mock Invoke-AtlasProcessStop -ModuleName Atlas.TasksProcs

        Stop-AtlasProcess -Name 'msteams*'

        Should -Invoke Invoke-AtlasProcessStop -ModuleName Atlas.TasksProcs -Times 1 -Exactly -ParameterFilter {
            $Process.Id -eq $PID
        }
    }

    It 'warns but does not throw when a process cannot be stopped' {
        Mock Get-Process -ModuleName Atlas.TasksProcs -ParameterFilter { $Name -eq 'msteams*' } -MockWith {
            [pscustomobject]@{ ProcessName = 'msteams'; Id = 4242 }
        }
        Mock Invoke-AtlasProcessStop -ModuleName Atlas.TasksProcs -MockWith { throw 'Access is denied.' }
        Mock Write-AtlasLog -ModuleName Atlas.TasksProcs

        { Stop-AtlasProcess -Name 'msteams*' } | Should -Not -Throw

        Should -Invoke Write-AtlasLog -ModuleName Atlas.TasksProcs -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -like "*msteams*"
        }
    }

    It 'stops only processes in the explicitly requested Windows session' {
        Mock Get-Process -ModuleName Atlas.TasksProcs -ParameterFilter { $Name -eq 'explorer' } -MockWith {
            @(
                [pscustomobject]@{ ProcessName = 'explorer'; Id = 7001; SessionId = 7 }
                [pscustomobject]@{ ProcessName = 'explorer'; Id = 8001; SessionId = 8 }
            )
        }
        Mock Invoke-AtlasProcessStop -ModuleName Atlas.TasksProcs

        Stop-AtlasProcess -Name 'explorer' -SessionId 7 -StopOnError

        Should -Invoke Invoke-AtlasProcessStop -ModuleName Atlas.TasksProcs -Times 1 -Exactly `
            -ParameterFilter { $Process.Id -eq 7001 }
        Should -Invoke Invoke-AtlasProcessStop -ModuleName Atlas.TasksProcs -Times 0 -Exactly `
            -ParameterFilter { $Process.Id -eq 8001 }
    }

    It 'fails closed when a requested-session process cannot be stopped' {
        Mock Get-Process -ModuleName Atlas.TasksProcs -ParameterFilter { $Name -eq 'explorer' } -MockWith {
            [pscustomobject]@{ ProcessName = 'explorer'; Id = 7001; SessionId = 7 }
        }
        Mock Invoke-AtlasProcessStop -ModuleName Atlas.TasksProcs -MockWith { throw 'injected stop failure' }

        { Stop-AtlasProcess -Name 'explorer' -SessionId 7 -StopOnError } |
            Should -Throw -ExpectedMessage '*injected stop failure*'
    }

    It 'tolerates the checked process exiting naturally before termination' {
        Mock Get-Process -ModuleName Atlas.TasksProcs -ParameterFilter { $Name -eq 'explorer' } -MockWith {
            [pscustomobject]@{
                ProcessName = 'explorer'; Id = 7001; SessionId = 7; HasExited = $true
            }
        }
        Mock Invoke-AtlasProcessStop -ModuleName Atlas.TasksProcs -MockWith { throw 'process already exited' }

        { Stop-AtlasProcess -Name 'explorer' -SessionId 7 -StopOnError } |
            Should -Not -Throw
    }

    It 'requires the retained stopped process to reach a bounded exit postcondition' {
        Mock Get-Process -ModuleName Atlas.TasksProcs -ParameterFilter { $Name -eq 'explorer' } -MockWith {
            [pscustomobject]@{ ProcessName = 'explorer'; Id = 7001; SessionId = 7 }
        }
        Mock Invoke-AtlasProcessStop -ModuleName Atlas.TasksProcs
        Mock Wait-AtlasProcessExit -ModuleName Atlas.TasksProcs

        Stop-AtlasProcess -Name explorer -SessionId 7 -StopOnError `
            -WaitTimeoutMilliseconds 5000

        Should -Invoke Wait-AtlasProcessExit -ModuleName Atlas.TasksProcs `
            -Times 1 -Exactly -ParameterFilter {
                $Process.Id -eq 7001 -and $TimeoutMilliseconds -eq 5000
            }
    }

    It 'fails closed when a stopped process misses its bounded exit postcondition' {
        Mock Get-Process -ModuleName Atlas.TasksProcs -ParameterFilter { $Name -eq 'msteams*' } -MockWith {
            [pscustomobject]@{
                ProcessName = 'msteams'; Id = 7002; SessionId = 7; HasExited = $false
            }
        }
        Mock Invoke-AtlasProcessStop -ModuleName Atlas.TasksProcs
        Mock Wait-AtlasProcessExit -ModuleName Atlas.TasksProcs -MockWith { throw 'wait timed out' }

        {
            Stop-AtlasProcess -Name 'msteams*' -SessionId 7 -StopOnError `
                -WaitTimeoutMilliseconds 5000
        } | Should -Throw -ExpectedMessage '*wait timed out*'
    }

    It 'accepts Explorer only when it owns the shell window in the requested session' {
        Mock Get-AtlasShellWindowProcessId -ModuleName Atlas.TasksProcs -MockWith { 7002 }
        Mock Get-Process -ModuleName Atlas.TasksProcs -ParameterFilter { $Id -eq 7002 } -MockWith {
            [pscustomobject]@{
                Id = 7002; ProcessName = 'explorer'; SessionId = 7; HasExited = $false
            }
        }

        $result = Wait-AtlasExplorerShellRecovery -SessionId 7 -TimeoutSeconds 1

        $result.Id | Should -Be 7002
        $result.SessionId | Should -Be 7
    }

    It 'waits past a shell-window owner from another session' {
        $script:processRead = 0
        Mock Get-AtlasShellWindowProcessId -ModuleName Atlas.TasksProcs -MockWith { 7002 }
        Mock Get-Process -ModuleName Atlas.TasksProcs -ParameterFilter { $Id -eq 7002 } -MockWith {
            $script:processRead++
            [pscustomobject]@{
                Id = 7002
                ProcessName = 'explorer'
                SessionId = if ($script:processRead -eq 1) { 8 } else { 7 }
                HasExited = $false
            }
        }
        Mock Start-Sleep -ModuleName Atlas.TasksProcs

        $result = Wait-AtlasExplorerShellRecovery -SessionId 7 -TimeoutSeconds 1

        $result.SessionId | Should -Be 7
        Should -Invoke Get-Process -ModuleName Atlas.TasksProcs -Times 2 -Exactly
    }
}

# Happy-path coverage for the scheduled-task wrappers. Disable/Enable/Remove-AtlasScheduledTask
# each shell out to schtasks.exe through the internal Invoke-AtlasScheduledTaskCommand helper.
# That helper is the existing, pre-built mockable seam, so these tests assert the exact schtasks
# arguments each wrapper builds without a real (or mutating) schtasks.exe invocation and without
# any product change.
Describe 'Scheduled-task wrappers build the correct schtasks command' {
    BeforeEach {
        Mock Invoke-AtlasScheduledTaskCommand -ModuleName Atlas.TasksProcs
    }

    It 'Disable-AtlasScheduledTask issues /Change /TN <path> /DISABLE' {
        Disable-AtlasScheduledTask -Path '\Microsoft\Windows\Defrag\ScheduledDefrag'

        Should -Invoke Invoke-AtlasScheduledTaskCommand -ModuleName Atlas.TasksProcs -Times 1 -Exactly -ParameterFilter {
            $Path -eq '\Microsoft\Windows\Defrag\ScheduledDefrag' -and
            $OperationLabel -eq 'disable' -and
            (($Arguments -join ' ') -eq '/Change /TN \Microsoft\Windows\Defrag\ScheduledDefrag /DISABLE') -and
            -not $IgnoreMissing
        }
    }

    It 'Enable-AtlasScheduledTask issues /Change /TN <path> /ENABLE' {
        Enable-AtlasScheduledTask -Path '\Microsoft\Windows\Defrag\ScheduledDefrag'

        Should -Invoke Invoke-AtlasScheduledTaskCommand -ModuleName Atlas.TasksProcs -Times 1 -Exactly -ParameterFilter {
            $Path -eq '\Microsoft\Windows\Defrag\ScheduledDefrag' -and
            $OperationLabel -eq 'enable' -and
            (($Arguments -join ' ') -eq '/Change /TN \Microsoft\Windows\Defrag\ScheduledDefrag /ENABLE')
        }
    }

    It 'Remove-AtlasScheduledTask issues /Delete /TN <path> /F' {
        Remove-AtlasScheduledTask -Path '\Microsoft\Windows\Defrag\ScheduledDefrag'

        Should -Invoke Invoke-AtlasScheduledTaskCommand -ModuleName Atlas.TasksProcs -Times 1 -Exactly -ParameterFilter {
            $Path -eq '\Microsoft\Windows\Defrag\ScheduledDefrag' -and
            $OperationLabel -eq 'delete' -and
            (($Arguments -join ' ') -eq '/Delete /TN \Microsoft\Windows\Defrag\ScheduledDefrag /F')
        }
    }

    It 'forwards -IgnoreMissing to the schtasks helper' {
        Disable-AtlasScheduledTask -Path '\Some\Task' -IgnoreMissing

        Should -Invoke Invoke-AtlasScheduledTaskCommand -ModuleName Atlas.TasksProcs -Times 1 -Exactly -ParameterFilter {
            $IgnoreMissing -eq $true
        }
    }
}

# Root-scoped process/task cleanup helpers moved here from Atlas.Core (plan 019). These assert
# the module now owns the renamed functions and that the old Core names are gone, not aliased.
Describe 'Root-scoped cleanup helpers live in Atlas.TasksProcs' {
    It 'exports Stop-AtlasProcessUnderRoot and Stop-AtlasScheduledTaskUnderRoot' {
        $exported = (Get-Command -Module Atlas.TasksProcs).Name
        $exported | Should -Contain 'Stop-AtlasProcessUnderRoot'
        $exported | Should -Contain 'Stop-AtlasScheduledTaskUnderRoot'
        $exported | Should -Contain 'Wait-AtlasExplorerShellRecovery'
    }

    It 'no longer exposes the old Stop-ProcessesUnderRoots name' {
        Get-Command -Name 'Stop-ProcessesUnderRoots' -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'no longer exposes the old Stop-TasksUnderRoots name' {
        Get-Command -Name 'Stop-TasksUnderRoots' -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'keeps TI root cleanup inside the explicitly requested Windows session' {
        Mock Get-Process -ModuleName Atlas.TasksProcs -MockWith {
            @(
                [pscustomobject]@{
                    Id = 100; Path = 'C:\Windows\AtlasModules\Tools\machine.exe'; SessionId = 0
                }
                [pscustomobject]@{
                    Id = 101; Path = 'C:\Windows\AtlasModules\Tools\user.exe'; SessionId = 7
                }
            )
        }
        Mock Invoke-AtlasProcessStop -ModuleName Atlas.TasksProcs
        Mock Wait-AtlasProcessExit -ModuleName Atlas.TasksProcs

        Stop-AtlasProcessUnderRoot -RootsLower @('c:\windows\atlasmodules\') -SessionId 0

        Should -Invoke Invoke-AtlasProcessStop -ModuleName Atlas.TasksProcs -Times 1 -Exactly `
            -ParameterFilter { $Process.Id -eq 100 }
        Should -Invoke Invoke-AtlasProcessStop -ModuleName Atlas.TasksProcs -Times 0 -Exactly `
            -ParameterFilter { $Process.Id -eq 101 }
    }
}
