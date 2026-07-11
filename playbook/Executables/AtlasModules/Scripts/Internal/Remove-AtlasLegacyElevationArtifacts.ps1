<#
.SYNOPSIS
    Removes exact Atlas/AveYo legacy elevation persistence without executing it.
.DESCRIPTION
    This migration recognizes only the shipped TermsRunAsTI registry-code payload,
    its duplicate System terminal verbs, Atlas's former Merge-as-TrustedInstaller
    command, the old terminal state marker, and exact current-user copies produced by
    RunAsTI.cmd. Unknown user artifacts are retained and logged. An ambiguous machine
    command or machine registry-code key aborts the install before any mutation occurs.

    Safe Mode, scheduled-task, Winlogon, BCD, package-list, and AppID recovery belong to
    the separate reboot-aware migration and are intentionally outside this script.
#>

Set-StrictMode -Version 3.0

$script:AtlasLegacyTermsFingerprints = @(
    # Exact 10..40 REG_SZ payloads found across all historical Atlas .reg blobs.
    '3472509A2BE945593493DFF98BC4B2DD2C3320D25FC2E3115FF86DF88ADBDC34'
    '558BEC70055E20B4CF58AE425AE77421F59DF7712BC8193BFC2FC2781CC29C73'
)
$script:AtlasLegacySendToFingerprints = @(
    # Exact normalized hashes of all 24 historical RunAsTI.cmd Git blobs. RunAsTI
    # copied its complete source into SendTo, so these are closed release identities.
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
$script:AtlasLegacyVolatileCodeFingerprints = @(
    '84A472EA90D6B3A2242569B29ED9C02059BF3950F6AFABFAE7EF24B9C6306A98'
    '89AA003B68C3E7F71ADF1433448CA135A847079D2E19D159EF1A5BBA04933913'
    'BA758021EAF55DFDC6995472EBFEBD95685A8292A6E94A31DDE85AD32E6E5626'
    'BA7D4BEA5E3C873463C0332D4CC11CB4ADDCB4A570235D458499D14FAD49B75C'
)
$script:AtlasLegacyMergeLabel = 'Merge As TrustedInstaller'
$script:AtlasLegacyMergeCommands = @(
    # Exact machine command tuples found in the historical merge tweak objects.
    'cmd /c "%windir%\AtlasModules\Scripts\RunAsTI.cmd" "%1"'
    'RunAsTI.cmd reg import "%1"'
    'cmd /c %windir%\AtlasModules\Scripts\RunAsTI.cmd "%1"'
    'cmd /c C:\Windows\AtlasModules\Scripts\RunAsTI.cmd "%1"'
)
$script:AtlasAdministratorMergeLabel = 'Merge as administrator'
$script:AtlasAdministratorMergeCommand = '"%SystemRoot%\System32\reg.exe" import "%1"'
$script:AtlasLegacyTerminalCmdCommand = `
    'PowerShell.exe -win 1 -nop -c iex((10..40|%%{(gp ''Registry::HKCR\TermsRunAsTI'' $_ -ea 0).$_})-join[char]10); # --%% cmd /k pushd "%V"'
$script:AtlasLegacyTerminalPowerShellCommand = `
    'PowerShell.exe -win 1 -nop -c iex((10..40|%%{(gp ''Registry::HKCR\TermsRunAsTI'' $_ -ea 0).$_})-join[char]10); # --%% PowerShell.exe -noexit -command Set-Location -literalPath ''%V'''

function Get-AtlasLegacySha256Text {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text
    )

    $normalized = $Text.Replace("`r`n", "`n").Replace("`r", "`n")
    $encoding = New-Object Text.UTF8Encoding($false, $true)
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha256.ComputeHash($encoding.GetBytes($normalized)))).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
    }
}

function Get-AtlasLegacyRegistryKeySnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('LocalMachine', 'CurrentUser')]
        [string]$Hive,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SubKey
    )

    $baseKey = $null
    $key = $null
    try {
        $registryHive = if ($Hive -ceq 'LocalMachine') {
            [Microsoft.Win32.RegistryHive]::LocalMachine
        }
        else {
            [Microsoft.Win32.RegistryHive]::CurrentUser
        }
        $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
            $registryHive,
            [Microsoft.Win32.RegistryView]::Registry64
        )
        $key = $baseKey.OpenSubKey($SubKey, $false)
        if ($null -eq $key) {
            return [pscustomobject]@{
                Exists  = $false
                Hive    = $Hive
                SubKey  = $SubKey
                Values  = @()
                SubKeys = @()
            }
        }

        $values = @($key.GetValueNames() | ForEach-Object {
                $name = [string]$_
                [pscustomobject]@{
                    Name  = $name
                    Kind  = $key.GetValueKind($name).ToString()
                    Value = $key.GetValue(
                        $name,
                        $null,
                        [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
                    )
                }
            })
        return [pscustomobject]@{
            Exists  = $true
            Hive    = $Hive
            SubKey  = $SubKey
            Values  = $values
            SubKeys = @($key.GetSubKeyNames())
        }
    }
    finally {
        if ($null -ne $key) { $key.Dispose() }
        if ($null -ne $baseKey) { $baseKey.Dispose() }
    }
}

