BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $driverUpdatePath = Join-Path -Path $repoRoot `
        -ChildPath 'playbook\Executables\AtlasModules\Scripts\Internal\Update-Drivers.ps1'
    $driverTogglePath = Join-Path -Path $repoRoot `
        -ChildPath 'playbook\Executables\AtlasModules\Toggles\General\UpdateDrivers.ps1'

    $script:driverToggle = & $driverTogglePath

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
    It 'rejects a missing adjacent driver script' {
        $context = [pscustomobject]@{
            ScriptsPath = Join-Path -Path $TestDrive -ChildPath 'missing-scripts'
            Silent      = $true
        }

        { & $script:driverToggle.States.Run.Action $context } |
            Should -Throw '*driver update script is missing*'
    }

    It 'forwards the exact silent state to the driver script' {
        $scriptsPath = Join-Path -Path $TestDrive -ChildPath 'Scripts'
        $internalPath = Join-Path -Path $scriptsPath -ChildPath 'Internal'
        $driverPath = Join-Path -Path $internalPath -ChildPath 'Update-Drivers.ps1'
        [void](New-Item -Path $internalPath -ItemType Directory -Force)
        [IO.File]::WriteAllText(
            $driverPath,
            "param ([switch]`$Silent)`r`n[bool]`$Silent`r`n",
            [Text.Encoding]::ASCII
        )

        foreach ($silent in @($true, $false)) {
            $context = [pscustomobject]@{
                ScriptsPath = $scriptsPath
                Silent      = $silent
            }

            (& $script:driverToggle.States.Run.Action $context) | Should -Be $silent
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
