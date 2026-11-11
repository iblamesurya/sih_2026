# ==============================================================================
# PrawnGuard.ai — Web Admin Portal Anti-Reverse Engineering Protection Script
# Powered by BLA (Blind LLM Agents: Poison -> Exhaust -> Hallucinate v3.2.4)
# ==============================================================================

param (
    [string]$Intensity = "balanced",
    [switch]$SkipBuild,
    [switch]$AllChunks
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$AdminDashboardDir = Join-Path $RootDir "admin-dashboard"
$BlaCli = Join-Path $RootDir "tools\bla\dist\cli.js"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  PrawnGuard Admin Portal Counter-REA Hardening Shield" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Build Admin Dashboard if not skipped
if (-not $SkipBuild) {
    Write-Host "`n[1/4] Building production React 19 + Vite 6 bundle..." -ForegroundColor Yellow
    Push-Location $AdminDashboardDir
    try {
        npm run build
    } finally {
        Pop-Location
    }
}

$DistDir = Join-Path $AdminDashboardDir "dist"
$AssetsDir = Join-Path $DistDir "assets"

if (-not (Test-Path $DistDir)) {
    Write-Error "Build output directory '$DistDir' does not exist. Run build first."
}

# 2. Inspect release artifacts for real SourceMap / symbol leaks
Write-Host "`n[2/4] Running BLA inspect-release to verify zero SourceMap leaks..." -ForegroundColor Yellow
node $BlaCli inspect-release $DistDir

# 3. Apply BLA Adversarial Shield to JavaScript assets
Write-Host "`n[3/4] Injecting BLA Counter-REA Adversarial Shield (Intensity: $Intensity)..." -ForegroundColor Yellow

$TargetFiles = if ($AllChunks) {
    Get-ChildItem -Path $AssetsDir -Filter "*.js"
} else {
    # Default: protect proprietary application code and UI icons
    Get-ChildItem -Path $AssetsDir -Filter "*.js" | Where-Object { 
        $_.Name -like "index-*.js" -or $_.Name -like "vendor-icons-*.js" 
    }
}

foreach ($file in $TargetFiles) {
    Write-Host "  -> Hardening $($file.Name)..." -ForegroundColor DarkCyan
    node $BlaCli protect $file.FullName --in-place --intensity $Intensity --allow-lane-independent
}

# 4. Verify Honey SourceMaps and token amplification
Write-Host "`n[4/4] Verifying Honey SourceMaps and Counter-REA invariant gates..." -ForegroundColor Yellow
$MainChunk = Get-ChildItem -Path $AssetsDir -Filter "vendor-icons-*.js" | Select-Object -First 1

if ($MainChunk) {
    Write-Host "  -> Verifying $($MainChunk.Name)..." -ForegroundColor DarkCyan
    & node $BlaCli verify $MainChunk.FullName
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "  Web Admin Portal Counter-REA Shielding Complete!  " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