function Remove-AtlasLegacyRegistryTree {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('LocalMachine', 'CurrentUser')]
        [string]$Hive,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SubKey
    )

    if (-not $PSCmdlet.ShouldProcess("$Hive\$SubKey", 'Remove exact legacy registry tree')) {
        return
    }

    $separator = $SubKey.LastIndexOf('\')
    if ($separator -lt 1 -or $separator -eq ($SubKey.Length - 1)) {
        throw "Legacy registry path '$SubKey' has no safe parent and leaf."
    }
    $parentPath = $SubKey.Substring(0, $separator)
    $leaf = $SubKey.Substring($separator + 1)
    $registryHive = if ($Hive -ceq 'LocalMachine') {
        [Microsoft.Win32.RegistryHive]::LocalMachine
    }
    else {
        [Microsoft.Win32.RegistryHive]::CurrentUser
    }

    $baseKey = $null
    $parent = $null
    try {
        $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
            $registryHive,
            [Microsoft.Win32.RegistryView]::Registry64
        )
        $parent = $baseKey.OpenSubKey($parentPath, $true)
        if ($null -ne $parent) {
            $parent.DeleteSubKeyTree($leaf, $false)
            $parent.Flush()
        }
    }
    finally {
        if ($null -ne $parent) { $parent.Dispose() }
        if ($null -ne $baseKey) { $baseKey.Dispose() }
    }
}

function Remove-AtlasLegacyRegistryValue {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('LocalMachine', 'CurrentUser')]
        [string]$Hive,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SubKey,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Name
    )

    if (-not $PSCmdlet.ShouldProcess("$Hive\$SubKey [$Name]", 'Remove exact legacy registry value')) {
        return
    }

    $registryHive = if ($Hive -ceq 'LocalMachine') {
        [Microsoft.Win32.RegistryHive]::LocalMachine
    }
    else {
        [Microsoft.Win32.RegistryHive]::CurrentUser
    }
    $baseKey = $null
    $key = $null
    try {
        $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
            $registryHive,
            [Microsoft.Win32.RegistryView]::Registry64
        )
        $key = $baseKey.OpenSubKey($SubKey, $true)
        if ($null -ne $key -and @($key.GetValueNames()) -icontains $Name) {
            $key.DeleteValue($Name, $false)
            $key.Flush()
        }
    }
    finally {
        if ($null -ne $key) { $key.Dispose() }
        if ($null -ne $baseKey) { $baseKey.Dispose() }
    }
}

function Set-AtlasLegacyRegistryValue {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('LocalMachine', 'CurrentUser')]
        [string]$Hive,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SubKey,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value,

        [Parameter(Mandatory = $true)]
        [ValidateSet('String', 'ExpandString')]
        [string]$Kind
    )

    if (-not $PSCmdlet.ShouldProcess("$Hive\$SubKey [$Name]", "Write canonical $Kind value")) {
        return
    }

    $registryHive = if ($Hive -ceq 'LocalMachine') {
        [Microsoft.Win32.RegistryHive]::LocalMachine
    }
    else {
        [Microsoft.Win32.RegistryHive]::CurrentUser
    }
    $baseKey = $null
    $key = $null
    try {
        $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
            $registryHive,
            [Microsoft.Win32.RegistryView]::Registry64
        )
        $key = $baseKey.CreateSubKey($SubKey)
        if ($null -eq $key) {
            throw "Creating or opening '$Hive\$SubKey' returned no registry key."
        }
        $valueKind = [Enum]::Parse([Microsoft.Win32.RegistryValueKind], $Kind, $false)
        $key.SetValue($Name, $Value, $valueKind)
        $key.Flush()
    }
    finally {
        if ($null -ne $key) { $key.Dispose() }
        if ($null -ne $baseKey) { $baseKey.Dispose() }
    }
}

