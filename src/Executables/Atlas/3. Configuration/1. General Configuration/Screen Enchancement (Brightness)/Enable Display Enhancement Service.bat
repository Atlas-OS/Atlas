@echo off
sc config DisplayEnhancementService start=auto
net start DisplayEnhancementService
schtasks /create /tn "Start Display Enhancement Service" /sc onstart /delay 0000:30 /tr "net start DisplayEnhancementService" /f