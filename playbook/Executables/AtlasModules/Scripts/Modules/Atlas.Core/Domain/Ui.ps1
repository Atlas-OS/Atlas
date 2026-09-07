# Atlas.Core domain: console presentation.
#
# One vocabulary for every interactive Atlas surface: the toggle engine, companion
# functions, nested helpers and the hand-written entry scripts. Each line carries its
# meaning in words (Warning:, Error:, Next step:, Done:) so colour is only a hint and a
# transcript reads the same as the window. See docs/console-presentation.md.
#
# Prompts read through the host. A -NonInteractive or windowless process fails with a
# clear error instead of waiting forever; callers still gate prompts on their own
# silent flag so replay and installation never reach one.

$script:AtlasUiBrand = 'AtlasOS'
$script:AtlasRunOutcome = 'Applied'
# Whether the last line this vocabulary printed was blank, so the closing lines can
# separate themselves from the text above without stacking blank lines.
$script:AtlasUiLastLineBlank = $true

function Get-AtlasUiLine {
    <#
    .SYNOPSIS
        Splits text into console lines, prefixing the first and indenting the rest.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        [string[]]$Text,

        [string]$Prefix = ''
    )

    $lines = New-Object 'System.Collections.Generic.List[string]'
    foreach ($item in $Text) {
        foreach ($line in ([string]$item -split '\r?\n')) {
            $lines.Add($line)
        }
    }
    if ($lines.Count -eq 0) {
        $lines.Add('')
    }

    $indent = ' ' * $Prefix.Length
    for ($index = 0; $index -lt $lines.Count; $index++) {
        $lines[$index] = $(if ($index -eq 0) { $Prefix } else { $indent }) + $lines[$index]
    }
    return $lines.ToArray()
}

function Write-AtlasUiText {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        [string[]]$Text,

        [string]$Prefix = '',

        [string]$Color
    )

    foreach ($line in (Get-AtlasUiLine -Text $Text -Prefix $Prefix)) {
        if ($Color) {
            Write-Host $line -ForegroundColor $Color
        }
        else {
            Write-Host $line
        }
        $script:AtlasUiLastLineBlank = [string]::IsNullOrWhiteSpace($line)
    }
}

function Write-AtlasBlankLine {
    <#
    .SYNOPSIS
        Prints one blank line unless the previous line was already blank.
    #>
    if (-not $script:AtlasUiLastLineBlank) {
        Write-Host ''
        $script:AtlasUiLastLineBlank = $true
    }
}

function Read-AtlasConsoleLine {
    <#
    .SYNOPSIS
        Prints a prompt without a trailing colon and reads one line from the host.
        Returns $null when the host has no input (end of stream).
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt
    )

    Write-Host $Prompt -NoNewline
    $script:AtlasUiLastLineBlank = $false
    try {
        return $Host.UI.ReadLine()
    }
    catch {
        Write-Host ''
        throw "Atlas needed an answer to '$($Prompt.Trim())' but this window cannot take keyboard input: $($_.Exception.Message)"
    }
}

function Write-AtlasTitle {
    <#
    .SYNOPSIS
        Prints the Atlas heading for an interactive run and sets the window title.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Text,

        [string[]]$Explanation
    )

    $heading = "$script:AtlasUiBrand - $Text"
    try {
        $Host.UI.RawUI.WindowTitle = $heading
    }
    catch {
        $null = $_
    }

    Write-Host $heading -ForegroundColor Cyan
    Write-Host ('-' * $heading.Length) -ForegroundColor DarkCyan
    if ($Explanation) {
        Write-AtlasUiText -Text $Explanation
    }
    Write-Host ''
    $script:AtlasUiLastLineBlank = $true
}

function Write-AtlasNote {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$Text
    )

    Write-AtlasUiText -Text $Text
}

function Write-AtlasStep {
    <#
    .SYNOPSIS
        Announces work that takes noticeable time. Say how long when it is known.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Text
    )

    Write-AtlasUiText -Text $Text
}

function Write-AtlasWarning {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Text
    )

    Write-AtlasUiText -Text $Text -Prefix 'Warning: ' -Color Yellow
}

function Write-AtlasSuccess {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Text
    )

    Write-AtlasUiText -Text $Text -Color Green
}

function Write-AtlasFailure {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Text
    )

    Write-AtlasUiText -Text $Text -Prefix 'Error: ' -Color Red
}

