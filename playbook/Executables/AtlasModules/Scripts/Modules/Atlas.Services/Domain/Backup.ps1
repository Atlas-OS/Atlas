# Atlas.Services domain: save and restore service/driver Start values.

$script:AtlasServicesBackupHeader = 'Windows Registry Editor Version 5.00'
$script:AtlasServicesBackupExcludedNames = @(
    'WdBoot', 'WdFilter', 'WdNisDrv', 'WdNisSvc', 'WinDefend'
)

function Test-AtlasServicesBackupExcludedName {
    param([Parameter(Mandatory = $true)][string]$Name)

    return $script:AtlasServicesBackupExcludedNames -contains $Name
}

function Get-AtlasServicesBackupRecordSet {
    $root = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
        'SYSTEM\CurrentControlSet\Services'
    )
    if ($null -eq $root) {
        throw 'The Windows Services registry key could not be opened.'
    }

    try {
        $names = @($root.GetSubKeyNames() | Sort-Object)
    }
    finally {
        $root.Dispose()
    }

    $records = @(
        foreach ($name in $names) {
            if (Test-AtlasServicesBackupExcludedName -Name $name) {
                continue
            }

            $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
                "SYSTEM\CurrentControlSet\Services\$name"
            )
            if ($null -eq $key) {
                continue
            }
            try {
                if ($key.GetValueNames() -notcontains 'Start') {
                    continue
                }
                if ($key.GetValueKind('Start') -ne
                    [Microsoft.Win32.RegistryValueKind]::DWord) {
                    throw "Service '$name' has a non-DWORD Start value."
                }
                $start = [int]$key.GetValue('Start')
                if ($start -lt 0 -or $start -gt 4) {
                    throw "Service '$name' has unsupported Start value '$start'."
                }
                [pscustomobject]@{ Name = $name; Start = $start }
            }
            finally {
                $key.Dispose()
            }
        }
    )
    if ($records.Count -eq 0) {
        throw 'No service Start values were available to back up.'
    }
    return $records
}

function Read-AtlasServicesBackup {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
    )

    $fullPath = [IO.Path]::GetFullPath($FilePath)
    if (-not [IO.File]::Exists($fullPath)) {
        throw "Services backup '$fullPath' does not exist."
    }

    $lines = [IO.File]::ReadAllLines(
        $fullPath,
        (New-Object Text.UTF8Encoding($false, $true))
    )
    if ($lines.Count -eq 0 -or $lines[0] -cne $script:AtlasServicesBackupHeader) {
        throw "Services backup '$fullPath' has an invalid header."
    }

    $records = New-Object 'Collections.Generic.List[object]'
    $seen = @{}
    for ($index = 1; $index -lt $lines.Count; $index++) {
        if ([string]::IsNullOrWhiteSpace($lines[$index])) {
            continue
        }
        if ($lines[$index] -cnotmatch
            '^\[HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\([^\\\]]+)\]$') {
            throw "Services backup '$fullPath' contains an invalid service section."
        }

        $name = [string]$Matches[1]
        Assert-AtlasServiceRegistryName -Name $name
        if ((Test-AtlasServicesBackupExcludedName -Name $name) -or $seen.ContainsKey($name)) {
            throw "Services backup '$fullPath' contains excluded or duplicate service '$name'."
        }
        $seen[$name] = $true

        $index++
        if ($index -ge $lines.Count -or
            $lines[$index] -cnotmatch '^"Start"=dword:0000000([0-4])$') {
            throw "Services backup section '$name' has an invalid Start value."
        }
        $records.Add([pscustomobject]@{ Name = $name; Start = [int]$Matches[1] })
    }

    if ($records.Count -eq 0) {
        throw "Services backup '$fullPath' contains no service records."
    }
    return [pscustomobject]@{ FilePath = $fullPath; Records = $records.ToArray() }
}

function Restore-AtlasServicesBackup {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
    )

    $backup = Read-AtlasServicesBackup -FilePath $FilePath
    $restored = 0
    $missing = 0
    foreach ($record in $backup.Records) {
        $result = Set-AtlasServiceStartup -Name $record.Name `
            -StartupType $record.Start -AllowMissing -PassThru
        if ($result.Applied) { $restored++ } else { $missing++ }
    }
    Write-AtlasLog -Message (
        "Restored $restored service Start value(s); skipped $missing removed service(s)."
    )
    return [pscustomobject]@{
        FilePath = $backup.FilePath
        RestoredCount = $restored
        MissingCount = $missing
    }
}

function Export-AtlasServicesBackup {
    param(
        [ValidateNotNullOrEmpty()]
        [string]$FilePath = (Join-Path -Path (Get-AtlasContext).AtlasModulesPath `
                -ChildPath 'Other\winServices.reg')
    )

    $fullPath = [IO.Path]::GetFullPath($FilePath)
    $parent = [IO.Path]::GetDirectoryName($fullPath)
    if (-not [IO.Directory]::Exists($parent)) {
        [void][IO.Directory]::CreateDirectory($parent)
    }
    if ([IO.File]::Exists($fullPath)) {
        [void](Read-AtlasServicesBackup -FilePath $fullPath)
        Write-AtlasLog -Message "Keeping existing service backup '$fullPath'."
        return
    }

    $lines = New-Object 'Collections.Generic.List[string]'
    $lines.Add($script:AtlasServicesBackupHeader)
    foreach ($record in @(Get-AtlasServicesBackupRecordSet | Sort-Object Name)) {
        Assert-AtlasServiceRegistryName -Name ([string]$record.Name)
        $lines.Add('')
        $lines.Add("[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\$($record.Name)]")
        $lines.Add(('"Start"=dword:{0:x8}' -f [uint32]$record.Start))
    }

    $temporaryPath = "$fullPath.$([guid]::NewGuid().ToString('N')).tmp"
    try {
        [IO.File]::WriteAllLines(
            $temporaryPath,
            $lines,
            (New-Object Text.UTF8Encoding($false))
        )
        [void](Read-AtlasServicesBackup -FilePath $temporaryPath)
        [IO.File]::Move($temporaryPath, $fullPath)
    }
    finally {
        if ([IO.File]::Exists($temporaryPath)) {
            [IO.File]::Delete($temporaryPath)
        }
    }
    Write-AtlasLog -Message "Saved the default service configuration to '$fullPath'."
}
