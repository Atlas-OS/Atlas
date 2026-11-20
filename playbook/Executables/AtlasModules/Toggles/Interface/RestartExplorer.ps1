# Companion for the RestartExplorer toggle. Show-AtlasRestartExplorerMessage runs in the
# launcher's own process, as you, when you run the launcher; the engine restarts File Explorer
# itself, and nothing is recorded.

function Show-AtlasRestartExplorerMessage {
    param($Toggle)

    # The engine performs and announces the Explorer restart through Reboot =
    # RestartExplorer; this action has nothing to add.
    [void]$Toggle
}