function Get-AtlasLegacyFileSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    if (-not [IO.File]::Exists($Path)) {
        return [pscustomobject]@{ Exists = $false; Path = $Path; IsReparsePoint = $false; Sha256 = $null; LegacyMarker = $false }
    }

    $attributes = [IO.File]::GetAttributes($Path)
    $isReparsePoint = ($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
    if ($isReparsePoint) {
        return [pscustomobject]@{ Exists = $true; Path = $Path; IsReparsePoint = $true; Sha256 = $null; LegacyMarker = $false }
    }

    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -gt 64KB) {
        return [pscustomobject]@{ Exists = $true; Path = $Path; IsReparsePoint = $false; Sha256 = $null; LegacyMarker = $false }
    }
    $offset = if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { 3 } else { 0 }
    $encoding = New-Object Text.UTF8Encoding($false, $true)
    try {
        $text = $encoding.GetString($bytes, $offset, $bytes.Length - $offset)
    }
    catch {
        return [pscustomobject]@{ Exists = $true; Path = $Path; IsReparsePoint = $false; Sha256 = $null; LegacyMarker = $false }
    }
    return [pscustomobject]@{
        Exists        = $true
        Path          = $Path
        IsReparsePoint = $false
        Sha256        = Get-AtlasLegacySha256Text -Text $text
        LegacyMarker  = $text -cmatch '#:RunAsTI|RunAsTI - lean and mean snippet by AveYo'
    }
}

function Remove-AtlasLegacyFile {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[A-F0-9]{64}$')]
        [string]$ExpectedSha256
    )

    $snapshot = Get-AtlasLegacyFileSnapshot -Path $Path
    if (-not $snapshot.Exists) { return }
    if ($snapshot.IsReparsePoint -or $snapshot.Sha256 -cne $ExpectedSha256) {
        throw "Legacy user file '$Path' changed after preflight; refusing to remove it."
    }
    if ($PSCmdlet.ShouldProcess($Path, 'Remove exact legacy user file')) {
        [IO.File]::Delete($Path)
    }
}

function Get-AtlasLegacySnapshotValue {
    param(
        [Parameter(Mandatory = $true)]$Snapshot,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Name
    )

    $matchingValues = @($Snapshot.Values | Where-Object { [string]$_.Name -ieq $Name })
    if ($matchingValues.Count -ne 1) { return $null }
    return $matchingValues[0]
}

function Test-AtlasLegacyValueEqual {
    param($Left, $Right)

    if ($Left -is [array] -or $Right -is [array]) {
        $leftItems = @($Left)
        $rightItems = @($Right)
        if ($leftItems.Count -ne $rightItems.Count) { return $false }
        for ($index = 0; $index -lt $leftItems.Count; $index++) {
            if ([string]$leftItems[$index] -cne [string]$rightItems[$index]) { return $false }
        }
        return $true
    }
    return [string]$Left -ceq [string]$Right
}

function Test-AtlasLegacyRegistrySnapshotExact {
    param(
        [Parameter(Mandatory = $true)]$Snapshot,
        [Parameter(Mandatory = $true)][object[]]$ExpectedValues,
        [string[]]$ExpectedSubKeys = @()
    )

    if (-not $Snapshot.Exists -or @($Snapshot.Values).Count -ne $ExpectedValues.Count -or
        @($Snapshot.SubKeys).Count -ne $ExpectedSubKeys.Count) {
        return $false
    }
    foreach ($expected in $ExpectedValues) {
        $actual = Get-AtlasLegacySnapshotValue -Snapshot $Snapshot -Name ([string]$expected.Name)
        if ($null -eq $actual -or [string]$actual.Kind -cne [string]$expected.Kind -or
            -not (Test-AtlasLegacyValueEqual -Left $actual.Value -Right $expected.Value)) {
            return $false
        }
    }
    foreach ($expectedSubKey in $ExpectedSubKeys) {
        if (@($Snapshot.SubKeys | Where-Object { [string]$_ -ieq $expectedSubKey }).Count -ne 1) {
            return $false
        }
    }
    return $true
}

