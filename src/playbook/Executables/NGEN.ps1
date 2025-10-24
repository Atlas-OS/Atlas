# speeds up powershell startup time by 10x
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$runtimeDirectory = [Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
if ([string]::IsNullOrWhiteSpace($runtimeDirectory)) {
    throw 'Failed to resolve the .NET runtime directory required for ngen.exe.'
}

$env:Path = "$runtimeDirectory;$env:Path"
$ngenExe = Join-Path -Path $runtimeDirectory -ChildPath 'ngen.exe'
if (-not (Test-Path -Path $ngenExe -PathType Leaf)) {
    throw "ngen.exe not found at '$ngenExe'."
}

$assemblyList = [System.Collections.Generic.List[string]]::new()
$uniqueAssemblies = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($assembly in [AppDomain]::CurrentDomain.GetAssemblies()) {
    $location = $assembly.Location
    if ([string]::IsNullOrEmpty($location)) {
        continue
    }

    if ($uniqueAssemblies.Add($location)) {
        [void]$assemblyList.Add($location)
    }
}

foreach ($assemblyPath in $assemblyList) {
    Write-Host "NGENing: $(Split-Path -Path $assemblyPath -Leaf)" -ForegroundColor Yellow
    & $ngenExe 'install' $assemblyPath *> $null

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "ngen.exe returned exit code $LASTEXITCODE for '$assemblyPath'."
    }
}
