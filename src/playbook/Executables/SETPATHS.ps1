$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-File `"$PSCommandPath`""
    exit
}
$rootPath = "HKLM:\SOFTWARE\AtlasOS\"
$registryKeys = Get-ChildItem -Path $rootPath -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer }

$valueName = "path"
foreach ($key in $registryKeys) {
    $path = (Get-ItemProperty -Path $key.PSPath -Name $valueName).$valueName
    Write-Output($path)
    if ($path -notlike "C:\Windows\AtlasDesktop\*") {
        $marker = "AtlasDesktop\"
        $index = $path.IndexOf($marker)
        $result = $path.Substring($index + $marker.Length)
        Set-ItemProperty -Path $key.PSPath -Name $valueName -Value "C:\Windows\AtlasDesktop\$result" 
    }
}