function Test-AtlasLegacyRegistrySnapshotUnchanged {
    param(
        [Parameter(Mandatory = $true)]$Before,
        [Parameter(Mandatory = $true)]$After
    )

    if ([bool]$Before.Exists -ne [bool]$After.Exists) { return $false }
    if (-not $Before.Exists) { return $true }
    return Test-AtlasLegacyRegistrySnapshotExact -Snapshot $After `
        -ExpectedValues @($Before.Values) -ExpectedSubKeys @($Before.SubKeys)
}

function Test-AtlasLegacyRegistryValueUnchanged {
    param(
        [Parameter(Mandatory = $true)]$Snapshot,
        [Parameter(Mandatory = $true)]$ExpectedValue
    )

    if (-not $Snapshot.Exists) { return $false }
    $actual = Get-AtlasLegacySnapshotValue -Snapshot $Snapshot -Name ([string]$ExpectedValue.Name)
    return $null -ne $actual -and [string]$actual.Kind -ceq [string]$ExpectedValue.Kind -and
        (Test-AtlasLegacyValueEqual -Left $actual.Value -Right $ExpectedValue.Value)
}

function Get-AtlasLegacyTermsFingerprint {
    param([Parameter(Mandatory = $true)]$Snapshot)

    if (-not $Snapshot.Exists -or @($Snapshot.Values).Count -ne 31 -or @($Snapshot.SubKeys).Count -ne 0) {
        return $null
    }
    $builder = New-Object Text.StringBuilder
    foreach ($number in 10..40) {
        $name = $number.ToString()
        $value = Get-AtlasLegacySnapshotValue -Snapshot $Snapshot -Name $name
        if ($null -eq $value -or [string]$value.Kind -cne 'String' -or $value.Value -isnot [string]) {
            return $null
        }
        [void]$builder.Append($name)
        [void]$builder.Append([char]0)
        [void]$builder.Append('String')
        [void]$builder.Append([char]0)
        [void]$builder.Append([string]$value.Value)
        [void]$builder.Append([char]0)
    }
    return Get-AtlasLegacySha256Text -Text $builder.ToString()
}

function Test-AtlasLegacyVolatileValue {
    param(
        [Parameter(Mandatory = $true)]$Value,
        [Parameter(Mandatory = $true)][string[]]$CodeFingerprints
    )

    if ([string]$Value.Kind -cne 'MultiString') { return $false }
    $parts = @($Value.Value)
    if ($parts.Count -ne 2) { return $false }
    $metadata = [string]$parts[0]
    $codeFingerprint = Get-AtlasLegacySha256Text -Text ([string]$parts[1])
    if ($CodeFingerprints -cnotcontains $codeFingerprint) { return $false }
    return $metadata -cmatch '(?s)\$id=''RunAsTI'';.*\$key=''Registry::HKU\\S-1-5-[0-9-]+\\Volatile Environment'';'
}

function Invoke-AtlasLegacyElevationMigrationCore {
    [CmdletBinding()]
    param(
        [scriptblock]$RegistryReader,
        [scriptblock]$RegistryTreeRemover,
        [scriptblock]$RegistryValueRemover,
        [scriptblock]$RegistryValueWriter,
        [scriptblock]$FileReader,
        [scriptblock]$FileRemover,
        [scriptblock]$Logger,
        [string]$SendToPath,
        [ValidateNotNullOrEmpty()][ValidatePattern('^[A-F0-9]{64}$')]
        [string[]]$TermsFingerprints = $script:AtlasLegacyTermsFingerprints,
        [ValidateNotNullOrEmpty()][ValidatePattern('^[A-F0-9]{64}$')]
        [string[]]$SendToFingerprints = $script:AtlasLegacySendToFingerprints,
        [string[]]$VolatileCodeFingerprints = $script:AtlasLegacyVolatileCodeFingerprints
    )

    if ($null -eq $RegistryReader) {
        $RegistryReader = { param($Hive, $SubKey) Get-AtlasLegacyRegistryKeySnapshot -Hive $Hive -SubKey $SubKey }
    }
    if ($null -eq $RegistryTreeRemover) {
        $RegistryTreeRemover = { param($Hive, $SubKey) Remove-AtlasLegacyRegistryTree -Hive $Hive -SubKey $SubKey -Confirm:$false }
    }
    if ($null -eq $RegistryValueRemover) {
        $RegistryValueRemover = { param($Hive, $SubKey, $Name) Remove-AtlasLegacyRegistryValue -Hive $Hive -SubKey $SubKey -Name $Name -Confirm:$false }
    }
    if ($null -eq $RegistryValueWriter) {
        $RegistryValueWriter = { param($Hive, $SubKey, $Name, $Value, $Kind) Set-AtlasLegacyRegistryValue -Hive $Hive -SubKey $SubKey -Name $Name -Value $Value -Kind $Kind -Confirm:$false }
    }
    if ($null -eq $FileReader) {
        $FileReader = { param($Path) Get-AtlasLegacyFileSnapshot -Path $Path }
    }
    if ($null -eq $FileRemover) {
        $FileRemover = { param($Path, $ExpectedSha256) Remove-AtlasLegacyFile -Path $Path -ExpectedSha256 $ExpectedSha256 -Confirm:$false }
    }
    if ($null -eq $Logger) {
        $Logger = {
            param($Level, $Message)
            $logCommand = Get-Command -Name Write-AtlasLog -CommandType Function -ErrorAction SilentlyContinue
            if ($null -ne $logCommand) {
                & $logCommand -Level $Level -Message $Message
            }
            elseif ($Level -ceq 'Warning') {
                Write-Warning $Message
            }
            else {
                Write-Verbose $Message
            }
        }
    }

    $plan = New-Object 'Collections.Generic.List[object]'
    $warnings = New-Object 'Collections.Generic.List[string]'
    $machineErrors = New-Object 'Collections.Generic.List[string]'

    $classRoots = @(
        'Directory\shell\AtlasTerminals',
        'LibraryFolder\shell\AtlasTerminals',
        'Drive\shell\AtlasTerminals',
        'Directory\Background\shell\AtlasTerminals'
    )
    $terminalDefinitions = @(
        [pscustomobject]@{
            Name = 'OpenPSAdmin'
            ParentValues = @(
                [pscustomobject]@{ Name = 'MUIVerb'; Kind = 'String'; Value = 'Command Prompt (System)' }
                [pscustomobject]@{ Name = 'HasLUAShield'; Kind = 'String'; Value = '' }
                [pscustomobject]@{ Name = 'Icon'; Kind = 'String'; Value = '%windir%\system32\cmd.exe,0' }
            )
            Command = $script:AtlasLegacyTerminalCmdCommand
        }
        [pscustomobject]@{
            Name = 'OpenPSAdmin0'
            ParentValues = @(
                [pscustomobject]@{ Name = 'MUIVerb'; Kind = 'String'; Value = 'PowerShell (System)' }
                [pscustomobject]@{ Name = 'Icon'; Kind = 'String'; Value = '%windir%\System32\WindowsPowerShell\v1.0\PowerShell.exe,0' }
                [pscustomobject]@{ Name = 'HasLUAShield'; Kind = 'String'; Value = '' }
            )
            Command = $script:AtlasLegacyTerminalPowerShellCommand
        }
    )

    foreach ($hive in @('LocalMachine', 'CurrentUser')) {
        foreach ($root in $classRoots) {
            foreach ($terminal in $terminalDefinitions) {
                $parentPath = "SOFTWARE\Classes\$root\shell\$($terminal.Name)"
                $commandPath = "$parentPath\command"
                $parent = & $RegistryReader $hive $parentPath
                $command = & $RegistryReader $hive $commandPath
                $expectedCommand = @(
                    [pscustomobject]@{ Name = ''; Kind = 'String'; Value = $terminal.Command }
                )
                $exact = (Test-AtlasLegacyRegistrySnapshotExact -Snapshot $parent `
                        -ExpectedValues $terminal.ParentValues -ExpectedSubKeys @('command')) -and
                    (Test-AtlasLegacyRegistrySnapshotExact -Snapshot $command `
                        -ExpectedValues $expectedCommand)
                $commandValue = if ($command.Exists) {
                    Get-AtlasLegacySnapshotValue -Snapshot $command -Name ''
                }
                else { $null }
                $verbValue = if ($parent.Exists) {
                    Get-AtlasLegacySnapshotValue -Snapshot $parent -Name 'MUIVerb'
                }
                else { $null }
                $legacyEvidence = ($null -ne $commandValue -and
                        [string]$commandValue.Value -match '(?i)TermsRunAsTI|iex\(\(10\.\.40') -or
                    ($null -ne $verbValue -and [string]$verbValue.Value -match '\(System\)')

                if ($exact) {
                    $plan.Add([pscustomobject]@{
                            Priority = 10; Action = 'RemoveTree'; Hive = $hive; SubKey = $parentPath
                            Artifact = 'Terminal'; BeforeSnapshot = $parent
                            RelatedSubKey = $commandPath; BeforeRelatedSnapshot = $command
                            Reason = "Removed exact legacy $($terminal.Name) terminal verb."
                        })
                }
                elseif ($legacyEvidence) {
                    $message = "Ambiguous legacy terminal command '$hive\$parentPath' was retained."
                    if ($hive -ceq 'LocalMachine') { $machineErrors.Add($message) } else { $warnings.Add($message) }
                }
            }
        }
    }

    $mergePath = 'SOFTWARE\Classes\regfile\Shell\RunAs'
    $mergeCommandPath = "$mergePath\Command"
    $merge = & $RegistryReader 'LocalMachine' $mergePath
    $mergeCommand = & $RegistryReader 'LocalMachine' $mergeCommandPath
    $legacyMergeValues = @(
        [pscustomobject]@{ Name = ''; Kind = 'String'; Value = $script:AtlasLegacyMergeLabel }
        [pscustomobject]@{ Name = 'HasLUAShield'; Kind = 'String'; Value = '1' }
    )
    $administratorMergeValues = @(
        [pscustomobject]@{ Name = ''; Kind = 'String'; Value = $script:AtlasAdministratorMergeLabel }
        [pscustomobject]@{ Name = 'HasLUAShield'; Kind = 'String'; Value = '1' }
    )
    $administratorMergeCommand = @(
        [pscustomobject]@{ Name = ''; Kind = 'ExpandString'; Value = $script:AtlasAdministratorMergeCommand }
    )
    $legacyMergeParentExact = Test-AtlasLegacyRegistrySnapshotExact -Snapshot $merge `
        -ExpectedValues $legacyMergeValues -ExpectedSubKeys @('Command')
    $administratorMergeParentExact = Test-AtlasLegacyRegistrySnapshotExact -Snapshot $merge `
        -ExpectedValues $administratorMergeValues -ExpectedSubKeys @('Command')
    $oldCommandExact = $false
    foreach ($legacyCommandText in $script:AtlasLegacyMergeCommands) {
        $candidateLegacyCommand = @(
            [pscustomobject]@{ Name = ''; Kind = 'String'; Value = $legacyCommandText }
        )
        if (Test-AtlasLegacyRegistrySnapshotExact -Snapshot $mergeCommand `
                -ExpectedValues $candidateLegacyCommand) {
            $oldCommandExact = $true
            break
        }
    }
    $oldMergeExact = $legacyMergeParentExact -and $oldCommandExact
    $newMergeExact = $administratorMergeParentExact -and
        (Test-AtlasLegacyRegistrySnapshotExact -Snapshot $mergeCommand -ExpectedValues $administratorMergeCommand)
    $newCommandExact = Test-AtlasLegacyRegistrySnapshotExact -Snapshot $mergeCommand `
        -ExpectedValues $administratorMergeCommand
    $mergeLabelValue = if ($merge.Exists) { Get-AtlasLegacySnapshotValue -Snapshot $merge -Name '' } else { $null }
    $mergeCommandValue = if ($mergeCommand.Exists) {
        Get-AtlasLegacySnapshotValue -Snapshot $mergeCommand -Name ''
    }
    else { $null }
    $legacyMergeEvidence = ($null -ne $mergeLabelValue -and
            [string]$mergeLabelValue.Value -match '(?i)TrustedInstaller') -or
        ($null -ne $mergeCommandValue -and [string]$mergeCommandValue.Value -match '(?i)RunAsTI\.cmd')
    $safeTransition = $legacyMergeParentExact -and $newCommandExact
    $labelFirstTransition = $administratorMergeParentExact -and $oldCommandExact

    if ($oldMergeExact -or $safeTransition -or $labelFirstTransition) {
        $plan.Add([pscustomobject]@{
                Priority = 20; Action = 'ReplaceMerge'; Hive = 'LocalMachine'; SubKey = $mergePath
                BeforeSnapshot = $merge; RelatedSubKey = $mergeCommandPath
                BeforeRelatedSnapshot = $mergeCommand
                Reason = 'Replaced the exact legacy Merge-as-TrustedInstaller verb with Administrator reg import.'
            })
    }
    elseif (-not $newMergeExact -and $legacyMergeEvidence) {
        $machineErrors.Add("Ambiguous legacy Merge command 'LocalMachine\$mergePath' was retained.")
    }
    elseif ($merge.Exists -and -not $newMergeExact) {
        $warnings.Add("Unrelated or customized registry-file RunAs verb 'LocalMachine\$mergePath' was retained.")
    }

    foreach ($hive in @('LocalMachine', 'CurrentUser')) {
        $termsPath = 'SOFTWARE\Classes\TermsRunAsTI'
        $terms = & $RegistryReader $hive $termsPath
        if (-not $terms.Exists) { continue }
        $termsFingerprint = Get-AtlasLegacyTermsFingerprint -Snapshot $terms
        if ($TermsFingerprints -ccontains $termsFingerprint) {
            $plan.Add([pscustomobject]@{
                    Priority = 30; Action = 'RemoveTree'; Hive = $hive; SubKey = $termsPath
                    Artifact = 'Terms'; BeforeSnapshot = $terms
                    ExpectedFingerprint = $termsFingerprint
                    Reason = 'Removed the exact Atlas/AveYo TermsRunAsTI registry-code key.'
                })
        }
        else {
            $message = "Ambiguous TermsRunAsTI key '$hive\$termsPath' was retained."
            if ($hive -ceq 'LocalMachine') { $machineErrors.Add($message) } else { $warnings.Add($message) }
        }
    }

    $legacyStatePath = 'SOFTWARE\AtlasOS\ContextMenuTerminals'
    $legacyState = & $RegistryReader 'LocalMachine' $legacyStatePath
    if ($legacyState.Exists) {
        $stateValue = Get-AtlasLegacySnapshotValue -Snapshot $legacyState -Name 'state'
        $exactLegacyState = @($legacyState.Values).Count -eq 1 -and @($legacyState.SubKeys).Count -eq 0 -and
            $null -ne $stateValue -and [string]$stateValue.Kind -ceq 'DWord' -and
            [int64]$stateValue.Value -ge 0 -and [int64]$stateValue.Value -le 3
        if ($exactLegacyState) {
            $plan.Add([pscustomobject]@{
                    Priority = 40; Action = 'RemoveTree'; Hive = 'LocalMachine'; SubKey = $legacyStatePath
                    Artifact = 'TerminalState'; BeforeSnapshot = $legacyState
                    Reason = 'Removed the exact obsolete Atlas terminal state key.'
                })
        }
        else {
            $warnings.Add("Customized non-executable legacy state '$legacyStatePath' was retained.")
        }
    }

    $volatile = & $RegistryReader 'CurrentUser' 'Volatile Environment'
    if ($volatile.Exists) {
        $runAsTiValue = Get-AtlasLegacySnapshotValue -Snapshot $volatile -Name 'RunAsTI'
        if ($null -ne $runAsTiValue) {
            if (Test-AtlasLegacyVolatileValue -Value $runAsTiValue `
                    -CodeFingerprints $VolatileCodeFingerprints) {
                $plan.Add([pscustomobject]@{
                        Priority = 50; Action = 'RemoveValue'; Hive = 'CurrentUser'
                        SubKey = 'Volatile Environment'; Name = 'RunAsTI'
                        BeforeValue = $runAsTiValue
                        Reason = 'Removed the exact current-user RunAsTI volatile code value.'
                    })
            }
            else {
                $warnings.Add('Customized current-user Volatile Environment\RunAsTI value was retained.')
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($SendToPath)) {
        $sendToFolder = [Environment]::GetFolderPath('SendTo')
        if (-not [string]::IsNullOrWhiteSpace($sendToFolder)) {
            $SendToPath = Join-Path -Path $sendToFolder -ChildPath 'RunAsTI.bat'
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($SendToPath)) {
        $sendTo = & $FileReader $SendToPath
        if ($sendTo.Exists) {
            if (-not $sendTo.IsReparsePoint -and
                $SendToFingerprints -ccontains [string]$sendTo.Sha256) {
                $plan.Add([pscustomobject]@{
                    Priority = 60; Action = 'RemoveFile'; Path = $SendToPath
                    ExpectedSha256 = [string]$sendTo.Sha256
                        BeforeSnapshot = $sendTo
                        Reason = 'Removed the exact current-user SendTo RunAsTI copy.'
                    })
            }
            else {
                $warnings.Add("Customized current-user SendTo artifact '$SendToPath' was retained.")
            }
        }
    }

    foreach ($warning in $warnings) { [void](& $Logger 'Warning' $warning) }
    if ($machineErrors.Count -gt 0) {
        foreach ($message in $machineErrors) { [void](& $Logger 'Warning' $message) }
        throw "Legacy elevation migration found $($machineErrors.Count) ambiguous executable machine artifact(s); no migration changes were applied. $($machineErrors -join ' ')"
    }

    $applied = 0
    foreach ($operation in @($plan | Sort-Object -Property Priority)) {
        switch ([string]$operation.Action) {
            'RemoveTree' {
                $current = & $RegistryReader $operation.Hive $operation.SubKey
                if (-not (Test-AtlasLegacyRegistrySnapshotUnchanged `
                            -Before $operation.BeforeSnapshot -After $current)) {
                    throw "Registry tree '$($operation.Hive)\$($operation.SubKey)' changed after preflight; refusing to remove it."
                }
                if ([string]$operation.Artifact -ceq 'Terminal') {
                    $currentRelated = & $RegistryReader $operation.Hive $operation.RelatedSubKey
                    if (-not (Test-AtlasLegacyRegistrySnapshotUnchanged `
                                -Before $operation.BeforeRelatedSnapshot -After $currentRelated)) {
                        throw "Registry command '$($operation.Hive)\$($operation.RelatedSubKey)' changed after preflight; refusing to remove its terminal verb."
                    }
                }
                elseif ([string]$operation.Artifact -ceq 'Terms' -and
                    (Get-AtlasLegacyTermsFingerprint -Snapshot $current) -cne
                    [string]$operation.ExpectedFingerprint) {
                    throw "Registry-code tree '$($operation.Hive)\$($operation.SubKey)' no longer has the approved fingerprint; refusing to remove it."
                }
                [void](& $RegistryTreeRemover $operation.Hive $operation.SubKey)
            }
            'RemoveValue' {
                $current = & $RegistryReader $operation.Hive $operation.SubKey
                if (-not (Test-AtlasLegacyRegistryValueUnchanged `
                            -Snapshot $current -ExpectedValue $operation.BeforeValue) -or
                    -not (Test-AtlasLegacyVolatileValue -Value $operation.BeforeValue `
                            -CodeFingerprints $VolatileCodeFingerprints)) {
                    throw "Registry value '$($operation.Hive)\$($operation.SubKey) [$($operation.Name)]' changed after preflight; refusing to remove it."
                }
                [void](& $RegistryValueRemover $operation.Hive $operation.SubKey $operation.Name)
            }
            'ReplaceMerge' {
                $currentMerge = & $RegistryReader 'LocalMachine' $operation.SubKey
                $currentMergeCommand = & $RegistryReader 'LocalMachine' $operation.RelatedSubKey
                if (-not (Test-AtlasLegacyRegistrySnapshotUnchanged `
                            -Before $operation.BeforeSnapshot -After $currentMerge) -or
                    -not (Test-AtlasLegacyRegistrySnapshotUnchanged `
                            -Before $operation.BeforeRelatedSnapshot -After $currentMergeCommand)) {
                    throw "Registry-file RunAs verb changed after preflight; refusing to rewrite it."
                }
                # Change the executable command first. If a later write is interrupted,
                # the surviving verb is already least-privilege and the next run repairs
                # its label rather than rediscovering the legacy TI command.
                [void](& $RegistryValueWriter 'LocalMachine' $mergeCommandPath '' `
                        $script:AtlasAdministratorMergeCommand 'ExpandString')
                $publishedCommand = & $RegistryReader 'LocalMachine' $mergeCommandPath
                if (-not (Test-AtlasLegacyRegistrySnapshotExact -Snapshot $publishedCommand `
                            -ExpectedValues $administratorMergeCommand)) {
                    throw 'The least-privilege registry-file RunAs command did not verify after publication.'
                }
                $parentBeforeLabel = & $RegistryReader 'LocalMachine' $mergePath
                if (-not (Test-AtlasLegacyRegistrySnapshotUnchanged `
                            -Before $operation.BeforeSnapshot -After $parentBeforeLabel)) {
                    throw 'The registry-file RunAs parent changed after command publication; refusing to relabel it.'
                }
                [void](& $RegistryValueWriter 'LocalMachine' $mergePath '' `
                        $script:AtlasAdministratorMergeLabel 'String')
                $publishedParent = & $RegistryReader 'LocalMachine' $mergePath
                $publishedCommand = & $RegistryReader 'LocalMachine' $mergeCommandPath
                if (-not (Test-AtlasLegacyRegistrySnapshotExact -Snapshot $publishedParent `
                            -ExpectedValues $administratorMergeValues -ExpectedSubKeys @('Command')) -or
                    -not (Test-AtlasLegacyRegistrySnapshotExact -Snapshot $publishedCommand `
                            -ExpectedValues $administratorMergeCommand)) {
                    throw 'The complete Administrator registry-file RunAs verb did not verify after publication.'
                }
            }
            'RemoveFile' {
                $currentFile = & $FileReader $operation.Path
                if (-not $currentFile.Exists -or $currentFile.IsReparsePoint -or
                    [string]$currentFile.Sha256 -cne [string]$operation.BeforeSnapshot.Sha256 -or
                    [string]$currentFile.Sha256 -cne [string]$operation.ExpectedSha256) {
                    throw "Legacy user file '$($operation.Path)' changed after preflight; refusing to remove it."
                }
                [void](& $FileRemover $operation.Path $operation.ExpectedSha256)
            }
            default {
                throw "Unknown legacy elevation migration action '$($operation.Action)'."
            }
        }
        $applied++
        [void](& $Logger 'Info' ([string]$operation.Reason))
    }

    return [pscustomobject]@{
        AppliedCount = $applied
        WarningCount = $warnings.Count
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    $ErrorActionPreference = 'Stop'
    Invoke-AtlasLegacyElevationMigrationCore
}
