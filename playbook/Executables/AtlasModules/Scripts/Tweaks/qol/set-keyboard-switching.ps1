$choices = @((Get-AtlasContext).Options | Where-Object {
    $_ -cin @('keyboard-shortcuts', 'keyboard-selector', 'keyboard-single')
})
if ($choices.Count -eq 0) { return }
if ($choices.Count -ne 1) { throw 'Choose exactly one keyboard language switching method.' }
Import-AtlasModule -Name Atlas.Toggles
$state = if ($choices[0] -ceq 'keyboard-shortcuts') { 'Enable' } else { 'Disable' }
# This is an explicit install choice, including on upgrades. User replay applies
# its HKCU work after the new choice has been recorded by the machine pass.
Invoke-AtlasToggleMachineState -Name KeyboardShortcuts -State $state
