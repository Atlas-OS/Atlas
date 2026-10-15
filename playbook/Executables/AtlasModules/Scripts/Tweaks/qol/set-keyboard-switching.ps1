$context = Get-AtlasContext
$choices = @($context.Options | Where-Object {
    $_ -cin @('keyboard-shortcuts', 'keyboard-selector', 'keyboard-single')
})
if ($choices.Count -eq 0) { return }
if ($choices.Count -ne 1) { throw 'Choose exactly one keyboard language switching method.' }
Import-AtlasModule -Name Atlas.Toggles
$state = if ($choices[0] -ceq 'keyboard-shortcuts') { 'Enable' } else { 'Disable' }
# On an update, a choice made since with the Keyboard Languages launchers stays, as
# every recorded toggle does; Your choices starts from the options of the install.
if ($context.IsUpgrade) {
    $record = Get-AtlasToggleState -Name KeyboardShortcuts
    if ($null -ne $record -and $null -ne $record.State) {
        $state = if ([int]$record.State -eq 1) { 'Enable' } else { 'Disable' }
    }
}
# User replay applies the HKCU work after the machine pass has recorded the state.
Invoke-AtlasToggleMachineState -Name KeyboardShortcuts -State $state
