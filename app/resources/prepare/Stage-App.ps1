param([switch]$FunctionsOnly)
$env:PSModulePath = [IO.Path]::Combine($PSHOME, 'Modules')
if (-not $FunctionsOnly) {
    [Console]::InputEncoding = New-Object Text.UTF8Encoding($false)
    [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
}
$ErrorActionPreference = 'Stop'

function Get-AtlasRecoverySecurity {
    $security = New-Object Security.AccessControl.DirectorySecurity
    $security.SetSecurityDescriptorSddlForm('O:BAG:BAD:P(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1200a9;;;BU)')
    return $security
}

function Get-AtlasRecoveryFileSecurity {
    $security = New-Object Security.AccessControl.FileSecurity
    $security.SetSecurityDescriptorSddlForm('O:BAG:BAD:P(A;;FA;;;SY)(A;;FA;;;BA)(A;;0x1200a9;;;BU)')
    return $security
}

function Write-AtlasProtectedRecoveryFile {
    param([string]$Path, [byte[]]$Bytes, [Security.AccessControl.FileSecurity]$Security)
    $stream = New-Object IO.FileStream($Path, [IO.FileMode]::CreateNew, [Security.AccessControl.FileSystemRights]::Write, [IO.FileShare]::None, 4096, [IO.FileOptions]::None, $Security)
    try { $stream.Write($Bytes, 0, $Bytes.Length); $stream.Flush($true) }
    finally { $stream.Dispose() }
}

function Get-AtlasPreparationDirectory {
    param([string]$Root, [string]$Scope, [string]$Job, [switch]$Create)
    if ($Scope -cnotmatch '^[0-9a-f]{64}$' -or $Job -notmatch '^\d+-\d+$') { throw 'Invalid preparation job identity.' }
    $directory = $Root
    foreach ($part in @('', 'Preparation', $Scope, $Job)) {
        if ($part) { $directory = Join-Path $directory $part }
        if ($Create) { $null = New-AtlasRecoveryDirectory $directory }
        else {
            Assert-AtlasRecoveryPath $directory
            Assert-AtlasRecoverySecurity ((Get-Item -LiteralPath $directory).GetAccessControl())
        }
    }
    return $directory
}

function Get-AtlasRecoveryAccessDescriptor {
    param([Security.AccessControl.FileSecurity]$Security)
    $sections = [Security.AccessControl.AccessControlSections]::Access -bor [Security.AccessControl.AccessControlSections]::Owner
    $descriptor = New-Object Security.AccessControl.RawSecurityDescriptor($Security.GetSecurityDescriptorSddlForm($sections))
    # ReplaceFile can mark an unchanged protected DACL as auto-inherited.
    # Ignore that history flag, retaining ownership, protection and every ACE.
    $descriptor.SetFlags($descriptor.ControlFlags -band (-bnot [Security.AccessControl.ControlFlags]::DiscretionaryAclAutoInherited))
    return $descriptor.GetSddlForm($sections)
}

function Assert-AtlasRecoveryFileSecurity {
    param([string]$Path, [Security.AccessControl.FileSecurity]$Expected = (Get-AtlasRecoveryFileSecurity))
    Assert-AtlasRecoveryPath $Path
    if ((Get-AtlasRecoveryAccessDescriptor ((Get-Item -LiteralPath $Path).GetAccessControl())) -cne (Get-AtlasRecoveryAccessDescriptor $Expected)) { throw 'The recovery file permissions changed.' }
}

function Get-AtlasCancellationSecurity {
    $security = Get-AtlasRecoveryFileSecurity
    $user = [Security.Principal.WindowsIdentity]::GetCurrent().User
    $security.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($user, 'Read,Write', 'Allow')))
    return $security
}

function New-AtlasPreparationJob {
    param([string]$Root, [string]$Scope, [string]$Job, [string]$Worker, [byte[]]$Policy)
    $directory = Get-AtlasPreparationDirectory $Root $Scope $Job -Create
    Write-AtlasProtectedRecoveryFile (Join-Path $directory 'Update-Windows.ps1') ([Text.Encoding]::UTF8.GetBytes($Worker)) (Get-AtlasRecoveryFileSecurity)
    Write-AtlasProtectedRecoveryFile (Join-Path $directory 'DriverPolicy.reg') $Policy (Get-AtlasRecoveryFileSecurity)
    foreach ($log in @('worker.log','updates.log')) { Write-AtlasProtectedRecoveryFile (Join-Path $directory $log) ([byte[]]@()) (Get-AtlasRecoveryFileSecurity) }
    Write-AtlasProtectedRecoveryFile (Join-Path $directory 'cancel') ([byte[]]@()) (Get-AtlasCancellationSecurity)
    return $directory
}

