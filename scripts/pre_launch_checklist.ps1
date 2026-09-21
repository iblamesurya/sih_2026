# ==============================================================================
# PrawnGuard.ai - Pre-Launch Validation Checklist
# ==============================================================================
# Validates production-readiness requirements before app launch / demo video.
# Usage: .\scripts\pre_launch_checklist.ps1

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"
$passed = 0
$failed = 0
$warnings = 0

function Test-Check {
    param([string]$Name, [scriptblock]$Test, [bool]$IsWarning = $false)
    Write-Host "  Checking: $Name... " -NoNewline
    try {
        $result = & $Test
        if ($result) {
            Write-Host "PASS" -ForegroundColor Green
            $script:passed++
        } else {
            if ($IsWarning) {
                Write-Host "WARN" -ForegroundColor Yellow
                $script:warnings++
            } else {
                Write-Host "FAIL" -ForegroundColor Red
                $script:failed++
            }
        }
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        $script:failed++
    }
}

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  PrawnGuard.ai - Pre-Launch Validation Checklist" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# --- Section 1: Environment and Secrets ---
Write-Host "[1/7] Environment and Secrets" -ForegroundColor Yellow
Test-Check ".env or .env.example file exists" { 
    (Test-Path ".env") -or (Test-Path ".env.example")
}
Test-Check ".env template has required keys" {
    $targetFile = if (Test-Path ".env") { ".env" } else { ".env.example" }
    $content = Get-Content $targetFile -Raw
    ($content -match "SUPABASE_URL") -and ($content -match "SUPABASE_ANON_KEY")
}
Write-Host ""

# --- Section 2: Android Signing ---
Write-Host "[2/7] Android Release Signing" -ForegroundColor Yellow
Test-Check "key.properties file exists" { Test-Path "android/key.properties" }
Test-Check "build.gradle.kts includes release signing configuration" {
    $gradle = Get-Content "android/app/build.gradle.kts" -Raw
    ($gradle -match "signingConfigs") -and ($gradle -match "key\.properties")
}
Test-Check "Release keystore generator script exists" {
    Test-Path "scripts/generate_keystore.ps1"
}
Write-Host ""

# --- Section 3: Code Quality ---
Write-Host "[3/7] Code Quality" -ForegroundColor Yellow
Test-Check "flutter analyze passes" {
    $null = flutter analyze --no-fatal-infos 2>&1
    $LASTEXITCODE -eq 0
}
Write-Host ""

# --- Section 4: Test Suite ---
Write-Host "[4/7] Automated Test Suites" -ForegroundColor Yellow
Test-Check "100% of unit and integration test tiers pass" {
    $null = flutter test 2>&1
    $LASTEXITCODE -eq 0
}
Write-Host ""

# --- Section 5: Security Configuration ---
Write-Host "[5/7] Security Configuration" -ForegroundColor Yellow
Test-Check "network_security_config.xml exists" {
    Test-Path "android/app/src/main/res/xml/network_security_config.xml"
}
Test-Check "AndroidManifest has networkSecurityConfig configured" {
    $manifest = Get-Content "android/app/src/main/AndroidManifest.xml" -Raw
    $manifest -match "networkSecurityConfig"
}
Test-Check "AndroidManifest disables unencrypted ADB backup" {
    $manifest = Get-Content "android/app/src/main/AndroidManifest.xml" -Raw
    $manifest -match 'allowBackup="false"'
}
Test-Check "No hardcoded production API secrets in lib/" {
    $found = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | Select-String -Pattern "AIza[0-9A-Za-z-_]{35}"
    $null -eq $found -or $found.Count -eq 0
}
Write-Host ""

# --- Section 6: Build and Performance ---
Write-Host "[6/7] Build and Performance" -ForegroundColor Yellow
Test-Check "pubspec.yaml valid version defined" {
    $pubspec = Get-Content "pubspec.yaml" -Raw
    $pubspec -match "version:\s+\d+\.\d+\.\d+"
}
Test-Check "ProGuard and R8 optimization rules exist" {
    Test-Path "android/app/proguard-rules.pro"
}
Test-Check ".gitignore protects secrets and keystores" {
    $gi = Get-Content ".gitignore" -Raw
    ($gi -match "\.env") -and ($gi -match "key\.properties") -and ($gi -match "\.keystore")
}
Write-Host ""

# --- Section 7: DevOps and Infrastructure ---
Write-Host "[7/7] DevOps and Infrastructure" -ForegroundColor Yellow
Test-Check "CI workflow exists and configured" { Test-Path ".github/workflows/ci.yml" }
Test-Check "Release publisher workflow exists" { Test-Path ".github/workflows/release.yml" }
Test-Check "Admin dashboard Dockerfile exists" { Test-Path "admin-dashboard/Dockerfile" }
Test-Check "docker-compose.yml exists" { Test-Path "docker-compose.yml" }
Test-Check "Release build automation script exists" { Test-Path "scripts/build_release.ps1" }
Write-Host ""

# --- Summary ---
$summaryColor = if ($failed -gt 0) { "Red" } elseif ($warnings -gt 0) { "Yellow" } else { "Green" }
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  RESULTS: $passed PASSED - $failed FAILED - $warnings WARNINGS" -ForegroundColor $summaryColor
Write-Host "=================================================================" -ForegroundColor Cyan

if ($failed -gt 0) {
    Write-Host ""
    Write-Host "  [X] NOT READY FOR LAUNCH - Fix $failed failed check(s) above." -ForegroundColor Red
    exit 1
} elseif ($warnings -gt 0) {
    Write-Host ""
    Write-Host "  [!] LAUNCH POSSIBLE - $warnings warning(s) should be reviewed." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host ""
    Write-Host "  [V] ALL CHECKS PASSED - Ready for video demo and production launch!" -ForegroundColor Green
    exit 0
}
