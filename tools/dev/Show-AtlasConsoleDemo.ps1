<#
.SYNOPSIS
    Renders the Atlas console vocabulary and four representative launcher flows
    without touching the machine.
.DESCRIPTION
    Imports the payload's Atlas.Core module, feeds scripted answers to its prompts and
    prints exactly what a user would see for: a simple declarative toggle, a
    multi-question flow, a failure, and a manual Settings hand-over. Nothing is applied,
    elevated, recorded or logged to the shared install log; the only side effect is
    console output. Run it under Windows PowerShell 5.1, the payload's runtime:

        powershell -NoProfile -File tools\dev\Show-AtlasConsoleDemo.ps1

    Pass -NoColor to see the plain-text rendering a transcript or a monochrome
    console produces.
#>
[CmdletBinding()]
param(
    [switch]$NoColor
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$coreManifest = Join-Path -Path $repoRoot -ChildPath 'playbook\Executables\AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1'
$core = Import-Module -Name $coreManifest -Force -PassThru

# Scripted answers replace the keyboard; the prompt text is still printed so the
# rendering matches a real window.
$script:DemoAnswers = New-Object 'System.Collections.Generic.Queue[string]'
& $core {
    Set-Item -Path 'function:Read-AtlasConsoleLine' -Value {
        param([string]$Prompt)
        $answer = if ($script:DemoAnswerSource.Count -gt 0) { $script:DemoAnswerSource.Dequeue() } else { '' }
        Write-Host ($Prompt + $answer)
        return $answer
    }
}
& $core { param($Queue) $script:DemoAnswerSource = $Queue } $script:DemoAnswers

if ($NoColor) {
    & $core {
        Set-Item -Path 'function:Write-AtlasUiText' -Value {
            param([string[]]$Text, [string]$Prefix = '', [string]$Color)
            [void]$Color
            foreach ($line in (Get-AtlasUiLine -Text $Text -Prefix $Prefix)) { Write-Host $line }
        }
    }
}

function Show-DemoSection {
    param([string]$Caption)
    Write-Host ''
    Write-Host "==== $Caption ====" -ForegroundColor DarkGray
    Write-Host ''
}

function Add-DemoAnswer {
    param([string[]]$Answer)
    foreach ($item in $Answer) { $script:DemoAnswers.Enqueue($item) }
}

Show-DemoSection 'Vocabulary'
Write-AtlasTitle -Text 'Vocabulary sample' -Explanation 'Every kind of line the launchers print.'
Write-AtlasNote -Text 'A note gives context in plain words.'
Write-AtlasStep -Text 'A step announces slow work. This can take a minute...'
Write-AtlasWarning -Text "A warning names a concrete consequence.`nContinuation lines line up under the text."
Write-AtlasSuccess -Text 'A success line states a verified fact.'
Write-AtlasNextStep -Text 'A next step is advice after a completed change.'
Write-AtlasRestartNotice -Kind Recommended
Write-AtlasFailure -Text 'An error names the reason something did not happen.'

Show-DemoSection 'Simple toggle: Disable Background Apps (default)'
Reset-AtlasRunOutcome
Add-DemoAnswer ''
Write-AtlasTitle -Text 'Disable Background Apps (default)'
Write-AtlasCompletion -Title 'Disable Background Apps (default)'
Wait-AtlasExit

Show-DemoSection 'Multi-option flow: Enable File Sharing (standard user, administrator credentials)'
Reset-AtlasRunOutcome
Add-DemoAnswer 'n', 'y', 'y', 'n', ''
Write-AtlasTitle -Text 'Enable File Sharing'
Write-AtlasStep -Text 'Asking for administrator permission...'
Write-Host '    (administrator window)'
Write-Host '    AtlasOS - Enable File Sharing'
Write-Host '    -----------------------------'
Write-Host '    Administrator step for the change started in the other window.'
Write-Host ''
Write-Host '    Enabling file sharing, NetBIOS and network discovery...'
Write-Host -NoNewline '    '
$null = Read-AtlasYesNo -Question 'Switch your active networks to the Private profile so other devices can see this PC?'
Write-Host -NoNewline '    '
$null = Read-AtlasYesNo -Question "Restore the 'Give access to' context menu?"
$null = Read-AtlasYesNo -Question 'Add Network to the File Explorer navigation pane?'
Write-Host '    (administrator window records that separate choice)'
Write-AtlasCompletion -Title 'Enable File Sharing'
Write-AtlasRestartNotice -Kind Required
$null = Read-AtlasYesNo -Question 'Restart Windows now?'
Wait-AtlasExit

Show-DemoSection 'Failure: Enable Widgets with Edge missing and its installation declined'
Reset-AtlasRunOutcome
Add-DemoAnswer 'n', '', ''
Write-AtlasTitle -Text 'Enable Widgets'
Write-AtlasStep -Text 'Asking for administrator permission...'
Write-Host '    (administrator window)'
Write-Host '    AtlasOS - Enable Widgets'
Write-Host '    ------------------------'
Write-Host '    Administrator step for the change started in the other window.'
Write-Host ''
Write-Host '    Widgets needs Microsoft Edge, which is not installed.'
Write-Host -NoNewline '    '
$null = Read-AtlasYesNo -Question 'Install Microsoft Edge now?'
Write-AtlasNotApplied -Title 'Enable Widgets' -Reason 'Microsoft Edge is not installed and its installation was declined.' `
    -DetailsPath 'C:\Windows\AtlasOS\Logs\install\atlas-install.log'
Wait-AtlasExit
Write-Host ''
Write-AtlasNotApplied -Title 'Enable Widgets' `
    -Reason "The administrator step for 'Widgets' did not complete (exit code 1). Its window shows the reason." `
    -DetailsPath "$env:LOCALAPPDATA\AtlasOS\Logs\install\atlas-install.log"
Wait-AtlasExit

Show-DemoSection 'Manual Settings action: Remove Python Store Prompt'
Reset-AtlasRunOutcome
Add-DemoAnswer ''
Write-AtlasTitle -Text 'Remove Python Store Prompt'
Write-AtlasNote -Text @(
    'Windows cannot tell which package owns a python.exe alias, so Atlas opens the'
    'Settings page and leaves the choice to you. No Python files are deleted.'
)
Write-AtlasBlankLine
Write-AtlasStep -Text 'Opening Settings > Apps > Advanced app settings...'
Write-AtlasManualStep -Text @(
    'select App execution aliases, then turn off python.exe and python3.exe'
    'under App Installer. Keep the aliases of any Python you installed yourself.'
)
Write-AtlasNote -Text 'If Settings did not open that page, go to Apps > Advanced app settings.'
Write-AtlasCompletion -Title 'Remove Python Store Prompt'
Wait-AtlasExit

Show-DemoSection 'Menu toggle: Toggle Defender with an invalid answer first'
Reset-AtlasRunOutcome
Add-DemoAnswer '5', '1', '', 'n', ''
Write-AtlasTitle -Text 'Toggle Defender'
Write-AtlasNote -Text 'Only disable Windows Defender after reading the Atlas documentation.'
Write-AtlasBlankLine
$choice = Read-AtlasChoice -Question 'What would you like to do?' `
    -Option @('Disable Windows Defender', 'Enable Windows Defender', 'Open the documentation') -CurrentIndex 2
Write-AtlasBlankLine
Write-AtlasWarning -Text @(
    'Disabling Windows Defender leaves this PC without real-time antivirus protection.'
    'Malware and unwanted software will no longer be blocked automatically.'
)
Wait-AtlasContinue
Write-AtlasStep -Text 'Disabling Windows Defender. This can take a few minutes...'
Write-AtlasCompletion -Title 'Toggle Defender'
Write-AtlasRestartNotice -Kind Required
$null = Read-AtlasYesNo -Question 'Restart Windows now?'
Wait-AtlasExit
[void]$choice
