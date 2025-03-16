$windir = [Environment]::GetFolderPath('Windows')

# Add Atlar's PowerShell modules
$env:PSModulePath += ";$windir\AtlarModules\Scripts\Modules"