if (Test-Path -Path "C:\Program Files\Atlas Toolbox\AtlasToolbox.exe") {
    Write-Host "AtlasOS Toolbox is already installed.";
    Write-Host "Press any key to exit..."
    Read-Host
    exit 0
} 
else {
    try {
        $tempDirectory = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $tempDirectory | Out-Null

        Write-Output "Downloading Toolbox..."
        & curl.exe -LSs "https://github.com/Atlas-OS/atlas-toolbox/releases/latest/download/AtlasToolbox-Setup.exe" -o "$tempDirectory\toolbox.exe"
        if (!$?) {
            Write-Error "Downloading Toolbox failed."
            exit 1
        }

        Write-Output "Installing Toolbox..."
        Start-Process -FilePath "$tempDirectory\toolbox.exe" -WindowStyle Hidden -ArgumentList '/verysilent /install /MERGETASKS="desktopicon"' -Wait
  
        exit
    }
    catch {
        Write-Warning "An error occurred: $_"
        return $false
    }

    return $false

}