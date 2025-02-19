$windir = [Environment]::GetFolderPath('Windows')
$folderItems = Get-ChildItem -Path "$windir\AtlasDesktop\*" -File -Recurse 
$pattern = "\(default\)\.cmd"

foreach ($script in $folderItems)
{
    if ($script.PSChildName -match $pattern){
      & $script.FullName /silent
    }
}