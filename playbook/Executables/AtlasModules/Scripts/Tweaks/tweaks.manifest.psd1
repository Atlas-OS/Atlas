@{
    # Category order and per-tweak run order for the Tweaks install phase.
    # - Categories run in the order custom.yml invokes them (one phase call each).
    # - Tweaks run top to bottom within a category; paths are relative to the
    #   category folder, without the .psd1 extension.
    # - Disable a tweak by commenting out its line (keep a short reason).
    Categories = @(
        @{
            Name   = 'networking'
            Tweaks = @(
                # 'disable-llmnr'  # disabled deliberately: LLMNR resolves single-label \\PCNAME on home LANs
                #                  # (mDNS only covers .local; router DNS rarely registers client names).
                #                  # Userbase is mostly trusted home networks, so the poisoning risk doesn't outweigh that.
                'atlas-network-settings'
                'shares/restrict-anonymous-access'
                'shares/restrict-anonymous-enumeration'
                'shares/disable-smb-bandwidth-throttling'
            )
        }
        @{
            Name   = 'performance'
            Tweaks = @(
                'config-mmcss'
                'disable-auto-folder-discovery'
                # 'disable-game-bar'  # disabled: users want Game Bar capture/overlays, and the Xbox app depends on it;
                #                     # the FSOGameBar toggle covers enthusiasts who want it gone
                'config-automatic-maintenance'
                'disable-background-apps'
                'disable-fth'
                'disable-sleep-study'
                'respect-power-modes-search'
                'system/optimize-ntfs'
                'system/disable-service-host-split'
                'system/win32-priority-separation'
            )
        }
        @{
            Name   = 'privacy'
            Tweaks = @(
                'config-app-permissions'
                'config-windows-media-player'
                'disable-activity-feed'
                'disable-app-launch-tracking'
                'disable-lockscreen-camera'
                # disable-experimentation removed: AllowExperimentation is a dead 1607-era MDM policy; the
                # PolicyManager\current variant is known to block Known Issue Rollback fixes, and disabling
                # DiagTrack already cuts the experimentation delivery channel.
                'disable-online-speech-recognition'
                'disable-pca'
                'disable-perf-track'
                'disable-privacy-experience'
                'disable-recall-snap'
                'disable-click-to-do'
                'disable-settings-agent'
                'disable-device-monitoring'
                'disable-find-my-device'
                'disable-rsop-logging'
                'disable-speech-auto-updates'
                'disable-tailored-experiences'
                'disable-user-tracking'
                'disable-web-lang-list-access'
                'disable-win-error-reporting'
                'disallow-ms-accounts'
                'disallow-user-activity-upload'
                'search-settings'
                'apps/disable-nvidia-telemetry'
                'apps/disable-office-telemetry'
                'apps/disable-paint-ai'
                'apps/disable-notepad-ai'
                'advertising/disable-advertising-info'
                'advertising/disable-sync-provider-notifs'
                'cloud/disable-setting-sync'
                'cloud/disable-suggest-ways-to-finish-setup'
                'cloud/disallow-message-cloud-sync'
                'cloud/disallow-clipboard-sync'
                'telemetry/disable-activation-telemetry'
                'telemetry/disable-ceip'
                'telemetry/disable-diagnostic-tracing'
                'telemetry/disable-dotnet-cli-telemetry'
                'telemetry/disable-input-telemetry'
                'telemetry/disable-phishing-protection'
                'telemetry/disallow-data-collection'
            )
        }
        @{
            Name   = 'qol'
            Tweaks = @(
                'bcdedit-tweaks'
                'best-wallpaper-quality'
                'disable-mouse-accel'
                'disable-settings-tips'
                'disable-spell-checking'
                'disable-store-auto-updates'
                # disable-store-search-recommendations moved into Initialize-NewUser: the deny-ACL
                # on store.db must be applied per user profile, not in the SYSTEM install context.
                'disable-touch-keyboard-features'
                'disable-touch-visual-feedback'
                'disable-usb-issues-notifications'
                'disable-windows-feedback'
                'disable-windows-spotlight'
                'do-not-reduce-sounds'
                'hide-disabled-disconnected-sounds'
                'show-all-tasks-control-panel'
                'visual-effects'
                'disable-tips'
                'disable-win11-settings-banner'
                'disable-screen-capture-hotkey'
                'disable-dynamic-lighting'
                'disable-auto-app-archival'
                'add-sharing-settings-shortcut'
                # atlas-theme sets lock-screen policy; the theme itself is applied by
                # Initialize-NewUser at first logon (interactive shell COM).
                'appearance/atlas-theme'
                'appearance/atlas-theme-upgrade'
                'appearance/disallow-theme-changes'
                'windows-update/disable-nagging'
                'windows-update/disable-insider'
                'windows-update/disable-msrt-telemetry'
                'windows-update/disable-feature-updates'
                'windows-update/disable-auto-updates-option'
                'windows-update/disable-auto-updates'
                'windows-update/disable-auto-reboot'
                'windows-update/disable-delivery-optimization'
                'ease-of-access/disable-always-read-section'
                'ease-of-access/disable-annoying-features-shortcuts'
                'ease-of-access/disable-making-touch-easier'
                'ease-of-access/disable-warning-sounds'
                'taskbar/disable-cloud-optimized-content'
                'taskbar/disable-news-and-interests'
                'taskbar/hide-task-view'
                'taskbar/disable-copilot'
                'taskbar/set-to-left'
                'taskbar/end-task'
                'explorer/always-more-details-transfer'
                'explorer/disable-invalid-shortcuts-search'
                'explorer/disable-check-boxes'
                # 'explorer/disable-folders-this-pc'  # disabled: no reason recorded
                'explorer/disable-network-navigation-pane'
                'explorer/full-context-on-more-than-15-items'
                'explorer/hide-frequently-used-items'
                'explorer/import-power-plan'
                'explorer/minimize-mouse-hover-time'
                'explorer/no-internet-open-with'
                'explorer/open-to-this-pc'
                'explorer/removable-drives-only-this-pc'
                'explorer/remove-previous-versions'
                'explorer/remove-shortcut-text'
                'explorer/show-files'
                'explorer/classic-search'
                'explorer/dont-show-office-files'
                'explorer/use-compact-mode'
                'explorer/disable-gallery'
                'explorer/disable-home'
                'explorer/debloat-send-to'
                'explorer/enable-long-paths'
                'explorer/add-context-menus/merge-as-trustedinstaller'
                'explorer/add-context-menus/new-bat'
                'explorer/add-context-menus/new-ps1'
                'explorer/add-context-menus/new-reg'
                'explorer/remove-context-menus/cast-to-device'
                'explorer/remove-context-menus/extract'
                'explorer/remove-context-menus/include-in-library'
                'explorer/remove-context-menus/new-bitmap'
                'explorer/remove-context-menus/new-rtf'
                'explorer/remove-context-menus/paint-3D'
                'explorer/remove-context-menus/share'
                'explorer/remove-context-menus/troubleshooting-compat'
                'explorer/remove-context-menus/printing'
                'security/disable-uac-secure-desktop'
                'shell/alt-tab-open-windows'
                'shell/disable-aero-shake'
                'shell/disable-low-disk-warning'
                'shell/disable-menu-delay'
                'shell/disable-network-location-wizard'
                'shell/set-unpinned-notification-items'
                'shell/restore-old-context-menu'
                'shell/show-more-pins'
                'shell/no-recommendations-start-menu'
                'shell/disable-nearby-sharing'
                'shell/config-autorun'
                'startup-shutdown/decrease-shutdown-time'
                'startup-shutdown/disable-startup-delay'
                # 'startup-shutdown/force-end-shutdown-apps'  # disabled: it confused people
                # 'startup-shutdown/enable-verbose-messages'  # disabled: no reason recorded
                'system/crash-control-qol'
                'system/disable-wpbt'
                # Applied last: these restart shell components (Start Menu / Explorer).
                'config-start-menu'
                'taskbar/config-pins'
            )
        }
        @{
            Name   = 'security'
            Tweaks = @(
                'block-anonymous-enum-sam'
                'disable-remote-assistance'
            )
        }
        @{
            Name   = 'debloat'
            Tweaks = @(
                'config-content-delivery'
                'disable-reserved-storage'
                'disable-scheduled-tasks'
                'block-razer-installs'
                'hide-unused-security-pages'
                'config-storage-sense'
            )
        }
        @{
            Name   = 'scripts'
            Tweaks = @(
                'set-file-associations'
                'disable-core-isolation'
                'disable-mitigations'
                'disable-pnp'
                'set-profile-pictures'
                'backup-services'
                'update-client-cbs'
                # set-power-settings runs LAST, invoked directly from tweaks.yml.
            )
        }
        @{
            Name   = 'misc'
            Tweaks = @(
                'config-time'
                'delete-windows-specific-files'
                'rebuild-perf-counters'
                'make-measuresleep-admin'
                'add-newUser-script'
                'config-oem-information'
                'create-shortcuts'
                # enable-notifications runs LAST of all tweaks, invoked directly from tweaks.yml,
                # so notifications re-enable only after everything else.
            )
        }
    )
}
