BeforeAll {
    $script:RepositoryRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).ProviderPath
    $script:LegacyMigrationPath = Join-Path -Path $script:RepositoryRoot -ChildPath `
        'playbook\Executables\AtlasModules\Scripts\Internal\Remove-AtlasLegacyElevationArtifacts.ps1'
    $script:MergeTransitionPath = Join-Path -Path $script:RepositoryRoot -ChildPath `
        'playbook\Executables\AtlasModules\Scripts\Tweaks\qol\explorer\add-context-menus\merge-as-administrator.ps1'
    $script:PreInstallPath = Join-Path -Path $script:RepositoryRoot -ChildPath `
        'playbook\Executables\AtlasModules\Scripts\Phases\Invoke-PreInstallPhase.ps1'

    # Both production entrypoints guard their top-level calls when dot-sourced. All
    # behavior below is exercised through injected in-memory seams.
    . $script:LegacyMigrationPath
    . $script:MergeTransitionPath

    $script:LegacyMigrationSource = Get-Content -LiteralPath $script:LegacyMigrationPath -Raw
    $script:MergeTransitionSource = Get-Content -LiteralPath $script:MergeTransitionPath -Raw
    $script:PreInstallSource = Get-Content -LiteralPath $script:PreInstallPath -Raw
    $script:TestSendToPath = 'C:\TestUser\AppData\Roaming\Microsoft\Windows\SendTo\RunAsTI.bat'

    function New-TestRegistryValue {
        param(
            [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Name,
            [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Kind,
            [Parameter(Mandatory = $true)][AllowNull()]$Value
        )

        return [pscustomobject]@{ Name = $Name; Kind = $Kind; Value = $Value }
    }

    function New-TestRegistrySnapshot {
        param(
            [bool]$Exists = $false,
            [object[]]$Values = @(),
            [string[]]$SubKeys = @()
        )

        return [pscustomobject]@{
            Exists  = $Exists
            Values  = @($Values)
            SubKeys = @($SubKeys)
        }
    }

    function Copy-TestRegistrySnapshot {
        param([Parameter(Mandatory = $true)]$Snapshot)

        $values = @(
            foreach ($value in @($Snapshot.Values)) {
                $copiedValue = if ($value.Value -is [array]) { @($value.Value) } else { $value.Value }
                New-TestRegistryValue -Name ([string]$value.Name) -Kind ([string]$value.Kind) `
                    -Value $copiedValue
            }
        )
        return New-TestRegistrySnapshot -Exists ([bool]$Snapshot.Exists) -Values $values `
            -SubKeys @($Snapshot.SubKeys)
    }

    function Set-TestSnapshotValue {
        param(
            [Parameter(Mandatory = $true)][hashtable]$Registry,
            [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Key,
            [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Name,
            [Parameter(Mandatory = $true)][AllowNull()]$Value,
            [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Kind
        )

        $snapshot = if ($Registry.ContainsKey($Key)) {
            Copy-TestRegistrySnapshot -Snapshot $Registry[$Key]
        }
        else {
            New-TestRegistrySnapshot -Exists $true
        }
        $snapshot.Exists = $true
        $snapshot.Values = @(
            @($snapshot.Values | Where-Object { [string]$_.Name -ine $Name })
            New-TestRegistryValue -Name $Name -Kind $Kind -Value $Value
        )
        $Registry[$Key] = $snapshot
    }

    function Add-TestSnapshotSubKey {
        param(
            [Parameter(Mandatory = $true)][hashtable]$Registry,
            [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Key,
            [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$SubKey
        )

        $snapshot = if ($Registry.ContainsKey($Key)) {
            Copy-TestRegistrySnapshot -Snapshot $Registry[$Key]
        }
        else {
            New-TestRegistrySnapshot -Exists $true
        }
        $snapshot.Exists = $true
        if (@($snapshot.SubKeys | Where-Object { [string]$_ -ieq $SubKey }).Count -eq 0) {
            $snapshot.SubKeys = @($snapshot.SubKeys) + $SubKey
        }
        $Registry[$Key] = $snapshot
    }

    function New-TestLegacyMergeParent {
        return New-TestRegistrySnapshot -Exists $true -Values @(
            (New-TestRegistryValue -Name '' -Kind 'String' -Value $script:AtlasMergeLegacyLabel)
            (New-TestRegistryValue -Name 'HasLUAShield' -Kind 'String' -Value '1')
        ) -SubKeys @('Command')
    }

    function New-TestAdministratorMergeParent {
        param([switch]$WithoutShield)

        $values = @(
            New-TestRegistryValue -Name '' -Kind 'String' -Value $script:AtlasMergeAdministratorLabel
        )
        if (-not $WithoutShield) {
            $values += New-TestRegistryValue -Name 'HasLUAShield' -Kind 'String' -Value '1'
        }
        return New-TestRegistrySnapshot -Exists $true -Values $values -SubKeys @('Command')
    }

    function New-TestLegacyMergeCommand {
        return New-TestRegistrySnapshot -Exists $true -Values @(
            New-TestRegistryValue -Name '' -Kind 'String' -Value $script:AtlasMergeLegacyCommands[0]
        )
    }

    function New-TestAdministratorMergeCommand {
        return New-TestRegistrySnapshot -Exists $true -Values @(
            New-TestRegistryValue -Name '' -Kind 'ExpandString' `
                -Value $script:AtlasMergeAdministratorCommand
        )
    }

    function New-TestMergeHarness {
        param(
            [Parameter(Mandatory = $true)]$Parent,
            [Parameter(Mandatory = $true)]$Command,
            [int]$FailBeforeWriteAt = 0,
            [switch]$EmitNoise
        )

        $registry = @{}
        $registry[$script:AtlasMergeParentPath] = Copy-TestRegistrySnapshot -Snapshot $Parent
        $registry[$script:AtlasMergeCommandPath] = Copy-TestRegistrySnapshot -Snapshot $Command
        $context = [pscustomobject]@{
            Registry          = $registry
            Reads             = New-Object 'Collections.Generic.List[string]'
            Writes            = New-Object 'Collections.Generic.List[string]'
            WriteAttempts     = 0
            FailBeforeWriteAt = $FailBeforeWriteAt
            EmitNoise         = [bool]$EmitNoise
        }
        $copyRegistrySnapshot = ${function:Copy-TestRegistrySnapshot}
        $newRegistrySnapshot = ${function:New-TestRegistrySnapshot}
        $setSnapshotValue = ${function:Set-TestSnapshotValue}
        $addSnapshotSubKey = ${function:Add-TestSnapshotSubKey}
        $mergeParentPath = [string]$script:AtlasMergeParentPath
        $mergeCommandPath = [string]$script:AtlasMergeCommandPath

        $reader = {
            param($SubKey)
            [void]$context.Reads.Add([string]$SubKey)
            if (-not $context.Registry.ContainsKey([string]$SubKey)) {
                return & $newRegistrySnapshot
            }
            return & $copyRegistrySnapshot -Snapshot $context.Registry[[string]$SubKey]
        }.GetNewClosure()
        $writer = {
            param($SubKey, $Name, $Value, $Kind)
            $context.WriteAttempts++
            if ($context.FailBeforeWriteAt -gt 0 -and
                $context.WriteAttempts -eq $context.FailBeforeWriteAt) {
                throw "Injected failure before registry write $($context.WriteAttempts)."
            }
            & $setSnapshotValue -Registry $context.Registry -Key ([string]$SubKey) `
                -Name ([string]$Name) -Value $Value -Kind ([string]$Kind)
            if ([string]$SubKey -ceq $mergeCommandPath) {
                & $addSnapshotSubKey -Registry $context.Registry `
                    -Key $mergeParentPath -SubKey 'Command'
            }
            [void]$context.Writes.Add(
                ('{0}|{1}|{2}|{3}' -f $SubKey, $Name, $Value, $Kind)
            )
            if ($context.EmitNoise) { Write-Output 'merge-writer-noise' }
        }.GetNewClosure()

        return [pscustomobject]@{
            Context        = $context
            RegistryReader = $reader
            RegistryWriter = $writer
        }
    }

    function Assert-TestMergeCanonical {
        param([Parameter(Mandatory = $true)]$Harness)

        $parent = $Harness.Context.Registry[$script:AtlasMergeParentPath]
        $command = $Harness.Context.Registry[$script:AtlasMergeCommandPath]
        (Test-AtlasMergeCanonical -Parent $parent -Command $command) | Should -BeTrue
    }

    function New-TestFileSnapshot {
        param(
            [Parameter(Mandatory = $true)][string]$Path,
            [bool]$Exists = $true,
            [bool]$IsReparsePoint = $false,
            [AllowNull()][string]$Sha256 = $null,
            [bool]$LegacyMarker = $true
        )

        return [pscustomobject]@{
            Exists         = $Exists
            Path           = $Path
            IsReparsePoint = $IsReparsePoint
            Sha256         = $Sha256
            LegacyMarker   = $LegacyMarker
        }
    }

    function Copy-TestFileSnapshot {
        param([Parameter(Mandatory = $true)]$Snapshot)

        return New-TestFileSnapshot -Path ([string]$Snapshot.Path) -Exists ([bool]$Snapshot.Exists) `
            -IsReparsePoint ([bool]$Snapshot.IsReparsePoint) -Sha256 $Snapshot.Sha256 `
            -LegacyMarker ([bool]$Snapshot.LegacyMarker)
    }

    function New-TestLegacyMigrationHarness {
        param([switch]$EmitNoise)

        $context = [pscustomobject]@{
            Registry          = @{}
            Files             = @{}
            ReadCounts        = @{}
            ReadSequences     = @{}
            RegistryWrites    = New-Object 'Collections.Generic.List[string]'
            TreeRemovals      = New-Object 'Collections.Generic.List[string]'
            ValueRemovals     = New-Object 'Collections.Generic.List[string]'
            FileRemovals      = New-Object 'Collections.Generic.List[string]'
            Logs              = New-Object 'Collections.Generic.List[string]'
            EmitNoise         = [bool]$EmitNoise
        }
        $copyRegistrySnapshot = ${function:Copy-TestRegistrySnapshot}
        $newRegistrySnapshot = ${function:New-TestRegistrySnapshot}
        $setSnapshotValue = ${function:Set-TestSnapshotValue}
        $addSnapshotSubKey = ${function:Add-TestSnapshotSubKey}
        $copyFileSnapshot = ${function:Copy-TestFileSnapshot}
        $newFileSnapshot = ${function:New-TestFileSnapshot}
        $mergeParentPath = 'SOFTWARE\Classes\regfile\Shell\RunAs'
        $mergeCommandPath = "$mergeParentPath\Command"

        $registryReader = {
            param($Hive, $SubKey)
            $key = '{0}|{1}' -f $Hive, $SubKey
            $count = if ($context.ReadCounts.ContainsKey($key)) {
                [int]$context.ReadCounts[$key] + 1
            }
            else { 1 }
            $context.ReadCounts[$key] = $count
            if ($context.ReadSequences.ContainsKey($key)) {
                $sequence = @($context.ReadSequences[$key])
                $index = [Math]::Min($count - 1, $sequence.Count - 1)
                return & $copyRegistrySnapshot -Snapshot $sequence[$index]
            }
            if (-not $context.Registry.ContainsKey($key)) {
                return & $newRegistrySnapshot
            }
            return & $copyRegistrySnapshot -Snapshot $context.Registry[$key]
        }.GetNewClosure()
        $treeRemover = {
            param($Hive, $SubKey)
            $key = '{0}|{1}' -f $Hive, $SubKey
            [void]$context.TreeRemovals.Add($key)
            $context.Registry.Remove($key)
            if ($context.EmitNoise) { Write-Output 'tree-remover-noise' }
        }.GetNewClosure()
        $valueRemover = {
            param($Hive, $SubKey, $Name)
            $key = '{0}|{1}' -f $Hive, $SubKey
            [void]$context.ValueRemovals.Add(('{0}|{1}' -f $key, $Name))
            if ($context.Registry.ContainsKey($key)) {
                $snapshot = & $copyRegistrySnapshot -Snapshot $context.Registry[$key]
                $snapshot.Values = @($snapshot.Values | Where-Object {
                        [string]$_.Name -ine [string]$Name
                    })
                $context.Registry[$key] = $snapshot
            }
            if ($context.EmitNoise) { Write-Output 'value-remover-noise' }
        }.GetNewClosure()
        $valueWriter = {
            param($Hive, $SubKey, $Name, $Value, $Kind)
            $key = '{0}|{1}' -f $Hive, $SubKey
            & $setSnapshotValue -Registry $context.Registry -Key $key -Name ([string]$Name) `
                -Value $Value -Kind ([string]$Kind)
            if ([string]$SubKey -ceq $mergeCommandPath) {
                & $addSnapshotSubKey -Registry $context.Registry `
                    -Key ('{0}|{1}' -f $Hive, $mergeParentPath) `
                    -SubKey 'Command'
            }
            [void]$context.RegistryWrites.Add(
                ('{0}|{1}|{2}|{3}' -f $key, $Name, $Value, $Kind)
            )
            if ($context.EmitNoise) { Write-Output 'value-writer-noise' }
        }.GetNewClosure()
        $fileReader = {
            param($Path)
            if (-not $context.Files.ContainsKey([string]$Path)) {
                return & $newFileSnapshot -Path ([string]$Path) -Exists $false `
                    -LegacyMarker $false
            }
            return & $copyFileSnapshot -Snapshot $context.Files[[string]$Path]
        }.GetNewClosure()
        $fileRemover = {
            param($Path, $ExpectedSha256)
            [void]$context.FileRemovals.Add(('{0}|{1}' -f $Path, $ExpectedSha256))
            $context.Files[[string]$Path] = & $newFileSnapshot -Path ([string]$Path) `
                -Exists $false -LegacyMarker $false
            if ($context.EmitNoise) { Write-Output 'file-remover-noise' }
        }.GetNewClosure()
        $logger = {
            param($Level, $Message)
            [void]$context.Logs.Add(('{0}|{1}' -f $Level, $Message))
            if ($context.EmitNoise) { Write-Output 'logger-noise' }
        }.GetNewClosure()

        return [pscustomobject]@{
            Context              = $context
            RegistryReader       = $registryReader
            RegistryTreeRemover  = $treeRemover
            RegistryValueRemover = $valueRemover
            RegistryValueWriter  = $valueWriter
            FileReader           = $fileReader
            FileRemover          = $fileRemover
            Logger               = $logger
        }
    }

    function Invoke-TestLegacyMigration {
        param(
            [Parameter(Mandatory = $true)]$Harness,
            [string[]]$VolatileCodeFingerprints
        )

        $parameters = @{
            RegistryReader       = $Harness.RegistryReader
            RegistryTreeRemover  = $Harness.RegistryTreeRemover
            RegistryValueRemover = $Harness.RegistryValueRemover
            RegistryValueWriter  = $Harness.RegistryValueWriter
            FileReader           = $Harness.FileReader
            FileRemover          = $Harness.FileRemover
            Logger               = $Harness.Logger
            SendToPath           = $script:TestSendToPath
        }
        if ($PSBoundParameters.ContainsKey('VolatileCodeFingerprints')) {
            $parameters.VolatileCodeFingerprints = $VolatileCodeFingerprints
        }
        Invoke-AtlasLegacyElevationMigrationCore @parameters
    }

    function Set-TestLegacyMergeState {
        param(
            [Parameter(Mandatory = $true)]$Harness,
            [string]$Command = $script:AtlasLegacyMergeCommands[0]
        )

        $Harness.Context.Registry['LocalMachine|SOFTWARE\Classes\regfile\Shell\RunAs'] =
            New-TestRegistrySnapshot -Exists $true -Values @(
                (New-TestRegistryValue -Name '' -Kind 'String' `
                        -Value $script:AtlasLegacyMergeLabel)
                (New-TestRegistryValue -Name 'HasLUAShield' -Kind 'String' -Value '1')
            ) -SubKeys @('Command')
        $Harness.Context.Registry['LocalMachine|SOFTWARE\Classes\regfile\Shell\RunAs\Command'] =
            New-TestRegistrySnapshot -Exists $true -Values @(
                New-TestRegistryValue -Name '' -Kind 'String' `
                    -Value $Command
            )
    }

    function New-TestOlderTermsSnapshot {
        # This is the decoded 10..40 REG_SZ block from the older, lowercase-
        # powershell Atlas release. It is data only and is never evaluated.
        $payload = @'
10|function RunAsTI ($cmd,$arg) { $id='RunAsTI'; $key="Registry::HKU\$(((whoami /user)-split' ')[-1])\Volatile Environment"; $code=@'
11| $I=[int32]; $M=$I.module.gettype("System.Runtime.Interop`Services.Mar`shal"); $P=$I.module.gettype("System.Int`Ptr"); $S=[string]
12| $D=@(); $T=@(); $DM=[AppDomain]::CurrentDomain."DefineDynami`cAssembly"(1,1)."DefineDynami`cModule"(1); $Z=[uintptr]::size
13| 0..5|% {$D += $DM."Defin`eType"("AveYo_$_",1179913,[ValueType])}; $D += [uintptr]; 4..6|% {$D += $D[$_]."MakeByR`efType"()}
14| $F='kernel','advapi','advapi', ($S,$S,$I,$I,$I,$I,$I,$S,$D[7],$D[8]), ([uintptr],$S,$I,$I,$D[9]),([uintptr],$S,$I,$I,[byte[]],$I)
15| 0..2|% {$9=$D[0]."DefinePInvok`eMethod"(('CreateProcess','RegOpenKeyEx','RegSetValueEx')[$_],$F[$_]+'32',8214,1,$S,$F[$_+3],1,4)}
16| $DF=($P,$I,$P),($I,$I,$I,$I,$P,$D[1]),($I,$S,$S,$S,$I,$I,$I,$I,$I,$I,$I,$I,[int16],[int16],$P,$P,$P,$P),($D[3],$P),($P,$P,$I,$I)
17| 1..5|% {$k=$_; $n=1; $DF[$_-1]|% {$9=$D[$k]."Defin`eField"('f' + $n++, $_, 6)}}; 0..5|% {$T += $D[$_]."Creat`eType"()}
18| 0..5|% {nv "A$_" ([Activator]::CreateInstance($T[$_])) -fo}; function F ($1,$2) {$T[0]."G`etMethod"($1).invoke(0,$2)}
19| $TI=(whoami /groups)-like'*1-16-16384*'; $As=0; if(!$cmd) {$cmd='control';$arg='admintools'}; if ($cmd-eq'This PC'){$cmd='file:'}
20| if (!$TI) {'TrustedInstaller','lsass','winlogon'|% {if (!$As) {$9=sc.exe start $_; $As=@(get-process -name $_ -ea 0|% {$_})[0]}}
21| function M ($1,$2,$3) {$M."G`etMethod"($1,[type[]]$2).invoke(0,$3)}; $H=@(); $Z,(4*$Z+16)|% {$H += M "AllocHG`lobal" $I $_}
22| M "WriteInt`Ptr" ($P,$P) ($H[0],$As.Handle); $A1.f1=131072; $A1.f2=$Z; $A1.f3=$H[0]; $A2.f1=1; $A2.f2=1; $A2.f3=1; $A2.f4=1
23| $A2.f6=$A1; $A3.f1=10*$Z+32; $A4.f1=$A3; $A4.f2=$H[1]; M "StructureTo`Ptr" ($D[2],$P,[boolean]) (($A2 -as $D[2]),$A4.f2,$false)
24| $Run=@($null, "powershell -win 1 -nop -c iex `$env:R; # $id", 0, 0, 0, 0x0E080600, 0, $null, ($A4 -as $T[4]), ($A5 -as $T[5]))
25| F 'CreateProcess' $Run; return}; $env:R=''; rp $key $id -force; $priv=[diagnostics.process]."GetM`ember"('SetPrivilege',42)[0]
26| 'SeSecurityPrivilege','SeTakeOwnershipPrivilege','SeBackupPrivilege','SeRestorePrivilege' |% {$priv.Invoke($null, @("$_",2))}
27| $HKU=[uintptr][uint32]2147483651; $NT='S-1-5-18'; $reg=($HKU,$NT,8,2,($HKU -as $D[9])); F 'RegOpenKeyEx' $reg; $LNK=$reg[4]
28| function L ($1,$2,$3) {sp 'Registry::HKCR\AppID\{CDCBCFCA-3CDC-436f-A4E2-0E02075250C2}' 'RunAs' $3 -force -ea 0
29|  $b=[Text.Encoding]::Unicode.GetBytes("\Registry\User\$1"); F 'RegSetValueEx' @($2,'SymbolicLinkValue',0,6,[byte[]]$b,$b.Length)}
30| function Q {[int](gwmi win32_process -filter 'name="explorer.exe"'|?{$_.getownersid().sid-eq$NT}|select -last 1).ProcessId}
31| $env:wt='powershell'; dir "$env:ProgramFiles\WindowsApps\Microsoft.WindowsTerminal*\wt.exe" -rec|% {$env:wt='"'+$_.FullName+'" "-d ."'}
32| $11bug=($((gwmi Win32_OperatingSystem).BuildNumber)-eq'22000')-AND(($cmd-eq'file:')-OR(test-path -lit $cmd -PathType Container))
33| if ($11bug) {'System.Windows.Forms','Microsoft.VisualBasic' |% {$9=[Reflection.Assembly]::LoadWithPartialName("'$_")}}
34| if ($11bug) {$path='^(l)'+$($cmd -replace '([\+\^\%\~\(\)\[\]])','{$1}')+'{ENTER}'; $cmd='control.exe'; $arg='admintools'}
35| L ($key-split'\\\\')[1] $LNK ''; $R=[diagnostics.process]::start($cmd,$arg); if ($R) {$R.PriorityClass='High'; $R.WaitForExit()}
36| if ($11bug) {$w=0; do {if($w-gt40){break}; sleep -mi 250;$w++} until (Q); [Microsoft.VisualBasic.Interaction]::AppActivate($(Q))}
37| if ($11bug) {[Windows.Forms.SendKeys]::SendWait($path)}; do {sleep 7} while(Q); L '.Default' $LNK 'Interactive User'
38|'@; $V='';'cmd','arg','id','key'|%{$V+="`n`$$_='$($(gv $_ -val)-replace"'","''")';"}; sp $key $id $($V,$code) -type 7 -force -ea 0
39| start powershell -args "-win 1 -nop -c `n$V `$env:R=(gi `$key -ea 0).getvalue(`$id)-join''; iex `$env:R" -verb runas
40|}; $A=,([environment]::commandline-split'-[-]%+ ?',2)[1]-split'"([^"]+)"|([^ ]+)',2|%{$_.Trim(' "')}; RunAsTI $A[1] $A[2]; # AveYo, 2023.07.06
'@
        $values = @(
            foreach ($line in ($payload -split "`r?`n")) {
                $separator = $line.IndexOf('|')
                if ($separator -lt 2) { throw "Invalid historical Terms fixture line '$line'." }
                $name = $line.Substring(0, $separator)
                $value = $line.Substring($separator + 1).Replace('\"', '"').Replace('\\', '\')
                if ($name -ceq '12') { $value += ' ' }
                New-TestRegistryValue -Name $name -Kind 'String' -Value $value
            }
        )
        return New-TestRegistrySnapshot -Exists $true -Values $values
    }

    function Get-TestLegacyMutationCount {
        param([Parameter(Mandatory = $true)]$Harness)

        return $Harness.Context.RegistryWrites.Count + $Harness.Context.TreeRemovals.Count +
            $Harness.Context.ValueRemovals.Count + $Harness.Context.FileRemovals.Count
    }
}

