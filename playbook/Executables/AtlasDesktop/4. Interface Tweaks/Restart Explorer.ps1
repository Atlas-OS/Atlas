#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Restart Explorer
# Restarts Windows Explorer to apply pending UI changes.
# Windows automatically relaunches explorer.exe as the shell after termination.
# ============================================================================

Write-Host '[>>] Restarting Explorer...' -ForegroundColor Yellow
Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue
Write-Host '[OK] Explorer restarted.' -ForegroundColor Green