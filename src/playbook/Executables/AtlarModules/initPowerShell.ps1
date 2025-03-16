$windir = [Environment]::GetFolderPath('Windows')

# Add Atlas' PowerShell modules
$env:PSModulePath += ";$windir\AtlarModules\Scripts\Modules"