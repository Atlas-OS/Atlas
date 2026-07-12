BeforeAll {
    $repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
    $migrationPath = Join-Path $repositoryRoot `
        'playbook\Executables\AtlasModules\Scripts\Internal\Remove-AtlasLegacyElevationArtifacts.ps1'
    . $migrationPath

    $script:UserSid = 'S-1-5-21-100-200-300-1001'
    $script:OtherSid = 'S-1-5-21-100-200-300-1002'

    function Get-TestLegacyKey {
        param([hashtable]$Values = @{}, [string[]]$SubKeys = @(), [switch]$Missing)
        [pscustomobject]@{ Exists = -not $Missing; Values = $Values; SubKeys = @($SubKeys) }
    }

    function Get-TestLegacyValue {
        param([string]$Kind, $Value)
        [pscustomobject]@{ Kind = $Kind; Value = $Value }
    }

    function Get-TestLegacyHarness {
        param([string]$IdentitySid = $script:UserSid)
        $state = [pscustomobject]@{
            Registry = @{}
            RemovedTrees = New-Object 'Collections.Generic.List[string]'
            RemovedValues = New-Object 'Collections.Generic.List[string]'
            Writes = New-Object 'Collections.Generic.List[string]'
            ReadKeys = New-Object 'Collections.Generic.List[string]'
            ReadCount = 0
            IdentitySid = $IdentitySid
        }
        $reader = {
            param($Hive, $SubKey)
            $state.ReadCount++
            $name = "$Hive|$SubKey"
            [void]$state.ReadKeys.Add($name)
            if (-not $state.Registry.ContainsKey($name)) {
                return [pscustomobject]@{ Exists = $false; Values = @{}; SubKeys = @() }
            }
            return $state.Registry[$name]
        }.GetNewClosure()
        $treeRemover = {
            param($Hive, $SubKey)
            $prefix = "$Hive|$SubKey"
            [void]$state.RemovedTrees.Add($prefix)
            foreach ($name in @($state.Registry.Keys)) {
                if ($name -ieq $prefix -or $name.StartsWith("$prefix\", [StringComparison]::OrdinalIgnoreCase)) {
                    $state.Registry.Remove($name)
                }
            }
        }.GetNewClosure()
        $valueRemover = {
            param($SubKey, $Name)
            [void]$state.RemovedValues.Add("CurrentUser|$SubKey|$Name")
            $key = "CurrentUser|$SubKey"
            if ($state.Registry.ContainsKey($key)) { $state.Registry[$key].Values.Remove($Name) }
        }.GetNewClosure()
        $valueWriter = {
            param($SubKey, $Name, $Value, $Kind)
            $keyName = "Machine|$SubKey"
            if (-not $state.Registry.ContainsKey($keyName)) {
                $state.Registry[$keyName] = [pscustomobject]@{
                    Exists = $true; Values = @{}; SubKeys = @()
                }
            }
            $state.Registry[$keyName].Values[$Name] = [pscustomobject]@{
                Kind = $Kind; Value = $Value
            }
            [void]$state.Writes.Add("$SubKey|$Name|$Kind|$Value")
        }.GetNewClosure()
        $identityReader = { $state.IdentitySid }.GetNewClosure()
        [pscustomobject]@{
            State = $state
            Reader = $reader
            TreeRemover = $treeRemover
            ValueRemover = $valueRemover
            ValueWriter = $valueWriter
            IdentityReader = $identityReader
        }
    }

    function Invoke-TestLegacyMigration {
        param($Harness, [ValidateSet('Machine', 'CurrentUser')][string]$Scope,
            [string]$ExpectedUserSid)
        Invoke-AtlasLegacyElevationMigrationCore -Scope $Scope `
            -ExpectedUserSid $ExpectedUserSid -RegistryReader $Harness.Reader `
            -RegistryTreeRemover $Harness.TreeRemover `
            -RegistryValueRemover $Harness.ValueRemover `
            -RegistryValueWriter $Harness.ValueWriter `
            -IdentitySidReader $Harness.IdentityReader -WarningAction SilentlyContinue
    }

    function Add-TestReleasedMachineArtifact {
        param($Harness)
        $terminalValues = @{
            OpenPSAdmin = @{
                MUIVerb = Get-TestLegacyValue String 'Command Prompt (System)'
                HasLUAShield = Get-TestLegacyValue String ''
                Icon = Get-TestLegacyValue String '%windir%\system32\cmd.exe,0'
            }
            OpenPSAdmin0 = @{
                MUIVerb = Get-TestLegacyValue String 'PowerShell (System)'
                HasLUAShield = Get-TestLegacyValue String ''
                Icon = Get-TestLegacyValue String '%windir%\System32\WindowsPowerShell\v1.0\PowerShell.exe,0'
            }
        }
        foreach ($root in @('Directory\shell\AtlasTerminals', 'LibraryFolder\shell\AtlasTerminals',
                'Drive\shell\AtlasTerminals', 'Directory\Background\shell\AtlasTerminals')) {
            foreach ($name in @('OpenPSAdmin', 'OpenPSAdmin0')) {
                $path = "SOFTWARE\Classes\$root\shell\$name"
                $Harness.State.Registry["Machine|$path"] = Get-TestLegacyKey `
                    -Values $terminalValues[$name] -SubKeys command
                $Harness.State.Registry["Machine|$path\command"] = Get-TestLegacyKey -Values @{
                    '' = Get-TestLegacyValue String $script:AtlasLegacyTerminalCommands[$name]
                }
            }
        }

        $mergePath = 'SOFTWARE\Classes\regfile\Shell\RunAs'
        $Harness.State.Registry["Machine|$mergePath"] = Get-TestLegacyKey -Values @{
            '' = Get-TestLegacyValue String 'Merge As TrustedInstaller'
            HasLUAShield = Get-TestLegacyValue String '1'
        } -SubKeys Command
        $Harness.State.Registry["Machine|$mergePath\Command"] = Get-TestLegacyKey -Values @{
            '' = Get-TestLegacyValue String $script:AtlasLegacyMergeCommands[0]
        }

        $terms = @{}
        foreach ($name in (Get-AtlasReleasedTermsValueMap).Keys) {
            $terms[$name] = Get-TestLegacyValue String (Get-AtlasReleasedTermsValueMap)[$name]
        }
        $Harness.State.Registry['Machine|SOFTWARE\Classes\TermsRunAsTI'] =
            Get-TestLegacyKey -Values $terms
        $Harness.State.Registry['Machine|SOFTWARE\AtlasOS\ContextMenuTerminals'] =
            Get-TestLegacyKey -Values @{ state = Get-TestLegacyValue DWord 2 }
    }

    function Get-TestReleasedVolatileValue {
        param([string]$Sid = $script:UserSid, [switch]$Older)
        $terms = Get-AtlasReleasedTermsValueMap
        $codeLines = foreach ($number in (@(11..30) + @(32..37))) {
            $line = [string]$terms[[string]$number]
            if ($number -eq 12) { $line = $line.TrimEnd() }
            elseif ($number -eq 24) { $line = $line.Replace('"PowerShell ', '"powershell ') }
            elseif ($number -eq 28) {
                $classes = if ($Older) { 'Software' } else { 'SOFTWARE' }
                $line = $line.Replace('Registry::HKCR\AppID', "HKLM:\$classes\Classes\AppID")
            }
            elseif ($number -eq 33) { $line = $line.Replace('{$9=[Reflection', '{[Reflection') }
            $line
        }
        $code = $codeLines -join "`r`n"
        $metadata = "`$cmd='x';`$arg='';`$id='RunAsTI';`$key='Registry::HKU\$Sid\Volatile Environment';"
        Get-TestLegacyValue MultiString @($metadata, $code)
    }
}

Describe 'Released legacy elevation migration' {
    It 'removes released machine persistence and converts the registry merge verb' {
        $harness = Get-TestLegacyHarness
        Add-TestReleasedMachineArtifact $harness

        $result = Invoke-TestLegacyMigration $harness Machine

        $result.RemovedCount | Should -Be 10
        $result.MigratedCount | Should -Be 1
        $result.RetainedCount | Should -Be 0
        @($harness.State.ReadKeys | Where-Object { $_ -notlike 'Machine|*' }).Count |
            Should -Be 0
        $harness.State.Registry.ContainsKey('Machine|SOFTWARE\Classes\TermsRunAsTI') |
            Should -BeFalse
        $merge = $harness.State.Registry['Machine|SOFTWARE\Classes\regfile\Shell\RunAs']
        $merge.Values[''].Value | Should -BeExactly 'Merge as administrator'
        $command = $harness.State.Registry['Machine|SOFTWARE\Classes\regfile\Shell\RunAs\Command']
        $command.Values[''].Kind | Should -BeExactly 'ExpandString'
        $command.Values[''].Value | Should -BeExactly $script:AtlasAdministratorMergeCommand
    }

    It 'is idempotent after released artifacts have been migrated' {
        $harness = Get-TestLegacyHarness
        Add-TestReleasedMachineArtifact $harness
        [void](Invoke-TestLegacyMigration $harness Machine)

        $result = Invoke-TestLegacyMigration $harness Machine

        $result.RemovedCount | Should -Be 0
        $result.MigratedCount | Should -Be 0
        $result.RetainedCount | Should -Be 0
    }

    It 'retains customized machine entries without changing them' {
        $harness = Get-TestLegacyHarness
        Add-TestReleasedMachineArtifact $harness
        foreach ($name in @($harness.State.Registry.Keys)) {
            if ($name -notmatch 'Directory\\shell\\AtlasTerminals\\shell\\OpenPSAdmin0(?:\\command)?$' -and
                $name -notmatch 'TermsRunAsTI$' -and $name -notmatch 'regfile\\Shell\\RunAs' -and
                $name -notmatch 'ContextMenuTerminals$') { $harness.State.Registry.Remove($name) }
        }
        $terminal = $harness.State.Registry[
            'Machine|SOFTWARE\Classes\Directory\shell\AtlasTerminals\shell\OpenPSAdmin0']
        $terminal.Values.Icon.Value = 'custom.exe,0'
        $harness.State.Registry['Machine|SOFTWARE\Classes\TermsRunAsTI'].Values['15'].Value += ' custom'
        $harness.State.Registry[
            'Machine|SOFTWARE\Classes\regfile\Shell\RunAs\Command'].Values[''].Value = 'custom.exe "%1"'
        $harness.State.Registry[
            'Machine|SOFTWARE\AtlasOS\ContextMenuTerminals'].Values.extra = Get-TestLegacyValue String x

        $before = $harness.State.Registry.Count
        $result = Invoke-TestLegacyMigration $harness Machine

        $result.RemovedCount | Should -Be 0
        $result.MigratedCount | Should -Be 0
        $result.RetainedCount | Should -Be 4
        $harness.State.Registry.Count | Should -Be $before
        $harness.State.Writes.Count | Should -Be 0
    }

    It 'rejects a missing or mismatched current-user identity before registry access' {
        $harness = Get-TestLegacyHarness -IdentitySid $script:OtherSid

        { Invoke-TestLegacyMigration -Harness $harness -Scope CurrentUser `
                -ExpectedUserSid $script:UserSid } |
            Should -Throw '*does not match install-state SID*'
        $harness.State.ReadCount | Should -Be 0
        { Invoke-TestLegacyMigration -Harness $harness -Scope CurrentUser } |
            Should -Throw '*requires the install-state user SID*'
        $harness.State.ReadCount | Should -Be 0
    }

    It 'removes only the released current-user volatile value' {
        $harness = Get-TestLegacyHarness
        $harness.State.Registry['CurrentUser|Volatile Environment'] = Get-TestLegacyKey -Values @{
            RunAsTI = Get-TestReleasedVolatileValue
            Other = Get-TestLegacyValue String 'keep'
        }

        $result = Invoke-TestLegacyMigration -Harness $harness -Scope CurrentUser `
            -ExpectedUserSid $script:UserSid

        $result.RemovedCount | Should -Be 1
        @($harness.State.ReadKeys | Where-Object { $_ -notlike 'CurrentUser|*' }).Count |
            Should -Be 0
        $harness.State.Registry['CurrentUser|Volatile Environment'].Values.ContainsKey('RunAsTI') |
            Should -BeFalse
        $harness.State.Registry['CurrentUser|Volatile Environment'].Values.Other.Value |
            Should -BeExactly 'keep'

        $harness.State.Registry['CurrentUser|Volatile Environment'].Values.RunAsTI =
            Get-TestReleasedVolatileValue -Older
        $result = Invoke-TestLegacyMigration -Harness $harness -Scope CurrentUser `
            -ExpectedUserSid $script:UserSid
        $result.RemovedCount | Should -Be 1

        $harness.State.Registry['CurrentUser|Volatile Environment'].Values.RunAsTI =
            Get-TestReleasedVolatileValue -Sid $script:OtherSid
        $result = Invoke-TestLegacyMigration -Harness $harness -Scope CurrentUser `
            -ExpectedUserSid $script:UserSid
        $result.RetainedCount | Should -Be 1
        $harness.State.Registry['CurrentUser|Volatile Environment'].Values.ContainsKey('RunAsTI') |
            Should -BeTrue
    }
}
