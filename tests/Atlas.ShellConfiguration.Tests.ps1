[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidGlobalVars',
    '',
    Justification = 'Extracted new-user functions resolve their script-level state dynamically, so fixtures must be staged as global variables.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter',
    '',
    Justification = 'AST helper parameters are consumed inside FindAll predicates and process doubles declare the surface of the commands they shadow.'
)]
param()

BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module -Name (Join-Path $PSScriptRoot '..\playbook\Executables\AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path $PSScriptRoot '..\playbook\Executables\AtlasModules\Scripts\Modules\Atlas.Registry\Atlas.Registry.psd1') -Force
    Import-Module -Name (Join-Path $PSScriptRoot '..\playbook\Executables\AtlasModules\Scripts\Modules\Atlas.Toggles\Atlas.Toggles.psd1') -Force
    $script:searchRefusal = InModuleScope Atlas.Registry {
        New-AtlasRegistryValueRefusedRecord -ProviderPath 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\SearchSettings' `
            -Name IsAADCloudSearchEnabled -Cause ([UnauthorizedAccessException]::new('Access denied'))
    }
    function Import-FunctionUnderTest {
        param(
            [Parameter(Mandatory = $true)][string]$Path,
            [Parameter(Mandatory = $true)][string]$Name
        )

        $tokens = $null
        $errors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile(
            $Path, [ref]$tokens, [ref]$errors
        )
        @($errors).Count | Should -Be 0
        $definition = $ast.Find({
                param($node)
                $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -eq $Name
            }, $true)
        $definition | Should -Not -BeNullOrEmpty
        Set-Item -Path "Function:\global:$Name" -Value $definition.Body.GetScriptBlock()
    }

    $script:newUserScript = Resolve-Path (Join-Path $PSScriptRoot `
            '..\playbook\Executables\AtlasModules\Scripts\Entry\Initialize-NewUser.ps1')
    Import-FunctionUnderTest -Path $script:newUserScript -Name Get-SetupMarker
    Import-FunctionUnderTest -Path $script:newUserScript -Name Set-SetupMarker
    Import-FunctionUnderTest -Path $script:newUserScript -Name Invoke-AtlasDesktopCommand
    Import-FunctionUnderTest -Path $script:newUserScript -Name Invoke-CurrentSessionExplorerRefresh
    Import-FunctionUnderTest -Path $script:newUserScript -Name Set-AtlasFirstLogonPreferences
    Import-FunctionUnderTest -Path $script:newUserScript -Name Set-SearchTaskbarMode
    Import-FunctionUnderTest -Path $script:newUserScript -Name Test-BuiltInAdministrator
    Import-FunctionUnderTest -Path $script:newUserScript -Name Test-FullAdministratorToken
    Import-FunctionUnderTest -Path $script:newUserScript -Name Get-UserSetupTokenBlock

    $tokens = $null
    $errors = $null
    $script:newUserAst = [Management.Automation.Language.Parser]::ParseFile(
        $script:newUserScript, [ref]$tokens, [ref]$errors
    )
    @($errors).Count | Should -Be 0

    function Find-CommandAst {
        param(
            [Parameter(Mandatory = $true)]$Ast,
            [Parameter(Mandatory = $true)][string]$Name
        )

        @($Ast.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.CommandAst] -and
                    $node.GetCommandName() -eq $Name
                }, $true))
    }

    function Find-StringConstant {
        param(
            [Parameter(Mandatory = $true)]$Ast,
            [Parameter(Mandatory = $true)][string]$Value
        )

        @($Ast.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.StringConstantExpressionAst] -and
                    $node.Value -eq $Value
                }, $true))
    }

    function Get-AncestorIfCondition {
        param([Parameter(Mandatory = $true)]$Ast)

        for ($node = $Ast.Parent; $null -ne $node; $node = $node.Parent) {
            if ($node -is [Management.Automation.Language.IfStatementAst]) {
                return $node.Clauses[0].Item1.Extent.Text.Trim()
            }
        }
        return $null
    }

    # First sign-in writes the Web Search state's user values itself, so read them from
    # the definition: its search-box mode, and its SearchSettings values that carry data.
    function Get-WebSearchUserState {
        param([Parameter(Mandatory = $true)][string]$State)

        $definition = Import-PowerShellDataFile -LiteralPath (Join-Path $script:AtlasTestScriptsRoot '..\Toggles\General\WebSearch.psd1')
        $registry = @(@($definition.States | Where-Object { $_.Name -ceq $State })[0].Registry)
        $modes = @($registry | Where-Object { $_.Name -ceq 'SearchboxTaskbarMode' -and $_.ContainsKey('Data') })
        $modes.Count | Should -Be 1
        [pscustomobject]@{
            Mode     = $modes[0].Data
            Settings = @($registry | Where-Object { $_.Path -like '*\SearchSettings' -and $_.ContainsKey('Data') })
        }
    }

    # Returns the AST of the argument bound to -Name on one command: either the
    # attached '-Name:value' argument or the element that follows the parameter.
    function Get-CommandParameterArgument {
        param(
            [Parameter(Mandatory = $true)]$Command,
            [Parameter(Mandatory = $true)][string]$Name
        )

        $elements = @($Command.CommandElements)
        for ($index = 0; $index -lt $elements.Count; $index++) {
            $element = $elements[$index]
            if ($element -is [Management.Automation.Language.CommandParameterAst] -and
                $element.ParameterName -eq $Name) {
                if ($null -ne $element.Argument) {
                    return $element.Argument
                }
                if ($index + 1 -lt $elements.Count) {
                    return $elements[$index + 1]
                }
                return $null
            }
        }
        return $null
    }
}

AfterAll {
    Remove-Item Function:\Set-SearchTaskbarMode -ErrorAction SilentlyContinue
    Remove-Item Function:\Set-AtlasFirstLogonPreferences -ErrorAction SilentlyContinue
    Remove-Item Function:\Get-SetupMarker -ErrorAction SilentlyContinue
    Remove-Item Function:\Set-SetupMarker -ErrorAction SilentlyContinue
    Remove-Item Function:\Invoke-AtlasDesktopCommand -ErrorAction SilentlyContinue
    Remove-Item Function:\Invoke-CurrentSessionExplorerRefresh -ErrorAction SilentlyContinue
    Remove-Item Function:\Test-BuiltInAdministrator -ErrorAction SilentlyContinue
    Remove-Item Function:\Test-FullAdministratorToken -ErrorAction SilentlyContinue
    Remove-Item Function:\Get-UserSetupTokenBlock -ErrorAction SilentlyContinue
}

Describe 'First-logon search preferences' {
    BeforeEach {
        $global:windir = [Environment]::GetFolderPath('Windows')
        $global:sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        InModuleScope Atlas.Registry { $script:AtlasRegistryIdentityContext = $null }
        Mock Import-Module {}
        Mock Test-Path { $true }
        Mock Set-ItemProperty {}
        Mock Write-AtlasLog -ModuleName Atlas.Registry {}
        Mock Invoke-AtlasRegistryTargetOperation -ModuleName Atlas.Registry {
            throw $script:searchRefusal
        } -ParameterFilter { $Path -eq 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' }
        # Keep this PC's own Atlas choices out of the default case.
        Mock Get-ItemProperty { $null } -ParameterFilter { $Path -eq 'HKLM:\SOFTWARE\AtlasOS\Services\WebSearch' }
    }
    AfterEach {
        Remove-Variable windir, sid -Scope Global -ErrorAction SilentlyContinue
    }

    It 'keeps a recorded Enable Web Search choice instead of the Atlas default' {
        $script:webSearchState = Get-WebSearchUserState -State 'Enable'
        Mock Get-ItemProperty { [pscustomobject]@{ state = 1 } } -ParameterFilter {
            $Path -eq 'HKLM:\SOFTWARE\AtlasOS\Services\WebSearch' -and $Name -eq 'state'
        }
        Mock Invoke-AtlasRegistryEntries {}

        Set-SearchTaskbarMode

        # The cache mirrors the mode, so it takes the definition's mode too.
        Should -Invoke Set-ItemProperty -Times 2 -Exactly -ParameterFilter {
            $Path -eq 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -and
            $Name -in @('SearchboxTaskbarMode', 'SearchboxTaskbarModeCache') -and
            $Value -eq $script:webSearchState.Mode
        }
        Should -Invoke Set-ItemProperty -Times 2 -Exactly
        Should -Invoke Invoke-AtlasRegistryEntries -Times 1 -Exactly -ParameterFilter {
            $written = @($Entries | ForEach-Object { '{0}={1}' -f $_.Name, $_.Data } | Sort-Object)
            $expected = @($script:webSearchState.Settings | ForEach-Object { '{0}={1}' -f $_.Name, $_.Data } | Sort-Object)
            $expected.Count -gt 0 -and ($written -join ';') -ceq ($expected -join ';')
        }
    }

    It 'applies the Atlas default when the recorded Web Search choice is <Recorded>' -ForEach @(
        @{ Recorded = 'Disable'; Record = [pscustomobject]@{ state = 0 } }
        @{ Recorded = 'a string'; Record = [pscustomobject]@{ state = '1' } }
    ) {
        $script:webSearchState = Get-WebSearchUserState -State 'Disable'
        Mock Get-ItemProperty { $Record } -ParameterFilter {
            $Path -eq 'HKLM:\SOFTWARE\AtlasOS\Services\WebSearch' -and $Name -eq 'state'
        }
        Mock Invoke-AtlasRegistryEntries {}

        Set-SearchTaskbarMode

        Should -Invoke Set-ItemProperty -Times 2 -Exactly -ParameterFilter {
            $Name -in @('SearchboxTaskbarMode', 'SearchboxTaskbarModeCache') -and
            $Value -eq $script:webSearchState.Mode
        }
        # Every value written is the default state's own value for it.
        Should -Invoke Invoke-AtlasRegistryEntries -Times 1 -Exactly -ParameterFilter {
            $expected = @($script:webSearchState.Settings | ForEach-Object { '{0}={1}' -f $_.Name, $_.Data })
            @($Entries).Count -eq 4 -and
            @($Entries | Where-Object { $expected -notcontains ('{0}={1}' -f $_.Name, $_.Data) }).Count -eq 0
        }
    }

    It 'reads the Web Search record without Atlas.Toggles, which the delayed finalizer does not load' {
        $definition = $script:newUserAst.Find({
                param($node)
                $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -eq 'Set-SearchTaskbarMode'
            }, $true)
        $togglesCommands = @((Import-PowerShellDataFile -LiteralPath (Join-Path $script:AtlasTestModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1')).FunctionsToExport)
        $used = @(Find-CommandAst -Ast $definition.Body -Name 'Get-ItemProperty')
        $used.Count | Should -Be 1
        @($definition.Body.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.CommandAst] -and
                    $node.GetCommandName() -in $togglesCommands
                }, $true)).Count | Should -Be 0
    }

    It 'finishes search finalization when Windows refuses its optional preferences' {
        { Set-SearchTaskbarMode } | Should -Not -Throw
        Should -Invoke Set-ItemProperty -Times 2 -Exactly -ParameterFilter {
            $Path -eq 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -and
            $Name -in @('SearchboxTaskbarMode', 'SearchboxTaskbarModeCache') -and $Value -eq 1
        }
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Registry -Times 4 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -match 'Continuing without'
        }
    }

    It 'does not hide unrelated failures while finishing search setup' {
        Mock Invoke-AtlasRegistryTargetOperation -ModuleName Atlas.Registry {
            throw 'Unexpected registry failure'
        } -ParameterFilter { $Path -eq 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' }
        { Set-SearchTaskbarMode } | Should -Throw '*Unexpected registry failure*'
    }
}

Describe 'Later-account setup with a full administrator token' {
    BeforeAll {
        $statements = @($script:newUserAst.EndBlock.Statements)
        $script:tokenGate = @($statements | Where-Object {
                $_ -is [Management.Automation.Language.IfStatementAst] -and
                @(Find-CommandAst -Ast $_ -Name 'Write-Warning' |
                        Where-Object { $_.Extent.Text -like '*skipped user setup*' }).Count -gt 0
            })
        $script:moduleImports = @($statements | Where-Object {
                $_ -is [Management.Automation.Language.ForEachStatementAst] -and
                @(Find-CommandAst -Ast $_ -Name 'Import-Module').Count -gt 0
            })
        $script:filesCheck = @($statements | Where-Object {
                $_ -is [Management.Automation.Language.IfStatementAst] -and
                $_.Clauses[0].Item1.Extent.Text -like '*`[IO.File`]::Exists($bootstrap)*' -and
                $_.Clauses[0].Item2.Extent.Text -like '*user-setup files are missing*'
            })
        $script:retryWrites = @(Find-CommandAst -Ast $script:newUserAst -Name 'Set-ItemProperty' | Where-Object {
                $nameArgument = Get-CommandParameterArgument -Command $_ -Name 'Name'
                $null -ne $nameArgument -and $nameArgument.Extent.Text -ceq 'RunScript'
            })
        # The token check, the sign-in retry and the gate, run on their own.
        $checkStart = @($statements | Where-Object {
                $_ -is [Management.Automation.Language.AssignmentStatementAst] -and
                $_.Left.Extent.Text -eq '$tokenBlock'
            })[0].Extent.StartOffset
        $script:tokenCheck = [scriptblock]::Create("param(`$FromInstall)`n" +
            $script:newUserAst.Extent.Text.Substring($checkStart, $script:tokenGate[0].Extent.EndOffset - $checkStart))
    }

    BeforeEach {
        $script:principal = [pscustomobject]@{ IsAdmin = $true } |
            Add-Member -MemberType ScriptMethod -Name IsInRole -Value { $this.IsAdmin } -PassThru
        Mock New-Object { $script:principal } -ParameterFilter { $TypeName -eq 'Security.Principal.WindowsPrincipal' }
        Mock Test-BuiltInAdministrator { $false }
        Mock Get-ItemProperty { $null } -ParameterFilter { $Name -eq 'FilterAdministratorToken' }
        Mock Test-Path { $true }
        Mock New-Item {}
        Mock Set-ItemProperty {}
        Mock Write-Warning {}
    }

    It 'returns <Expected> for an administrator token <Admin> with EnableLUA <EnableLua>' -ForEach @(
        @{ Admin = $false; EnableLua = 0; Expected = $null }
        @{ Admin = $true; EnableLua = 0; Expected = 'UacOff' }
        @{ Admin = $true; EnableLua = $null; Expected = 'UacOff' }
        @{ Admin = $true; EnableLua = 1; Expected = 'BuiltInAdministrator' }
    ) {
        $script:principal.IsAdmin = $Admin
        Mock Get-ItemProperty { if ($null -ne $EnableLua) { [pscustomobject]@{ EnableLUA = $EnableLua } } } -ParameterFilter { $Name -eq 'EnableLUA' }

        Get-UserSetupTokenBlock | Should -Be $Expected
    }

    It 'warns and <Retry> the sign-in retry for <Account> when EnableLUA is <EnableLua>' -ForEach @(
        @{ Account = 'another administrator'; BuiltIn = $false; ApprovalMode = $null; EnableLua = 0; Retry = 'keeps'; RetryCount = 1; Reason = '*(UAC) is off*' }
        @{ Account = 'another administrator'; BuiltIn = $false; ApprovalMode = $null; EnableLua = $null; Retry = 'keeps'; RetryCount = 1; Reason = '*(UAC) is off*' }
        @{ Account = 'another administrator'; BuiltIn = $false; ApprovalMode = $null; EnableLua = 1; Retry = 'drops'; RetryCount = 0; Reason = '*built-in Administrator*' }
        @{ Account = 'the built-in Administrator'; BuiltIn = $true; ApprovalMode = $null; EnableLua = 0; Retry = 'drops'; RetryCount = 0; Reason = '*built-in Administrator*' }
        @{ Account = 'the built-in Administrator in Admin Approval Mode'; BuiltIn = $true; ApprovalMode = 1; EnableLua = 0; Retry = 'keeps'; RetryCount = 1; Reason = '*(UAC) is off*' }
    ) {
        Mock Get-ItemProperty { if ($null -ne $EnableLua) { [pscustomobject]@{ EnableLUA = $EnableLua } } } -ParameterFilter { $Name -eq 'EnableLUA' }
        Mock Test-BuiltInAdministrator { $BuiltIn }
        if ($null -ne $ApprovalMode) {
            Mock Get-ItemProperty { [pscustomobject]@{ FilterAdministratorToken = $ApprovalMode } } -ParameterFilter { $Name -eq 'FilterAdministratorToken' }
        }

        & $script:tokenCheck -FromInstall $false

        # A retry helps only when turning UAC on gives the account a standard token, which
        # it doesn't for the built-in Administrator outside Admin Approval Mode.
        Should -Invoke Set-ItemProperty -Times $RetryCount -Exactly -ParameterFilter { $Name -eq 'RunScript' }
        Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter { $Message -like $Reason }
    }

    It 'queues the sign-in retry and carries on for a standard user token' {
        $script:principal.IsAdmin = $false

        & $script:tokenCheck -FromInstall $false

        Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter { $Name -eq 'RunScript' }
        Should -Invoke Write-Warning -Times 0 -Exactly
    }

    It 'stops before the user-setup files are checked or any module is imported' {
        $script:tokenGate.Count | Should -Be 1
        $script:moduleImports.Count | Should -Be 1
        $script:filesCheck.Count | Should -Be 1
        $returns = @($script:tokenGate[0].Clauses[0].Item2.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.ReturnStatementAst]
                }, $true))
        $returns.Count | Should -BeGreaterThan 0
        $gateEnd = $script:tokenGate[0].Extent.EndOffset
        $gateEnd | Should -BeLessThan $script:filesCheck[0].Extent.StartOffset
        $gateEnd | Should -BeLessThan $script:moduleImports[0].Extent.StartOffset
    }

    It 'queues the sign-in retry before stopping, decided by the same token check' {
        $script:retryWrites.Count | Should -Be 1
        $script:retryWrites[0].Extent.EndOffset | Should -BeLessThan $script:tokenGate[0].Extent.StartOffset

        $retryCondition = $null
        for ($node = $script:retryWrites[0].Parent; $null -ne $node; $node = $node.Parent) {
            if ($node -is [Management.Automation.Language.IfStatementAst]) {
                $retryCondition = $node.Clauses[0].Item1
                break
            }
        }
        $retryCondition | Should -Not -BeNullOrEmpty
        $variablesIn = {
            param($Ast)
            @($Ast.FindAll({
                        param($node)
                        $node -is [Management.Automation.Language.VariableExpressionAst]
                    }, $true) | ForEach-Object { $_.VariablePath.UserPath } | Sort-Object -Unique)
        }
        $retryVariables = & $variablesIn $retryCondition
        $retryVariables | Should -Contain 'FromInstall'
        $gateVariables = & $variablesIn $script:tokenGate[0].Clauses[0].Item1
        @($gateVariables | Where-Object { $retryVariables -contains $_ }).Count | Should -BeGreaterThan 0
    }
}

Describe 'First-logon preferences after Windows profile creation' {
    BeforeEach {
        Mock Test-AtlasSystem { $false }
        Mock Test-AtlasAdmin { $false }
        Mock Get-AtlasToggleState { $null }
        Mock Test-Path { $true }
        Mock New-Item {}
        Mock Set-ItemProperty {}
    }

    It 'repairs the three observed user preferences without a machine write' {
        Set-AtlasFirstLogonPreferences

        Should -Invoke Set-ItemProperty -Times 3 -Exactly
        Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $LiteralPath -eq 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' -and
            $Name -eq 'GlobalUserDisabled' -and $Value -eq 1
        }
        Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $LiteralPath -eq 'HKCU:\Software\Classes\CLSID\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}' -and
            $Name -eq 'System.IsPinnedToNameSpaceTree' -and $Value -eq 0
        }
        Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $LiteralPath -eq 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -and
            $Name -eq 'ContentDeliveryAllowed' -and $Value -eq 0
        }
    }

    It 'leaves recorded state <RecordedState> to the normal toggle replay' -TestCases @(
        @{ RecordedState = 0 }
        @{ RecordedState = 1 }
    ) {
        param($RecordedState)
        Mock Get-AtlasToggleState { [pscustomobject]@{ State = $RecordedState } }

        Set-AtlasFirstLogonPreferences

        Should -Invoke Set-ItemProperty -Times 0 -Exactly
        Should -Invoke New-Item -Times 0 -Exactly
    }

    It 'rejects elevated execution before reading choices or writing preferences' {
        Mock Test-AtlasAdmin { $true }

        { Set-AtlasFirstLogonPreferences } | Should -Throw '*non-elevated*'

        Should -Invoke Get-AtlasToggleState -Times 0 -Exactly
        Should -Invoke Set-ItemProperty -Times 0 -Exactly
    }

    It 'applies defaults before recorded user choices and only outside installation' {
        $defaults = @(Find-CommandAst -Ast $script:newUserAst -Name 'Set-AtlasFirstLogonPreferences')
        $replay = @(Find-CommandAst -Ast $script:newUserAst -Name 'Invoke-AtlasToggleUserReapply')
        $defaults.Count | Should -Be 1
        $replay.Count | Should -Be 1
        Get-AncestorIfCondition -Ast $defaults[0] | Should -Be '-not $FromInstall'
        $defaults[0].Extent.EndOffset | Should -BeLessThan $replay[0].Extent.StartOffset
    }
}

Describe 'Taskbar tweak install resilience' {
    It 'keeps live Taskband seed writes best-effort' {
        $definitionPath = Join-Path $PSScriptRoot `
            '..\playbook\Executables\AtlasModules\Scripts\Tweaks\qol\taskbar\config-pins.psd1'
        $definition = Import-PowerShellDataFile -LiteralPath $definitionPath

        @($definition.Registry).Count | Should -BeGreaterThan 0
        foreach ($entry in @($definition.Registry)) {
            $entry.Path | Should -Match '(?i)\\Explorer\\Taskband(?:\\|$)'
            $entry.IgnoreErrors | Should -BeTrue
        }
    }
}

