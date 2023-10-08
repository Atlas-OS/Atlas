# Get recovery partition paths
function TestPathFatal {
    param (
        [string]$path,
        [string]$message,
        [string]$exitCode
    )

    function WriteError {
        Write-Host "Error: " -NoNewLine -ForegroundColor Red
        Write-Host "$message"
        # exit $exitCode
    }

    if ($path -like "*\*") {
        if (!(Test-Path $path)) { WriteError }
    } else {
        if (!(Get-Command $path -EA SilentlyContinue)) { WriteError }
    }
}

$recoveryXML = "$env:windir\System32\Recovery\ReAgent.xml"
$atlasEnvironmentItems = "$env:windir\AtlasModules\Other\recovery"

TestPathFatal -path "reagentc.exe" -message "Reagentc not found, Recovery is stripped or broken." -exitCode 1
TestPathFatal -path $recoveryXML -message "Recovery XML not found, Recovery is stripped or broken." -exitCode 2
TestPathFatal -path $atlasEnvironmentItems -message "Atlas Package Installation Environment files not found." -exitCode 3

# Enable Windows Recovery
reagentc /enable | Out-Null

# Initial BCD values
$recoveryBCD = $([xml]$(Get-Content -Path $recoveryXML)).WindowsRE.WinreBCD.id
$bcdeditRecoveryOutput = bcdedit /enum "$recoveryBCD" | Select-String 'device' | Select-Object -First 1
$deviceDrive = ($bcdeditRecoveryOutput -split '\]' -split '\[')[1]
$winrePath = ($bcdeditRecoveryOutput -split '\]' -split ',')[1]

# If WinRE is on Recovery partition, mount it
if ($deviceDrive -notcontains ':') {
    $Kernel32 = Add-Type -Name 'Kernel32' -Namespace '' -PassThru -MemberDefinition @"
        [DllImport("kernel32")]
        public static extern int QueryDosDevice(string name, System.Text.StringBuilder path, int pathMaxLength);
"@; $DevicePath = [System.Text.StringBuilder]::new(255)

    $recoveryID = Get-Volume | ForEach-Object {
        $UniqueId = $_.UniqueId.TrimStart('\\?\').TrimEnd('\')
        $Kernel32::QueryDosDevice($UniqueId, $DevicePath, $DevicePath.Capacity) | Out-Null
        [PSCustomObject]@{
            DevicePath = $DevicePath.ToString()
            UniqueId = $_.UniqueId
        }
    } | Where-Object { $_.DevicePath -eq $deviceDrive } | Select-Object -ExpandProperty UniqueId

    # Create mount point
    do {
        $mountPoint = Join-Path -Path $env:WinDir -ChildPath ("atlasRecovery." + $([System.IO.Path]::GetRandomFileName()))
    } until (!(Test-Path $mountPoint))
    if (-Not (Test-Path $mountPoint)) { New-Item -Path $mountPoint -Type Directory -Force | Out-Null }
    mountvol $mountPoint $recoveryID | Out-Null
    $deviceDrive = $mountPoint
}

# Mount the Recovery WIM
do {
    $atlasWinRE = Join-Path -Path $env:WinDir -ChildPath ("atlasWinRE." + $([System.IO.Path]::GetRandomFileName()))
} until (!(Test-Path $atlasWinRE))
New-Item -Path $atlasWinRE -Type Directory -Force | Out-Null
$fullWimPath = "$deviceDrive\$winrePath"
Mount-WindowsImage -ImagePath $fullWimPath -Index 1 -Path $atlasWinRE | Out-Null

# Set startup application
# https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpeshlini-reference-launching-an-app-when-winpe-starts
[IO.File]::WriteAllLines("$atlasWinRE\Windows\System32\winpeshl.ini", @"
[LaunchApp]
AppPath = %SYSTEMDRIVE%\atlas\packages.cmd
"@)

# Copy Atlas Package Installation Environment items
Copy-Item "$env:windir\AtlasModules\Other\recovery\*" -Destination "$atlasWinRe\atlas" -Recurse -Force

# Cleanup
Dismount-WindowsImage -Path $atlasWinRE -Save
Remove-Item $atlasWinRE -Force
if ($mountPoint) {
    mountvol "$mountPoint" /D
    if (!$?) { Remove-Item $mountPoint -Force }
}

# Boot into Windows Recovery next boot
reagentc /boottore | Out-Null

# Load the Recovery Registry hive
# do { $atlasRegistryPath = "HKLM\atlaswinre$($count; $count++)" } until (!(Test-Path "Registry::$atlasRegistryPath"))
# reg load "$atlasRegistryPath" "$atlasWinRE\Windows\System32\config\SOFTWARE"
# Set-ItemProperty -Path "Registry::$atlasRegistryPath\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name 'Shell' -Value "X:\hi.cmd" -Type String -Force
# reg unload "$atlasRegistryPath"

# $title = "Microsoft Windows Recovery Environment (amd64)"
# $title = "Atlas Package Installation Environment"
# $atlasWim = "Windows\System32\Recovery\atlas.wim"
# # New-WindowsImage -ImagePath "$env:SystemDrive\$atlasWim" -CapturePath $atlasWinRE -Name $title -Description "Microsoft Windows Recover Environment (amd64)"
# New-WindowsImage -ImagePath "$env:SystemDrive\$atlasWim" -CapturePath $atlasWinRE -Name $title -Description "Atlas Component Removal Environment"

# # Create BCD boot entry
# $atlasBootID = "{$(((bcdedit /copy "$recoveryBCD" /d "$title") -split '{' -split '}')[1])}"
# $recoveryBootID = "{$(($bcdeditRecoveryOutput -split '{' -split '}')[1])}"
# $atlasDeviceEntry = "ramdisk=[$env:SystemDrive]\$atlasWim,$recoveryBootID"
# $atlasDeviceEntry = "ramdisk=[$env:SystemDrive]\$atlasWim,{54d21b42-4990-11ee-b411-adda669ed4a0}"

# bcdedit /set "$atlasBootID" device "$atlasDeviceEntry"
# bcdedit /set "$atlasBootID" osdevice "$atlasDeviceEntry"
# bcdedit /displayorder "$atlasBootID" /addfirst
# bcdedit /timeout 0