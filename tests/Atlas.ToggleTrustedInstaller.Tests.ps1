BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
    $modulesRoot = Join-Path -Path $repoRoot `
        -ChildPath 'playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path -Path $modulesRoot `
            -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path -Path $modulesRoot `
            -ChildPath 'Atlas.Toggles\Atlas.Toggles.psd1') -Force

    $script:toggleRoot = Join-Path -Path $TestDrive -ChildPath 'Toggles'
    $toggleGroup = Join-Path -Path $script:toggleRoot -ChildPath 'Security'
    [void](New-Item -Path $toggleGroup -ItemType Directory -Force)

    $script:actionMarker = Join-Path -Path $TestDrive -ChildPath 'toggle-action-ran.txt'
    $script:splitEventPath = Join-Path -Path $TestDrive -ChildPath 'toggle-split-events.txt'
    $script:stateRoot = 'HKCU:\Software\AtlasRewriteTest\ToggleTrustedInstaller'
    $env:AtlasToggleSplitEventPath = $script:splitEventPath
    $escapedMarker = $script:actionMarker.Replace("'", "''")

    $definitionTemplate = @'
@{
    Name          = '__NAME__'
    Elevation     = '__ELEVATION__'
    NoStateRecord = $true
    States        = [ordered]@{
        Enable = @{
            StateValue = 1
            Reboot     = 'None'
            Action     = {
                param($Toggle)
                [IO.File]::WriteAllText('__MARKER__', 'ran')
            }
        }
    }
}
'@
    foreach ($definition in @(
            @{ Name = 'BrokerToggle'; Elevation = 'TrustedInstaller' }
            @{ Name = 'AdminToggle'; Elevation = 'Admin' }
        )) {
        $content = $definitionTemplate.Replace('__NAME__', $definition.Name).
            Replace('__ELEVATION__', $definition.Elevation).
            Replace('__MARKER__', $escapedMarker)
        Set-Content -LiteralPath (Join-Path -Path $toggleGroup `
                -ChildPath "$($definition.Name).ps1") -Encoding Ascii -Value $content
    }

    $splitContent = @'