Describe 'Installing-user setup marker state' {
    BeforeEach {
        $global:markerSubKey = 'Software\AtlasRewriteTest\UserSetup'
        $global:markerPath = "HKCU:\$global:markerSubKey"
        $global:sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    }

    AfterEach {
        Remove-Item -Path 'HKCU:\Software\AtlasRewriteTest' -Recurse -Force `
            -ErrorAction SilentlyContinue
        Remove-Variable -Name markerSubKey, markerPath, sid -Scope Global `
            -ErrorAction SilentlyContinue
    }

    It 'round-trips the per-SID setup stages' {
        Set-SetupMarker -Value 1
        Get-SetupMarker | Should -Be 1

        Set-SetupMarker -Value 2
        Get-SetupMarker | Should -Be 2
    }

    It 'reads stage zero for no marker, a marker of the wrong type or one belonging to another SID' {
        Get-SetupMarker | Should -Be 0

        $null = New-Item -Path $global:markerPath -Force
        Set-ItemProperty -Path $global:markerPath -Name $global:sid -Value '2' `
            -Type String -Force
        Get-SetupMarker | Should -Be 0

        Remove-ItemProperty -Path $global:markerPath -Name $global:sid -Force
        Set-ItemProperty -Path $global:markerPath -Name 'S-1-5-21-1-2-3-1001' -Value 2 `
            -Type DWord -Force
        Get-SetupMarker | Should -Be 0
    }
}

