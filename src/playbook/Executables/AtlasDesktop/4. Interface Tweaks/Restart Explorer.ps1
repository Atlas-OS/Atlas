#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Restart Explorer
# Restarts Windows Explorer to apply pending UI changes.
# Windows automatically relaunches explorer.exe as the shell after termination.
# ============================================================================

$ErrorActionPreference = 'Stop'

try {
    Write-Host '[>>] Restarting Explorer...' -ForegroundColor Yellow
    Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue

    Write-Host '[OK] Explorer restarted.' -ForegroundColor Green
} catch {
    Write-Host "[!!] Failed to restart Explorer: $_" -ForegroundColor Red
    exit 1
}