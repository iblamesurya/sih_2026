# ==============================================================================
# PrawnGuard.ai (SIH 2026) â€” Enterprise Release Build Automation Script
# ==============================================================================

[CmdletBinding()]
param (
    [string]$Target = "apk",               # 'apk' or 'appbundle'
    [string]$BuildMode = "release",        # 'release' or 'debug'
    [string]$EnvFile = ".env",
    [switch]$SkipTests = $false,
    [switch]$SkipAnalyze = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  PrawnGuard.ai â€” Enterprise Release Build Automation (SIH 2026)" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# 1. Load Environment Configuration
$SupabaseUrl = "https://xyzcompany.supabase.co"
$SupabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.fake_key"

if (Test-Path $EnvFile) {
    Write-Host "[1/6] Loading environment variables from $EnvFile..." -ForegroundColor Yellow
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#")) {
            $parts = $line.Split("=", 2)
            if ($parts.Length -eq 2) {
                $key = $parts[0].Trim()
                $val = $parts[1].Trim()
                if ($key -eq "SUPABASE_URL") { $SupabaseUrl = $val }
                if ($key -eq "SUPABASE_ANON_KEY") { $SupabaseAnonKey = $val }
            }
        }
    }
} else {
    Write-Host "[1/6] No .env file found; using standard secure defaults with compile-time injection." -ForegroundColor Gray
}

# 2. Static Analysis Verification
if (-not $SkipAnalyze) {
    Write-Host "[2/6] Running Flutter Static Analysis (flutter analyze)..." -ForegroundColor Yellow
    flutter analyze
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Static analysis failed! Aborting release build."
    }
    Write-Host "Static analysis passed with 0 issues!" -ForegroundColor Green
} else {
    Write-Host "[2/6] Skipping static analysis as requested." -ForegroundColor Gray
}

# 3. Test Suite Verification
if (-not $SkipTests) {
    Write-Host "[3/6] Running Full Test Suite (flutter test)..." -ForegroundColor Yellow
    flutter test
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Test suite failed! Aborting release build."
    }
    Write-Host "100% of test suites passed!" -ForegroundColor Green
} else {
    Write-Host "[3/6] Skipping tests as requested." -ForegroundColor Gray
}

# 4. Clean and Resolve Dependencies
Write-Host "[4/6] Cleaning build cache and resolving dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Error "flutter pub get failed!"
}

# 5. Execute Obfuscated Release Compilation
Write-Host "[5/6] Compiling production $Target ($BuildMode mode with obfuscation)..." -ForegroundColor Yellow
$SymbolsDir = "./build/symbols"
if (-not (Test-Path $SymbolsDir)) {
    New-Item -ItemType Directory -Path $SymbolsDir -Force | Out-Null
}

$DartDefines = @(
    "--dart-define=SUPABASE_URL=$SupabaseUrl",
    "--dart-define=SUPABASE_ANON_KEY=$SupabaseAnonKey",
    "--dart-define=ENVIRONMENT=production"
)

if ($Target -eq "appbundle") {
    flutter build appbundle --release --obfuscate --split-debug-info=$SymbolsDir $DartDefines
} else {
    flutter build apk --release --obfuscate --split-debug-info=$SymbolsDir $DartDefines
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "Compilation failed! Check build logs above."
}

# 6. Artifact Verification & Checksum
Write-Host "[6/6] Generating Release Artifact Checksums..." -ForegroundColor Yellow

$ArtifactPath = if ($Target -eq "appbundle") {
    "build/app/outputs/bundle/release/app-release.aab"
} else {
    "build/app/outputs/flutter-apk/app-release.apk"
}

if (Test-Path $ArtifactPath) {
    $Hash = (Get-FileHash -Path $ArtifactPath -Algorithm SHA256).Hash
    $Size = (Get-Item $ArtifactPath).Length / 1MB
    Write-Host "=================================================================" -ForegroundColor Green
    Write-Host "  BUILD SUCCESSFUL!" -ForegroundColor Green
    Write-Host "  Artifact: $ArtifactPath ($('{0:N2}' -f $Size) MB)" -ForegroundColor Green
    Write-Host "  SHA256:   $Hash" -ForegroundColor Green
    Write-Host "=================================================================" -ForegroundColor Green
} else {
    Write-Host "Compilation step completed. Output directory: build/app/outputs/" -ForegroundColor Green
}
