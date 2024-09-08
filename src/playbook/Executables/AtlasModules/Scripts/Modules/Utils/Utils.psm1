function Write-Title {
    param (
        [Parameter(Mandatory=$true)]
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
        [Parameter(Mandatory=$true)]
        [string]$Title,
        [Parameter(Mandatory=$true)]
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

    $result = (New-Object -ComObject "Wscript.Shell").Popup($Body,$Timeout,$Title,$value)
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
    } else {
        return 'None'
    }
}

Export-ModuleMember -Function Write-Title, Read-Pause, Read-MessageBox