function Assert-AtlasRecoveryPath {
    param([string]$Path)
    $item = Get-Item -LiteralPath $Path -Force
    while ($null -ne $item) {
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw 'Linked recovery paths are not supported.'
        }
        $item = if ($item -is [IO.FileInfo]) { $item.Directory } else { $item.Parent }
    }
}

function Assert-AtlasRecoverySecurity {
    param([Security.AccessControl.DirectorySecurity]$Security)
    $sections = [Security.AccessControl.AccessControlSections]::Access -bor [Security.AccessControl.AccessControlSections]::Owner
    if ($Security.GetSecurityDescriptorSddlForm($sections) -cne (Get-AtlasRecoverySecurity).GetSecurityDescriptorSddlForm($sections)) {
        throw 'The recovery directory does not have the required protected permissions.'
    }
}

function New-AtlasRecoveryDirectory {
    param([string]$Path)
    $parent = Split-Path -Parent $Path
    Assert-AtlasRecoveryPath $parent
    $directory = New-Object IO.DirectoryInfo($Path)
    if (-not $directory.Exists) { $directory.Create((Get-AtlasRecoverySecurity)) }
    Assert-AtlasRecoveryPath $Path
    Assert-AtlasRecoverySecurity ($directory.GetAccessControl())
    return $directory.FullName
}

function Copy-AtlasRecoveryExecutable {
    param([string]$Source, [string]$Root)
    Assert-AtlasRecoveryPath $Source
    $rootPath = New-AtlasRecoveryDirectory $Root
    $inputStream = [IO.File]::Open($Source, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
    $temporary = $null
    try {
        $hasher = [Security.Cryptography.SHA256]::Create()
        try { $digest = [BitConverter]::ToString($hasher.ComputeHash($inputStream)).Replace('-', '').ToLowerInvariant() }
        finally { $hasher.Dispose() }
        $inputStream.Position = 0
        $directory = New-AtlasRecoveryDirectory (Join-Path $rootPath $digest)
        $destination = Join-Path $directory 'AtlasManager.exe'
        if (-not [IO.File]::Exists($destination)) {
            $temporary = Join-Path $directory ('.copy-' + [guid]::NewGuid().ToString('N'))
            $outputStream = New-Object IO.FileStream($temporary, [IO.FileMode]::CreateNew, [Security.AccessControl.FileSystemRights]::Write, [IO.FileShare]::None, 4096, [IO.FileOptions]::None, (Get-AtlasRecoveryFileSecurity))
            try { $inputStream.CopyTo($outputStream); $outputStream.Flush($true) }
            finally { $outputStream.Dispose() }
            if ((Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash -ine $digest) { throw 'Recovery copy verification failed.' }
            try { [IO.File]::Move($temporary, $destination) }
            catch [IO.IOException] { if (-not [IO.File]::Exists($destination)) { throw } }
        }
        Assert-AtlasRecoveryPath $destination
        $sections = [Security.AccessControl.AccessControlSections]::Access -bor [Security.AccessControl.AccessControlSections]::Owner
        $security = (Get-Item -LiteralPath $destination).GetAccessControl()
        if ($security.GetSecurityDescriptorSddlForm($sections) -cne (Get-AtlasRecoveryFileSecurity).GetSecurityDescriptorSddlForm($sections)) { throw 'The recovery executable permissions changed.' }
        if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -ine $digest) { throw 'The existing recovery executable does not match this app.' }
        return $destination
    }
    finally {
        $inputStream.Dispose()
        # Only the random file created by this invocation is eligible for cleanup.
        if ($temporary -and [IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
    }
}

if (-not $FunctionsOnly) {
    $request = [Console]::In.ReadToEnd() | ConvertFrom-Json
    $programFiles = [Environment]::GetFolderPath('ProgramFiles')
    if ([string]::IsNullOrWhiteSpace($programFiles)) { throw 'Windows did not provide the Program Files directory.' }
    $root = Join-Path $programFiles 'Atlas Setup Recovery'
    $path = if ($request.operation -eq 'preparation') {
        New-AtlasPreparationJob -Root $root -Scope ([string]$request.scope) -Job ([string]$request.job) -Worker ([string]$request.worker) -Policy ([byte[]]$request.policy)
    } elseif ($request.operation -eq 'validate-preparation') {
        $directory = Get-AtlasPreparationDirectory $root ([string]$request.scope) ([string]$request.job)
        foreach ($file in @('Update-Windows.ps1','DriverPolicy.reg','state.json')) { Assert-AtlasRecoveryFileSecurity (Join-Path $directory $file) }
        Assert-AtlasRecoveryFileSecurity (Join-Path $directory 'cancel') (Get-AtlasCancellationSecurity)
        $directory
    } else { Copy-AtlasRecoveryExecutable -Source ([string]$request.source) -Root $root }
    [Console]::WriteLine(($path | ConvertTo-Json -Compress))
}
