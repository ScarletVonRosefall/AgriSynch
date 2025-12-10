# AgriSynch Cloud Functions - Quick Deploy Script
# Run this script to deploy your Cloud Functions

Write-Host "🚀 AgriSynch Cloud Functions Deployment" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green
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

# Check if Firebase CLI is installed
Write-Host "Checking Firebase CLI installation..." -ForegroundColor Yellow
$firebaseVersion = firebase --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Firebase CLI is not installed!" -ForegroundColor Red
    Write-Host "Installing Firebase CLI..." -ForegroundColor Yellow
    npm install -g firebase-tools
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install Firebase CLI" -ForegroundColor Red
        exit 1
    }
}
Write-Host "✅ Firebase CLI installed" -ForegroundColor Green
Write-Host ""

# Login to Firebase
Write-Host "Checking Firebase login status..." -ForegroundColor Yellow
$loginStatus = firebase login:list 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Not logged in to Firebase" -ForegroundColor Yellow
    Write-Host "Opening login page..." -ForegroundColor Yellow
    firebase login
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Firebase login failed" -ForegroundColor Red
        exit 1
    }
}
Write-Host "✅ Logged in to Firebase" -ForegroundColor Green
Write-Host ""

# Set project
Write-Host "Setting Firebase project to agrisynch-a9350..." -ForegroundColor Yellow
firebase use agrisynch-a9350
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to set project" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Project set" -ForegroundColor Green
Write-Host ""

# Navigate to functions directory
Write-Host "Navigating to functions directory..." -ForegroundColor Yellow
Set-Location -Path "functions"
Write-Host "✅ In functions directory" -ForegroundColor Green
Write-Host ""

# Install dependencies
Write-Host "Installing Node.js dependencies..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Write-Host "✅ Dependencies installed" -ForegroundColor Green
Write-Host ""

# Deploy functions
Write-Host "🚀 Deploying Cloud Functions to Firebase..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Yellow
Write-Host ""
firebase deploy --only functions
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    Set-Location ..
    exit 1
}

# Success
Write-Host ""
Write-Host "=======================================" -ForegroundColor Green
Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your Cloud Functions are now live!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Test notifications by placing an order in the app" -ForegroundColor White
Write-Host "2. View logs: firebase functions:log" -ForegroundColor White
Write-Host "3. Monitor usage in Firebase Console" -ForegroundColor White
Write-Host ""
Write-Host "View deployed functions:" -ForegroundColor Yellow
firebase functions:list
Write-Host ""

# Return to root directory
Set-Location ..
