###############################################################################
# Install Git Hooks for Browser Automation Security (PowerShell)
#
# Installs pre-commit hook that scans for secrets before allowing commits
###############################################################################

#Requires -Version 5.1

$ErrorActionPreference = "Stop"

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Git Hooks Installation - Browser Automation Security" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Get git root
try {
    $GIT_ROOT = git rev-parse --show-toplevel 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Not a git repository"
    }
} catch {
    Write-Host "❌ Not a git repository" -ForegroundColor Red
    Write-Host "Run this script from inside a git repository" -ForegroundColor Yellow
    exit 1
}

# Convert Unix path to Windows path
$GIT_ROOT = $GIT_ROOT -replace '/', '\'

Write-Host "✓ Git repository: $GIT_ROOT" -ForegroundColor Green

# Check if .git/hooks directory exists
$HOOKS_DIR = Join-Path $GIT_ROOT ".git\hooks"
if (-not (Test-Path $HOOKS_DIR)) {
    Write-Host "⚠  Creating hooks directory: $HOOKS_DIR" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $HOOKS_DIR -Force | Out-Null
}

# Path to hook templates
$HOOK_TEMPLATE_SH = Join-Path $GIT_ROOT ".memory-system\git-hooks\pre-commit"
$HOOK_TEMPLATE_PS1 = Join-Path $GIT_ROOT ".memory-system\git-hooks\pre-commit.ps1"
$HOOK_DEST = Join-Path $HOOKS_DIR "pre-commit"

# Check if templates exist
if (-not (Test-Path $HOOK_TEMPLATE_SH)) {
    Write-Host "❌ Hook template not found: $HOOK_TEMPLATE_SH" -ForegroundColor Red
    Write-Host "Expected location: .memory-system\git-hooks\pre-commit" -ForegroundColor Yellow
    exit 1
}

# Backup existing hook if present
if (Test-Path $HOOK_DEST) {
    $BACKUP_FILE = "$HOOK_DEST.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Host "⚠  Existing pre-commit hook found" -ForegroundColor Yellow
    Write-Host "⚠  Creating backup: $BACKUP_FILE" -ForegroundColor Yellow
    Move-Item $HOOK_DEST $BACKUP_FILE -Force
}

# Determine which hook to install based on OS
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    # Windows: Create wrapper that calls PowerShell script
    Write-Host "✓ Installing pre-commit hook (PowerShell wrapper)..." -ForegroundColor Green

    # Copy PowerShell script
    Copy-Item $HOOK_TEMPLATE_PS1 "$HOOKS_DIR\pre-commit.ps1" -Force

    # Create bash wrapper that calls PowerShell
    $WRAPPER_CONTENT = @"
#!/bin/bash
# Pre-commit hook wrapper for Windows
# Calls PowerShell script for security scanning

SCRIPT_DIR="`$(git rev-parse --show-toplevel)/.git/hooks"
powershell -ExecutionPolicy Bypass -File "`$SCRIPT_DIR/pre-commit.ps1"
exit `$?
"@

    Set-Content -Path $HOOK_DEST -Value $WRAPPER_CONTENT -Encoding UTF8
} else {
    # Linux/Mac: Use bash script directly
    Write-Host "✓ Installing pre-commit hook (bash)..." -ForegroundColor Green
    Copy-Item $HOOK_TEMPLATE_SH $HOOK_DEST -Force
}

# Make executable (if on Unix-like system)
if (Get-Command chmod -ErrorAction SilentlyContinue) {
    chmod +x $HOOK_DEST 2>$null
    Write-Host "✓ Hook is executable" -ForegroundColor Green
}

# Verify installation
if (Test-Path $HOOK_DEST) {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                 ✅ Installation Complete                  ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "Pre-commit hook installed at:" -ForegroundColor Cyan
    Write-Host "  $HOOK_DEST"
    Write-Host ""
    Write-Host "What happens now:" -ForegroundColor Cyan
    Write-Host "  • Every git commit will scan for secrets in test results"
    Write-Host "  • Commits are blocked if API keys, tokens, or passwords detected"
    Write-Host "  • Run security filters to redact secrets before committing"
    Write-Host ""
    Write-Host "Test the hook:" -ForegroundColor Cyan
    Write-Host "  git commit -m `"test commit`" --allow-empty"
    Write-Host ""
    Write-Host "Bypass the hook (NOT RECOMMENDED):" -ForegroundColor Cyan
    Write-Host "  git commit --no-verify -m `"message`""
    Write-Host ""
} else {
    Write-Host "❌ Installation failed" -ForegroundColor Red
    exit 1
}
