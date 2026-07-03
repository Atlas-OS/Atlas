# Toggle: Sleep (power-scheme sleep settings + optional hibernation follow-up).
#
# An interactive Read-Host offers to also toggle hibernation via the Hibernation toggle;
# silent runs skip the prompt.
@{
    Name      = 'Sleep'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\Sleep\Disable Sleep.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $powercfg = "$($Toggle.WinDir)\System32\powercfg.exe"
                $sub = '238c9fa8-0aad-41ed-83f4-97be242c8f20'
                foreach ($pair in @(
                    @{ Guid = '25dfa149-5dd1-4736-b5ab-e8a37b5b8187'; Value = 0 }
                    @{ Guid = 'abfc2519-3608-4c2a-94ea-171b0ed546ab'; Value = 0 }
                    @{ Guid = '94ac6d29-73ce-41a6-809f-6363ba21b47e'; Value = 0 }
                    @{ Guid = '7bc4a2f9-d8fc-4469-b07b-33eb785aaca0'; Value = 0 }
                    @{ Guid = 'bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d'; Value = 0 }
                )) {
                    & $powercfg /setacvalueindex scheme_current $sub $pair.Guid $pair.Value
                }
                & $powercfg /setacvalueindex scheme_current '2e601130-5351-4d9d-8e04-252966bad054' 'd502f7ee-1dc7-4efd-a55d-f04b6f5c0545' 0
                & $powercfg /setactive scheme_current

                if ($Toggle.Silent) { return }

                $answer = Read-Host 'Would you like to disable hibernation? [Y/N]'
                if ($answer -match '^(y|yes)$') {
                    Invoke-AtlasToggle -Name 'Hibernation' -State 'Disable' -Silent
                }
                else {
                    Invoke-AtlasToggle -Name 'Hibernation' -State 'Enable' -Silent
                }
                Write-Host 'Sleep has been disabled.'
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '3. General Configuration\Sleep\Enable Sleep (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $powercfg = "$($Toggle.WinDir)\System32\powercfg.exe"
                $sub = '238c9fa8-0aad-41ed-83f4-97be242c8f20'
                foreach ($pair in @(
                    @{ Guid = '25dfa149-5dd1-4736-b5ab-e8a37b5b8187'; Value = 1 }
                    @{ Guid = 'abfc2519-3608-4c2a-94ea-171b0ed546ab'; Value = 1 }
                    @{ Guid = '94ac6d29-73ce-41a6-809f-6363ba21b47e'; Value = 1 }
                    @{ Guid = '7bc4a2f9-d8fc-4469-b07b-33eb785aaca0'; Value = 120 }
                    @{ Guid = 'bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d'; Value = 1 }
                )) {
                    & $powercfg /setacvalueindex scheme_current $sub $pair.Guid $pair.Value
                }
                & $powercfg /setacvalueindex scheme_current '2e601130-5351-4d9d-8e04-252966bad054' 'd502f7ee-1dc7-4efd-a55d-f04b6f5c0545' 1
                & $powercfg /setactive scheme_current

                if ($Toggle.Silent) { return }

                $answer = Read-Host 'Would you like to enable hibernation? [Y/N]'
                if ($answer -match '^(y|yes)$') {
                    Invoke-AtlasToggle -Name 'Hibernation' -State 'Enable' -Silent
                }
                else {
                    Invoke-AtlasToggle -Name 'Hibernation' -State 'Disable' -Silent
                }
                Write-Host 'Sleep has been enabled.'
            }
        }
    }
}