function Write-AtlasPartial {
    <#
    .SYNOPSIS
        Reports that part of the work applied and marks the run outcome Partial.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Text
    )

    Set-AtlasRunOutcome -Outcome Partial
    Write-AtlasUiText -Text $Text -Prefix 'Partly done: ' -Color Yellow
}

function Write-AtlasNextStep {
    <#
    .SYNOPSIS
        Advice after a completed change. The run still counts as applied.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Text
    )

    Write-AtlasUiText -Text $Text -Prefix 'Next step: ' -Color Cyan
}

function Write-AtlasManualStep {
    <#
    .SYNOPSIS
        Hands the change over to the user (Settings was opened, a choice must be made
        there) and marks the run outcome Manual so the closing line says so.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Text
    )

    Set-AtlasRunOutcome -Outcome Manual
    Write-AtlasUiText -Text $Text -Prefix 'To finish: ' -Color Yellow
}

function Write-AtlasRestartNotice {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Recommended', 'Required', 'SignOut', 'ExplorerRestarted', 'ExplorerRestartNeeded')]
        [string]$Kind
    )

    switch ($Kind) {
        'Recommended' {
            Write-AtlasUiText -Text 'Restart recommended: restart Windows to finish applying this change.' -Color Yellow
        }
        'Required' {
            Write-AtlasUiText -Text 'Restart required: this change takes effect after Windows restarts.' -Color Yellow
        }
        'SignOut' {
            Write-AtlasUiText -Text 'Sign out required: sign out and back in to finish applying this change.' -Color Yellow
        }
        'ExplorerRestarted' {
            Write-AtlasUiText -Text 'File Explorer was restarted to apply this change.'
        }
        'ExplorerRestartNeeded' {
            Write-AtlasUiText -Text 'Restart File Explorer, or sign out and back in, to see this change.' -Color Yellow
        }
    }
}

function Write-AtlasNotApplied {
    <#
    .SYNOPSIS
        The standard failure block of an interactive entry point: what was not applied,
        why, and where the full diagnostic went.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Reason,

        [string]$DetailsPath
    )

    Write-AtlasBlankLine
    Write-AtlasUiText -Text "Not applied: $Title." -Color Red
    Write-AtlasFailure -Text $Reason
    if ($DetailsPath) {
        Write-AtlasUiText -Text $DetailsPath -Prefix 'Details: '
    }
}

function Reset-AtlasRunOutcome {
    $script:AtlasRunOutcome = 'Applied'
}

function Get-AtlasRunOutcome {
    return $script:AtlasRunOutcome
}

function Set-AtlasRunOutcome {
    <#
    .SYNOPSIS
        Records how the current run ended. Partial outranks Manual, which outranks
        Applied, so a later weaker report never hides an earlier stronger one.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Applied', 'Manual', 'Partial')]
        [string]$Outcome
    )

    $rank = @{ Applied = 0; Manual = 1; Partial = 2 }
    if ($rank[$Outcome] -ge $rank[$script:AtlasRunOutcome]) {
        $script:AtlasRunOutcome = $Outcome
    }
}

function Write-AtlasCompletion {
    <#
    .SYNOPSIS
        Prints the one closing line of an interactive run from the recorded outcome.
        Print it only after every part of the work finished and was recorded.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Title
    )

    Write-AtlasBlankLine
    switch (Get-AtlasRunOutcome) {
        'Applied' { Write-AtlasSuccess -Text "Done: $Title." }
        'Manual' { Write-AtlasUiText -Text 'Not finished yet: complete the step above.' -Color Yellow }
        'Partial' { Write-AtlasUiText -Text "Partly done: $Title. Review the warnings above." -Color Yellow }
    }
}

function Read-AtlasYesNo {
    <#
    .SYNOPSIS
        Asks one yes/no question. y/yes and n/no in any case are accepted, Enter takes
        the default (No unless -DefaultYes), anything else asks again.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Question,

        [switch]$DefaultYes
    )

    $hint = if ($DefaultYes) { '[Y/n]' } else { '[y/N]' }
    while ($true) {
        $answer = Read-AtlasConsoleLine -Prompt "$Question $hint "
        if ($null -eq $answer) {
            return [bool]$DefaultYes
        }
        $answer = $answer.Trim()
        if ($answer.Length -eq 0) {
            return [bool]$DefaultYes
        }
        if ($answer -match '^(?i:y|yes)$') {
            return $true
        }
        if ($answer -match '^(?i:n|no)$') {
            return $false
        }
        Write-Host 'Please answer y or n.' -ForegroundColor Yellow
    }
}

