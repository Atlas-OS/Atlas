function Write-Title {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $dashes = '-' * $text.Length
    Write-Host "`n$dashes`n$text`n$dashes" -ForegroundColor Yellow
}

function Read-Pause {
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string]$Message = "Press Enter to exit",
        [switch]$NewLine
    )

    if ($NewLine) { Write-Output "" }
    $null = Read-Host $Message
}

enum MsgIcon {
    Stop
    Question
    Warning
    Info
}
enum MsgButtons {
    Ok
    OkCancel
    AbortRetryIgnore
    YesNoCancel
    YesNo
    RetryAndCancel
}
function Read-MessageBox {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,
        [Parameter(Mandatory = $true)]
        [string]$Body,
        [MsgIcon]$Icon = 'Info',
        [MsgButtons]$Buttons = 'YesNo',
        [int]$Timeout = 0,
        [switch]$NoTopmost
    )

    $value = 0
    $value += @(16, 32, 48, 64)[$([MsgIcon].GetEnumValues().IndexOf([MsgIcon]"$Icon"))] # icon
    $value += [MsgButtons].GetEnumValues().IndexOf([MsgButtons]"$Buttons") # buttons
    if (!$NoTopmost) { $value += 4096 } # topmost

    $result = (New-Object -ComObject "Wscript.Shell").Popup($Body, $Timeout, $Title, $value)
    $results = @{
        1 = 'Ok'
        2 = 'Cancel'
        3 = 'Abort'
        4 = 'Retry'
        5 = 'Ignore'
        6 = 'Yes'
        7 = 'No'
    }

    if ($result) {
        return $results.$result
    }
    else {
        return 'None'
    }
}

function Stop-ProcessesUnderRoots {
    param([string[]]$RootsLower)

    foreach ($proc in Get-Process -ErrorAction SilentlyContinue) {
        if (-not $proc.Path) { continue }

        $procPath = try {
            ([System.IO.Path]::GetFullPath($proc.Path)).ToLowerInvariant()
        }
        catch {
            continue
        }

        foreach ($root in $RootsLower) {
            if ($procPath.StartsWith($root)) {
                try {
                    Stop-Process -Id $proc.Id -Force -ErrorAction Stop
                    Wait-Process -Id $proc.Id -ErrorAction SilentlyContinue -Timeout 5
                }
                catch {
                    continue
                }

                break
            }
        }
    }
}

function Stop-TasksUnderRoots {
    param([string[]]$RootsLower)

    try {
        Import-Module ScheduledTasks -ErrorAction SilentlyContinue | Out-Null
    }
    catch {
        # Module may not be available on older systems; continue with fallbacks.
    }

    $tasks = @()
    try {
        $tasks = Get-ScheduledTask -ErrorAction Stop
    }
    catch {
        $tasks = @()
    }

    foreach ($task in $tasks) {
        $matchesRoot = $false

        foreach ($action in $task.Actions) {
            $execute = $null
            if ($action.PSObject.Properties.Match('Execute').Count) {
                $execute = $action.Execute
            }
            elseif ($action.PSObject.Properties.Match('Path').Count) {
                $execute = $action.Path
            }

            if (-not $execute) { continue }

            $executeLower = try {
                ([System.IO.Path]::GetFullPath($execute)).ToLowerInvariant()
            }
            catch {
                $null
            }

            if (-not $executeLower) { continue }

            foreach ($root in $RootsLower) {
                if ($executeLower.StartsWith($root)) {
                    $matchesRoot = $true
                    break
                }
            }

            if ($matchesRoot) { break }
        }

        if (-not $matchesRoot) { continue }

        try {
            Stop-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue
        }
        catch {
            # Ignore and fall back to schtasks below.
        }
    }

    foreach ($candidate in @('Force Timer Resolution', '\Force Timer Resolution')) {
        & schtasks.exe /End /TN $candidate 1>$null 2>$null
    }
}

Export-ModuleMember -Function Write-Title, Read-Pause, Read-MessageBox, Stop-ProcessesUnderRoots, Stop-TasksUnderRoots