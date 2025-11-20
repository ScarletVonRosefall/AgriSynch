# AgriSynch v1.0.0 - Release Deployment Script (PowerShell)
# Run this script to publish v1.0.0 to GitHub

param(
    [switch]$SkipValidation = $false,
    [switch]$DryRun = $false
)

# ============================================
# SETUP
# ============================================
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues = @{}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      AgriSynch v1.0.0 - Release Deployment Script         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ============================================
# 1. VERIFY RELEASE IS READY
# ============================================
Write-Host "📋 Step 1: Verifying release files..." -ForegroundColor Yellow
Write-Host ""

$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkPath) {
    $apkSize = [math]::Round((Get-Item $apkPath).Length / 1MB, 2)
    Write-Host "✅ APK Found: $apkPath" -ForegroundColor Green
    Write-Host "   Size: $apkSize MB" -ForegroundColor Green
} else {
    Write-Host "❌ ERROR: APK not found at $apkPath" -ForegroundColor Red
    exit 1
}

# Verify documentation files
$docFiles = @(
    "RELEASE_NOTES.md",
    "QUICKSTART.md",
    "GITHUB_RELEASE_GUIDE.md",
    "RELEASE_SUMMARY.md"
)

Write-Host ""
Write-Host "📚 Documentation Files:" -ForegroundColor Yellow
foreach ($file in $docFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file" -ForegroundColor Green
    } else {
        Write-Host "⚠️  $file (not found)" -ForegroundColor Yellow
    }
}

# ============================================
# 2. VERIFY GIT REPOSITORY
# ============================================
Write-Host ""
Write-Host "🔗 Step 2: Verifying Git repository..." -ForegroundColor Yellow
Write-Host ""

try {
    $gitStatus = git status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Not a valid Git repository" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Valid Git repository found" -ForegroundColor Green
    
    # Get branch info
    $currentBranch = git rev-parse --abbrev-ref HEAD
    Write-Host "   Current Branch: $currentBranch" -ForegroundColor Cyan
    
    # Check for uncommitted changes
    $changes = git status --porcelain
    if ($changes) {
        Write-Host ""
        Write-Host "⚠️  Uncommitted changes detected:" -ForegroundColor Yellow
        $changes | ForEach-Object { Write-Host "   $_" }
    }
} catch {
    Write-Host "❌ Git error: $_" -ForegroundColor Red
    exit 1
}

# ============================================
# 3. DISPLAY RELEASE INFO
# ============================================
Write-Host ""
Write-Host "📦 Step 3: Release Information" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Version: 1.0.0" -ForegroundColor Cyan
Write-Host "  Build: 1" -ForegroundColor Cyan
Write-Host "  APK Size: 69.34 MB" -ForegroundColor Cyan
Write-Host "  Release Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "  Status: Production Ready ✅" -ForegroundColor Green
Write-Host ""

