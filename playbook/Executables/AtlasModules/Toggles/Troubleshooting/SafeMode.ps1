# Companion for the SafeMode toggle: sets or clears safe mode in the boot configuration
# through SafeMode.ps1. Set-AtlasSafeModeBoot runs as Administrator when you run a launcher;
# nothing is recorded.

function Set-AtlasSafeModeBoot {
    param($Toggle)

    # The state name is the SafeMode.ps1 operation: Minimal, Networking, CommandPrompt or Exit.
    & (Join-Path -Path $Toggle.OperationsPath -ChildPath 'SafeMode.ps1') -Mode $Toggle.State
}
