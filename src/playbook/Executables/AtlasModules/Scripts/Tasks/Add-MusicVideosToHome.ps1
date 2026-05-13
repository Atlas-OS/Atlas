$ErrorActionPreference = 'Stop'

$shell = New-Object -ComObject Shell.Application
$homeNamespace = $shell.Namespace('shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}')
if ($null -eq $homeNamespace) {
    throw 'Could not open the File Explorer Home namespace.'
}

$currentPins = @($homeNamespace.Items() | ForEach-Object { $_.Path })
foreach ($path in @(
    [Environment]::GetFolderPath('MyVideos'),
    [Environment]::GetFolderPath('MyMusic')
)) {
    if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -LiteralPath $path -PathType Container)) {
        Write-Warning "Skipping missing shell folder '$path'."
        continue
    }

    if ($currentPins -notcontains $path) {
        $folder = $shell.Namespace($path)
        if ($null -eq $folder) {
            throw "Could not open shell namespace for '$path'."
        }

        $folder.Self.InvokeVerb('pintohome')
    }
}
