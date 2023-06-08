@echo off
net stop DisplayEnhancementService
schtasks /delete /tn "Start Display Enhancement Service" /f