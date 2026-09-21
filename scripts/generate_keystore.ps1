#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generates a release keystore for PrawnGuard.ai Android app signing.
.DESCRIPTION
    Uses Java keytool to create a release keystore at android/app/prawnguard-release.keystore.
    Prompts for alias (default: prawnguard), store password, and key password.
    Outputs instructions for creating android/key.properties.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Resolve project root (one level up from scripts/)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$KeystoreDir = Join-Path $ProjectRoot "android" "app"
$KeystorePath = Join-Path $KeystoreDir "prawnguard-release.keystore"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PrawnGuard.ai - Release Keystore Generator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if keytool is available
try {
    $null = Get-Command keytool -ErrorAction Stop
} catch {
    Write-Host "[ERROR] 'keytool' not found. Please ensure Java JDK is installed and on your PATH." -ForegroundColor Red
    exit 1
}

# Check if keystore already exists
if (Test-Path $KeystorePath) {
    Write-Host "[WARNING] Keystore already exists at:" -ForegroundColor Yellow
    Write-Host "  $KeystorePath" -ForegroundColor Yellow
    $overwrite = Read-Host "Overwrite? (y/N)"
    if ($overwrite -ne "y" -and $overwrite -ne "Y") {
        Write-Host "Aborted. Existing keystore preserved." -ForegroundColor Green
        exit 0
    }
    Remove-Item $KeystorePath -Force
}

# Prompt for keystore parameters
$alias = Read-Host "Enter key alias (default: prawnguard)"
if ([string]::IsNullOrWhiteSpace($alias)) {
    $alias = "prawnguard"
}

$storePassword = Read-Host "Enter keystore password (min 6 characters)" -AsSecureString
$storePasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePassword)
)

if ($storePasswordPlain.Length -lt 6) {
    Write-Host "[ERROR] Keystore password must be at least 6 characters." -ForegroundColor Red
    exit 1
}

$keyPassword = Read-Host "Enter key password (min 6 characters, press Enter to use same as store password)" -AsSecureString
$keyPasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPassword)
)

if ([string]::IsNullOrWhiteSpace($keyPasswordPlain)) {
    $keyPasswordPlain = $storePasswordPlain
}

if ($keyPasswordPlain.Length -lt 6) {
    Write-Host "[ERROR] Key password must be at least 6 characters." -ForegroundColor Red
    exit 1
}

# Prompt for distinguished name fields
$cn = Read-Host "Enter your name / organization (default: PrawnGuard)"
if ([string]::IsNullOrWhiteSpace($cn)) {
    $cn = "PrawnGuard"
}

$dname = "CN=$cn, OU=Mobile, O=PrawnGuard.ai, L=India, ST=India, C=IN"

Write-Host ""
Write-Host "Generating keystore..." -ForegroundColor Yellow

# Ensure output directory exists
if (-not (Test-Path $KeystoreDir)) {
    New-Item -ItemType Directory -Path $KeystoreDir -Force | Out-Null
}

# Generate the keystore
$keytoolArgs = @(
    "-genkeypair",
    "-v",
    "-keystore", $KeystorePath,
    "-alias", $alias,
    "-keyalg", "RSA",
    "-keysize", "2048",
    "-validity", "10000",
    "-storepass", $storePasswordPlain,
    "-keypass", $keyPasswordPlain,
    "-dname", $dname
)

try {
    & keytool @keytoolArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] keytool exited with code $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[ERROR] Failed to generate keystore: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[SUCCESS] Keystore generated at:" -ForegroundColor Green
Write-Host "  $KeystorePath" -ForegroundColor Green
Write-Host ""

# Output instructions for key.properties
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  NEXT STEPS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Create or update 'android/key.properties' with:" -ForegroundColor White
Write-Host ""
Write-Host "  storePassword=$storePasswordPlain" -ForegroundColor Gray
Write-Host "  keyPassword=$keyPasswordPlain" -ForegroundColor Gray
Write-Host "  keyAlias=$alias" -ForegroundColor Gray
Write-Host "  storeFile=prawnguard-release.keystore" -ForegroundColor Gray
Write-Host ""
Write-Host "[IMPORTANT] Do NOT commit key.properties or the .keystore file to git!" -ForegroundColor Yellow
Write-Host "Both are already listed in .gitignore." -ForegroundColor Yellow
Write-Host ""

# Clear sensitive variables from memory
$storePasswordPlain = $null
$keyPasswordPlain = $null
[System.GC]::Collect()

Write-Host "Done!" -ForegroundColor Green
