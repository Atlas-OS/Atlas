# Toggle: 'Run with priority' cascading entry in the .exe context menu.
# Note: the stored command strings keep the literal '%1' shell placeholder verbatim.
@{
    Name      = 'RunWithPriority'
    Elevation = 'Admin'
    States    = [ordered]@{
        Add    = @{
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Context Menus\Run With Priority\Add Run With Priority In Context Menu.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $shell = 'Registry::HKEY_CLASSES_ROOT\exefile\Shell\Priority\shell'
                New-Item -Path "$shell\001flyout" -Value 'Realtime' -Force | Out-Null
                New-Item -Path "$shell\001flyout\command" -Value 'powershell start -file ''cmd'' -args ''/c start """Realtime App""" /Realtime """%1"""'' -verb runas' -Force | Out-Null
                New-Item -Path "$shell\002flyout" -Value 'High' -Force | Out-Null
                New-Item -Path "$shell\002flyout\command" -Value 'cmd /c start "" /High "%1"' -Force | Out-Null
                New-Item -Path "$shell\003flyout" -Value 'Above normal' -Force | Out-Null
                New-Item -Path "$shell\003flyout\command" -Value 'cmd /c start "" /AboveNormal "%1"' -Force | Out-Null
                New-Item -Path "$shell\004flyout" -Value 'Normal' -Force | Out-Null
                New-Item -Path "$shell\004flyout\command" -Value 'cmd /c start "" /Normal "%1"' -Force | Out-Null
                New-Item -Path "$shell\005flyout" -Value 'Below normal' -Force | Out-Null
                New-Item -Path "$shell\005flyout\command" -Value 'cmd /c start "" /BelowNormal "%1"' -Force | Out-Null
                New-Item -Path "$shell\006flyout" -Value 'Low' -Force | Out-Null
                New-Item -Path "$shell\006flyout\command" -Value 'cmd /c start "" /Low "%1"' -Force | Out-Null

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
        Remove = @{
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Context Menus\Run With Priority\Remove Run With Priority In Context Menu (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Remove-Item -Path 'Registry::HKEY_CLASSES_ROOT\exefile\shell\Priority' -Recurse -Force -ErrorAction SilentlyContinue

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
    }
}