# ============================================
# 4. CONFIRM DEPLOYMENT
# ============================================
if (-not $DryRun) {
    Write-Host "⚠️  This will push v1.0.0 to GitHub!" -ForegroundColor Yellow
    Write-Host ""
    $confirm = Read-Host "Continue with release deployment? (yes/no)"
    
    if ($confirm -ne "yes") {
        Write-Host ""
        Write-Host "❌ Deployment cancelled" -ForegroundColor Red
        exit 0
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

# ============================================
# 5. STAGE AND COMMIT
# ============================================
Write-Host ""
Write-Host "📝 Step 5: Staging and committing changes..." -ForegroundColor Yellow
Write-Host ""

if ($DryRun) {
    Write-Host "[DRY RUN] Would add all files with: git add -A" -ForegroundColor Magenta
    Write-Host "[DRY RUN] Would commit with release message" -ForegroundColor Magenta
} else {
    try {
        Write-Host "Adding files..." -ForegroundColor Cyan
        git add -A
        
        Write-Host "Committing changes..." -ForegroundColor Cyan
        $commitMessage = @"
v1.0.0: Initial release - Agricultural marketplace platform

Features:
- Complete buyer marketplace with cart and checkout
- Farmer dashboard with product and order management
- Real-time Firestore integration
- Multi-currency support (14+ currencies)
- Messaging and notification system
- Rating and review system
- Task management for farmers
- Financial tracking dashboard

Bug Fixes:
- Fixed UI overflow on order cards
- Fixed product price display overflow
- Fixed order total amount overflow
- Implemented dynamic currency symbol loading
- Added real-time stock updates
- Improved responsive design

APK: 69.34 MB
Platform: Android 13+ (API 33+)
Build: 1.0.0+1
"@
        
        git commit -m $commitMessage
        Write-Host "✅ Changes committed" -ForegroundColor Green
    } catch {
        Write-Host "❌ Commit failed: $_" -ForegroundColor Red
        exit 1
    }
}

# ============================================
# 6. CREATE AND PUSH TAG
# ============================================
Write-Host ""
Write-Host "🏷️  Step 6: Creating and pushing Git tag..." -ForegroundColor Yellow
Write-Host ""

if ($DryRun) {
    Write-Host "[DRY RUN] Would create tag v1.0.0" -ForegroundColor Magenta
    Write-Host "[DRY RUN] Would push tag to origin" -ForegroundColor Magenta
} else {
    try {
        $tagMessage = @"
AgriSynch v1.0.0 - Agricultural Marketplace Platform

🎉 Initial Production Release

✨ Key Features:
  • Buyer marketplace with real-time product browsing
  • Farmer dashboard with comprehensive management tools
  • Firestore-powered real-time database
  • Firebase authentication
  • Multi-currency exchange rates
  • Integrated messaging system
  • Rating & review system
  • Task management with calendar
  • Financial tracking for farmers
  • Push notifications

🐛 Critical Fixes in v1.0.0:
  • Order card UI overflow resolution
  • Product price overflow prevention
  • Order total display fixes
  • Dynamic currency symbol support
  • Real-time stock synchronization
  • Responsive design enhancements

📱 Download: app-release.apk (69.34 MB)
🔗 Minimum: Android 13 (API 33)
⚡ Status: Production Ready

See RELEASE_NOTES.md for complete details
"@
        
        Write-Host "Creating tag v1.0.0..." -ForegroundColor Cyan
        git tag -a v1.0.0 -m $tagMessage
        Write-Host "✅ Tag created" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "Pushing main branch..." -ForegroundColor Cyan
        git push origin main
        Write-Host "✅ Branch pushed" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "Pushing tag to GitHub..." -ForegroundColor Cyan
        git push origin v1.0.0
        Write-Host "✅ Tag pushed" -ForegroundColor Green
    } catch {
        Write-Host "❌ Git push failed: $_" -ForegroundColor Red
        exit 1
    }
}

# ============================================
# 7. COMPLETION
# ============================================
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "✅ DRY RUN COMPLETED" -ForegroundColor Green
    Write-Host ""
    Write-Host "Preview of what would happen:" -ForegroundColor Yellow
    Write-Host "  1. All changes would be committed"
    Write-Host "  2. Tag v1.0.0 would be created"
    Write-Host "  3. Both branch and tag would be pushed to GitHub"
    Write-Host ""
    Write-Host "Run without -DryRun to actually deploy" -ForegroundColor Cyan
} else {
    Write-Host "🎉 RELEASE DEPLOYMENT COMPLETE!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📍 Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Go to: https://github.com/ScarletVonRosefall/AgriSynch/releases" -ForegroundColor Cyan
    Write-Host "  2. Click 'Create a new release'" -ForegroundColor Cyan
    Write-Host "  3. Select tag v1.0.0" -ForegroundColor Cyan
    Write-Host "  4. Upload: app-release.apk (69.34 MB)" -ForegroundColor Cyan
    Write-Host "  5. Copy content from RELEASE_NOTES.md" -ForegroundColor Cyan
    Write-Host "  6. Click 'Publish release'" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor Yellow
Write-Host "  • RELEASE_NOTES.md - Complete release information"
Write-Host "  • QUICKSTART.md - Installation & getting started"
Write-Host "  • GITHUB_RELEASE_GUIDE.md - Detailed GitHub process"
Write-Host "  • RELEASE_SUMMARY.md - Release package summary"
Write-Host ""
Write-Host "🌾 AgriSynch v1.0.0 Ready for Production!" -ForegroundColor Green
Write-Host ""
