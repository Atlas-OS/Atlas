if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
  Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
}

$windir = [Environment]::GetFolderPath('Windows')
$folderItems = Get-ChildItem -Path "$windir\AtlasDesktop\*" -File -Recurse 
$pattern = "\(default\)\.cmd"

foreach ($script in $folderItems)
{
  if ($script.PSChildName -match $pattern){
    #& $script.FullName /silent
    Write-Host $script.PSChildName
  }
}