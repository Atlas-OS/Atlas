@{
    Name        = 'Disable WU Auto-Updates (app re-install prevention)'
    Description = 'Prevents DevHome and Outlook from re-installing through Windows Update. Split from disable-auto-updates: these entries always apply, while the auto-update disabling itself is gated on the ''auto-updates-disable'' option (see disable-auto-updates-option.psd1).'
    Registry    = @(
        # Prevent DevHome & Outlook from re-installing
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate'; Operation = 'DeleteKey' }
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate'; Name = 'workCompleted'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate'; Operation = 'DeleteKey' }
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate'; Name = 'workCompleted'; Type = 'DWord'; Data = 1 }

        # Prevent random apps from installing, including Widgets or advertisements
        # Commented until it's proven that this helps - deleting these values is irreversible
        # (preserved verbatim from the legacy YAML playbook):
        # - !registryValue: {path: 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\Settings', value: 'STOREBIZCRITICALAPPS', operation: delete}
        # - !registryValue: {path: 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\InstallService\State\CategoryCache', value: '48caba8a-2e62-2097-dcd8-4255c637b32dUS', operation: delete}
        # - !registryValue: {path: 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell\Update\Packages\Components', value: 'AccountsService', operation: delete}
        # - !registryValue: {path: 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell\Update\Packages\Components', value: 'BackupBanner', operation: delete}
        # - !registryValue: {path: 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell\Update\Packages\Components', value: 'DesktopSpotlight', operation: delete}
        # - !registryValue: {path: 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell\Update\Packages\Components', value: 'IrisService', operation: delete}
        # - !registryValue: {path: 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell\Update\Packages\Components', value: 'SystemSettingsExtensions', operation: delete}
        # - !registryValue: {path: 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell\Update\Packages\Components', value: 'WebExperienceHost', operation: delete}
        # - !registryValue: {path: 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell\Update\Packages\Components', value: 'WindowsBackup', operation: delete}
        # - !registryValue: {path: 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\LastOnlineScanTimeForAppCategory\855E8A7C-ECB4-4CA3-B045-1DFA50104289', value: 'EA6A8EC8-24BF-48A3-B0F0-A86A6447C0E2', operation: delete}
        # - !registryValue: {path: 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RequestedAppCategories\855E8A7C-ECB4-4CA3-B045-1DFA50104289', value: 'EA6A8EC8-24BF-48A3-B0F0-A86A6447C0E2', operation: delete}
        # - Windows Web Experience Pack firewall block rules (see git history of
        #   playbook/Configuration/tweaks/qol/windows-update/disable-auto-updates.yml for the full data)
    )
}
