# Companion of atlas-theme.psd1. Runs in the install engine (TrustedInstaller); the
# interactive theme/lock-screen apply lives in Initialize-NewUser (first logon).
# Disables the rotating lock-screen "fun facts" for every provisioned account
# (Enterprise/Education only). Dynamic subkeys under HKLM, so it can't be a static
# Registry entry.
$ErrorActionPreference = 'Continue'

$creativeKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Creative'
if (Test-Path -LiteralPath $creativeKey) {
    # @(): the key can exist with no subkeys; $null.PSPath throws under StrictMode.
    foreach ($userKey in @(Get-ChildItem -LiteralPath $creativeKey -ErrorAction SilentlyContinue)) {
        Set-ItemProperty -LiteralPath $userKey.PSPath -Name 'RotatingLockScreenEnabled' -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    }
}
