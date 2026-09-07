function Invoke-AtlasAnimationLogoffPrompt {
    param($Toggle)

    if ($Toggle.Silent) {
        return
    }

    Write-AtlasRestartNotice -Kind SignOut
    if (Read-AtlasYesNo -Question 'Sign out now?') {
        $logoff = Join-Path -Path $Toggle.WinDir -ChildPath 'System32\logoff.exe'
        if (-not (Test-Path -LiteralPath $logoff -PathType Leaf)) {
            throw "Animation: logoff.exe is missing at '$logoff'."
        }
        Write-AtlasStep -Text 'Signing out...'
        Invoke-AtlasToggleNativeCommand -FilePath $logoff `
            -ArgumentList ([string[]]@()) -AllowedExitCodes ([int[]]@(0)) | Out-Null
    }
}
