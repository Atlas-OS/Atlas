---
title: Disable Modern Standby SleepStudy
description: Disables Modern Standby's SleepStudy feature, as it's unnecessary logging that isn't needed on boot
actions:
  - !run:
    exe: 'wevtutil.exe'
    args: 'set-log "Microsoft-Windows-SleepStudy/Diagnostic" /e:false'
  - !run:
    exe: 'wevtutil.exe'
    args: 'set-log "Microsoft-Windows-Kernel-Processor-Power/Diagnostic" /e:false'
  - !run:
    exe: 'wevtutil.exe'
    args: 'set-log "Microsoft-Windows-UserModePowerService/Diagnostic" /e:false'
  - !scheduledTask: {path: '\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem', operation: disable}
