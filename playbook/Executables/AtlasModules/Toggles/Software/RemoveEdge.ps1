function Invoke-AtlasEdgeRemover {
    param($Toggle)

    $script = Join-Path -Path $Toggle.OperationsPath -ChildPath 'Remove-Edge.ps1'
    if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
        throw "Required Edge action helper is missing: '$script'."
    }
    if ($Toggle.Silent) {
        throw 'Installing or removing Microsoft Edge needs an interactive window to choose the action.'
    }

    # The engine's elevated window hosts the helper's menu and owns the heading and
    # the exit pause. The helper's exit code decides whether this run counts as done.
    $global:LASTEXITCODE = 0
    & $script -Embedded
    if ($LASTEXITCODE -ne 0) {
        throw "The Edge helper did not complete (exit code $LASTEXITCODE)."
    }

    # The uninstall-edge install choice follows whatever the helper left, and so
    # does the option flag a new account's setup reads (Initialize-NewUser.ps1) to
    # clean that account's Edge data, once the document has taken the choice: an
    # install that is running publishes the flags itself when it completes. Edge
    # has already changed, so a record that can't be written is a warning; the
    # next install records what the PC has.
    Import-AtlasModule -Name Atlas.State
    try {
        $programFilesX86 = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFilesX86)
        if ([string]::IsNullOrWhiteSpace($programFilesX86)) {
            throw 'the 32-bit Program Files directory is unavailable.'
        }
        $edgeInstalled = Test-Path -LiteralPath ([IO.Path]::Combine($programFilesX86, 'Microsoft\Edge\Application\msedge.exe')) -PathType Leaf
        $document = Set-AtlasStateChoice -Option 'uninstall-edge' -Absent:$edgeInstalled
        if ($null -ne $document) {
            $flag = [IO.Path]::Combine($Toggle.AtlasModulesPath, 'Flags', 'option-uninstall-edge.flag')
            if ($edgeInstalled) {
                if ([IO.File]::Exists($flag)) { [IO.File]::Delete($flag) }
            }
            elseif (-not [IO.File]::Exists($flag)) {
                [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($flag))
                [IO.File]::Create($flag).Dispose()
            }
        }
    }
    catch {
        Write-AtlasLog -Level Warning -Message "Couldn't record whether Microsoft Edge is installed for Atlas: $($_.Exception.Message)" -ErrorRecord $_
    }
}
