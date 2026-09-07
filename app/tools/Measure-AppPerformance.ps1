# Read-only smoke measurements for a built Atlas executable. Uses isolated
# app data and never starts an installation or changes Windows settings.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Executable,
    [ValidateSet('home', 'settings')][string]$Page = 'home',
    [ValidateRange(1, 10)][int]$Runs = 3,
    [ValidateRange(1, 60)][int]$IdleSeconds = 5,
    [string]$OutFile
)
$ErrorActionPreference = 'Stop'
$executablePath = (Resolve-Path -LiteralPath $Executable).Path
Add-Type @'
using System;
using System.Runtime.InteropServices;
using System.Text;
public static class AtlasPerformanceWindow {
    public delegate bool Callback(IntPtr hwnd, IntPtr arg);
    [DllImport("user32.dll")] public static extern bool EnumWindows(Callback callback, IntPtr arg);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint id);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr hwnd, StringBuilder text, int count);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hwnd, int command);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hwnd, IntPtr after, int x, int y, int w, int h, uint flags);
    public static IntPtr Find(uint id) {
        IntPtr found = IntPtr.Zero;
        EnumWindows((hwnd, arg) => {
            uint pid; GetWindowThreadProcessId(hwnd, out pid);
            if (pid != id) return true;
            var text = new StringBuilder(256);
            GetWindowText(hwnd, text, text.Capacity);
            if (text.ToString() == "Atlas Manager") found = hwnd;
            return true;
        }, IntPtr.Zero);
        return found;
    }
}
'@
$savedEnvironment = @{}
foreach ($name in @('ATLAS_APP_DATA', 'ATLAS_STATE_FILE', 'ATLAS_LANGUAGE')) {
    $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}
$results = @()
try {
    for ($run = 1; $run -le $Runs; $run++) {
        $dataDirectory = Join-Path ([IO.Path]::GetTempPath()) ('atlas-perf-' + [guid]::NewGuid().ToString('N'))
        $env:ATLAS_APP_DATA = $dataDirectory
        $env:ATLAS_STATE_FILE = Join-Path $dataDirectory 'no-installed-state.json'
        $env:ATLAS_LANGUAGE = 'en-GB'
        $process = $null
        try {
            $startup = [Diagnostics.Stopwatch]::StartNew()
            $process = Start-Process -FilePath $executablePath -ArgumentList @('--page', $Page) -WindowStyle Hidden -PassThru
            do {
                $handle = [AtlasPerformanceWindow]::Find([uint32]$process.Id)
                if ($handle -ne [IntPtr]::Zero) { break }
                if ($process.HasExited) { throw 'Atlas exited before creating a window.' }
                if ($startup.Elapsed.TotalSeconds -ge 30) { throw 'Atlas did not create a window within 30 seconds.' }
                Start-Sleep -Milliseconds 10
            } while ($true)
            $startup.Stop()
            [void][AtlasPerformanceWindow]::ShowWindow($handle, 4)
            # Let startup/recovery and the asynchronous update check settle.
            Start-Sleep -Seconds 5
            $process.Refresh()
            $initialCpu = $process.TotalProcessorTime.TotalMilliseconds
            $idle = [Diagnostics.Stopwatch]::StartNew()
            Start-Sleep -Seconds $IdleSeconds
            $idle.Stop()
            $process.Refresh()
            $idleCpu = $process.TotalProcessorTime.TotalMilliseconds - $initialCpu
            $privateMiB = $process.PrivateMemorySize64 / 1MB
            $workingMiB = $process.WorkingSet64 / 1MB
            # A repeatable redraw workload, not a frame-latency measurement.
            $initialCpu = $process.TotalProcessorTime.TotalMilliseconds
            $resize = [Diagnostics.Stopwatch]::StartNew()
            for ($frame = 0; $frame -le 120; $frame++) {
                $width = 700 + ($frame % 20) * 10
                [void][AtlasPerformanceWindow]::SetWindowPos($handle, [IntPtr]::Zero, 0, 0, $width, 680, 6)
                Start-Sleep -Milliseconds 16
            }
            Start-Sleep -Milliseconds 250
            $resize.Stop()
            $process.Refresh()
            $results += [pscustomobject]@{
                Run = $run
                Page = $Page
                WindowCreatedMs = [Math]::Round($startup.Elapsed.TotalMilliseconds, 2)
                IdleCpuMs = [Math]::Round($idleCpu, 2)
                IdlePercentOfOneCore = [Math]::Round(100 * $idleCpu / $idle.Elapsed.TotalMilliseconds, 3)
                PrivateMiB = [Math]::Round($privateMiB, 2)
                WorkingSetMiB = [Math]::Round($workingMiB, 2)
                ResizeCpuMs = [Math]::Round($process.TotalProcessorTime.TotalMilliseconds - $initialCpu, 2)
                ResizeWallMs = [Math]::Round($resize.Elapsed.TotalMilliseconds, 2)
            }
        }
        finally {
            if ($process -and -not $process.HasExited) { Stop-Process -Id $process.Id }
        }
    }
}
finally {
    foreach ($name in $savedEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], 'Process')
    }
}
$report = [pscustomobject]@{
    Executable = $executablePath
    Sha256 = (Get-FileHash -LiteralPath $executablePath -Algorithm SHA256).Hash
    Bytes = (Get-Item -LiteralPath $executablePath).Length
    LogicalProcessors = [Environment]::ProcessorCount
    TimestampUtc = [DateTime]::UtcNow.ToString('o')
    Samples = $results
}
if ($OutFile) { $report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $OutFile -Encoding utf8 }
$report | ConvertTo-Json -Depth 5
