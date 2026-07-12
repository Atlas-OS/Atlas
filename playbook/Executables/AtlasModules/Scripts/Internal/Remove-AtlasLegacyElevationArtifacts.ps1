<#
.SYNOPSIS
    Removes elevation persistence left by released Atlas versions.
.DESCRIPTION
    Machine scope removes the released RunAsTI terminal registrations and terminal
    state, and converts the released registry-file verb to the UAC-backed
    Administrator command. CurrentUser scope removes only the released volatile
    RunAsTI value after verifying the current token against ExpectedUserSid.

    Development-only SendTo and NSudo variants are intentionally not migration
    contracts. Customized registry entries are retained.
#>

[CmdletBinding()]
param(
    [ValidateSet('Machine', 'CurrentUser')][string]$Scope = 'Machine',
    [string]$ExpectedUserSid
)

Set-StrictMode -Version 3.0

$script:AtlasLegacyMergeCommands = @('RunAsTI.cmd reg import "%1"',
    'cmd /c %windir%\AtlasModules\Scripts\RunAsTI.cmd "%1"',
    'cmd /c "%windir%\AtlasModules\Scripts\RunAsTI.cmd" "%1"')
$script:AtlasAdministratorMergeCommand = '"%SystemRoot%\System32\reg.exe" import "%1"'
$script:AtlasLegacyTerminalCommands = @{
    OpenPSAdmin = 'PowerShell.exe -win 1 -nop -c iex((10..40|%%{(gp ''Registry::HKCR\TermsRunAsTI'' $_ -ea 0).$_})-join[char]10); # --%% cmd /k pushd "%V"'
    OpenPSAdmin0 = 'PowerShell.exe -win 1 -nop -c iex((10..40|%%{(gp ''Registry::HKCR\TermsRunAsTI'' $_ -ea 0).$_})-join[char]10); # --%% PowerShell.exe -noexit -command Set-Location -literalPath ''%V'''
}

# Decoded REG_SZ values from the TermsRunAsTI payload shipped in 0.4.x and 0.5.x.
$script:AtlasReleasedTermsData = @'
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
24| $Run=@($null, "PowerShell -win 1 -nop -c iex `$env:R; # $id", 0, 0, 0, 0x0E080600, 0, $null, ($A4 -as $T[4]), ($A5 -as $T[5]))
25| F 'CreateProcess' $Run; return}; $env:R=''; rp $key $id -force; $priv=[diagnostics.process]."GetM`ember"('SetPrivilege',42)[0]
26| 'SeSecurityPrivilege','SeTakeOwnershipPrivilege','SeBackupPrivilege','SeRestorePrivilege' |% {$priv.Invoke($null, @("$_",2))}
27| $HKU=[uintptr][uint32]2147483651; $NT='S-1-5-18'; $reg=($HKU,$NT,8,2,($HKU -as $D[9])); F 'RegOpenKeyEx' $reg; $LNK=$reg[4]
28| function L ($1,$2,$3) {sp 'Registry::HKCR\AppID\{CDCBCFCA-3CDC-436f-A4E2-0E02075250C2}' 'RunAs' $3 -force -ea 0
29|  $b=[Text.Encoding]::Unicode.GetBytes("\Registry\User\$1"); F 'RegSetValueEx' @($2,'SymbolicLinkValue',0,6,[byte[]]$b,$b.Length)}
30| function Q {[int](gwmi win32_process -filter 'name="explorer.exe"'|?{$_.getownersid().sid-eq$NT}|select -last 1).ProcessId}
31| $env:wt='PowerShell'; dir "$env:ProgramFiles\WindowsApps\Microsoft.WindowsTerminal*\wt.exe" -rec|% {$env:wt='"'+$_.FullName+'" "-d ."'}
32| $11bug=($((gwmi Win32_OperatingSystem).BuildNumber)-eq'22000')-AND(($cmd-eq'file:')-OR(test-path -lit $cmd -PathType Container))
33| if ($11bug) {'System.Windows.Forms','Microsoft.VisualBasic' |% {$9=[Reflection.Assembly]::LoadWithPartialName("'$_")}}
34| if ($11bug) {$path='^(l)'+$($cmd -replace '([\+\^\%\~\(\)\[\]])','{$1}')+'{ENTER}'; $cmd='control.exe'; $arg='admintools'}
35| L ($key-split'\\')[1] $LNK ''; $R=[diagnostics.process]::start($cmd,$arg); if ($R) {$R.PriorityClass='High'; $R.WaitForExit()}
36| if ($11bug) {$w=0; do {if($w-gt40){break}; sleep -mi 250;$w++} until (Q); [Microsoft.VisualBasic.Interaction]::AppActivate($(Q))}
37| if ($11bug) {[Windows.Forms.SendKeys]::SendWait($path)}; do {sleep 7} while(Q); L '.Default' $LNK 'Interactive User'
38|'@; $V='';'cmd','arg','id','key'|%{$V+="`n`$$_='$($(gv $_ -val)-replace"'","''")';"}; sp $key $id $($V,$code) -type 7 -force -ea 0
39| start PowerShell -args "-win 1 -nop -c `n$V `$env:R=(gi `$key -ea 0).getvalue(`$id)-join''; iex `$env:R" -verb runas
40|}; $A=,([environment]::commandline-split'-[-]%+ ?',2)[1]-split'"([^"]+)"|([^ ]+)',2|%{$_.Trim(' "')}; RunAsTI $A[1] $A[2]; # AveYo, 2023.07.06
'@

