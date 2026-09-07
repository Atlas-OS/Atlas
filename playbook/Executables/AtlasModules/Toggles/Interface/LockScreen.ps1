function Assert-AtlasLockScreenPolicyRemoved {
    param($Toggle)

    # The Registry entries have already deleted the policy values; confirm none of them
    # survived so a lingering policy can never be recorded as 'Show'.
    $verifyKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
        'SOFTWARE\Policies\Microsoft\Windows\Personalization',
        $false
    )
    if ($null -ne $verifyKey) {
        try {
            $remainingNames = @($verifyKey.GetValueNames())
            foreach ($removedName in @('NoLockScreen', 'NoChangingLockScreen')) {
                if ($remainingNames -contains $removedName) {
                    throw "Lock-screen policy value '$removedName' remains after removal."
                }
            }
        }
        finally {
            $verifyKey.Dispose()
        }
    }
    [void]$Toggle
}
