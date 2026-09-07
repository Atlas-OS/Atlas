BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $driverUpdatePath = Join-Path -Path $repoRoot `
        -ChildPath 'playbook\Executables\AtlasModules\Scripts\Operations\Update-Drivers.ps1'
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $driverUpdatePath,
        [ref]$tokens,
        [ref]$errors
    )
    $functionAst = $ast.Find({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -eq 'Assert-WuaOperationSucceeded'
        }, $true)
    if ($null -eq $functionAst) {
        throw "Assert-WuaOperationSucceeded was not found in '$driverUpdatePath'."
    }
    $script:assertWuaOperationSucceeded = [scriptblock]::Create($functionAst.Extent.Text)

    $script:newWuaResult = {
        param(
            [int]$OverallCode,
            [int[]]$UpdateCodes
        )

        $updateResults = @(
            foreach ($code in $UpdateCodes) {
                [pscustomobject]@{ ResultCode = $code }
            }
        )
        $result = [pscustomobject]@{
            ResultCode    = $OverallCode
            UpdateResults = $updateResults
        }
        $result | Add-Member -MemberType ScriptMethod -Name GetUpdateResult -Value {
            param($index)
            if ($index -lt 0 -or $index -ge $this.UpdateResults.Count) {
                return $null
            }
            return $this.UpdateResults[$index]
        } -PassThru
    }
}

Describe 'Driver update toggle' {
    BeforeAll {
        Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
        Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force
        $script:driverToggle = Get-AtlasToggleDefinition -Name UpdateDrivers `
            -TogglesRoot (Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Toggles')

        function Invoke-DriverUpdateAction {
            param([Parameter(Mandatory = $true)]$Toggle)

            InModuleScope Atlas.Toggles {
                Invoke-AtlasToggleFunction -Definition $d -FunctionName 'Invoke-AtlasDriverUpdate' -Toggle $t -Label 'test'
            } -Parameters @{ d = $script:driverToggle; t = $Toggle }
        }
    }

    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Toggles
    }

    It 'is an elevated one-shot machine action that records no state' {
        $run = $script:driverToggle.States['Run']

        $script:driverToggle.Elevation | Should -BeExactly 'Admin'
        $script:driverToggle.NoStateRecord | Should -BeTrue
        $run['MachineAction'] | Should -BeExactly 'Invoke-AtlasDriverUpdate'
        $run.Contains('StateValue') | Should -BeFalse

        $work = Get-AtlasToggleStateWork -Definition $script:driverToggle -StateEntry $run
        $work.Machine | Should -BeTrue
        $work.User | Should -BeFalse
    }

    It 'rejects a missing adjacent driver script' {
        $context = [pscustomobject]@{
            Name           = 'UpdateDrivers'
            State          = 'Run'
            OperationsPath = Join-Path -Path $TestDrive -ChildPath 'missing-operations'
            Silent         = $true
        }

        { Invoke-DriverUpdateAction -Toggle $context } |
            Should -Throw '*driver update script is missing*'
    }

    It 'forwards the exact silent state to the driver script' {
        $operationsPath = Join-Path -Path $TestDrive -ChildPath 'Operations'
        $driverPath = Join-Path -Path $operationsPath -ChildPath 'Update-Drivers.ps1'
        [void](New-Item -Path $operationsPath -ItemType Directory -Force)
        [IO.File]::WriteAllText(
            $driverPath,
            "param ([switch]`$Silent)`r`n[bool]`$Silent`r`n",
            [Text.Encoding]::ASCII
        )

        foreach ($silent in @($true, $false)) {
            $context = [pscustomobject]@{
                Name           = 'UpdateDrivers'
                State          = 'Run'
                OperationsPath = $operationsPath
                Silent         = $silent
            }

            (Invoke-DriverUpdateAction -Toggle $context) | Should -Be $silent
        }
    }
}

Describe 'Windows Update Agent result validation' {
    BeforeEach {
        . $script:assertWuaOperationSucceeded
    }

    It 'accepts complete overall and per-update success' {
        $result = & $script:newWuaResult -OverallCode 2 -UpdateCodes @(2, 2)

        {
            Assert-WuaOperationSucceeded -Result $result `
                -ExpectedUpdateCount 2 -Operation 'installation'
        } | Should -Not -Throw
    }

    It 'rejects <Name>' -TestCases @(
        @{
            Name          = 'overall partial success'
            OverallCode   = 3
            UpdateCodes   = @(2)
            Message       = '*result code 3*'
        }
        @{
            Name          = 'per-update partial success'
            OverallCode   = 2
            UpdateCodes   = @(2, 3)
            Message       = '*selected update index 1*result code 3*'
        }
    ) {
        param($OverallCode, $UpdateCodes, $Message)

        $result = & $script:newWuaResult `
            -OverallCode $OverallCode -UpdateCodes $UpdateCodes

        {
            Assert-WuaOperationSucceeded -Result $result `
                -ExpectedUpdateCount @($UpdateCodes).Count -Operation 'download'
        } | Should -Throw $Message
    }

    It 'rejects a missing result for a selected update' {
        $result = & $script:newWuaResult -OverallCode 2 -UpdateCodes @(2)

        {
            Assert-WuaOperationSucceeded -Result $result `
                -ExpectedUpdateCount 2 -Operation 'download'
        } | Should -Throw '*did not return a result*index 1*'
    }
}
