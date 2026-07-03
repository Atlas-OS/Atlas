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
}
