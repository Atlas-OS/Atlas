$tempDir = "$env:WinDir\Temp\$([System.IO.Path]::GetRandomFileName())"
New-Item $tempDir -ItemType Directory -Force

Invoke-WebRequest "https://laptop-updates.brave.com/latest/winx64" -OutFile "$tempDir\BraveSetup.exe" -UseBasicParsing
if (!$?) {
    Write-Error "Downloading Brave failed."
    exit 1
}

& "$tempDir\BraveSetup.exe" /silent /install

do {
    $processesFound = Get-Process | ? { "BraveSetup" -contains $_.Name } | Select-Object -ExpandProperty Name
    if ($processesFound) {
        Write-Host "Still running: $($processesFound -join ', ')"
        Start-Sleep -Seconds 2
    } else {
        Remove-Item "$tempDir" -ErrorAction SilentlyContinue -Force -Recurse
    }
} until (!$processesFound)