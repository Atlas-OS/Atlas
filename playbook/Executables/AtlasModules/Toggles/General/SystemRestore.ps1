function Enable-AtlasWindowsVolumeProtection {
    param($Toggle)

    $windowsVolume = [IO.Path]::GetPathRoot([Environment]::GetFolderPath('Windows'))
    if ([string]::IsNullOrWhiteSpace($windowsVolume)) {
        throw 'The Windows volume could not be resolved.'
    }
    Enable-ComputerRestore -Drive $windowsVolume -ErrorAction Stop
    if (-not $Toggle.Silent) {
        Write-AtlasNote -Text "System Protection is on for $windowsVolume. No restore point was created."
    }
}