function Get-AtlasReleasedTermsValueMap {
    $values = @{}
    foreach ($line in ($script:AtlasReleasedTermsData -split "`r?`n")) {
        $separator = $line.IndexOf('|')
        $name = $line.Substring(0, $separator)
        $value = $line.Substring($separator + 1)
        if ($name -ceq '12') { $value += ' ' }
        $values[$name] = $value
    }
    return $values
}

function Get-AtlasLegacyRegistryKey {
    param([ValidateSet('Machine', 'CurrentUser')][string]$Hive, [string]$SubKey)

    $registryHive = if ($Hive -ceq 'Machine') {
        [Microsoft.Win32.RegistryHive]::LocalMachine
    }
    else { [Microsoft.Win32.RegistryHive]::CurrentUser }
    $base = $null
    $key = $null
    try {
        $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
            $registryHive, [Microsoft.Win32.RegistryView]::Registry64)
        $key = $base.OpenSubKey($SubKey, $false)
        if ($null -eq $key) {
            return [pscustomobject]@{ Exists = $false; Values = @{}; SubKeys = @() }
        }
        $values = @{}
        foreach ($name in $key.GetValueNames()) {
            $values[[string]$name] = [pscustomobject]@{
                Kind = $key.GetValueKind($name).ToString()
                Value = $key.GetValue($name, $null,
                    [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            }
        }
        return [pscustomobject]@{ Exists = $true; Values = $values; SubKeys = @($key.GetSubKeyNames()) }
    }
    finally {
        if ($null -ne $key) { $key.Dispose() }
        if ($null -ne $base) { $base.Dispose() }
    }
}

function Invoke-AtlasLegacyRegistryChange {
    param(
        [ValidateSet('RemoveTree', 'RemoveValue', 'WriteValue')][string]$Action,
        [ValidateSet('Machine', 'CurrentUser')][string]$Hive,
        [string]$SubKey, [string]$Name, [string]$Value, [string]$Kind
    )

    $registryHive = if ($Hive -ceq 'Machine') {
        [Microsoft.Win32.RegistryHive]::LocalMachine
    }
    else { [Microsoft.Win32.RegistryHive]::CurrentUser }
    $base = $null
    $key = $null
    try {
        $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
            $registryHive, [Microsoft.Win32.RegistryView]::Registry64)
        if ($Action -ceq 'RemoveTree') {
            $separator = $SubKey.LastIndexOf('\')
            $key = $base.OpenSubKey($SubKey.Substring(0, $separator), $true)
            if ($null -ne $key) { $key.DeleteSubKeyTree($SubKey.Substring($separator + 1), $false) }
        }
        elseif ($Action -ceq 'RemoveValue') {
            $key = $base.OpenSubKey($SubKey, $true)
            if ($null -ne $key) { $key.DeleteValue($Name, $false) }
        }
        else {
            $key = $base.CreateSubKey($SubKey)
            $valueKind = [Enum]::Parse([Microsoft.Win32.RegistryValueKind], $Kind, $false)
            $key.SetValue($Name, $Value, $valueKind)
        }
        if ($null -ne $key) { $key.Flush() }
    }
    finally {
        if ($null -ne $key) { $key.Dispose() }
        if ($null -ne $base) { $base.Dispose() }
    }
}

function Test-AtlasLegacyKeyExact {
    param($Key, [hashtable]$Values, [string[]]$SubKeys = @())

    if (-not $Key.Exists -or $Key.Values.Count -ne $Values.Count -or
        @($Key.SubKeys).Count -ne $SubKeys.Count) { return $false }
    foreach ($name in $Values.Keys) {
        if (-not $Key.Values.ContainsKey($name)) { return $false }
        $actual = $Key.Values[$name]
        $expected = $Values[$name]
        if ([string]$actual.Kind -cne [string]$expected[0] -or
            [string]$actual.Value -cne [string]$expected[1]) { return $false }
    }
    foreach ($subKey in $SubKeys) {
        if (@($Key.SubKeys | Where-Object { [string]$_ -ieq $subKey }).Count -ne 1) {
            return $false
        }
    }
    return $true
}

function Test-AtlasReleasedTermsKey {
    param($Key)

    $released = Get-AtlasReleasedTermsValueMap
    if (-not $Key.Exists -or $Key.Values.Count -ne $released.Count -or
        @($Key.SubKeys).Count -ne 0) { return $false }
    foreach ($name in $released.Keys) {
        if (-not $Key.Values.ContainsKey($name)) { return $false }
        $actual = $Key.Values[$name]
        if ([string]$actual.Kind -cne 'String') { return $false }
        if ([string]$actual.Value -cne [string]$released[$name]) { return $false }
    }
    return $true
}

function Test-AtlasReleasedVolatileValue {
    param($Value, [string]$ExpectedSid)

    if ($null -eq $Value -or [string]$Value.Kind -cne 'MultiString') { return $false }
    $parts = @($Value.Value)
    if ($parts.Count -ne 2) { return $false }
    $metadata = [string]$parts[0]
    if ($metadata -cnotmatch [regex]::Escape("`$id='RunAsTI'") -or
        $metadata -cnotmatch [regex]::Escape("`$key='Registry::HKU\$ExpectedSid\Volatile Environment'")) {
        return $false
    }

    $released = Get-AtlasReleasedTermsValueMap
    $code = ([string]$parts[1]).Replace("`r`n", "`n").Trim("`r", "`n")
    $codeLines = foreach ($number in (@(11..30) + @(32..37))) {
        $line = [string]$released[[string]$number]
        if ($number -eq 12) { $line = $line.TrimEnd() }
        elseif ($number -eq 24) { $line = $line.Replace('"PowerShell ', '"powershell ') }
        elseif ($number -eq 28) {
            $line = $line.Replace('Registry::HKCR\AppID', 'HKLM:\SOFTWARE\Classes\AppID')
        }
        elseif ($number -eq 33) { $line = $line.Replace('{$9=[Reflection', '{[Reflection') }
        $line
    }
    $expected = $codeLines -join "`n"
    $alternate = $expected.Replace('HKLM:\SOFTWARE\Classes', 'HKLM:\Software\Classes')
    return $code -ceq $expected -or $code -ceq $alternate
}

function Invoke-AtlasLegacyElevationMigrationCore {
    [CmdletBinding()]
    param(
        [ValidateSet('Machine', 'CurrentUser')][string]$Scope = 'Machine',
        [string]$ExpectedUserSid,
        [scriptblock]$RegistryReader,
        [scriptblock]$RegistryTreeRemover,
        [scriptblock]$RegistryValueRemover,
        [scriptblock]$RegistryValueWriter,
        [scriptblock]$IdentitySidReader
    )

    if ($null -eq $RegistryReader) {
        $RegistryReader = { param($Hive, $SubKey)
            Get-AtlasLegacyRegistryKey -Hive $Hive -SubKey $SubKey }
    }
    if ($null -eq $RegistryTreeRemover) {
        $RegistryTreeRemover = { param($Hive, $SubKey)
            Invoke-AtlasLegacyRegistryChange -Action RemoveTree -Hive $Hive -SubKey $SubKey }
    }
    if ($null -eq $RegistryValueRemover) {
        $RegistryValueRemover = { param($SubKey, $Name)
            Invoke-AtlasLegacyRegistryChange -Action RemoveValue -Hive CurrentUser `
                -SubKey $SubKey -Name $Name }
    }
    if ($null -eq $RegistryValueWriter) {
        $RegistryValueWriter = { param($SubKey, $Name, $Value, $Kind)
            Invoke-AtlasLegacyRegistryChange -Action WriteValue -Hive Machine `
                -SubKey $SubKey -Name $Name -Value $Value -Kind $Kind }
    }
    if ($null -eq $IdentitySidReader) {
        $IdentitySidReader = { [Security.Principal.WindowsIdentity]::GetCurrent().User.Value }
    }

    $removed = $migrated = $retained = 0

    if ($Scope -ceq 'CurrentUser') {
        if ([string]::IsNullOrWhiteSpace($ExpectedUserSid)) {
            throw 'Current-user legacy migration requires the install-state user SID.' }
        try { $expectedSid = (New-Object Security.Principal.SecurityIdentifier($ExpectedUserSid)).Value }
        catch { throw "The expected current-user SID '$ExpectedUserSid' is invalid." }
        $actualSid = [string](& $IdentitySidReader)
        if ($actualSid -cne $expectedSid) {
            throw "Current-user legacy migration token SID '$actualSid' does not match install-state SID '$expectedSid'." }

        $volatile = & $RegistryReader 'CurrentUser' 'Volatile Environment'
        $value = if ($volatile.Exists -and $volatile.Values.ContainsKey('RunAsTI')) {
            $volatile.Values['RunAsTI']
        }
        else { $null }
        if (Test-AtlasReleasedVolatileValue $value $expectedSid) {
            [void](& $RegistryValueRemover 'Volatile Environment' 'RunAsTI')
            $removed++
        }
        elseif ($null -ne $value) {
            $retained++
            Write-Warning 'Customized current-user Volatile Environment\RunAsTI was retained.'
        }
        return [pscustomobject]@{ RemovedCount = $removed; MigratedCount = 0; RetainedCount = $retained }
    }
    if (-not [string]::IsNullOrWhiteSpace($ExpectedUserSid)) {
        throw 'Machine legacy migration must not accept a user SID.' }

    $roots = @('Directory\shell\AtlasTerminals', 'LibraryFolder\shell\AtlasTerminals',
        'Drive\shell\AtlasTerminals', 'Directory\Background\shell\AtlasTerminals')
    $terminalValues = @{
        OpenPSAdmin = @{ MUIVerb = @('String', 'Command Prompt (System)');
            HasLUAShield = @('String', ''); Icon = @('String', '%windir%\system32\cmd.exe,0') }
        OpenPSAdmin0 = @{ MUIVerb = @('String', 'PowerShell (System)');
            HasLUAShield = @('String', '');
            Icon = @('String', '%windir%\System32\WindowsPowerShell\v1.0\PowerShell.exe,0') }
    }
    foreach ($root in $roots) {
        foreach ($name in @('OpenPSAdmin', 'OpenPSAdmin0')) {
            $path = "SOFTWARE\Classes\$root\shell\$name"
            $parent = & $RegistryReader 'Machine' $path
            $command = & $RegistryReader 'Machine' "$path\command"
            $commandValues = @{ '' = @('String', $script:AtlasLegacyTerminalCommands[$name]) }
            if ((Test-AtlasLegacyKeyExact -Key $parent -Values $terminalValues[$name] `
                    -SubKeys @('command')) -and
                (Test-AtlasLegacyKeyExact -Key $command -Values $commandValues)) {
                [void](& $RegistryTreeRemover 'Machine' $path)
                $removed++
            }
            elseif ($parent.Exists -or $command.Exists) {
                $retained++
                Write-Warning "Customized terminal entry 'HKLM\$path' was retained."
            }
        }
    }

    $mergePath = 'SOFTWARE\Classes\regfile\Shell\RunAs'
    $merge = & $RegistryReader 'Machine' $mergePath
    $mergeCommand = & $RegistryReader 'Machine' "$mergePath\Command"
    $legacyParent = @{ '' = @('String', 'Merge As TrustedInstaller'); HasLUAShield = @('String', '1') }
    $legacyCommand = $mergeCommand.Exists -and $mergeCommand.Values.Count -eq 1 -and
        $mergeCommand.Values.ContainsKey('') -and
        [string]$mergeCommand.Values[''].Kind -ceq 'String' -and
        $script:AtlasLegacyMergeCommands -ccontains [string]$mergeCommand.Values[''].Value
    $newParent = @{ '' = @('String', 'Merge as administrator'); HasLUAShield = @('String', '1') }
    $newCommand = @{ '' = @('ExpandString', $script:AtlasAdministratorMergeCommand) }
    $parentIsLegacy = Test-AtlasLegacyKeyExact -Key $merge -Values $legacyParent -SubKeys @('Command')
    $parentIsNew = Test-AtlasLegacyKeyExact -Key $merge -Values $newParent -SubKeys @('Command')
    $commandIsNew = Test-AtlasLegacyKeyExact -Key $mergeCommand -Values $newCommand
    if (($parentIsLegacy -and ($legacyCommand -or $commandIsNew)) -or
        ($parentIsNew -and $legacyCommand)) {
        [void](& $RegistryValueWriter "$mergePath\Command" '' $script:AtlasAdministratorMergeCommand 'ExpandString')
        [void](& $RegistryValueWriter $mergePath '' 'Merge as administrator' 'String')
        $migrated++
    }
    elseif (($merge.Exists -or $mergeCommand.Exists) -and -not ($parentIsNew -and $commandIsNew)) {
        $retained++
        Write-Warning "Customized registry-file RunAs entry 'HKLM\$mergePath' was retained."
    }

    $termsPath = 'SOFTWARE\Classes\TermsRunAsTI'
    $terms = & $RegistryReader 'Machine' $termsPath
    if (Test-AtlasReleasedTermsKey $terms) {
        [void](& $RegistryTreeRemover 'Machine' $termsPath)
        $removed++
    }
    elseif ($terms.Exists) {
        $retained++
        Write-Warning "Customized TermsRunAsTI entry 'HKLM\$termsPath' was retained."
    }

    $statePath = 'SOFTWARE\AtlasOS\ContextMenuTerminals'
    $state = & $RegistryReader 'Machine' $statePath
    $stateExact = $state.Exists -and $state.Values.Count -eq 1 -and
        $state.Values.ContainsKey('state') -and @($state.SubKeys).Count -eq 0 -and
        [string]$state.Values['state'].Kind -ceq 'DWord' -and
        [int64]$state.Values['state'].Value -in 0..3
    if ($stateExact) {
        [void](& $RegistryTreeRemover 'Machine' $statePath)
        $removed++
    }
    elseif ($state.Exists) {
        $retained++
        Write-Warning "Customized terminal state 'HKLM\$statePath' was retained."
    }

    return [pscustomobject]@{ RemovedCount = $removed; MigratedCount = $migrated;
        RetainedCount = $retained }
}

if ($MyInvocation.InvocationName -ne '.') {
    $ErrorActionPreference = 'Stop'
    $trustBootstrap = [IO.Path]::Combine($PSScriptRoot, 'Initialize-PowerShellTrust.ps1')
    if (-not [IO.File]::Exists($trustBootstrap)) {
        throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
    }
    . $trustBootstrap
    Invoke-AtlasLegacyElevationMigrationCore -Scope $Scope -ExpectedUserSid $ExpectedUserSid
}