Describe 'Administrator registry-file merge transition' {
    It 'creates the closed verb from absent state' {
        $harness = New-TestMergeHarness -Parent (New-TestRegistrySnapshot) `
            -Command (New-TestRegistrySnapshot)

        @(
            Invoke-AtlasAdministratorMergeTransition -RegistryReader $harness.RegistryReader `
                -RegistryWriter $harness.RegistryWriter
        ).Count | Should -Be 0

        Assert-TestMergeCanonical -Harness $harness
        $harness.Context.Writes.Count | Should -Be 3
    }

    It 'replaces the exact former TrustedInstaller verb' {
        $harness = New-TestMergeHarness -Parent (New-TestLegacyMergeParent) `
            -Command (New-TestLegacyMergeCommand)

        Invoke-AtlasAdministratorMergeTransition -RegistryReader $harness.RegistryReader `
            -RegistryWriter $harness.RegistryWriter

        Assert-TestMergeCanonical -Harness $harness
    }

    It 'leaves the exact canonical verb untouched' {
        $harness = New-TestMergeHarness -Parent (New-TestAdministratorMergeParent) `
            -Command (New-TestAdministratorMergeCommand)

        Invoke-AtlasAdministratorMergeTransition -RegistryReader $harness.RegistryReader `
            -RegistryWriter $harness.RegistryWriter

        Assert-TestMergeCanonical -Harness $harness
        $harness.Context.Writes.Count | Should -Be 0
    }

    It 'repairs the known command-first partial transition' {
        $harness = New-TestMergeHarness -Parent (New-TestLegacyMergeParent) `
            -Command (New-TestAdministratorMergeCommand)

        Invoke-AtlasAdministratorMergeTransition -RegistryReader $harness.RegistryReader `
            -RegistryWriter $harness.RegistryWriter

        Assert-TestMergeCanonical -Harness $harness
    }

    It 'repairs the known label-first partial transition' {
        $harness = New-TestMergeHarness -Parent (New-TestAdministratorMergeParent -WithoutShield) `
            -Command (New-TestLegacyMergeCommand)

        Invoke-AtlasAdministratorMergeTransition -RegistryReader $harness.RegistryReader `
            -RegistryWriter $harness.RegistryWriter

        Assert-TestMergeCanonical -Harness $harness
    }

    It 'publishes the fixed ExpandString command before the fixed String label and shield' {
        $harness = New-TestMergeHarness -Parent (New-TestLegacyMergeParent) `
            -Command (New-TestLegacyMergeCommand)

        Invoke-AtlasAdministratorMergeTransition -RegistryReader $harness.RegistryReader `
            -RegistryWriter $harness.RegistryWriter

        $expected = @(
            ('{0}||{1}|ExpandString' -f $script:AtlasMergeCommandPath,
                $script:AtlasMergeAdministratorCommand)
            ('{0}||{1}|String' -f $script:AtlasMergeParentPath,
                $script:AtlasMergeAdministratorLabel)
            ('{0}|HasLUAShield|1|String' -f $script:AtlasMergeParentPath)
        ) -join "`n"
        (@($harness.Context.Writes) -join "`n") | Should -BeExactly $expected
        $script:AtlasMergeAdministratorCommand | Should -BeExactly `
            '"%SystemRoot%\System32\reg.exe" import "%1"'
        $script:MergeTransitionSource | Should -Not -Match `
            '(?i)Invoke-Expression|\biex\b|Start-Process'
    }

    It 'can retry safely after interruption following command publication' {
        $harness = New-TestMergeHarness -Parent (New-TestLegacyMergeParent) `
            -Command (New-TestLegacyMergeCommand) -FailBeforeWriteAt 2

        {
            Invoke-AtlasAdministratorMergeTransition -RegistryReader $harness.RegistryReader `
                -RegistryWriter $harness.RegistryWriter
        } | Should -Throw '*Injected failure*'
        $command = $harness.Context.Registry[$script:AtlasMergeCommandPath]
        (Test-AtlasMergeCommandKnown -Command $command) | Should -BeTrue
        (Get-AtlasMergeSnapshotValue -Snapshot $command -Name '').Kind | Should -BeExactly 'ExpandString'

        $harness.Context.FailBeforeWriteAt = 0
        Invoke-AtlasAdministratorMergeTransition -RegistryReader $harness.RegistryReader `
            -RegistryWriter $harness.RegistryWriter
        Assert-TestMergeCanonical -Harness $harness
    }

    It 'can retry safely after interruption following label publication' {
        $harness = New-TestMergeHarness -Parent (New-TestLegacyMergeParent) `
            -Command (New-TestLegacyMergeCommand) -FailBeforeWriteAt 3

        {
            Invoke-AtlasAdministratorMergeTransition -RegistryReader $harness.RegistryReader `
                -RegistryWriter $harness.RegistryWriter
        } | Should -Throw '*Injected failure*'
        $parent = $harness.Context.Registry[$script:AtlasMergeParentPath]
        (Get-AtlasMergeSnapshotValue -Snapshot $parent -Name '').Value | Should -BeExactly `
            $script:AtlasMergeAdministratorLabel

        $harness.Context.FailBeforeWriteAt = 0
        Invoke-AtlasAdministratorMergeTransition -RegistryReader $harness.RegistryReader `
            -RegistryWriter $harness.RegistryWriter
        Assert-TestMergeCanonical -Harness $harness
    }

    It 'rejects customized, extra, and wrong-kind states without writes' {
        $cases = @(
            [pscustomobject]@{
                Name = 'custom command'
                Parent = New-TestLegacyMergeParent
                Command = New-TestRegistrySnapshot -Exists $true -Values @(
                    New-TestRegistryValue -Name '' -Kind 'String' -Value 'custom.exe "%1"'
                )
            }
            [pscustomobject]@{
                Name = 'extra parent value'
                Parent = New-TestRegistrySnapshot -Exists $true -Values @(
                    (New-TestRegistryValue -Name '' -Kind 'String' -Value $script:AtlasMergeLegacyLabel)
                    (New-TestRegistryValue -Name 'HasLUAShield' -Kind 'String' -Value '1')
                    (New-TestRegistryValue -Name 'Owner' -Kind 'String' -Value 'custom')
                ) -SubKeys @('Command')
                Command = New-TestLegacyMergeCommand
            }
            [pscustomobject]@{
                Name = 'extra command subkey'
                Parent = New-TestLegacyMergeParent
                Command = New-TestRegistrySnapshot -Exists $true -Values @(
                    New-TestRegistryValue -Name '' -Kind 'String' -Value $script:AtlasMergeLegacyCommands[0]
                ) -SubKeys @('custom')
            }
            [pscustomobject]@{
                Name = 'wrong command kind'
                Parent = New-TestAdministratorMergeParent
                Command = New-TestRegistrySnapshot -Exists $true -Values @(
                    New-TestRegistryValue -Name '' -Kind 'String' `
                        -Value $script:AtlasMergeAdministratorCommand
                )
            }
        )

        foreach ($case in $cases) {
            $harness = New-TestMergeHarness -Parent $case.Parent -Command $case.Command
            {
                Invoke-AtlasAdministratorMergeTransition -RegistryReader $harness.RegistryReader `
                    -RegistryWriter $harness.RegistryWriter
            } | Should -Throw '*customized or ambiguous*' -Because $case.Name
            $harness.Context.Writes.Count | Should -Be 0 -Because $case.Name
        }
    }

    It 'rejects a registry race between validation and mutation with zero writes' {
        $harness = New-TestMergeHarness -Parent (New-TestLegacyMergeParent) `
            -Command (New-TestLegacyMergeCommand)
        $race = [pscustomobject]@{ ParentReads = 0 }
        $baseReader = $harness.RegistryReader
        $mergeParentPath = [string]$script:AtlasMergeParentPath
        $changedParent = New-TestRegistrySnapshot -Exists $true -Values @(
            New-TestRegistryValue -Name '' -Kind 'String' -Value 'changed'
        ) -SubKeys @('Command')
        $racingReader = {
            param($SubKey)
            if ([string]$SubKey -ceq $mergeParentPath) {
                $race.ParentReads++
                if ($race.ParentReads -eq 2) {
                    return $changedParent
                }
            }
            return & $baseReader $SubKey
        }.GetNewClosure()

        {
            Invoke-AtlasAdministratorMergeTransition -RegistryReader $racingReader `
                -RegistryWriter $harness.RegistryWriter
        } | Should -Throw '*changed after validation*'
        $harness.Context.Writes.Count | Should -Be 0
    }
}

Describe 'Legacy elevation persistence migration' {
    It 'rewrites only the exact old Merge-as-TrustedInstaller shape, command first' {
        $harness = New-TestLegacyMigrationHarness
        Set-TestLegacyMergeState -Harness $harness

        $output = @(Invoke-TestLegacyMigration -Harness $harness)

        $output.Count | Should -Be 1
        $output[0].AppliedCount | Should -Be 1
        $output[0].WarningCount | Should -Be 0
        $expectedWrites = @(
            ('LocalMachine|SOFTWARE\Classes\regfile\Shell\RunAs\Command||{0}|ExpandString' -f
                $script:AtlasAdministratorMergeCommand)
            ('LocalMachine|SOFTWARE\Classes\regfile\Shell\RunAs||{0}|String' -f
                $script:AtlasAdministratorMergeLabel)
        ) -join "`n"
        (@($harness.Context.RegistryWrites) -join "`n") | Should -BeExactly $expectedWrites
        $harness.Context.TreeRemovals.Count | Should -Be 0
        $harness.Context.ValueRemovals.Count | Should -Be 0
        $harness.Context.FileRemovals.Count | Should -Be 0
    }

    It 'aborts all planned mutations when an executable machine artifact is ambiguous' {
        $harness = New-TestLegacyMigrationHarness
        Set-TestLegacyMergeState -Harness $harness
        $harness.Context.Registry['LocalMachine|SOFTWARE\Classes\TermsRunAsTI'] =
            New-TestRegistrySnapshot -Exists $true -Values @(
                New-TestRegistryValue -Name '10' -Kind 'String' -Value 'custom executable code'
            )
        $approvedHash = $script:AtlasLegacySendToFingerprints[0]
        $harness.Context.Files[$script:TestSendToPath] = New-TestFileSnapshot `
            -Path $script:TestSendToPath -Sha256 $approvedHash

        { Invoke-TestLegacyMigration -Harness $harness } |
            Should -Throw '*ambiguous executable machine artifact*'
        (Get-TestLegacyMutationCount -Harness $harness) | Should -Be 0
    }

    It 'rejects a preflight registry race before writing the old merge verb' {
        $harness = New-TestLegacyMigrationHarness
        Set-TestLegacyMergeState -Harness $harness
        $mergeKey = 'LocalMachine|SOFTWARE\Classes\regfile\Shell\RunAs'
        $old = Copy-TestRegistrySnapshot -Snapshot $harness.Context.Registry[$mergeKey]
        $changed = Copy-TestRegistrySnapshot -Snapshot $old
        $changed.Values += New-TestRegistryValue -Name 'Owner' -Kind 'String' -Value 'foreign'
        $harness.Context.ReadSequences[$mergeKey] = @($old, $changed)

        { Invoke-TestLegacyMigration -Harness $harness } |
            Should -Throw '*changed after preflight*'
        (Get-TestLegacyMutationCount -Harness $harness) | Should -Be 0
    }

    It 'retains customized and reparse-point SendTo files' {
        $cases = @(
            New-TestFileSnapshot -Path $script:TestSendToPath -Sha256 ('F' * 64)
            New-TestFileSnapshot -Path $script:TestSendToPath -IsReparsePoint $true `
                -Sha256 $script:AtlasLegacySendToFingerprints[0]
        )
        foreach ($file in $cases) {
            $harness = New-TestLegacyMigrationHarness
            $harness.Context.Files[$script:TestSendToPath] = $file

            $output = @(Invoke-TestLegacyMigration -Harness $harness)

            $output.Count | Should -Be 1
            $output[0].AppliedCount | Should -Be 0
            $output[0].WarningCount | Should -Be 1
            $harness.Context.FileRemovals.Count | Should -Be 0
            $harness.Context.Files[$script:TestSendToPath].Exists | Should -BeTrue
        }
    }

    It 'suppresses every logger and mutator output and returns one strict typed result' {
        $harness = New-TestLegacyMigrationHarness -EmitNoise
        Set-TestLegacyMergeState -Harness $harness
        $harness.Context.Registry['LocalMachine|SOFTWARE\AtlasOS\ContextMenuTerminals'] =
            New-TestRegistrySnapshot -Exists $true -Values @(
                New-TestRegistryValue -Name 'state' -Kind 'DWord' -Value 2
            )
        $code = 'synthetic historical volatile payload'
        $codeFingerprint = Get-AtlasLegacySha256Text -Text $code
        $metadata = '$id=''RunAsTI''; $key=''Registry::HKU\S-1-5-21-1-2-3-1001\Volatile Environment'';'
        $harness.Context.Registry['CurrentUser|Volatile Environment'] =
            New-TestRegistrySnapshot -Exists $true -Values @(
                New-TestRegistryValue -Name 'RunAsTI' -Kind 'MultiString' `
                    -Value @($metadata, $code)
            )
        $approvedHash = $script:AtlasLegacySendToFingerprints[0]
        $harness.Context.Files[$script:TestSendToPath] = New-TestFileSnapshot `
            -Path $script:TestSendToPath -Sha256 $approvedHash

        $output = @(
            Invoke-TestLegacyMigration -Harness $harness `
                -VolatileCodeFingerprints @($codeFingerprint)
        )

        $output.Count | Should -Be 1
        $output[0] -is [Management.Automation.PSCustomObject] | Should -BeTrue
        (@($output[0].PSObject.Properties.Name | Sort-Object) -join ',') |
            Should -BeExactly 'AppliedCount,WarningCount'
        $output[0].AppliedCount | Should -Be 4
        $output[0].WarningCount | Should -Be 0
        $output[0].AppliedCount.GetType().IsPrimitive | Should -BeTrue
        $output[0].WarningCount.GetType().IsPrimitive | Should -BeTrue
        $harness.Context.RegistryWrites.Count | Should -Be 2
        $harness.Context.TreeRemovals.Count | Should -Be 1
        $harness.Context.ValueRemovals.Count | Should -Be 1
        $harness.Context.FileRemovals.Count | Should -Be 1
        $harness.Context.Logs.Count | Should -Be 4
    }
}

Describe 'Closed historical legacy fingerprints' {
    It 'pins both TermsRunAsTI identities and accepts the older exact payload' {
        $expected = @(
            '3472509A2BE945593493DFF98BC4B2DD2C3320D25FC2E3115FF86DF88ADBDC34'
            '558BEC70055E20B4CF58AE425AE77421F59DF7712BC8193BFC2FC2781CC29C73'
        )
        $script:AtlasLegacyTermsFingerprints.Count | Should -Be 2
        ($script:AtlasLegacyTermsFingerprints -join "`n") | Should -BeExactly `
            ($expected -join "`n")

        $olderSnapshot = New-TestOlderTermsSnapshot
        (Get-AtlasLegacyTermsFingerprint -Snapshot $olderSnapshot) | Should -BeExactly $expected[0]
        $harness = New-TestLegacyMigrationHarness
        $harness.Context.Registry['LocalMachine|SOFTWARE\Classes\TermsRunAsTI'] = $olderSnapshot

        $result = @(Invoke-TestLegacyMigration -Harness $harness)

        $result.Count | Should -Be 1
        $result[0].AppliedCount | Should -Be 1
        $result[0].WarningCount | Should -Be 0
        (@($harness.Context.TreeRemovals) -join ',') | Should -BeExactly `
            'LocalMachine|SOFTWARE\Classes\TermsRunAsTI'
    }

    It 'pins four historical merge tuples and migrates a non-current tuple' {
        $expected = @(
            'cmd /c "%windir%\AtlasModules\Scripts\RunAsTI.cmd" "%1"'
            'RunAsTI.cmd reg import "%1"'
            'cmd /c %windir%\AtlasModules\Scripts\RunAsTI.cmd "%1"'
            'cmd /c C:\Windows\AtlasModules\Scripts\RunAsTI.cmd "%1"'
        )
        $script:AtlasLegacyMergeCommands.Count | Should -Be 4
        $script:AtlasMergeLegacyCommands.Count | Should -Be 4
        ($script:AtlasLegacyMergeCommands -join "`n") | Should -BeExactly ($expected -join "`n")
        ($script:AtlasMergeLegacyCommands -join "`n") | Should -BeExactly ($expected -join "`n")

        $mergeHarness = New-TestMergeHarness -Parent (New-TestLegacyMergeParent) `
            -Command (New-TestRegistrySnapshot -Exists $true -Values @(
                    New-TestRegistryValue -Name '' -Kind 'String' -Value $expected[2]
                ))
        Invoke-AtlasAdministratorMergeTransition -RegistryReader $mergeHarness.RegistryReader `
            -RegistryWriter $mergeHarness.RegistryWriter
        Assert-TestMergeCanonical -Harness $mergeHarness

        $migrationHarness = New-TestLegacyMigrationHarness
        Set-TestLegacyMergeState -Harness $migrationHarness -Command $expected[1]
        $result = @(Invoke-TestLegacyMigration -Harness $migrationHarness)
        $result.Count | Should -Be 1
        $result[0].AppliedCount | Should -Be 1
        $migrationHarness.Context.RegistryWrites.Count | Should -Be 2
    }

    It 'pins and accepts every one of the 24 historical SendTo file identities' {
        $expected = @(
            '04663F101CBFFDF92D24E58F084400AE1D938A2C7C4FBA7DD84FC77871D8D29B'
            '12C795339A361120E9B7684C06BE862BF42AB20E59B3B2B24D44A944CED4A410'
            '303C8B0C1543E5196415D6E31CC3843408241A6CE38601626DE9C93395A8175A'
            '36A3318CD4A466776D9EA86E29685B9C3FB4D2D8E9737726DF823039B6E27B81'
            '377BF20004CDE1AC3CDCC2C1782F67D393B2A1608ED3A633136E3ED5C7BEC65B'
            '38861297180726C8A100B24E130F72F88FDEACBB1CD149E6D0BC0F9CE36E180A'
            '594AE292B2C6572F082E684730F2527806C7B09ED49588FBB20AF5DB6273E67E'
            '5B60B71463A947F28A10A24D4672516D46FC34C9486A473FF9362E0E45110393'
            '673FDA7AAFA2D81147D6DB6893D4FA4AC98F423101503351D6425E37FA5ED185'
            '7C9BD23B02A862FBA1756817E1C80CA887F0B276D83ABA0CFAFEFD4A156CF268'
            '936AD2E2998971661D2B504008B8B7C11703829A2A51F7C96D17928ED1BAA387'
            '9B8A2FC7B3623479BC64036ABD6624DE4F2B185579BA3FDCD7710ADBD278F301'
            'A040DA65BC468670DF410453311874EB73E09CB5242386545DE0FF03B32B5C67'
            'AD0A7AE781DB196AEAD82E26A3C16AC82224421690E08B41595B745A6F4952F6'
            'AEE9F48E498CB7A0C0F17544A59E62DCBA98B6B5E64314D75D332BAF7B91EDD2'
            'B3D0F159085C0006DFC36B30B1A787AAE08F2EAFAB3A56571162D5F86DB7FE0F'
            'B6476D224A31130660E575CFD436BC691212FD6C433FA40B2B8B2BFB6DF2C413'
            'C091CB1AD475F6CECA02D29337CF858DF0B35CD11FC1A74FB3DB699539FAB23F'
            'C2544AE883E5F7ED8FCA0BE2B9AC8FB362086ABA165BC7BF31FB79FBBF06C8A7'
            'C6A8D88172E6E1F6DA4B985717DA1B313B903195289C1EDB4F96DBD27942D93E'
            'D4AD9184B0F183ACD4D5219171A604EC69CF15037A745B6621C2D84720C921CC'
            'D92A74327CC6AFDA660BB49035DEC9604BED067CF581F1A10F71830BDD5077A4'
            'E58DF357E4AAF9E39C81E98233E054A0D385BD674ABBAB9DC3F9CDD594B8FFA0'
            'F4D621672015506BCF8CF230A4E270D8E629DFAA78A020EA6B4670E43CFDD83D'
        )

        $script:AtlasLegacySendToFingerprints.Count | Should -Be 24
        @($script:AtlasLegacySendToFingerprints | Sort-Object -Unique).Count | Should -Be 24
        ($script:AtlasLegacySendToFingerprints -join "`n") | Should -BeExactly ($expected -join "`n")
        foreach ($fingerprint in $script:AtlasLegacySendToFingerprints) {
            $fingerprint | Should -Match '^[A-F0-9]{64}$'
            $harness = New-TestLegacyMigrationHarness
            $harness.Context.Files[$script:TestSendToPath] = New-TestFileSnapshot `
                -Path $script:TestSendToPath -Sha256 $fingerprint

            $result = @(Invoke-TestLegacyMigration -Harness $harness)

            $result.Count | Should -Be 1
            $result[0].AppliedCount | Should -Be 1
            $harness.Context.FileRemovals.Count | Should -Be 1
        }
    }

    It 'pins the four historical volatile-code identities and requires metadata binding' {
        $expected = @(
            '84A472EA90D6B3A2242569B29ED9C02059BF3950F6AFABFAE7EF24B9C6306A98'
            '89AA003B68C3E7F71ADF1433448CA135A847079D2E19D159EF1A5BBA04933913'
            'BA758021EAF55DFDC6995472EBFEBD95685A8292A6E94A31DDE85AD32E6E5626'
            'BA7D4BEA5E3C873463C0332D4CC11CB4ADDCB4A570235D458499D14FAD49B75C'
        )

        $script:AtlasLegacyVolatileCodeFingerprints.Count | Should -Be 4
        @($script:AtlasLegacyVolatileCodeFingerprints | Sort-Object -Unique).Count | Should -Be 4
        ($script:AtlasLegacyVolatileCodeFingerprints -join "`n") | Should -BeExactly `
            ($expected -join "`n")
        foreach ($fingerprint in $script:AtlasLegacyVolatileCodeFingerprints) {
            $fingerprint | Should -Match '^[A-F0-9]{64}$'
        }

        $code = 'test volatile code'
        $fingerprint = Get-AtlasLegacySha256Text -Text $code
        $valid = New-TestRegistryValue -Name 'RunAsTI' -Kind 'MultiString' -Value @(
            '$id=''RunAsTI''; $key=''Registry::HKU\S-1-5-21-1-2-3-1001\Volatile Environment'';'
            $code
        )
        $wrongIdentity = New-TestRegistryValue -Name 'RunAsTI' -Kind 'MultiString' -Value @(
            '$id=''RunAsTI''; $key=''Registry::HKU\S-1-5-21-1-2-3-1002\Other'';'
            $code
        )
        (Test-AtlasLegacyVolatileValue -Value $valid -CodeFingerprints @($fingerprint)) |
            Should -BeTrue
        (Test-AtlasLegacyVolatileValue -Value $wrongIdentity `
                -CodeFingerprints @($fingerprint)) | Should -BeFalse
    }
}

Describe 'PreInstall legacy migration result contract' {
    It 'requires exactly one PSCustomObject with only nonnegative integral counts' {
        $script:PreInstallSource | Should -Match `
            '(?m)^\$legacyMigrationOutput\s*=\s*@\(& \$legacyMigration\)\s*$'
        $script:PreInstallSource | Should -Match '\$legacyMigrationOutput\.Count\s+-ne\s+1'
        $script:PreInstallSource | Should -Match `
            '\$legacyMigrationResult\s+-isnot\s+\[Management\.Automation\.PSCustomObject\]'
        $script:PreInstallSource | Should -Match '\$resultProperties\.Count\s+-ne\s+2'
        $script:PreInstallSource | Should -Match `
            '\$resultProperties\s+-cnotcontains\s+''AppliedCount'''
        $script:PreInstallSource | Should -Match `
            '\$resultProperties\s+-cnotcontains\s+''WarningCount'''
        foreach ($typeName in @('SByte', 'Byte', 'Int16', 'UInt16', 'Int32', 'UInt32', 'Int64', 'UInt64')) {
            $script:PreInstallSource | Should -Match ([regex]::Escape("'$typeName'"))
        }
        $script:PreInstallSource | Should -Match `
            '\$integralTypeCodes\s+-cnotcontains\s+\$typeCode'
        $script:PreInstallSource | Should -Match '\[decimal\]\$value\s+-lt\s+0'
        $script:PreInstallSource | Should -Not -Match `
            '(?i)Select-Object\s+-(?:First|Last)|Write-Output\s+\$legacyMigrationResult'
    }

    It 'keeps both migration entrypoints inert when dot-sourced' {
        $script:LegacyMigrationSource | Should -Match `
            'if \(\$MyInvocation\.InvocationName -ne ''\.''\)'
        $script:MergeTransitionSource | Should -Match `
            'if \(\$MyInvocation\.InvocationName -ne ''\.''\)'
    }
}
