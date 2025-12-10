# AgriSynch Cloud Functions - Test Locally Script
# Run this to test Cloud Functions locally before deploying

Write-Host "🧪 AgriSynch Cloud Functions - Local Testing" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Check if Node.js is installed
Write-Host "Checking Node.js installation..." -ForegroundColor Yellow
$nodeVersion = node --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Node.js is not installed!" -ForegroundColor Red
    Write-Host "Please download and install from: https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ Node.js installed: $nodeVersion" -ForegroundColor Green
Write-Host ""

# Navigate to functions directory
Write-Host "Navigating to functions directory..." -ForegroundColor Yellow
Set-Location -Path "functions"
Write-Host "✅ In functions directory" -ForegroundColor Green
Write-Host ""

# Install dependencies if needed
if (!(Test-Path "node_modules")) {
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
        Set-Location ..
        exit 1
    }
}
Write-Host "✅ Dependencies ready" -ForegroundColor Green
Write-Host ""

# Start emulator
Write-Host "🚀 Starting Firebase Emulator..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop the emulator" -ForegroundColor Yellow
Write-Host ""
Write-Host "Once running, you can:" -ForegroundColor Green
Write-Host "- Create test orders in Firestore" -ForegroundColor White
Write-Host "- Watch function logs in real-time" -ForegroundColor White
Write-Host "- Test notifications locally" -ForegroundColor White
Write-Host ""
Write-Host "Starting emulator..." -ForegroundColor Yellow
Write-Host ""

firebase emulators:start --only functions

# Return to root directory
Set-Location ..
