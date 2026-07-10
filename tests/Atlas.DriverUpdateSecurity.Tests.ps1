BeforeAll {
    $script:repoRoot = Split-Path -Parent $PSScriptRoot
    $script:driverUpdatePath = Join-Path -Path $script:repoRoot `
        -ChildPath 'playbook\Executables\AtlasModules\Scripts\Internal\Update-Drivers.ps1'
    $script:driverUpdateSource = Get-Content -LiteralPath $script:driverUpdatePath -Raw
    $script:driverTogglePath = Join-Path -Path $script:repoRoot `
        -ChildPath 'playbook\Executables\AtlasModules\Toggles\General\UpdateDrivers.ps1'
    $script:driverToggleDefinition = & $script:driverTogglePath

    $tokens = $null
    $parseErrors = $null
    $script:driverUpdateAst = [System.Management.Automation.Language.Parser]::ParseFile(
        $script:driverUpdatePath,
        [ref]$tokens,
        [ref]$parseErrors
    )
    $script:driverUpdateParseErrors = @($parseErrors)

    $assertFunctionAst = $script:driverUpdateAst.Find(
        {
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -eq 'Assert-WuaOperationSucceeded'
        },
        $true
    )
    $script:assertWuaOperationFunction = [scriptblock]::Create($assertFunctionAst.Extent.Text)

    $script:newFakeWuaResult = {
        param (
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

Describe 'Driver update trust boundary' {
    It 'parses without PowerShell errors' {
        $script:driverUpdateParseErrors | Should -HaveCount 0
    }

    It 'establishes the protected inbox module boundary before loading Atlas code' {
        $trustBootstrap = $script:driverUpdateSource.IndexOf('. $trustBootstrap')
        $atlasCoreImport = $script:driverUpdateSource.IndexOf(
            'Microsoft.PowerShell.Core\Import-Module -Name $atlasCoreManifest'
        )
        $adminCheck = $script:driverUpdateSource.IndexOf('function Test-Admin')

        $trustBootstrap | Should -BeGreaterThan -1
        $atlasCoreImport | Should -BeGreaterThan $trustBootstrap
        $adminCheck | Should -BeGreaterThan $atlasCoreImport
        $script:driverUpdateSource | Should -Match '\[IO\.File\]::Exists\(\$trustBootstrap\)'
        $script:driverUpdateSource | Should -Match `
            '\[IO\.Path\]::ChangeExtension\(\$atlasCoreManifest, ''\.psm1''\)'
        $script:driverUpdateSource | Should -Match '\$loadedAtlasCore\[0\]\.Path'
        $script:driverUpdateSource | Should -Match `
            '\.Equals\(\s*\$atlasCoreModule,\s*\[StringComparison\]::OrdinalIgnoreCase'
        $script:driverUpdateSource | Should -Match '\[StringComparison\]::OrdinalIgnoreCase'
    }

    It 'relaunches through protected Windows PowerShell and propagates the real elevated result' {
        $script:driverUpdateSource | Should -Match `
            "GetFolderPath\(\[Environment\+SpecialFolder\]::System\)[\s\S]+?'WindowsPowerShell'[\s\S]+?'powershell\.exe'"
        $script:driverUpdateSource | Should -Match `
            'Microsoft\.PowerShell\.Management\\Start-Process @startProcessParams'
        $script:driverUpdateSource | Should -Match '-NoProfile'
        $script:driverUpdateSource | Should -Match `
            '\$startProcessParams\s*=\s*@\{[\s\S]+?Verb\s*=\s*''RunAs''[\s\S]+?Wait\s*=\s*\$true[\s\S]+?PassThru\s*=\s*\$true'
        $script:driverUpdateSource | Should -Match `
            'if\s*\(\$Silent\)\s*\{\s*\$startProcessParams\[''WindowStyle''\]\s*=\s*''Hidden''\s*\}'
        ([regex]::Matches($script:driverUpdateSource, "\['WindowStyle'\]")).Count | Should -Be 1
        $script:driverUpdateSource | Should -Match 'ErrorAction\s*=\s*''Stop'''
        $script:driverUpdateSource | Should -Match 'NativeErrorCode -eq 1223'
        $script:driverUpdateSource | Should -Match 'exit \(\[int\]\$elevatedProcess\.ExitCode\)'
        $script:driverUpdateSource | Should -Match `
            'WorkingDirectory\s*=\s*\[Environment\]::GetFolderPath'
        $script:driverUpdateSource | Should -Not -Match '-FilePath\s+["'']powershell(?:\.exe)?["'']'
        $script:driverUpdateSource | Should -Not -Match '\$PSHOME'
    }

    It 'fails closed when the adjacent driver script is missing' {
        $context = [pscustomobject]@{
            ScriptsPath = Join-Path -Path $TestDrive -ChildPath 'missing-scripts'
            Silent      = $true
        }

        {
            & $script:driverToggleDefinition.States.Run.Action $context
        } | Should -Throw '*driver update script is missing*'
    }

    It 'forwards the exact toggle silent state to the driver script' {
        $scriptsPath = Join-Path -Path $TestDrive -ChildPath 'Scripts'
        $internalPath = Join-Path -Path $scriptsPath -ChildPath 'Internal'
        $fakeDriverPath = Join-Path -Path $internalPath -ChildPath 'Update-Drivers.ps1'
        [void](New-Item -Path $internalPath -ItemType Directory -Force)
        [IO.File]::WriteAllText(
            $fakeDriverPath,
            "param ([switch]`$Silent)`n[bool]`$Silent`n",
            [Text.Encoding]::ASCII
        )

        $silentContext = [pscustomobject]@{
            ScriptsPath = $scriptsPath
            Silent      = $true
        }
        $interactiveContext = [pscustomobject]@{
            ScriptsPath = $scriptsPath
            Silent      = $false
        }

        (& $script:driverToggleDefinition.States.Run.Action $silentContext) | Should -BeTrue
        (& $script:driverToggleDefinition.States.Run.Action $interactiveContext) | Should -BeFalse
    }

    It 'has no gallery, package-provider, or PSWindowsUpdate execution path' {
        $script:driverUpdateSource | Should -Not -Match `
            '(?i)\b(?:Install-Module|Install-PackageProvider|Get-PackageProvider|PSWindowsUpdate)\b'
        $script:driverUpdateSource | Should -Not -Match `
            '(?i)\b(?:Get-WUList|Get-WUInstall|Add-WUServiceManager)\b'
    }

    It 'activates only the fixed inbox Windows Update Agent coclasses' {
        $script:driverUpdateSource | Should -Match `
            "\[Guid\]'f8d253d9-89a4-4daa-87b6-1168369f0b21'"
        $script:driverUpdateSource | Should -Match `
            "\[Guid\]'4cb43d7f-7eee-4906-8698-60da1c38f2fe'"
        $script:driverUpdateSource | Should -Match `
            "\[Guid\]'13639463-00db-4646-803d-528026140d88'"
        $script:driverUpdateSource | Should -Match '\[Type\]::GetTypeFromCLSID\(\$classId, \$true\)'
        $script:driverUpdateSource | Should -Match '\[Activator\]::CreateInstance\(\$comType\)'
        $script:driverUpdateSource | Should -Match 'return ,\$instance'
        $script:driverUpdateSource | Should -Not -Match 'GetTypeFromProgID|New-Object\s+-ComObject'
    }

    It 'registers and searches Microsoft Update for pending visible drivers only' {
        $script:driverUpdateSource | Should -Match `
            "\$script:MicrosoftUpdateServiceId = '7971f918-a847-4430-9279-4a52d1efe18d'"
        $script:driverUpdateSource | Should -Match `
            'AddService2\([\s\S]+?\$script:MicrosoftUpdateServiceId,[\s\S]+?7,[\s\S]+?'''''
        $script:driverUpdateSource | Should -Match '\$registration\.RegistrationState -ne 3'
        $script:driverUpdateSource | Should -Match '\$service\.ServiceID'
        $script:driverUpdateSource | Should -Match '\$service\.IsRegisteredWithAU'
        $script:driverUpdateSource | Should -Match '\$searcher\.ServerSelection = 3'
        $script:driverUpdateSource | Should -Match `
            '\$searcher\.ServiceID = \$script:MicrosoftUpdateServiceId'
        $script:driverUpdateSource | Should -Match `
            '\.Search\("IsInstalled=0 and IsHidden=0 and Type=''Driver''"\)'
    }

    It 'carries the exact selected update objects into the download and install collections' {
        $script:driverUpdateSource | Should -Match '\$item\.Tag = \$update'
        $script:driverUpdateSource | Should -Match '\$selectedUpdates \+= \$selected\.Tag'
        $script:driverUpdateSource | Should -Match '\[void\]\$collection\.Add\(\$update\)'
        $script:driverUpdateSource | Should -Match 'return ,\$collection'
        $script:driverUpdateSource | Should -Match '\$downloader\.Updates = \$selectedUpdates'
        $script:driverUpdateSource | Should -Match '\$installer\.Updates = \$selectedUpdates'
        ([regex]::Matches($script:driverUpdateSource, '\.Search\(')).Count | Should -Be 1
    }

    It 'turns restart initiation failures into terminating script failures' {
        ([regex]::Matches(
                $script:driverUpdateSource,
                'Microsoft\.PowerShell\.Management\\Restart-Computer -Force -ErrorAction Stop'
            )).Count | Should -Be 2
        $script:driverUpdateSource | Should -Not -Match '(?m)^\s*Restart-Computer\b'
    }
}

Describe 'Windows Update Agent result validation' {
    It 'accepts only complete overall and per-update success' {
        . $script:assertWuaOperationFunction
        $result = & $script:newFakeWuaResult -OverallCode 2 -UpdateCodes @(2, 2)

        {
            Assert-WuaOperationSucceeded -Result $result `
                -ExpectedUpdateCount 2 -Operation 'installation'
        } | Should -Not -Throw
    }

    It 'rejects an overall partial-success result' {
        . $script:assertWuaOperationFunction
        $result = & $script:newFakeWuaResult -OverallCode 3 -UpdateCodes @(2)

        {
            Assert-WuaOperationSucceeded -Result $result `
                -ExpectedUpdateCount 1 -Operation 'download'
        } | Should -Throw '*result code 3*'
    }

    It 'rejects a per-update partial-success result' {
        . $script:assertWuaOperationFunction
        $result = & $script:newFakeWuaResult -OverallCode 2 -UpdateCodes @(2, 3)

        {
            Assert-WuaOperationSucceeded -Result $result `
                -ExpectedUpdateCount 2 -Operation 'installation'
        } | Should -Throw '*selected update index 1*result code 3*'
    }

    It 'rejects a missing result for any selected update' {
        . $script:assertWuaOperationFunction
        $result = & $script:newFakeWuaResult -OverallCode 2 -UpdateCodes @(2)

        {
            Assert-WuaOperationSucceeded -Result $result `
                -ExpectedUpdateCount 2 -Operation 'download'
        } | Should -Throw '*did not return a result*index 1*'
    }
}
