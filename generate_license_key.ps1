# =============================================================================
# DaftarDZ Seller License Key Generator (For Abderrahmane Mihoubi)
# Usage: Run this script and enter the customer's Device Code (e.g., DZ-7842)
#        to get the lifetime Pro Activation Key to send after CCP/BaridiMob payment!
# =============================================================================
param([string]$DeviceCode = "")
if (-not $DeviceCode) {
    $DeviceCode = Read-Host "Enter Customer Device Code (e.g. DZ-7842)"
}
$digits = [int]($DeviceCode -replace '[^0-9]', '')
$key = "PRO-" + (($digits * 7) + 509)
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Device Code    : $DeviceCode" -ForegroundColor Yellow
Write-Host "  Activation Key : $key" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