function Read-AtlasChoice {
    <#
    .SYNOPSIS
        Shows a numbered list and returns the chosen 1-based index. -CurrentIndex marks
        the active option, which cannot be chosen again; -DefaultIndex is taken on Enter.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Question,

        [Parameter(Mandatory = $true)]
        [ValidateCount(1, 99)]
        [string[]]$Option,

        [ValidateRange(0, 99)]
        [int]$CurrentIndex = 0,

        [ValidateRange(0, 99)]
        [int]$DefaultIndex = 0
    )

    if ($CurrentIndex -gt $Option.Count -or $DefaultIndex -gt $Option.Count) {
        throw 'The current or default option index is outside the option list.'
    }

    Write-AtlasUiText -Text $Question
    for ($index = 1; $index -le $Option.Count; $index++) {
        $label = "  [$index] $($Option[$index - 1])"
        if ($index -eq $CurrentIndex) {
            $label += ' (current)'
        }
        elseif ($index -eq $DefaultIndex) {
            $label += ' (default)'
        }
        Write-Host $label
    }
    Write-Host ''
    $script:AtlasUiLastLineBlank = $true

    while ($true) {
        $answer = Read-AtlasConsoleLine -Prompt "Choose 1-$($Option.Count): "
        if ($null -eq $answer) {
            if ($DefaultIndex -gt 0) {
                return $DefaultIndex
            }
            throw 'No option was chosen because this window has no keyboard input.'
        }
        $answer = $answer.Trim()
        if ($answer.Length -eq 0 -and $DefaultIndex -gt 0) {
            return $DefaultIndex
        }

        $choice = 0
        if (-not [int]::TryParse($answer, [ref]$choice) -or $choice -lt 1 -or $choice -gt $Option.Count) {
            Write-Host "Please type a number from 1 to $($Option.Count)." -ForegroundColor Yellow
            continue
        }
        if ($choice -eq $CurrentIndex) {
            Write-Host 'That is already the current setting. Choose another option.' -ForegroundColor Yellow
            continue
        }
        return $choice
    }
}

function Wait-AtlasContinue {
    <#
    .SYNOPSIS
        The acknowledgement gate after a warning. Ctrl+C ends the run without changes.
    #>
    param(
        [string]$Message = 'Press Enter to continue, or Ctrl+C to cancel.'
    )

    $null = Read-AtlasConsoleLine -Prompt "$Message "
}

function Wait-AtlasExit {
    <#
    .SYNOPSIS
        The single exit pause of an interactive run. Only the owning entry point calls it.
    #>
    param(
        [string]$Message = 'Press Enter to exit.'
    )

    Write-AtlasBlankLine
    $null = Read-AtlasConsoleLine -Prompt "$Message "
}

function Read-MessageBox {
    <#
    .SYNOPSIS
        Shows a Windows message box. Reserved for flows that already run inside a
        dialog (the software picker); console flows use the prompt helpers above.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,
        [Parameter(Mandatory = $true)]
        [string]$Body,
        [ValidateSet('Stop', 'Question', 'Warning', 'Info', 'Information')]
        [string]$Icon = 'Info',
        [ValidateSet('Ok', 'OkCancel', 'AbortRetryIgnore', 'YesNoCancel', 'YesNo', 'RetryAndCancel')]
        [string]$Buttons = 'YesNo',
        [int]$Timeout = 0,
        [switch]$NoTopmost
    )

    $iconValues = @{ Stop = 16; Question = 32; Warning = 48; Info = 64; Information = 64 }
    $buttonValues = @{ Ok = 0; OkCancel = 1; AbortRetryIgnore = 2; YesNoCancel = 3; YesNo = 4; RetryAndCancel = 5 }
    $value = $iconValues[$Icon] + $buttonValues[$Buttons]
    if (-not $NoTopmost) { $value += 4096 }

    $result = (New-Object -ComObject 'Wscript.Shell').Popup($Body, $Timeout, $Title, $value)
    $results = @{
        1 = 'Ok'
        2 = 'Cancel'
        3 = 'Abort'
        4 = 'Retry'
        5 = 'Ignore'
        6 = 'Yes'
        7 = 'No'
    }

    if ($result -and $results.ContainsKey([int]$result)) {
        return $results[[int]$result]
    }
    return 'None'
}
