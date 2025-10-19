$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-File `"$PSCommandPath`""
    exit
}
$rootPath = "HKLM:\SOFTWARE\AtlasOS\Services"
$registryKeys = Get-ChildItem -Path $rootPath -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer }

$valueName = "path"
foreach ($key in $registryKeys) {
    $value = Get-ItemProperty -Path $key.PSPath -Name $valueName -ErrorAction SilentlyContinue
    if ($null -eq $value) {
        continue
    }
    $path = $value.$valueName
    Write-Output($path)
    if ([string]::IsNullOrWhiteSpace($path)) {
        continue
    }
    if ($path -notlike "C:\Windows\AtlasDesktop\*") {
        $marker = "AtlasDesktop\"
        $index = $path.IndexOf($marker)
        if ($index -lt 0) {
            continue
        }
        $result = $path.Substring($index + $marker.Length)
        Set-ItemProperty -Path $key.PSPath -Name $valueName -Value "C:\Windows\AtlasDesktop\$result"
    }
}
