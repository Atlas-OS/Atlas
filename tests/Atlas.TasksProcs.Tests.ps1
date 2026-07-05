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
        Mock Stop-Process -ModuleName Atlas.TasksProcs

        Stop-AtlasProcess -Name 'msteams*'

        Should -Invoke Stop-Process -ModuleName Atlas.TasksProcs -Times 1 -Exactly -ParameterFilter {
            $InputObject.Id -eq $PID -and $Force
        }
    }

    It 'warns but does not throw when a process cannot be stopped' {
        Mock Get-Process -ModuleName Atlas.TasksProcs -ParameterFilter { $Name -eq 'msteams*' } -MockWith {
            [pscustomobject]@{ ProcessName = 'msteams'; Id = 4242 }
        }
        Mock Stop-Process -ModuleName Atlas.TasksProcs -MockWith { throw 'Access is denied.' }
        Mock Write-AtlasLog -ModuleName Atlas.TasksProcs

        { Stop-AtlasProcess -Name 'msteams*' } | Should -Not -Throw

        Should -Invoke Write-AtlasLog -ModuleName Atlas.TasksProcs -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -like "*msteams*"
        }
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
    }

    It 'no longer exposes the old Stop-ProcessesUnderRoots name' {
        Get-Command -Name 'Stop-ProcessesUnderRoots' -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'no longer exposes the old Stop-TasksUnderRoots name' {
        Get-Command -Name 'Stop-TasksUnderRoots' -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }
}
