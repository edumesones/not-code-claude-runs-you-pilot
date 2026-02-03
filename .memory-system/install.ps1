# Memory-MCP Installation Script for Ralph Loop (PowerShell)
#
# This script sets up the complete memory system integration for Windows

#Requires -Version 5.1

# Stop on errors
$ErrorActionPreference = "Stop"

Write-Host "🚀 Memory-MCP Integration Installer" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Get project root (parent of .memory-system)
$MEMORY_SYSTEM_DIR = $PSScriptRoot
$PROJECT_ROOT = Split-Path $MEMORY_SYSTEM_DIR -Parent
$MEMORY_DIR = Join-Path $PROJECT_ROOT ".memory"

Write-Host "📂 Project root: $PROJECT_ROOT"
Write-Host ""

###############################################################################
# Step 1: Check prerequisites
###############################################################################

Write-Host "🔍 Step 1: Checking prerequisites..." -ForegroundColor Yellow

# Check Node.js
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Node.js not found. Please install Node.js 18+ first." -ForegroundColor Red
    Write-Host "   Download from: https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

$nodeVersion = (node --version).TrimStart('v').Split('.')[0]
if ([int]$nodeVersion -lt 18) {
    Write-Host "❌ Node.js version must be 18 or higher (found: $(node --version))" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Node.js $(node --version) found" -ForegroundColor Green

# Check Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Git not found. Please install Git first." -ForegroundColor Red
    Write-Host "   Download from: https://git-scm.com/" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Git $(git --version) found" -ForegroundColor Green

###############################################################################
# Step 2: Create directory structure
###############################################################################

Write-Host ""
Write-Host "📁 Step 2: Creating directory structure..." -ForegroundColor Yellow

$directories = @(
    (Join-Path $MEMORY_DIR "snapshots"),
    (Join-Path $MEMORY_SYSTEM_DIR "scripts"),
    (Join-Path $MEMORY_SYSTEM_DIR "logs")
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

Write-Host "✅ Directories created" -ForegroundColor Green

###############################################################################
# Step 3: Initialize state.json (if not exists)
###############################################################################

Write-Host ""
Write-Host "💾 Step 3: Initializing memory state..." -ForegroundColor Yellow

$STATE_FILE = Join-Path $MEMORY_DIR "state.json"

if (Test-Path $STATE_FILE) {
    Write-Host "⚠️  state.json already exists, skipping..." -ForegroundColor Yellow
} else {
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    $stateContent = @{
        version = "1.0"
        memories = @()
        metadata = @{
            total_memories = 0
            last_consolidation = $null
            confidence_avg = 0
            features_processed = @()
            schema_version = "1.0.0"
            created_at = $timestamp
        }
        config = @{
            confidence_decay_enabled = $false
            confidence_decay_rate = 0.01
            max_memories = 2000
            deduplication_threshold = 0.8
            secret_detection_enabled = $true
        }
    }

    $stateContent | ConvertTo-Json -Depth 10 | Set-Content -Path $STATE_FILE -Encoding UTF8
    Write-Host "✅ state.json initialized" -ForegroundColor Green
}

###############################################################################
# Step 4: Scripts are already executable on Windows (no chmod needed)
###############################################################################

Write-Host ""
Write-Host "🔧 Step 4: Verifying scripts..." -ForegroundColor Yellow

$extractScript = Join-Path $MEMORY_SYSTEM_DIR "scripts\extract-memory.js"
$consolidateScript = Join-Path $MEMORY_SYSTEM_DIR "scripts\consolidate-claude-md.js"

if ((Test-Path $extractScript) -and (Test-Path $consolidateScript)) {
    Write-Host "✅ Scripts verified" -ForegroundColor Green
} else {
    Write-Host "❌ Scripts not found in .memory-system/scripts/" -ForegroundColor Red
    exit 1
}

###############################################################################
# Step 5: Test installation
###############################################################################

Write-Host ""
Write-Host "🧪 Step 5: Testing installation..." -ForegroundColor Yellow

# Test extract-memory.js
try {
    $output = & node $extractScript stats 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ extract-memory.js working" -ForegroundColor Green
    } else {
        throw "Script failed"
    }
} catch {
    Write-Host "❌ extract-memory.js failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Test consolidate-claude-md.js
try {
    $env:MEMORY_DIR = $MEMORY_DIR
    $env:OUTPUT_FILE = Join-Path $PROJECT_ROOT "CLAUDE.md.test"
    $output = & node $consolidateScript 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ consolidate-claude-md.js working" -ForegroundColor Green
        Remove-Item -Path (Join-Path $PROJECT_ROOT "CLAUDE.md.test") -ErrorAction SilentlyContinue
        Remove-Item -Path (Join-Path $PROJECT_ROOT "CLAUDE.md.test.backup") -ErrorAction SilentlyContinue
    } else {
        throw "Script failed"
    }
} catch {
    Write-Host "❌ consolidate-claude-md.js failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

###############################################################################
# Step 6: Create .gitignore entries
###############################################################################

Write-Host ""
Write-Host "📝 Step 6: Configuring Git ignore..." -ForegroundColor Yellow

$GITIGNORE = Join-Path $PROJECT_ROOT ".gitignore"

if (Test-Path $GITIGNORE) {
    $content = Get-Content $GITIGNORE -Raw
    if ($content -notlike "*`.memory/snapshots/*") {
        Add-Content -Path $GITIGNORE -Value "`n# Memory-MCP (keep state.json, ignore snapshots)"
        Add-Content -Path $GITIGNORE -Value ".memory/snapshots/"
        Add-Content -Path $GITIGNORE -Value ".memory-system/logs/"
        Add-Content -Path $GITIGNORE -Value "CLAUDE.md.backup"
        Write-Host "✅ Added entries to .gitignore" -ForegroundColor Green
    } else {
        Write-Host "⚠️  .gitignore entries already exist" -ForegroundColor Yellow
    }
} else {
    Set-Content -Path $GITIGNORE -Value @"
# Memory-MCP
.memory/snapshots/
.memory-system/logs/
CLAUDE.md.backup
"@
    Write-Host "✅ Created .gitignore" -ForegroundColor Green
}

###############################################################################
# Step 7: Generate initial CLAUDE.md
###############################################################################

Write-Host ""
Write-Host "📄 Step 7: Generating initial CLAUDE.md..." -ForegroundColor Yellow

$env:MEMORY_DIR = $MEMORY_DIR
$env:OUTPUT_FILE = Join-Path $PROJECT_ROOT "CLAUDE.md"

& node $consolidateScript

Write-Host "✅ CLAUDE.md generated" -ForegroundColor Green

###############################################################################
# Step 8: Installation complete
###############################################################################

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "🎉 Installation Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Memory Statistics:" -ForegroundColor Yellow
& node $extractScript stats
Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Test with a feature:"
Write-Host "   cd docs\features"
Write-Host "   mkdir FEAT-TEST\context -Force"
Write-Host "   # Create spec.md with Technical Decisions table"
Write-Host ""
Write-Host "2. Extract memories:"
Write-Host "   node .memory-system\scripts\extract-memory.js interview FEAT-TEST docs\features\FEAT-TEST\spec.md"
Write-Host ""
Write-Host "3. Generate CLAUDE.md:"
Write-Host "   node .memory-system\scripts\consolidate-claude-md.js"
Write-Host ""
Write-Host "4. View CLAUDE.md:"
Write-Host "   cat CLAUDE.md"
Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor Cyan
Write-Host "   - Integration Plan: docs\memory-integration-plan.md"
Write-Host "   - Implementation Guide: docs\memory-implementation-guide.md"
Write-Host "   - Examples: docs\memory-integration-examples.md"
Write-Host "   - Command Reference: COMMAND_REFERENCE.md"
Write-Host ""
Write-Host "✨ Memory system ready to use!" -ForegroundColor Green
