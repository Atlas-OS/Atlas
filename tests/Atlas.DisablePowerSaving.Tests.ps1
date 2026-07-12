BeforeAll {
    $script:powerScript = Join-Path -Path (Split-Path -Parent $PSScriptRoot) `
        -ChildPath 'playbook\Executables\AtlasModules\Scripts\Internal\Set-PowerSavingState.ps1'
    . $script:powerScript -LibraryOnly
    $script:invokePowerCfg = ${function:Invoke-AtlasPowerCfg}

    $script:balanced = '381b4222-f694-41f0-9685-ff5bb260df2e'
    $script:atlas = '11111111-1111-1111-1111-111111111111'
    $script:custom = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
    $script:powerCfg = 'C:\Windows\System32\powercfg.exe'
}

Describe 'Atlas power-saving state' {
    BeforeEach {
        $script:activeQueue = New-Object 'Collections.Generic.Queue[string]'
        Mock Get-AtlasActivePowerScheme { $script:activeQueue.Dequeue() }
        Mock Get-AtlasPowerSchemeInventory { @($script:balanced, $script:custom) }
        Mock Get-AtlasPreviousPowerScheme { $null }
        Mock Save-AtlasPreviousPowerScheme { $SchemeGuid }
        Mock Clear-AtlasPreviousPowerScheme
        Mock Invoke-AtlasPowerCfg { @() }
    }

    It 'creates the Atlas plan from Balanced and applies only the four reviewed AC settings' {
        $script:activeQueue.Enqueue($script:custom)
        $script:activeQueue.Enqueue($script:atlas)

        Invoke-AtlasPowerSavingState -RequestedMode Atlas -PowerCfgPath $script:powerCfg

        Should -Invoke Save-AtlasPreviousPowerScheme -Times 1 -Exactly `
            -ParameterFilter { $SchemeGuid -ceq $script:custom }
        Should -Invoke Invoke-AtlasPowerCfg -Times 1 -Exactly -ParameterFilter {
            $ArgumentList[0] -ceq '/duplicatescheme' -and
                $ArgumentList[1] -ceq $script:balanced -and
                $ArgumentList[2] -ceq $script:atlas
        }
        Should -Invoke Invoke-AtlasPowerCfg -Times 4 -Exactly -ParameterFilter {
            $ArgumentList[0] -ceq '/setacvalueindex'
        }
        Should -Invoke Invoke-AtlasPowerCfg -Times 1 -Exactly -ParameterFilter {
            $ArgumentList[0] -ceq '/setactive' -and
                $ArgumentList[1] -ceq $script:atlas
        }
    }

    It 'recreates an existing Atlas plan without saving Atlas as the rollback target' {
        Mock Get-AtlasPowerSchemeInventory {
            @($script:balanced, $script:atlas)
        }
        $script:activeQueue.Enqueue($script:atlas)
        $script:activeQueue.Enqueue($script:atlas)

        Invoke-AtlasPowerSavingState -RequestedMode Atlas -PowerCfgPath $script:powerCfg

        Should -Invoke Save-AtlasPreviousPowerScheme -Times 1 -Exactly `
            -ParameterFilter { $SchemeGuid -ceq $script:balanced }
        Should -Invoke Invoke-AtlasPowerCfg -Times 1 -Exactly -ParameterFilter {
            $ArgumentList[0] -ceq '/delete' -and
                $ArgumentList[1] -ceq $script:atlas
        }
    }

    It 'restores an installed saved plan and then removes the Atlas plan' {
        Mock Get-AtlasPowerSchemeInventory {
            @($script:balanced, $script:custom, $script:atlas)
        }
        Mock Get-AtlasPreviousPowerScheme { $script:custom }
        $script:activeQueue.Enqueue($script:custom)

        Invoke-AtlasPowerSavingState -RequestedMode Default -PowerCfgPath $script:powerCfg

        Should -Invoke Invoke-AtlasPowerCfg -Times 1 -Exactly -ParameterFilter {
            $ArgumentList[0] -ceq '/setactive' -and
                $ArgumentList[1] -ceq $script:custom
        }
        Should -Invoke Invoke-AtlasPowerCfg -Times 1 -Exactly -ParameterFilter {
            $ArgumentList[0] -ceq '/delete' -and
                $ArgumentList[1] -ceq $script:atlas
        }
        Should -Invoke Clear-AtlasPreviousPowerScheme -Times 1 -Exactly `
            -ParameterFilter { $ExpectedSchemeGuid -ceq $script:custom }
    }

    It 'falls back to Balanced when the saved plan is no longer installed' {
        Mock Get-AtlasPowerSchemeInventory {
            @($script:balanced, $script:atlas)
        }
        Mock Get-AtlasPreviousPowerScheme { $script:custom }
        $script:activeQueue.Enqueue($script:balanced)

        Invoke-AtlasPowerSavingState -RequestedMode Default -PowerCfgPath $script:powerCfg

        Should -Invoke Invoke-AtlasPowerCfg -Times 1 -Exactly -ParameterFilter {
            $ArgumentList[0] -ceq '/setactive' -and
                $ArgumentList[1] -ceq $script:balanced
        }
    }

    It 'keeps the saved plan when the final active-plan check fails' {
        Mock Get-AtlasPowerSchemeInventory {
            @($script:balanced, $script:custom, $script:atlas)
        }
        Mock Get-AtlasPreviousPowerScheme { $script:custom }
        $script:activeQueue.Enqueue($script:balanced)

        { Invoke-AtlasPowerSavingState -RequestedMode Default `
                -PowerCfgPath $script:powerCfg } |
            Should -Throw '*expected*'

        Should -Invoke Clear-AtlasPreviousPowerScheme -Times 0 -Exactly
    }

    It 'propagates a nonzero powercfg exit code' {
        $commandProcessor = Join-Path -Path ([Environment]::SystemDirectory) `
            -ChildPath 'cmd.exe'

        { & $script:invokePowerCfg -FilePath $commandProcessor `
                -ArgumentList @('/d', '/c', 'exit 7') } |
            Should -Throw "*exit code '7'*"
    }

    It 'parses scheme GUIDs independently of localized powercfg labels' {
        $result = Get-AtlasPowerSchemeGuidFromOutput -Output @(
            ''
            "Localized label: $script:balanced"
            "Another label: $script:custom"
        )

        $result | Should -Be @($script:balanced, $script:custom)
    }
}
