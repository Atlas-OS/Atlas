function Invoke-AtlasSendToContextMenuChooser {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Shell
    if ($Toggle.Silent) {
        Set-AtlasSendToContextMenu -DebloatDefaults
        return
    }

    if (-not (Set-AtlasSendToContextMenu)) {
        return
    }
    # The engine never restarts Explorer from an elevated process, so asking here would
    # offer a restart that can't happen.
    if ((Test-AtlasSystem) -or (Test-AtlasAdmin)) {
        Write-AtlasLog -NoConsole -Message 'The Send To items changed in an elevated window, so no File Explorer restart was offered.'
        Write-AtlasNextStep -Text 'Restart File Explorer from a normal (non-administrator) window, or sign out and back in, to see the change.'
        return
    }
    if (-not (Read-AtlasYesNo -Question 'Restart File Explorer now to apply the change?' -DefaultYes)) {
        return
    }
    # The items have already changed, so a failed refresh leaves the run partly done
    # rather than not applied.
    try {
        Write-AtlasStep -Text 'Restarting File Explorer...'
        Invoke-AtlasToggleCurrentSessionShellRefresh -Operation ExplorerRefresh
    }
    catch {
        Write-AtlasLog -Level Warning -NoConsole -Message "The Send To Explorer refresh failed: $($_.Exception.Message)"
        Write-AtlasPartial -Text "The Send To items changed, but File Explorer couldn't be restarted. Restart File Explorer, or sign out and back in."
    }
}
