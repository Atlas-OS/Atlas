function Set-AtlasSafeModeBoot {
    param($Toggle)

    # The state name is the SafeMode.ps1 operation: Minimal, Networking, CommandPrompt or Exit.
    & (Join-Path -Path $Toggle.OperationsPath -ChildPath 'SafeMode.ps1') -Mode $Toggle.State
}
