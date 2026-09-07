# Prints the UI Automation tree of the running Atlas window (control type,
# name, and the states assistive technology sees), so accessibility changes
# can be checked without a screen reader. Developer tooling for UI review.
param(
    [string]$ProcessName = 'atlas',
    [int]$ProcessId = 0,
    # Invoke the control with this exact UI Automation name before dumping
    # (exercises the accessible Click action, as voice control would).
    [string]$Invoke,
    [switch]$Json
)
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$process = if ($ProcessId) { Get-Process -Id $ProcessId -ErrorAction Stop } else { Get-Process -Name $ProcessName -ErrorAction Stop | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1 }
if (-not $process) { throw "No window for $ProcessName" }
$root = [System.Windows.Automation.AutomationElement]::FromHandle($process.MainWindowHandle)
$walker = [System.Windows.Automation.TreeWalker]::ControlViewWalker

function Get-Nodes {
    param($Element, [int]$Depth)
    $current = $Element.Current
    $states = @()
    $pattern = $null
    if ($Element.TryGetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern, [ref]$pattern)) {
        $states += "toggle=$($pattern.Current.ToggleState)"
    }
    if ($Element.TryGetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern, [ref]$pattern)) {
        $states += "selected=$($pattern.Current.IsSelected)"
    }
    if ($Element.TryGetCurrentPattern([System.Windows.Automation.RangeValuePattern]::Pattern, [ref]$pattern)) {
        $states += "value=$($pattern.Current.Value)"
    }
    if ($Element.TryGetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern, [ref]$pattern)) {
        $states += 'invokable'
    }
    if (-not $current.IsEnabled) { $states += 'disabled' }
    if ($current.HasKeyboardFocus) { $states += 'FOCUSED' }
    if ($current.IsKeyboardFocusable) { $states += 'focusable' }
    $help = $current.HelpText
    [pscustomobject]@{
        Depth   = $Depth
        Type    = $current.ControlType.ProgrammaticName -replace '^ControlType\.', ''
        Name    = $current.Name
        Help    = $help
        States  = ($states -join ' ')
        Element = $Element
    }
    $child = $walker.GetFirstChild($Element)
    while ($child) {
        Get-Nodes -Element $child -Depth ($Depth + 1)
        $child = $walker.GetNextSibling($child)
    }
}

$nodes = @(Get-Nodes -Element $root -Depth 0)

if ($Invoke) {
    $target = $nodes | Where-Object { $_.Name -eq $Invoke } | Select-Object -First 1
    if (-not $target) { throw "No control named '$Invoke'" }
    $pattern = $null
    if ($target.Element.TryGetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern, [ref]$pattern)) {
        $pattern.Invoke()
    }
    elseif ($target.Element.TryGetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern, [ref]$pattern)) {
        $pattern.Toggle()
    }
    elseif ($target.Element.TryGetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern, [ref]$pattern)) {
        $pattern.Select()
    }
    else { throw "'$Invoke' has no invoke, toggle or select pattern" }
    Start-Sleep -Milliseconds 700
    $nodes = @(Get-Nodes -Element $root -Depth 0)
}

if ($Json) {
    $nodes | Select-Object Depth, Type, Name, Help, States | ConvertTo-Json -Depth 3
}
else {
    foreach ($node in $nodes) {
        $indent = '  ' * $node.Depth
        $line = "$indent[$($node.Type)] $($node.Name)"
        if ($node.Help) { $line += "  {$($node.Help)}" }
        if ($node.States) { $line += "  <$($node.States)>" }
        $line
    }
}