Describe 'Installing-user desktop command and Explorer refresh' {
    BeforeEach {
        $global:atlasDesktop = Join-Path $TestDrive 'AtlasDesktop'
        $null = New-Item -Path $global:atlasDesktop -ItemType Directory -Force
    }

    AfterEach {
        Remove-Variable -Name atlasDesktop -Scope Global -ErrorAction SilentlyContinue
    }

    It 'runs an Atlas desktop command silently and accepts a zero exit code' {
        $probe = Join-Path $global:atlasDesktop 'probe.cmd'
        $argumentLog = Join-Path $TestDrive 'desktop-command-args.txt'
        Set-Content -LiteralPath $probe -Value "@echo %*> `"$argumentLog`"`r`n@exit /b 0" `
            -Encoding Ascii

        { Invoke-AtlasDesktopCommand -RelativePath 'probe.cmd' } | Should -Not -Throw
        (Get-Content -LiteralPath $argumentLog -Raw).Trim() | Should -BeExactly '/silent /noaction'
    }

    It 'fails loudly when a desktop command exits nonzero or is missing' {
        $failing = Join-Path $global:atlasDesktop 'failing.cmd'
        Set-Content -LiteralPath $failing -Value '@exit /b 5' -Encoding Ascii

        { Invoke-AtlasDesktopCommand -RelativePath 'failing.cmd' } |
            Should -Throw '*exited with code 5*'
        { Invoke-AtlasDesktopCommand -RelativePath 'missing.cmd' } |
            Should -Throw '*was not found*'
    }

    It 'restarts only Explorer processes in the current session' {
        # Loosely-typed doubles: the real Stop-Process cannot bind fake process
        # objects, and the refresh must never touch this session's real Explorer.
        $currentSessionId = [Diagnostics.Process]::GetCurrentProcess().SessionId
        $global:explorerRefreshFakes = @(
            [pscustomobject]@{ SessionId = $currentSessionId; Name = 'explorer'; Id = 101 }
            [pscustomobject]@{ SessionId = $currentSessionId + 7; Name = 'explorer'; Id = 202 }
        )
        $global:explorerRefreshStopped = [Collections.Generic.List[object]]::new()
        function global:Get-Process {
            param($Name, $ErrorAction)
            return $global:explorerRefreshFakes
        }
        function global:Stop-Process {
            param($InputObject, [switch]$Force, $ErrorAction)
            $global:explorerRefreshStopped.Add($InputObject)
        }

        try {
            Invoke-CurrentSessionExplorerRefresh
        }
        finally {
            Remove-Item Function:\Get-Process -ErrorAction SilentlyContinue
            Remove-Item Function:\Stop-Process -ErrorAction SilentlyContinue
        }

        @($global:explorerRefreshStopped).Count | Should -Be 1
        $global:explorerRefreshStopped[0].Id | Should -Be 101
        Remove-Variable -Name explorerRefreshFakes, explorerRefreshStopped -Scope Global `
            -ErrorAction SilentlyContinue
    }
}

Describe 'Installing-user shell completion flow' {
    It 'imports the module of every Atlas command it calls, and stops if one is missing' {
        $owners = @{}
        foreach ($module in Get-ChildItem -LiteralPath $script:AtlasTestModulesRoot -Directory) {
            $manifest = Import-PowerShellDataFile -LiteralPath (Join-Path $module.FullName "$($module.Name).psd1")
            foreach ($name in @($manifest.FunctionsToExport)) {
                $owners[$name] = $module.Name
            }
        }

        $importLoops = @($script:newUserAst.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.ForEachStatementAst] -and
                    @(Find-CommandAst -Ast $node.Body -Name 'Import-Module').Count -gt 0
                }, $true))
        $importLoops.Count | Should -Be 1
        $imported = @($importLoops[0].Condition.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.StringConstantExpressionAst]
                }, $true) | ForEach-Object { $_.Value })
        $imported += @(Find-CommandAst -Ast $script:newUserAst -Name 'Import-Module' | ForEach-Object {
                [regex]::Matches($_.Extent.Text, 'Atlas\.[A-Za-z]+') | ForEach-Object { $_.Value }
            })

        $used = @($script:newUserAst.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.CommandAst]
                }, $true) | ForEach-Object { $_.GetCommandName() } |
                Where-Object { $_ -and $owners.ContainsKey($_) } |
                ForEach-Object { $owners[$_] } | Sort-Object -Unique)
        $used.Count | Should -BeGreaterThan 0
        foreach ($module in $used) {
            $imported | Should -Contain $module
        }

        $importCommand = @(Find-CommandAst -Ast $importLoops[0].Body -Name 'Import-Module')[0]
        $parameterNames = @($importCommand.CommandElements | Where-Object {
                $_ -is [Management.Automation.Language.CommandParameterAst]
            } | ForEach-Object { $_.ParameterName })
        $parameterNames | Should -Contain 'Force'
        (Get-CommandParameterArgument -Command $importCommand -Name 'ErrorAction').SafeGetValue() |
            Should -BeExactly 'Stop'
    }

    It 'includes every icon it uses, because setup stops without one' {
        $atlasModulesRoot = Split-Path -Parent $script:AtlasTestScriptsRoot
        $icons = @($script:newUserAst.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.StringConstantExpressionAst] -and
                    $node.Value -like '*.ico'
                }, $true))

        $icons.Count | Should -BeGreaterThan 0
        foreach ($icon in $icons) {
            Join-Path $atlasModulesRoot $icon.Value | Should -Exist
        }
    }

    It 'runs <Script> only for later accounts, bound to the exact user' -ForEach @(
        @{ Script = 'Remove-OneDriveCurrentUserData.ps1'; Conditions = @('-not $FromInstall') }
        @{
            Script     = 'Remove-EdgeCurrentUserData.ps1'
            Conditions = @('Test-Path -LiteralPath $uninstallEdgeFlag -PathType Leaf', '-not $FromInstall')
        }
    ) {
        $cleanupStrings = Find-StringConstant -Ast $script:newUserAst -Value "Scripts\Operations\$Script"
        $cleanupStrings.Count | Should -Be 1

        # The launch is '& (Join-Path ...) -ExpectedUserSid $sid'; take the outermost
        # command, not the nested Join-Path.
        $cleanupCommand = $null
        for ($node = $cleanupStrings[0].Parent; $null -ne $node; $node = $node.Parent) {
            if ($node -is [Management.Automation.Language.CommandAst]) {
                $cleanupCommand = $node
            }
        }
        $cleanupCommand | Should -Not -BeNullOrEmpty
        (Get-CommandParameterArgument -Command $cleanupCommand -Name 'ExpectedUserSid').VariablePath.UserPath |
            Should -Be 'sid'

        $ifConditions = [Collections.Generic.List[string]]::new()
        for ($node = $cleanupCommand.Parent; $null -ne $node; $node = $node.Parent) {
            if ($node -is [Management.Automation.Language.IfStatementAst]) {
                $ifConditions.Add($node.Clauses[0].Item1.Extent.Text.Trim())
            }
        }
        $ifConditions -join ' | ' | Should -BeExactly ($Conditions -join ' | ')
    }

    It 'commits setup marker 2 before refreshing Explorer on the install and later-account paths' {
        $fromInstallCompletion = $script:newUserAst.Find({
                param($node)
                $node -is [Management.Automation.Language.IfStatementAst] -and
                $node.Clauses[0].Item1.Extent.Text.Trim() -eq '$FromInstall' -and
                $node.Clauses[0].Item2.Extent.Text -match 'Set-SetupMarker'
            }, $true)
        $fromInstallCompletion | Should -Not -BeNullOrEmpty
        $completionBody = $fromInstallCompletion.Clauses[0].Item2
        $installMarker = @(Find-CommandAst -Ast $completionBody -Name 'Set-SetupMarker')
        $installRefresh = @(Find-CommandAst -Ast $completionBody -Name 'Invoke-CurrentSessionExplorerRefresh')
        $installReturn = @($completionBody.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.ReturnStatementAst]
                }, $true))

        $installMarker.Count | Should -Be 1
        (Get-CommandParameterArgument -Command $installMarker[0] -Name 'Value').SafeGetValue() |
            Should -Be 2
        $installRefresh.Count | Should -Be 1
        $installRefresh[0].Extent.StartOffset | Should -BeGreaterThan $installMarker[0].Extent.EndOffset
        # Falling through would rerun later-account setup and start the delayed
        # completion notice while the install is still running.
        $installReturn.Count | Should -Be 1
        $installReturn[0].Extent.StartOffset | Should -BeGreaterThan $installRefresh[0].Extent.EndOffset

        $endStatements = $script:newUserAst.EndBlock
        $markers = @(Find-CommandAst -Ast $endStatements -Name 'Set-SetupMarker' |
                Where-Object { $_.Extent.Text -match '-Value 2' })
        $markers.Count | Should -Be 2
        $finalMarker = $markers | Sort-Object { $_.Extent.StartOffset } |
            Select-Object -Last 1

        $retryRemoval = @(Find-CommandAst -Ast $endStatements -Name 'Remove-ItemProperty' |
                Where-Object {
                    $_.Extent.Text -match '\$runOncePath' -and
                    $_.Extent.StartOffset -gt $finalMarker.Extent.EndOffset
                })
        $retryRemoval.Count | Should -Be 1

        $laterRefresh = @(
            Find-CommandAst -Ast $endStatements -Name 'Invoke-CurrentSessionExplorerRefresh' |
                Where-Object { $_.Extent.StartOffset -gt $retryRemoval[0].Extent.EndOffset }
        )
        $laterRefresh.Count | Should -Be 1
    }

    It 'announces readiness only after the final Explorer refresh of the delayed finalizer' {
        $finalizer = $script:newUserAst.Find({
                param($node)
                $node -is [Management.Automation.Language.IfStatementAst] -and
                $node.Clauses[0].Item1.Extent.Text.Trim() -eq '$FinalizeSearch'
            }, $true)
        $finalizer | Should -Not -BeNullOrEmpty
        $finalizerBody = $finalizer.Clauses[0].Item2
        $finalRefresh = @(Find-CommandAst -Ast $finalizerBody `
                -Name 'Invoke-CurrentSessionExplorerRefresh')
        $finalRefresh.Count | Should -Be 1

        $appLaunch = @(Find-StringConstant -Ast $script:newUserAst -Value '--just-installed')
        $persistentToast = @($script:newUserAst.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.CommandAst] -and
                    $node.Extent.Text -match 'Show-AtlasToast\.ps1' -and
                    @($node.CommandElements | Where-Object {
                            $_ -is [Management.Automation.Language.CommandParameterAst] -and
                            $_.ParameterName -eq 'Persistent'
                        }).Count -eq 1
                }, $true))
        $appLaunch.Count | Should -Be 1
        $persistentToast.Count | Should -Be 1

        foreach ($announcement in @($appLaunch[0], $persistentToast[0])) {
            $announcement.Extent.StartOffset | Should -BeGreaterThan $finalRefresh[0].Extent.EndOffset
            $announcement.Extent.EndOffset | Should -BeLessThan $finalizerBody.Extent.EndOffset
        }
    }
}
