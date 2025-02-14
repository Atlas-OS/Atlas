Start-Process -FilePath "wevtutil.exe" -ArgumentList 'set-log "Microsoft-Windows-SleepStudy/Diagnostic" /e:false' -NoNewWindow -Wait
Start-Process -FilePath "wevtutil.exe" -ArgumentList 'set-log "Microsoft-Windows-Kernel-Processor-Power/Diagnostic" /e:false' -NoNewWindow -Wait
Start-Process -FilePath "wevtutil.exe" -ArgumentList 'set-log "Microsoft-Windows-UserModePowerService/Diagnostic" /e:false' -NoNewWindow -Wait
schtasks /Change /TN "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /Disable