@{
    Name      = 'SplitBrokerToggle'
    Elevation = 'TrustedInstaller'
    States    = [ordered]@{
        Enable = @{
            StateValue       = 7
            Reboot           = 'RestartExplorer'
            StateRecordScope = 'Machine'
            MachineAction    = {
                param($Toggle)
                [IO.File]::AppendAllText($env:AtlasToggleSplitEventPath, "machine`n")
            }
            UserAction       = {
                param($Toggle)
                [IO.File]::AppendAllText($env:AtlasToggleSplitEventPath, "user`n")
            }
        }
    }
}
'@
    Set-Content -LiteralPath (Join-Path -Path $toggleGroup `
            -ChildPath 'SplitBrokerToggle.ps1') -Encoding Ascii -Value $splitContent
}

AfterAll {
    Remove-Item -LiteralPath $script:actionMarker -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $script:splitEventPath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $script:stateRoot -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item Env:\ATLAS_USER_CONTEXT -ErrorAction SilentlyContinue
    Remove-Item Env:\AtlasToggleSplitEventPath -ErrorAction SilentlyContinue
}

Describe 'TrustedInstaller toggle broker boundary' {
    BeforeEach {
        Remove-Item -LiteralPath $script:actionMarker -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $script:splitEventPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $script:stateRoot -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item Env:\ATLAS_USER_CONTEXT -ErrorAction SilentlyContinue

        Mock -CommandName Test-AtlasTrustedInstaller -ModuleName Atlas.Toggles -MockWith { $false }
        Mock -CommandName Test-AtlasSystem -ModuleName Atlas.Toggles -MockWith { $false }
        Mock -CommandName Test-AtlasAdmin -ModuleName Atlas.Toggles -MockWith { $true }
        Mock -CommandName Read-Pause -ModuleName Atlas.Toggles
        Mock -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles -MockWith {
            [pscustomobject]@{ ExitCode = 0 }
        }
    }

    It 'routes an exact TrustedInstaller definition through the typed broker only' {
        Invoke-AtlasToggle -Name BrokerToggle -State Enable -JustContext -NoExplorerRestart `
            -TogglesRoot $script:toggleRoot

        Should -Invoke -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles `
            -Times 1 -Exactly -ParameterFilter {
                $Operation -ceq 'Toggle' -and
                $Name -ceq 'BrokerToggle' -and
                $State -ceq 'Enable' -and
                $Silent -eq $true -and
                $JustContext -eq $true -and
                $NoExplorerRestart -eq $true -and
                -not $MachineOnly
            }
        $script:actionMarker | Should -Not -Exist
    }

    It 'rejects case-shifted names and states before privileged dispatch' -TestCases @(
        @{ Name = 'brokertoggle'; State = 'Enable'; Message = '*No toggle definition named*' }
        @{ Name = 'BrokerToggle'; State = 'enable'; Message = '*Unknown state*' }
    ) {
        param($Name, $State, $Message)
        $toggleName = $Name
        $toggleState = $State

        {
            Invoke-AtlasToggle -Name $toggleName -State $toggleState -Silent `
                -TogglesRoot $script:toggleRoot
        } | Should -Throw -ExpectedMessage $Message

        Should -Not -Invoke -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles
        $script:actionMarker | Should -Not -Exist
    }

    It 'rejects a non-TrustedInstaller definition at the strict TrustedInstaller sink' {
        Mock -CommandName Test-AtlasTrustedInstaller -ModuleName Atlas.Toggles -MockWith { $true }

        {
            Invoke-AtlasToggle -Name AdminToggle -State Enable -Silent `
                -TogglesRoot $script:toggleRoot
        } | Should -Throw -ExpectedMessage '*does not declare exact TrustedInstaller elevation*'

        Should -Not -Invoke -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles
        $script:actionMarker | Should -Not -Exist
    }

    It 'propagates a nonzero TrustedInstaller child exit without running the local action' {
        Mock -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles -MockWith {
            throw 'TrustedInstaller broker exited with disallowed code 5.'
        }

        {
            Invoke-AtlasToggle -Name BrokerToggle -State Enable `
                -TogglesRoot $script:toggleRoot
        } | Should -Throw -ExpectedMessage '*disallowed code 5*'

        $script:actionMarker | Should -Not -Exist
    }

    It 'runs split machine and user scopes with state owned only by the machine scope' {
        Mock -CommandName Test-AtlasTrustedInstaller -ModuleName Atlas.Toggles -MockWith { $true }
        Mock -CommandName Invoke-AtlasToggleCurrentSessionShellRefresh -ModuleName Atlas.Toggles

        Invoke-AtlasToggle -Name SplitBrokerToggle -State Enable -Silent -MachineOnly `
            -TogglesRoot $script:toggleRoot -StateRoot $script:stateRoot

        Get-Content -LiteralPath $script:splitEventPath | Should -Be @('machine')
        (Get-AtlasToggleState -Name SplitBrokerToggle -StateRoot $script:stateRoot).State |
            Should -Be 7
        Should -Not -Invoke -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles

        Remove-Item -LiteralPath $script:splitEventPath -Force
        Remove-Item -LiteralPath $script:stateRoot -Recurse -Force
        Mock -CommandName Test-AtlasTrustedInstaller -ModuleName Atlas.Toggles -MockWith { $false }
        Mock -CommandName Test-AtlasAdmin -ModuleName Atlas.Toggles -MockWith { $false }
        $env:ATLAS_USER_CONTEXT = '1'

        Invoke-AtlasToggle -Name SplitBrokerToggle -State Enable -Silent `
            -TogglesRoot $script:toggleRoot -StateRoot $script:stateRoot

        Get-Content -LiteralPath $script:splitEventPath | Should -Be @('user')
        Get-AtlasToggleState -Name SplitBrokerToggle -StateRoot $script:stateRoot |
            Should -BeNullOrEmpty
    }

    It 'runs the split user action only after a successful elevated machine child' {
        Mock -CommandName Test-AtlasAdmin -ModuleName Atlas.Toggles -MockWith { $false }
        Mock -CommandName Start-AtlasToggleAdminRelaunch -ModuleName Atlas.Toggles -MockWith {
            [IO.File]::AppendAllText($script:splitEventPath, "machine-child`n")
            [pscustomobject]@{ ExitCode = 0 }
        }
        Mock -CommandName Invoke-AtlasToggleCurrentSessionShellRefresh -ModuleName Atlas.Toggles `
            -MockWith {
                [IO.File]::AppendAllText($script:splitEventPath, "refresh`n")
            }

        Invoke-AtlasToggle -Name SplitBrokerToggle -State Enable `
            -TogglesRoot $script:toggleRoot -StateRoot $script:stateRoot

        Get-Content -LiteralPath $script:splitEventPath | Should -Be @(
            'machine-child'
            'user'
            'refresh'
        )
        Should -Invoke -CommandName Start-AtlasToggleAdminRelaunch -ModuleName Atlas.Toggles `
            -Times 1 -Exactly -ParameterFilter {
                $ArgumentList -contains '-MachineOnly' -and
                $ArgumentList -contains '/noaction'
            }
        Should -Not -Invoke -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles
        Get-AtlasToggleState -Name SplitBrokerToggle -StateRoot $script:stateRoot |
            Should -BeNullOrEmpty
    }
}

