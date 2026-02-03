###############################################################################
# Git Pre-Commit Hook - Browser Automation Security (PowerShell)
#
# MANDATORY security scan before git commit
# Prevents secret leakage in screenshots, console logs, network logs
#
# Installation:
#   powershell -ExecutionPolicy Bypass -File .memory-system/scripts/install-git-hooks.ps1
###############################################################################

#Requires -Version 5.1

$ErrorActionPreference = "Stop"

Write-Host "[PRE-COMMIT] Running browser automation security scan..." -ForegroundColor Yellow

# Get the root of the git repository
$GIT_ROOT = git rev-parse --show-toplevel
if ($LASTEXITCODE -ne 0) {
    Write-Host "[PRE-COMMIT] ❌ Not a git repository" -ForegroundColor Red
    exit 1
}

# Path to security filter script
$SECURITY_SCRIPT = Join-Path $GIT_ROOT ".memory-system\scripts\security-filters.ps1"

# Check if security script exists
if (-not (Test-Path $SECURITY_SCRIPT)) {
    Write-Host "[PRE-COMMIT] ❌ Security script not found: $SECURITY_SCRIPT" -ForegroundColor Red
    Write-Host "[PRE-COMMIT] Run: powershell -ExecutionPolicy Bypass -File .memory-system\install.ps1" -ForegroundColor Red
    exit 1
}

# Check if docs/features directory exists
$FEATURES_DIR = Join-Path $GIT_ROOT "docs\features"
if (-not (Test-Path $FEATURES_DIR)) {
    Write-Host "[PRE-COMMIT] ℹ️  No features directory, skipping security scan" -ForegroundColor Green
    exit 0
}

# Run security scan on staged files only
Write-Host "[PRE-COMMIT] Scanning staged files for secrets..." -ForegroundColor Yellow

# Get list of staged files that match patterns
$STAGED_FILES = git diff --cached --name-only --diff-filter=ACMR | Where-Object {
    $_ -match 'docs/features/.*/test-results/.*\.(txt|json|md|png|jpg)$'
}

if (-not $STAGED_FILES) {
    Write-Host "[PRE-COMMIT] ✅ No test result files staged, skipping scan" -ForegroundColor Green
    exit 0
}

# Scan each staged file
$FAILED = 0
foreach ($file in $STAGED_FILES) {
    $fullPath = Join-Path $GIT_ROOT $file
    if (Test-Path $fullPath) {
        Write-Host "[PRE-COMMIT] Scanning: $file" -ForegroundColor Yellow

        # Run security scan
        $result = & powershell -ExecutionPolicy Bypass -File $SECURITY_SCRIPT scan $fullPath
        if ($LASTEXITCODE -ne 0) {
            $FAILED++
            Write-Host "[PRE-COMMIT] ❌ Secrets detected in: $file" -ForegroundColor Red
        }
    }
}

# Check results
if ($FAILED -gt 0) {
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                    🚨 COMMIT BLOCKED 🚨                        ║" -ForegroundColor Red
    Write-Host "╠════════════════════════════════════════════════════════════════╣" -ForegroundColor Red
    Write-Host "║ Found secrets in $FAILED files                                      ║" -ForegroundColor Red
    Write-Host "║                                                                ║" -ForegroundColor Red
    Write-Host "║ Action Required:                                               ║" -ForegroundColor Red
    Write-Host "║ 1. Run security filters to redact secrets:                    ║" -ForegroundColor Red
    Write-Host "║    powershell -ExecutionPolicy Bypass -File `                  ║" -ForegroundColor Yellow
    Write-Host "║      .memory-system\scripts\security-filters.ps1 filter-all `  ║" -ForegroundColor Yellow
    Write-Host "║      docs\features\FEAT-XXX\test-results                       ║" -ForegroundColor Yellow
    Write-Host "║                                                                ║" -ForegroundColor Red
    Write-Host "║ 2. Review filtered files manually                             ║" -ForegroundColor Red
    Write-Host "║ 3. Re-stage files: git add <files>                            ║" -ForegroundColor Red
    Write-Host "║ 4. Retry commit                                               ║" -ForegroundColor Red
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    exit 1
}

Write-Host "[PRE-COMMIT] ✅ Security scan passed - no secrets detected" -ForegroundColor Green
exit 0
