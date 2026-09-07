# Host-side image worker. Never executes a playbook or writes host setup keys.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RequestFile, [ValidateSet('Inspect', 'Build')][string]$Operation)
# This elevated worker must never autoload a module from an inherited user path.
$env:PSModulePath = [IO.Path]::Combine($PSHOME, 'Modules')
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
$ProgressPreference = 'SilentlyContinue'
$job = [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($RequestFile))
$request = [IO.File]::ReadAllText($RequestFile) | ConvertFrom-Json
. (Join-Path $PSScriptRoot 'Windows-Release.ps1')
$ownedMount = $false
$work = $null
$partial = $null
$source = $null
$mutex = $null
$ownsMutex = $false

function Write-Stage([string]$Stage) {
    Write-Output "ATLAS_STAGE:$Stage"
    if (Test-Path -LiteralPath (Join-Path $job 'cancel')) { throw 'Cancelled at a safe checkpoint.' }
}
function Assert-PlainTree([string]$Path) {
    $root = Get-Item -LiteralPath $Path -Force
    if ($root.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Reparse point: $Path" }
    foreach ($item in Get-ChildItem -LiteralPath $Path -Force -Recurse) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Reparse point: $($item.FullName)" }
    }
}
function Assert-BootCatalog([string]$Path) {
    $stream = [IO.File]::OpenRead($Path)
    try {
        $buffer = New-Object byte[] 2048
        for ($sector = 16; $sector -lt 48; $sector++) {
            [void]$stream.Seek([long]$sector * 2048, [IO.SeekOrigin]::Begin)
            if ($stream.Read($buffer, 0, 2048) -ne 2048) { throw 'Truncated volume descriptors.' }
            if ($buffer[0] -eq 0 -and [Text.Encoding]::ASCII.GetString($buffer, 1, 5) -eq 'CD001' -and
                [Text.Encoding]::ASCII.GetString($buffer, 7, 23) -eq 'EL TORITO SPECIFICATION') {
                $lba = [BitConverter]::ToUInt32($buffer, 71)
                [void]$stream.Seek([long]$lba * 2048, [IO.SeekOrigin]::Begin)
                if ($stream.Read($buffer, 0, 2048) -ne 2048) { throw 'Truncated boot catalog.' }
                $checksum = 0
                for ($i = 0; $i -lt 32; $i += 2) { $checksum += [BitConverter]::ToUInt16($buffer, $i) }
                if (($checksum -band 0xffff) -ne 0 -or $buffer[0] -ne 1 -or $buffer[1] -ne 0 -or
                    $buffer[30] -ne 0x55 -or $buffer[31] -ne 0xaa -or $buffer[32] -ne 0x88 -or
                    $buffer[64] -notin @(0x90, 0x91) -or $buffer[65] -ne 0xef -or $buffer[96] -ne 0x88) {
                    throw 'The output does not contain valid BIOS and UEFI boot entries.'
                }
                return
            }
        }
        throw 'The output has no El Torito boot catalog.'
    }
    finally { $stream.Dispose() }
}
function Assert-Output {
    if ([IO.Path]::GetExtension($request.output) -ine '.iso') { throw 'Output must end in .iso.' }
    if (Test-Path -LiteralPath $request.output) { throw 'Output already exists. Choose a new filename.' }
    $parent = Get-Item -LiteralPath ([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($request.output)))
    if ($parent.FullName.StartsWith('\\')) { throw 'Choose a local NTFS or ReFS destination.' }
    $volume = Get-Volume -FilePath $parent.FullName
    if ($volume.FileSystem -notin @('NTFS', 'ReFS')) { throw 'Choose an NTFS or ReFS destination for large installation files.' }
    # Conservative budget: extracted media, output, package, plus scratch headroom.
    $packageBytes = (Get-ChildItem -LiteralPath $request.package -File -Force -Recurse | Measure-Object Length -Sum).Sum
    $required = 5 * (Get-Item -LiteralPath $source).Length + 2 * [long]$packageBytes + 4GB
    if ($volume.SizeRemaining -lt $required) { throw "Not enough free space. Required: $required bytes." }
    return $parent.FullName
}
function Get-AtlasMediaEditions([string]$ImagePath, [int[]]$SupportedBuilds) {
    foreach ($summary in @(Get-WindowsImage -ImagePath $ImagePath)) {
        $info = Get-WindowsImage -ImagePath $ImagePath -Index $summary.ImageIndex
        $version = [version]$info.Version
        if ([int]$info.Architecture -ne 9 -or $SupportedBuilds -notcontains $version.Build) {
            throw "Unsupported Windows image: $($info.ImageName), $($info.Version), architecture $($info.Architecture)."
        }
        if ($info.InstallationType -ne 'Client') { throw 'Only Windows client installation media is supported.' }
        if ((Get-AtlasWindowsReleaseStatus -Version $version) -ne 'Released') {
            [Console]::Out.WriteLine('ATLAS_ERROR:windows-release-unknown')
            throw "The Windows image version $version could not be verified as a public release. Connect to the internet and retry, or choose official release media."
        }
        # Match the destination edition gate. Normal Microsoft consumer media
        # also contains Home; retain every supported edition for Setup to offer.
        $edition = [string]$info.EditionId
        if ([string]::IsNullOrWhiteSpace($edition)) { throw 'The Windows image has no edition identity.' }
        if ($edition -like 'Core*' -or $edition -in @('EnterpriseS','EnterpriseSN','EnterpriseSEval','EnterpriseSNEval','IoTEnterpriseS','IoTEnterpriseSK')) { continue }
        $info
    }
}
function Export-AtlasMediaEditions([string]$SourceImage, [string]$DestinationImage, [object[]]$Editions) {
    if (Test-Path -LiteralPath $DestinationImage) { throw 'The filtered Windows image already exists.' }
    if ($Editions.Count -eq 0) { throw 'The ISO contains no supported Windows editions.' }
    foreach ($edition in $Editions) {
        Write-Stage copy
        Export-WindowsImage -SourceImagePath $SourceImage -SourceIndex $edition.ImageIndex -DestinationImagePath $DestinationImage -CompressionType Max -CheckIntegrity -ErrorAction Stop | Out-Null
    }
    $actual = @(Get-WindowsImage -ImagePath $DestinationImage)
    if ($actual.Count -ne $Editions.Count) { throw 'The filtered Windows image has an unexpected edition count.' }
    for ($index = 0; $index -lt $actual.Count; $index++) {
        $info = Get-WindowsImage -ImagePath $DestinationImage -Index $actual[$index].ImageIndex
        $expected = $Editions[$index]
        if ($info.EditionId -ne $expected.EditionId -or $info.ImageName -ne $expected.ImageName -or
            [version]$info.Version -ne [version]$expected.Version -or [int]$info.Architecture -ne 9 -or $info.InstallationType -ne 'Client') {
            throw 'The filtered Windows image does not match the selected editions.'
        }
    }
}
try {
    $mutex = New-Object Threading.Mutex($false, 'Global\AtlasOS.ISO.Build')
    try { $ownsMutex = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $ownsMutex = $true }
    if (-not $ownsMutex) { throw 'Another Atlas ISO operation is running. Wait for it to finish.' }
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Administrator access is required.' }
    Write-Stage inspect
    $source = (Get-Item -LiteralPath $request.source).FullName
    if ([IO.Path]::GetExtension($source) -ine '.iso') { throw 'Choose a Windows ISO file.' }
    $parent = Assert-Output
    $disk = Get-DiskImage -ImagePath $source
    if (-not $disk.Attached) {
        $disk = Mount-DiskImage -ImagePath $source -Access ReadOnly -PassThru
        $ownedMount = $true
    }
    $volumes = @($disk | Get-Volume | Where-Object DriveLetter)
    if ($volumes.Count -ne 1) { throw 'The ISO must contain one readable Windows installation volume.' }
    $root = "$($volumes[0].DriveLetter):\"
    foreach ($relative in @('setup.exe', 'sources\boot.wim', 'boot\etfsboot.com', 'efi\microsoft\boot\efisys.bin')) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $relative))) { throw "Windows installation file missing: $relative" }
    }
    foreach ($relative in @('autounattend.xml', 'unattend.xml', 'sources\autounattend.xml', 'sources\unattend.xml', 'sources\$OEM$')) {
        if (Test-Path -LiteralPath (Join-Path $root $relative)) { throw "This ISO already has custom setup content ($relative). Choose unmodified Microsoft media." }
    }
    $images = @('sources\install.wim', 'sources\install.esd' | ForEach-Object { Join-Path $root $_ } | Where-Object { Test-Path -LiteralPath $_ })
    if ($images.Count -ne 1) { throw 'Expected one install.wim or install.esd. Split images are not supported in this Beta.' }
    Import-Module Dism -ErrorAction Stop
    $sourceEditionCount = @(Get-WindowsImage -ImagePath $images[0]).Count
    $supportedEditions = @(Get-AtlasMediaEditions -ImagePath $images[0] -SupportedBuilds $request.supportedBuilds)
    $editions = @($supportedEditions | ForEach-Object { [string]$_.ImageName })
    if ($editions.Count -eq 0) { throw 'The ISO contains no supported Windows editions. Windows Home and LTSC are not supported.' }
    Write-Output ('ATLAS_RESULT:' + (@{ editions = $editions; bytes = (Get-Item -LiteralPath $source).Length } | ConvertTo-Json -Compress))
    if ($Operation -eq 'Inspect') { exit 0 }
    if ($request.mode -notin @('interactive', 'configured', 'before-desktop')) { throw 'Unknown setup mode.' }
    if ($request.copyNetworkDrivers -and -not $request.reinstallThisPc) { throw 'Network driver copying is only available when reinstalling this PC.' }
    if ($request.updateNetworkDrivers -and -not $request.copyNetworkDrivers) { throw 'Network driver updates require network driver copying.' }
    [xml]$packageManifest = Get-Content -LiteralPath (Join-Path $request.package 'playbook.conf') -Raw
    $packageVersion = [version]([string]$packageManifest.Playbook.Version -replace '-.*$', '')
    if ($packageVersion -lt [version]'0.6.0') { throw 'ISO creation requires Atlas 0.6.0 or newer.' }
    Assert-PlainTree $request.package
    if ($request.mode -ne 'interactive') {
        $cap = Get-Content -LiteralPath (Join-Path $request.package 'Executables\AtlasModules\Scripts\Install\iso-setup.json') -Raw | ConvertFrom-Json
        if ($cap.schema -ne 1 -or $cap.firstSignIn -ne $true) { throw 'The package does not support ISO setup.' }
    }
    $id = [guid]::NewGuid().ToString('N')
    $work = Join-Path $parent ".atlas-iso-$id"
    $partial = Join-Path $parent ".atlas-iso-$id.partial"
    # The elevated worker creates the private tree with its final ACL atomically.
    $acl = New-Object Security.AccessControl.DirectorySecurity
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($sid in @('S-1-5-18', 'S-1-5-32-544')) {
        $acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule((New-Object Security.Principal.SecurityIdentifier($sid)), 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')))
    }
    [void][IO.Directory]::CreateDirectory($work, $acl)
    [IO.File]::WriteAllText((Join-Path $job 'workspace.txt'), $work)
    $media = Join-Path $work 'media'
    [void][IO.Directory]::CreateDirectory($media)
    Write-Stage copy
    Assert-PlainTree $root
    foreach ($item in Get-ChildItem -LiteralPath $root -Force) {
        Copy-Item -LiteralPath $item.FullName -Destination $media -Recurse -Force
    }
    $imageRelative = 'sources\' + [IO.Path]::GetFileName($images[0])
    $mediaImage = Join-Path $media $imageRelative
    if ((Get-FileHash -LiteralPath $images[0]).Hash -ne (Get-FileHash -LiteralPath $mediaImage).Hash) { throw 'Windows installation image copy verification failed.' }
    if ($supportedEditions.Count -ne $sourceEditionCount) {
        $filteredImage = Join-Path $work 'supported.wim'
        Export-AtlasMediaEditions -SourceImage $images[0] -DestinationImage $filteredImage -Editions $supportedEditions
        # Only the copy inside our private workspace is replaced. No image is
        # selected in the answer file and no generic product key is injected.
        Remove-Item -LiteralPath $mediaImage -Force
        $imageRelative = 'sources\install.wim'
        $mediaImage = Join-Path $media $imageRelative
        [IO.File]::Move($filteredImage, $mediaImage)
    }
    Write-Stage inject
    $target = Join-Path $media 'sources\$OEM$\$$\AtlasISO'
    [void][IO.Directory]::CreateDirectory($target)
    Copy-Item -LiteralPath $request.app -Destination (Join-Path $target 'AtlasManager.exe')
    Copy-Item -LiteralPath $request.archive -Destination (Join-Path $target 'Atlas.apbx')
    Copy-Item -LiteralPath (Join-Path $job 'Setup.ps1') -Destination $target
    Copy-Item -LiteralPath (Join-Path $job 'Desktop.ps1') -Destination $target
    Copy-Item -LiteralPath (Join-Path $job 'Desktop-Policy.ps1') -Destination $target
    Copy-Item -LiteralPath (Join-Path $job 'THIRD-PARTY-NOTICES.txt') -Destination $target
    Copy-Item -LiteralPath (Join-Path $job 'DriverPolicy.reg') -Destination $target
    if ($request.copyNetworkDrivers) {
        Write-Stage network-drivers
        . (Join-Path $job 'Network-Drivers.ps1')
        $networkRoot = Join-Path $target 'NetworkDrivers'
        $networkPackages = @(Export-AtlasNetworkDrivers -Destination $networkRoot -CancelFile (Join-Path $job 'cancel') -LogPath (Join-Path $job 'network-drivers.log') -CheckUpdates:$request.updateNetworkDrivers)
        Assert-PlainTree $networkRoot
        [IO.File]::WriteAllText((Join-Path $target 'network-drivers.json'), (ConvertTo-Json -InputObject $networkPackages), (New-Object Text.UTF8Encoding($false)))
        Write-Stage inject
    }
    if ($request.mode -ne 'interactive') {
        Copy-Item -LiteralPath $request.package -Destination (Join-Path $target 'Package') -Recurse
    }
    $username = [string]$request.username
    if ($username.Length -lt 1 -or $username.Length -gt 20 -or $username.Trim() -cne $username -or $username.EndsWith('.') -or $username -match '[\p{Cc}"/\\\[\]:;|=,+*?<>@]' -or $username -in @('administrator','guest','defaultaccount','defaultuser0','wdagutilityaccount','system','anonymous logon')) { throw 'Invalid Windows local account name.' }
    if ($request.drivers -notin @('automatic','manual')) { throw 'Choose an automatic or manual driver policy.' }
    $config = @{ schema = 2; mode = $request.mode; options = @($request.options); username = $username; drivers = $request.drivers }
    [IO.File]::WriteAllText((Join-Path $target 'setup.json'), ($config | ConvertTo-Json -Compress), (New-Object Text.UTF8Encoding($false)))
    $answer = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <EnableFirewall>true</EnableFirewall>
      <UserData><ProductKey><WillShowUI>Always</WillShowUI></ProductKey></UserData>
      <ImageInstall><OSImage><WillShowUI>Always</WillShowUI></OSImage></ImageInstall>
    </component>
  </settings>
  <settings pass="specialize">
    <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <RunSynchronous>
        <RunSynchronousCommand xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" wcm:action="add">
          <Order>1</Order>
          <Path>powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%WINDIR%\AtlasISO\Setup.ps1"</Path>
          <Description>Atlas</Description>
          <WillReboot>Never</WillReboot>
        </RunSynchronousCommand>
      </RunSynchronous>
    </component>
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <OOBE>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideEULAPage>true</HideEULAPage>
        <ProtectYourPC>3</ProtectYourPC>
      </OOBE>
      <UserAccounts><LocalAccounts><LocalAccount xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" wcm:action="add">
        <Name>ATLAS_LOCAL_ACCOUNT</Name><Group>Administrators</Group>
        <Password><Value></Value><PlainText>true</PlainText></Password>
      </LocalAccount></LocalAccounts></UserAccounts>
      <AutoLogon><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>ATLAS_LOCAL_ACCOUNT</Username>
        <Password><Value></Value><PlainText>true</PlainText></Password>
      </AutoLogon>
      <FirstLogonCommands><SynchronousCommand xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" wcm:action="add">
        <Order>1</Order><Description>Atlas account preparation</Description>
        <CommandLine>powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%WINDIR%\AtlasISO\Setup.ps1" -FirstLogon</CommandLine>
      </SynchronousCommand></FirstLogonCommands>
    </component>
  </settings>
</unattend>
'@
    [xml]$document = $answer
    $namespace = New-Object Xml.XmlNamespaceManager($document.NameTable)
    $namespace.AddNamespace('u', 'urn:schemas-microsoft-com:unattend')
    foreach ($node in $document.SelectNodes('//u:LocalAccount/u:Name | //u:AutoLogon/u:Username', $namespace)) { $node.InnerText = $username }
    $answer = $document.OuterXml
    [IO.File]::WriteAllText((Join-Path $media 'autounattend.xml'), $answer, (New-Object Text.UTF8Encoding($false)))
    # Setup discovers/caches only files with settings for the current pass.
    # Keep the normal WinPE firewall enabled so this file is valid on first
    # boot. Also cover optical distribution and destination search paths.
    [IO.File]::WriteAllText((Join-Path $media 'sources\autounattend.xml'), $answer, (New-Object Text.UTF8Encoding($false)))
    $sysprep = Join-Path $media 'sources\$OEM$\$$\System32\Sysprep'
    [void][IO.Directory]::CreateDirectory($sysprep)
    [IO.File]::WriteAllText((Join-Path $sysprep 'unattend.xml'), $answer, (New-Object Text.UTF8Encoding($false)))
    Write-Stage master
    & (Join-Path $PSScriptRoot 'Master-Iso.ps1') -Media $media -Output $partial -CancelFile (Join-Path $job 'cancel')
    Write-Stage verify
    Assert-BootCatalog $partial
    if (-not (Test-Path -LiteralPath $partial) -or (Get-Item -LiteralPath $partial).Length -le (Get-Item -LiteralPath $mediaImage).Length) { throw 'The output ISO is missing or incomplete.' }
    # Mount the finished image and confirm its setup payload and boot files can
    # actually be read. Mount-DiskImage needs the .iso extension.
    $verifyIso = Join-Path $work 'verify.iso'
    [IO.File]::Move($partial, $verifyIso)
    $verifiedMount = $false
    try {
        $checkDisk = Mount-DiskImage -ImagePath $verifyIso -Access ReadOnly -PassThru
        $verifiedMount = $true
        $checkVolumes = @($checkDisk | Get-Volume | Where-Object DriveLetter)
        if ($checkVolumes.Count -ne 1) { throw 'Output volume is unreadable.' }
        $checkRoot = "$($checkVolumes[0].DriveLetter):\"
        # Windows' installation image is the largest and most important file.
        # Compare with the verified staged image, which may have been exported
        # to remove unsupported editions before mastering.
        if ((Get-FileHash -LiteralPath $mediaImage -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath (Join-Path $checkRoot $imageRelative) -Algorithm SHA256).Hash) {
            throw "Output Windows image verification failed: $imageRelative"
        }
        foreach ($relative in @('autounattend.xml', 'sources\autounattend.xml', 'sources\$OEM$\$$\System32\Sysprep\unattend.xml', 'sources\boot.wim', 'boot\etfsboot.com', 'efi\microsoft\boot\efisys.bin', 'sources\$OEM$\$$\AtlasISO\AtlasManager.exe', 'sources\$OEM$\$$\AtlasISO\Atlas.apbx', 'sources\$OEM$\$$\AtlasISO\Setup.ps1', 'sources\$OEM$\$$\AtlasISO\Desktop.ps1', 'sources\$OEM$\$$\AtlasISO\Desktop-Policy.ps1', 'sources\$OEM$\$$\AtlasISO\setup.json', 'sources\$OEM$\$$\AtlasISO\DriverPolicy.reg')) {
            $before = Get-FileHash -LiteralPath (Join-Path $media $relative) -Algorithm SHA256
            $after = Get-FileHash -LiteralPath (Join-Path $checkRoot $relative) -Algorithm SHA256
            if ($before.Hash -ne $after.Hash) { throw "Output verification failed: $relative" }
        }
        $noticeRelative = 'sources\$OEM$\$$\AtlasISO\THIRD-PARTY-NOTICES.txt'
        if ((Get-FileHash -LiteralPath (Join-Path $media $noticeRelative)).Hash -ne (Get-FileHash -LiteralPath (Join-Path $checkRoot $noticeRelative)).Hash) {
            throw 'Output license notice verification failed.'
        }
        if ($request.copyNetworkDrivers) {
            foreach ($file in @(Get-ChildItem -LiteralPath $networkRoot -File -Force -Recurse) + @(Get-Item -LiteralPath (Join-Path $target 'network-drivers.json'))) {
                $relative = $file.FullName.Substring($media.Length + 1)
                if ((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath (Join-Path $checkRoot $relative)).Hash) {
                    throw "Output network driver verification failed: $relative"
                }
            }
        }
    }
    finally {
        if ($verifiedMount) { Dismount-DiskImage -ImagePath $verifyIso -ErrorAction Stop | Out-Null }
    }
    [IO.File]::Move($verifyIso, $partial)
    # Read the entire output before publication, retaining a checksum for diagnostics.
    $digest = Get-FileHash -LiteralPath $partial -Algorithm SHA256
    $digest.Hash | Set-Content -LiteralPath (Join-Path $job 'sha256.txt')
    Write-Stage cleanup
    # File.Move refuses an existing destination, including one created mid-build.
    [IO.File]::Move($partial, [IO.Path]::GetFullPath($request.output))
    $partial = $null
}
catch {
    [Console]::Error.WriteLine($_.Exception.ToString())
    [Console]::Error.WriteLine($_.ScriptStackTrace)
    exit 1
}
finally {
    if ($ownedMount -and $source) { Dismount-DiskImage -ImagePath $source -ErrorAction Continue | Out-Null }
    # Only remove the exact unique paths created above, after checking their parent.
    if ($work -and (Test-Path -LiteralPath $work)) {
        $resolved = [IO.Path]::GetFullPath($work)
        if ([IO.Path]::GetDirectoryName($resolved) -eq $parent -and [IO.Path]::GetFileName($resolved) -match '^\.atlas-iso-[0-9a-f]{32}$') {
            try { Assert-PlainTree $resolved; Remove-Item -LiteralPath $resolved -Recurse -Force } catch { [Console]::Error.WriteLine("Cleanup required: $resolved. $_") }
        }
    }
    if ($partial -and (Test-Path -LiteralPath $partial)) {
        if ([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($partial)) -eq $parent -and [IO.Path]::GetFileName($partial) -match '^\.atlas-iso-[0-9a-f]{32}\.partial$') {
            Remove-Item -LiteralPath $partial -Force -ErrorAction Continue
        }
    }
    if ($ownsMutex) { $mutex.ReleaseMutex() }
    if ($null -ne $mutex) { $mutex.Dispose() }
}