Describe 'Administrator toggle child handoff' {
    BeforeEach {
        Remove-Item -LiteralPath $script:actionMarker -Force -ErrorAction SilentlyContinue
        Mock -CommandName Test-AtlasAdmin -ModuleName Atlas.Toggles -MockWith { $false }
        Mock -CommandName Test-AtlasSystem -ModuleName Atlas.Toggles -MockWith { $false }
        Mock -CommandName Test-AtlasTrustedInstaller -ModuleName Atlas.Toggles -MockWith { $false }
        Mock -CommandName Read-Pause -ModuleName Atlas.Toggles
        Mock -CommandName Start-AtlasToggleAdminRelaunch -ModuleName Atlas.Toggles -MockWith {
            [pscustomobject]@{ ExitCode = 0 }
        }
    }

    It 'waits for the exact elevated child and never runs the action in the parent' {
        Invoke-AtlasToggle -Name AdminToggle -State Enable -TogglesRoot $script:toggleRoot

        Should -Invoke -CommandName Start-AtlasToggleAdminRelaunch -ModuleName Atlas.Toggles `
            -Times 1 -Exactly -ParameterFilter {
                $FilePath -like '*\System32\WindowsPowerShell\v1.0\powershell.exe' -and
                $ArgumentList -contains '"AdminToggle"' -and
                $ArgumentList -contains '"Enable"'
            }
        $script:actionMarker | Should -Not -Exist
    }

    It 'preserves the exact nonzero child exit for the CLI boundary' {
        Mock -CommandName Start-AtlasToggleAdminRelaunch -ModuleName Atlas.Toggles -MockWith {
            [pscustomobject]@{ ExitCode = 37 }
        }

        $failure = $null
        try {
            Invoke-AtlasToggle -Name AdminToggle -State Enable -TogglesRoot $script:toggleRoot
        }
        catch {
            $failure = $_.Exception
        }

        $failure | Should -Not -BeNullOrEmpty
        $failure.Message | Should -BeExactly "Elevated toggle 'AdminToggle' exited with code 37."
        $failure.Data['Atlas.Toggle.AdminChildExitCode'] | Should -Be 37
        $script:actionMarker | Should -Not -Exist
    }
}
